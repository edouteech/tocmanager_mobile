import uuid
from typing import Any, List, Optional
from datetime import datetime, date, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.api import deps
from app.core.database import get_db
from app.models import Vente, VenteItem, Product, Client, AuditLog
from app.schemas.sync import VenteSync, VenteItemSync
from app.schemas.entities import VenteCreate
from app.services.entitlements import check_feature_access
from app.services.stock_service import adjust_magasin_stock, check_and_get_availability
from app.services.tenant_context_service import (
    TenantContext,
    resolve_operational_magasin,
    resolve_read_magasin_id,
)

router = APIRouter()


def _to_vente_sync(v: Vente) -> VenteSync:
    return VenteSync(
        sync_id=v.sync_id,
        magasin_id=v.magasin_id,
        ticket_number=v.ticket_number,
        client_sync_id=v.client_sync_id,
        client_name=v.client_name,
        user_id=v.user_id,
        user_name=v.user_name,
        total_amount=v.total_amount,
        paid_amount=v.paid_amount,
        discount_amount=v.discount_amount,
        payment_method=v.payment_method,
        status=getattr(v, "status", "completed") or "completed",
        notes=v.notes,
        created_at=v.created_at,
        updated_at=v.updated_at,
        items=[
            VenteItemSync(
                sync_id=it.sync_id,
                product_sync_id=it.product_sync_id,
                product_name=it.product_name,
                quantity=it.quantity,
                unit_price=it.unit_price,
                cost_price=it.cost_price,
                total=it.total,
            )
            for it in v.items
        ],
    )


@router.get("", response_model=List[VenteSync])
def list_ventes(
    skip: int = 0,
    limit: int = 100,
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    ctx: TenantContext = Depends(deps.get_tenant_context),
    db: Session = Depends(get_db),
) -> Any:
    magasin_id = resolve_read_magasin_id(ctx)
    query = db.query(Vente).filter(
        Vente.boutique_id == ctx.boutique.id, Vente.deleted_at.is_(None)
    )
    if magasin_id:
        query = query.filter(Vente.magasin_id == magasin_id)
    if start_date:
        query = query.filter(func.date(Vente.created_at) >= start_date)
    if end_date:
        query = query.filter(func.date(Vente.created_at) <= end_date)
    ventes = query.order_by(Vente.created_at.desc()).offset(skip).limit(limit).all()
    return [_to_vente_sync(v) for v in ventes]


@router.post("", response_model=VenteSync, status_code=status.HTTP_201_CREATED)
def create_vente(
    vente_in: VenteCreate,
    ctx: TenantContext = Depends(deps.get_tenant_context),
    db: Session = Depends(get_db),
) -> Any:
    check_feature_access(db, ctx.boutique.id, "module_pos_sales")
    if not vente_in.items:
        raise HTTPException(status_code=400, detail="La vente doit contenir au moins un article.")
    magasin = resolve_operational_magasin(
        db, ctx, body_magasin_id=vente_in.magasin_id, allow_warehouse=False
    )

    current_user = ctx.user
    v_uid = current_user.id
    v_uname = current_user.full_name or current_user.username
    vente_sync_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc)
    today_str = now.strftime("%Y%m%d")

    total_sales_count = (
        db.query(func.count(Vente.sync_id))
        .filter(Vente.boutique_id == ctx.boutique.id)
        .scalar()
        or 0
    )
    ticket_num = f"VNT-{today_str}-{(total_sales_count + 1):04d}"

    db_items = []
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
            raise HTTPException(
                status_code=404, detail=f"Produit ID {item_in.product_sync_id} introuvable"
            )
        _, effective_price = check_and_get_availability(db, ctx.boutique.id, magasin.id, prod)
        unit_price = item_in.unit_price if item_in.unit_price is not None else effective_price
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
        cost_price = (
            item_in.cost_price
            if item_in.cost_price is not None
            else (sm.average_cost_price or sm.cost_price or prod.average_cost_price or prod.cost_price or 0.0)
        )

        db_items.append(
            VenteItem(
                sync_id=str(uuid.uuid4()),
                product_sync_id=prod.sync_id,
                product_name=prod.name,
                quantity=item_in.quantity,
                unit_price=unit_price,
                cost_price=cost_price,
                total=line_total,
            )
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
        item.vente_sync_id = vente_sync_id
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
    db.commit()
    db.refresh(new_vente)
    return _to_vente_sync(new_vente)


@router.get("/{sync_id}", response_model=VenteSync)
def get_vente(
    sync_id: str,
    ctx: TenantContext = Depends(deps.get_tenant_context),
    db: Session = Depends(get_db),
) -> Any:
    v = (
        db.query(Vente)
        .filter(Vente.sync_id == sync_id, Vente.boutique_id == ctx.boutique.id)
        .first()
    )
    if not v:
        raise HTTPException(status_code=404, detail="Vente non trouvée")
    return _to_vente_sync(v)
