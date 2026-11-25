from datetime import datetime, timezone
from typing import Optional
from sqlalchemy.orm import Session

from app.models import Magasin, Product
from app.services.stock_service import ensure_stock_row, sync_product_total_stock
from app.services.tenant_context_service import TenantContext


def belongs_to_other_boutique(record, boutique_id: str) -> bool:
    return record is not None and record.boutique_id is not None and record.boutique_id != boutique_id


def aware_dt(dt: Optional[datetime]) -> Optional[datetime]:
    if dt is None:
        return None
    return dt.replace(tzinfo=timezone.utc) if dt.tzinfo is None else dt


def should_apply_incoming_balance(
    incoming_updated_at: Optional[datetime],
    latest_tx_dt: Optional[datetime],
) -> bool:
    inc = aware_dt(incoming_updated_at)
    tx = aware_dt(latest_tx_dt)
    return bool(inc and tx and inc > tx)


def resolve_target_magasin_id(
    db: Session,
    ctx: TenantContext,
    body_magasin_id: Optional[str],
) -> Optional[str]:
    boutique_id = ctx.boutique.id
    candidate = body_magasin_id or ctx.requested_magasin_id
    if candidate:
        mag = (
            db.query(Magasin)
            .filter(
                Magasin.id == candidate,
                Magasin.boutique_id == boutique_id,
                Magasin.is_active == True,
            )
            .first()
        )
        return mag.id if mag else None

    active_magasins = (
        db.query(Magasin.id)
        .filter(Magasin.boutique_id == boutique_id, Magasin.is_active == True)
        .limit(2)
        .all()
    )
    if len(active_magasins) == 1:
        return active_magasins[0][0]
    return None


def apply_pushed_product_stock(
    db: Session,
    ctx: TenantContext,
    product: Product,
    incoming_stock: float,
    incoming_min_stock: Optional[float],
    body_magasin_id: Optional[str],
) -> None:
    """Update StockMagasin for the resolved magasin and recompute Product.stock."""
    magasin_id = resolve_target_magasin_id(db, ctx, body_magasin_id)
    if not magasin_id:
        return
    stock_row = ensure_stock_row(
        db=db,
        boutique_id=ctx.boutique.id,
        magasin_id=magasin_id,
        product=product,
        for_update=True,
    )
    stock_row.quantity = float(incoming_stock)
    if incoming_min_stock is not None:
        stock_row.min_stock = float(incoming_min_stock)
    sync_product_total_stock(db=db, boutique_id=ctx.boutique.id, product=product)
