import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from fastapi import HTTPException, status
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models import (
    AuditLog,
    Magasin,
    Product,
    ProductMagasinAvailability,
    StockTransfer,
    StockTransferItem,
)
from app.schemas.inventory import TransferCreate, TransferReceiveRequest
from app.services.stock_service import adjust_magasin_stock, ensure_stock_row
from app.services.tenant_context_service import TenantContext, resolve_operational_magasin


def _next_transfer_reference(db: Session, boutique_id: str, now: datetime) -> str:
    prefix = f"TRF-{now.strftime('%Y%m')}-"
    count = (
        db.query(func.count(StockTransfer.id))
        .filter(StockTransfer.boutique_id == boutique_id, StockTransfer.reference.like(f"{prefix}%"))
        .scalar()
        or 0
    )
    return f"{prefix}{(count + 1):04d}-{uuid.uuid4().hex[:3].upper()}"


def serialize_transfer(db: Session, transfer: StockTransfer) -> Dict[str, Any]:
    mag_names = {
        m.id: m.name
        for m in db.query(Magasin).filter(Magasin.boutique_id == transfer.boutique_id).all()
    }
    return {
        "id": transfer.id,
        "reference": transfer.reference,
        "from_magasin_id": transfer.from_magasin_id,
        "from_magasin_name": mag_names.get(transfer.from_magasin_id),
        "to_magasin_id": transfer.to_magasin_id,
        "to_magasin_name": mag_names.get(transfer.to_magasin_id),
        "status": transfer.status,
        "notes": transfer.notes,
        "created_by_user_id": transfer.created_by_user_id,
        "created_by_name": transfer.created_by_name,
        "shipped_at": transfer.shipped_at,
        "received_at": transfer.received_at,
        "received_by_name": transfer.received_by_name,
        "canceled_at": transfer.canceled_at,
        "created_at": transfer.created_at,
        "items": transfer.items,
    }


def list_transfers(
    db: Session, ctx: TenantContext, status_filter: Optional[str] = None, limit: int = 100
) -> List[Dict[str, Any]]:
    query = db.query(StockTransfer).filter(StockTransfer.boutique_id == ctx.boutique.id)
    if ctx.requested_magasin_id:
        query = query.filter(
            (StockTransfer.from_magasin_id == ctx.requested_magasin_id)
            | (StockTransfer.to_magasin_id == ctx.requested_magasin_id)
        )
    if status_filter:
        query = query.filter(StockTransfer.status == status_filter)
    rows = query.order_by(StockTransfer.created_at.desc()).limit(limit).all()
    return [serialize_transfer(db, t) for t in rows]


def create_transfer(db: Session, ctx: TenantContext, payload: TransferCreate) -> Dict[str, Any]:
    if payload.from_magasin_id == payload.to_magasin_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Le magasin source et le magasin destinataire doivent être distincts.",
        )

    from_mag = resolve_operational_magasin(
        db, ctx, body_magasin_id=payload.from_magasin_id, allow_warehouse=True
    )
    to_mag = (
        db.query(Magasin)
        .filter(
            Magasin.id == payload.to_magasin_id,
            Magasin.boutique_id == ctx.boutique.id,
            Magasin.is_active == True,
        )
        .first()
    )
    if not to_mag:
        raise HTTPException(status_code=404, detail="Magasin destinataire introuvable ou inactif.")

    now = datetime.now(timezone.utc)
    uid = ctx.user.id
    uname = ctx.user.full_name or ctx.user.username
    transfer_id = str(uuid.uuid4())
    reference = _next_transfer_reference(db, ctx.boutique.id, now)

    transfer = StockTransfer(
        id=transfer_id,
        boutique_id=ctx.boutique.id,
        reference=reference,
        from_magasin_id=from_mag.id,
        to_magasin_id=to_mag.id,
        status="in_transit" if payload.ship_immediately else "draft",
        notes=payload.notes,
        created_by_user_id=uid,
        created_by_name=uname,
        shipped_at=now if payload.ship_immediately else None,
        created_at=now,
        updated_at=now,
    )
    db.add(transfer)

    for line in payload.items:
        prod = db.query(Product).filter(
            Product.sync_id == line.product_sync_id,
            Product.boutique_id == ctx.boutique.id,
            Product.deleted_at.is_(None),
        ).first()
        if not prod:
            raise HTTPException(status_code=404, detail=f"Produit {line.product_sync_id} introuvable.")
        sm_src = ensure_stock_row(db, ctx.boutique.id, from_mag.id, prod)
        unit_cost = float(sm_src.average_cost_price or sm_src.cost_price or prod.cost_price or 0.0)
        db.add(StockTransferItem(
            transfer_id=transfer_id,
            product_sync_id=prod.sync_id,
            product_name=prod.name,
            quantity_sent=line.quantity_sent,
            unit_cost=unit_cost,
        ))
        if payload.ship_immediately:
            adjust_magasin_stock(
                db=db,
                boutique_id=ctx.boutique.id,
                magasin_id=from_mag.id,
                product=prod,
                quantity_delta=-line.quantity_sent,
                enforce_sufficient=True,
                movement_type="transfer_out",
                reference_type="transfer",
                reference_id=transfer_id,
                reason=f"Transfert vers {to_mag.name} ({reference})",
                user_id=uid,
                user_name=uname,
            )

    db.add(AuditLog(
        boutique_id=ctx.boutique.id,
        user_id=uid,
        user_name=uname,
        action="TRANSFER_CREATE",
        entity_type="stock_transfer",
        entity_id=transfer_id,
        details={"reference": reference, "from": from_mag.name, "to": to_mag.name, "items": len(payload.items)},
        created_at=now,
    ))
    db.commit()
    db.refresh(transfer)
    return serialize_transfer(db, transfer)


def receive_transfer(
    db: Session, ctx: TenantContext, transfer_id: str, payload: TransferReceiveRequest
) -> Dict[str, Any]:
    q = db.query(StockTransfer).filter(StockTransfer.id == transfer_id, StockTransfer.boutique_id == ctx.boutique.id)
    transfer = (q.with_for_update() if db.bind and db.bind.dialect.name == "postgresql" else q).first()
    if not transfer:
        raise HTTPException(status_code=404, detail="Bon de transfert introuvable.")
    if transfer.status != "in_transit":
        raise HTTPException(status_code=400, detail=f"Impossible de réceptionner un transfert au statut '{transfer.status}'.")

    recv_map = {it.product_sync_id: it.quantity_received for it in (payload.items or [])}
    now = datetime.now(timezone.utc)
    uid, uname = ctx.user.id, (ctx.user.full_name or ctx.user.username)

    for item in transfer.items:
        qty_in = recv_map.get(item.product_sync_id, item.quantity_sent)
        item.quantity_received = qty_in
        prod = db.query(Product).filter(Product.sync_id == item.product_sync_id, Product.boutique_id == ctx.boutique.id).first()
        if prod and qty_in > 0:
            avail = db.query(ProductMagasinAvailability).filter(
                ProductMagasinAvailability.magasin_id == transfer.to_magasin_id,
                ProductMagasinAvailability.product_sync_id == prod.sync_id,
            ).first()
            if not avail:
                db.add(ProductMagasinAvailability(
                    boutique_id=ctx.boutique.id, magasin_id=transfer.to_magasin_id,
                    product_sync_id=prod.sync_id, is_available=True,
                ))
            adjust_magasin_stock(
                db=db, boutique_id=ctx.boutique.id, magasin_id=transfer.to_magasin_id,
                product=prod, quantity_delta=qty_in, enforce_sufficient=False,
                new_unit_cost=item.unit_cost if item.unit_cost > 0 else None,
                movement_type="transfer_in", reference_type="transfer", reference_id=transfer.id,
                reason=f"Réception transfert {transfer.reference}", user_id=uid, user_name=uname,
            )

    transfer.status = "received"
    transfer.received_at = now
    transfer.received_by_user_id = uid
    transfer.received_by_name = uname
    if payload.notes:
        transfer.notes = f"{transfer.notes or ''}\n{payload.notes}".strip()
    db.commit()
    db.refresh(transfer)
    return serialize_transfer(db, transfer)


def cancel_transfer(db: Session, ctx: TenantContext, transfer_id: str) -> Dict[str, Any]:
    transfer = db.query(StockTransfer).filter(StockTransfer.id == transfer_id, StockTransfer.boutique_id == ctx.boutique.id).first()
    if not transfer:
        raise HTTPException(status_code=404, detail="Bon de transfert introuvable.")
    if transfer.status not in ("draft", "in_transit"):
        raise HTTPException(status_code=400, detail=f"Impossible d'annuler un transfert au statut '{transfer.status}'.")

    now = datetime.now(timezone.utc)
    uid, uname = ctx.user.id, (ctx.user.full_name or ctx.user.username)
    if transfer.status == "in_transit":
        for item in transfer.items:
            prod = db.query(Product).filter(Product.sync_id == item.product_sync_id, Product.boutique_id == ctx.boutique.id).first()
            if prod:
                adjust_magasin_stock(
                    db=db, boutique_id=ctx.boutique.id, magasin_id=transfer.from_magasin_id,
                    product=prod, quantity_delta=item.quantity_sent, enforce_sufficient=False,
                    movement_type="adjustment", reference_type="transfer", reference_id=transfer.id,
                    reason=f"Annulation transfert {transfer.reference}", user_id=uid, user_name=uname,
                )
    transfer.status = "canceled"
    transfer.canceled_at = now
    db.commit()
    db.refresh(transfer)
    return serialize_transfer(db, transfer)
