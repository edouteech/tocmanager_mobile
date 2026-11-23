from datetime import datetime, timezone
from typing import Dict
from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models import AuditLog, Client, Magasin, Product, Vente, VenteItem
from app.schemas.cash import SaleRefundRequest
from app.services.stock_service import adjust_magasin_stock
from app.services.tenant_context_service import TenantContext


def refund_vente(
    db: Session, ctx: TenantContext, vente_sync_id: str, payload: SaleRefundRequest
) -> Vente:
    vente = (
        db.query(Vente)
        .filter(
            Vente.sync_id == vente_sync_id,
            Vente.boutique_id == ctx.boutique.id,
            Vente.deleted_at.is_(None),
        )
        .first()
    )
    if not vente:
        raise HTTPException(status_code=404, detail="Vente introuvable dans cette boutique.")
    if vente.status == "refunded":
        raise HTTPException(status_code=400, detail="Cette vente a déjà été entièrement remboursée.")

    items_by_id: Dict[str, VenteItem] = {it.sync_id: it for it in vente.items}
    refund_lines: Dict[str, float] = {}
    if payload.items:
        for req in payload.items:
            it = items_by_id.get(req.vente_item_sync_id)
            if not it:
                raise HTTPException(status_code=404, detail=f"Ligne de vente {req.vente_item_sync_id} introuvable.")
            remaining = round(float(it.quantity) - float(it.refunded_quantity or 0.0), 4)
            if req.quantity > remaining + 1e-6:
                raise HTTPException(
                    status_code=400,
                    detail=f"Quantité à rembourser ({req.quantity}) supérieure au solde remboursable ({remaining}) pour '{it.product_name}'.",
                )
            refund_lines[it.sync_id] = req.quantity
    else:
        for it in vente.items:
            remaining = round(float(it.quantity) - float(it.refunded_quantity or 0.0), 4)
            if remaining > 0:
                refund_lines[it.sync_id] = remaining

    if not refund_lines:
        raise HTTPException(status_code=400, detail="Aucun article remboursable restant sur ce ticket.")

    target_mag_id = vente.magasin_id
    if not target_mag_id:
        fallback_mag = (
            db.query(Magasin.id)
            .filter(Magasin.boutique_id == ctx.boutique.id, Magasin.is_active == True)
            .first()
        )
        target_mag_id = fallback_mag[0] if fallback_mag else None

    now = datetime.now(timezone.utc)
    uid = ctx.user.id
    uname = ctx.user.full_name or ctx.user.username
    refunded_value = 0.0

    for item_id, qty_ret in refund_lines.items():
        it = items_by_id[item_id]
        it.refunded_quantity = round(float(it.refunded_quantity or 0.0) + qty_ret, 4)
        refunded_value += round(qty_ret * float(it.unit_price), 2)
        if it.product_sync_id and target_mag_id:
            prod = db.query(Product).filter(
                Product.sync_id == it.product_sync_id, Product.boutique_id == ctx.boutique.id
            ).first()
            if prod:
                adjust_magasin_stock(
                    db=db,
                    boutique_id=ctx.boutique.id,
                    magasin_id=target_mag_id,
                    product=prod,
                    quantity_delta=qty_ret,
                    enforce_sufficient=False,
                    movement_type="return",
                    reference_type="vente",
                    reference_id=vente.sync_id,
                    reason=f"Retour vente {vente.ticket_number}: {payload.reason.strip()}",
                    user_id=uid,
                    user_name=uname,
                )

    all_refunded = all(
        float(it.refunded_quantity or 0.0) >= float(it.quantity) - 1e-6 for it in vente.items
    )
    vente.status = "refunded" if all_refunded else "partially_refunded"
    vente.updated_at = now

    if vente.client_sync_id and refunded_value > 0:
        client = db.query(Client).filter(
            Client.sync_id == vente.client_sync_id, Client.boutique_id == ctx.boutique.id
        ).first()
        if client and client.balance > 0:
            unpaid_on_sale = max(0.0, float(vente.total_amount) - float(vente.paid_amount))
            credit_reduce = min(client.balance, unpaid_on_sale if all_refunded else min(refunded_value, unpaid_on_sale))
            if credit_reduce > 0:
                client.balance = round(max(0.0, client.balance - credit_reduce), 2)
                client.updated_at = now

    db.add(AuditLog(
        boutique_id=ctx.boutique.id,
        user_id=uid,
        user_name=uname,
        action="SALE_REFUND",
        entity_type="vente",
        entity_id=vente.sync_id,
        details={
            "ticket_number": vente.ticket_number,
            "status": vente.status,
            "refunded_amount": round(refunded_value, 2),
            "reason": payload.reason.strip(),
        },
        created_at=now,
    ))
    db.commit()
    db.refresh(vente)
    return vente
