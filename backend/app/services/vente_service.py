import uuid
from datetime import datetime, timezone
from typing import Dict, List
from fastapi import HTTPException, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.permissions import normalize_tenant_role
from app.models import AuditLog, Client, Product, Vente, VenteItem
from app.schemas.entities import VenteCreate
from app.services.entitlements import check_feature_access
from app.services.stock_service import adjust_magasin_stock, check_and_get_availability
from app.services.tenant_context_service import TenantContext, resolve_operational_magasin


def _generate_unique_ticket_number(db: Session, boutique_id: str, today_str: str, salt: bool = False) -> str:
    prefix = f"VNT-{today_str}-"
    existing_rows = (
        db.query(Vente.ticket_number)
        .filter(Vente.boutique_id == boutique_id, Vente.ticket_number.like(f"{prefix}%"))
        .all()
    )
    max_seq = 0
    for (tnum,) in existing_rows:
        suffix = tnum[len(prefix):].split("-")[0]
        if suffix.isdigit():
            max_seq = max(max_seq, int(suffix))
    next_seq = max_seq + 1
    if salt:
        return f"{prefix}{next_seq:04d}-{uuid.uuid4().hex[:4].upper()}"
    return f"{prefix}{next_seq:04d}"


def create_vente_transaction(
    db: Session, ctx: TenantContext, vente_in: VenteCreate
) -> Vente:
    """Create a validated POS sale with server-derived prices/COGS and atomic stock deduction."""
    check_feature_access(db, ctx.boutique.id, "module_pos_sales")
    if not vente_in.items:
        raise HTTPException(status_code=400, detail="La vente doit contenir au moins un article.")
    magasin = resolve_operational_magasin(
        db, ctx, body_magasin_id=vente_in.magasin_id, allow_warehouse=False
    )

    current_user = ctx.user
    eff_role = normalize_tenant_role(ctx.role)
    v_uid = current_user.id
    v_uname = current_user.full_name or current_user.username
    vente_sync_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc)
    today_str = now.strftime("%Y%m%d")
    ticket_num = _generate_unique_ticket_number(db, ctx.boutique.id, today_str)

    db_items: List[VenteItem] = []
    price_overrides: List[Dict] = []
    calculated_subtotal = 0.0

    for item_in in vente_in.items:
        prod = (
            db.query(Product)
            .filter(
                Product.sync_id == item_in.product_sync_id,
                Product.boutique_id == ctx.boutique.id,
                Product.deleted_at.is_(None),
            )
            .first()
        )
        if not prod:
            raise HTTPException(status_code=404, detail=f"Produit ID {item_in.product_sync_id} introuvable")

        _, effective_price = check_and_get_availability(db, ctx.boutique.id, magasin.id, prod)
        if item_in.unit_price is not None and abs(float(item_in.unit_price) - effective_price) > 0.01:
            if eff_role == "cashier":
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Seul un gérant ou propriétaire peut modifier le prix unitaire",
                )
            unit_price = round(float(item_in.unit_price), 2)
            price_overrides.append({
                "product_sync_id": prod.sync_id,
                "product_name": prod.name,
                "catalogue_price": effective_price,
                "applied_price": unit_price,
            })
        else:
            unit_price = effective_price

        sm, _, _ = adjust_magasin_stock(
            db=db,
            boutique_id=ctx.boutique.id,
            magasin_id=magasin.id,
            product=prod,
            quantity_delta=-item_in.quantity,
            enforce_sufficient=True,
            movement_type="sale",
            reference_type="vente",
            reference_id=vente_sync_id,
            reason=f"Vente {ticket_num}",
            user_id=v_uid,
            user_name=v_uname,
        )

        line_total = round(item_in.quantity * unit_price, 2)
        calculated_subtotal += line_total
        server_cost = float(
            sm.average_cost_price or sm.cost_price or prod.average_cost_price or prod.cost_price or 0.0
        )

        db_items.append(
            VenteItem(
                sync_id=str(uuid.uuid4()),
                vente_sync_id=vente_sync_id,
                product_sync_id=prod.sync_id,
                product_name=prod.name,
                quantity=item_in.quantity,
                unit_price=unit_price,
                cost_price=server_cost,
                total=line_total,
            )
        )

    if vente_in.discount_amount > calculated_subtotal + 1e-6:
        raise HTTPException(
            status_code=400,
            detail="La remise ne peut pas dépasser le sous-total de la vente.",
        )

    net_total = max(0.0, round(calculated_subtotal - vente_in.discount_amount, 2))
    if vente_in.payment_method == "Crédit" or vente_in.paid_amount < net_total:
        check_feature_access(db, ctx.boutique.id, "module_credit_sales")

    target_client = None
    client_name = vente_in.client_name
    if vente_in.client_sync_id:
        target_client = (
            db.query(Client)
            .filter(
                Client.sync_id == vente_in.client_sync_id,
                Client.boutique_id == ctx.boutique.id,
                Client.deleted_at.is_(None),
            )
            .first()
        )
        if not target_client:
            raise HTTPException(status_code=404, detail="Client introuvable dans cette boutique")
        client_name = target_client.name
        if vente_in.paid_amount < net_total:
            target_client.balance += round(net_total - vente_in.paid_amount, 2)
            target_client.updated_at = now

    new_vente = Vente(
        sync_id=vente_sync_id,
        boutique_id=ctx.boutique.id,
        magasin_id=magasin.id,
        ticket_number=ticket_num,
        client_sync_id=target_client.sync_id if target_client else None,
        client_name=client_name or "Client Occasionnel",
        user_id=v_uid,
        user_name=v_uname,
        total_amount=net_total,
        paid_amount=vente_in.paid_amount,
        discount_amount=vente_in.discount_amount,
        payment_method=vente_in.payment_method,
        notes=vente_in.notes,
        created_at=now,
        updated_at=now,
    )
    for item in db_items:
        new_vente.items.append(item)

    db.add(new_vente)
    db.add(AuditLog(
        id=f"audit-{vente_sync_id}",
        boutique_id=ctx.boutique.id,
        user_id=v_uid,
        user_name=v_uname,
        action="SALE_CREATE",
        entity_type="vente",
        entity_id=vente_sync_id,
        details={
            "ticket_number": ticket_num,
            "total_amount": net_total,
            "paid_amount": vente_in.paid_amount,
            "client_name": client_name or "Client Occasionnel",
            "payment_method": vente_in.payment_method,
            "item_count": len(db_items),
            "source": "backoffice",
        },
        created_at=now,
    ))
    if price_overrides:
        db.add(AuditLog(
            boutique_id=ctx.boutique.id,
            user_id=v_uid,
            user_name=v_uname,
            action="PRICE_OVERRIDE",
            entity_type="vente",
            entity_id=vente_sync_id,
            details={"ticket_number": ticket_num, "overrides": price_overrides},
            created_at=now,
        ))

    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        new_vente.ticket_number = _generate_unique_ticket_number(db, ctx.boutique.id, today_str, salt=True)
        db.add(new_vente)
        db.commit()
    db.refresh(new_vente)
    return new_vente
