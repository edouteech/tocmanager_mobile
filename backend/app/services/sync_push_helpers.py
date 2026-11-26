from datetime import datetime, timezone
from typing import Optional, Set
from sqlalchemy.orm import Session

from app.models import Approvisionnement, Client, Magasin, Product, Supplier
from app.services.stock_service import ensure_stock_row, sync_product_total_stock
from app.services.tenant_context_service import TenantContext


def belongs_to_other_boutique(record, boutique_id: str) -> bool:
    return record is not None and record.boutique_id is not None and record.boutique_id != boutique_id


def aware_dt(dt: Optional[datetime]) -> Optional[datetime]:
    if dt is None:
        return None
    return dt.replace(tzinfo=timezone.utc) if dt.tzinfo is None else dt


def is_stale_update(
    existing_updated_at: Optional[datetime],
    incoming_updated_at: Optional[datetime],
) -> bool:
    """Return True when incoming timestamp is strictly older than persisted updated_at."""
    inc = aware_dt(incoming_updated_at)
    ext = aware_dt(existing_updated_at)
    return bool(inc and ext and inc < ext)


def should_apply_incoming_balance(
    incoming_updated_at: Optional[datetime],
    latest_tx_dt: Optional[datetime],
) -> bool:
    inc = aware_dt(incoming_updated_at)
    tx = aware_dt(latest_tx_dt)
    return bool(inc and tx and inc > tx)


def compute_appro_debt(
    total_cost: Optional[float],
    paid_amount: Optional[float],
    payment_status: Optional[str],
) -> float:
    total = float(total_cost or 0.0)
    if paid_amount is not None:
        return round(max(0.0, total - float(paid_amount)), 2)
    paid = total if (payment_status or "").lower().startswith("pay") else 0.0
    return round(max(0.0, total - paid), 2)


def recompute_magasin_pamp(
    db: Session,
    boutique_id: str,
    magasin_id: str,
    product: Product,
) -> float:
    """Recompute weighted average cost from active approvisionnements in magasin."""
    db.flush()
    rows = (
        db.query(Approvisionnement.quantity, Approvisionnement.unit_cost)
        .filter(
            Approvisionnement.boutique_id == boutique_id,
            Approvisionnement.magasin_id == magasin_id,
            Approvisionnement.product_sync_id == product.sync_id,
            Approvisionnement.deleted_at.is_(None),
            Approvisionnement.quantity > 0,
        )
        .all()
    )
    total_qty = sum(float(r[0] or 0.0) for r in rows)
    total_val = sum(float(r[0] or 0.0) * float(r[1] or 0.0) for r in rows)
    new_pamp = round(total_val / total_qty, 2) if total_qty > 0 else round(float(product.cost_price or 0.0), 2)
    sm = ensure_stock_row(db, boutique_id, magasin_id, product, for_update=True)
    sm.average_cost_price = new_pamp
    product.average_cost_price = new_pamp
    return new_pamp


def adjust_client_credit_delta(
    db: Session,
    boutique_id: str,
    client_sync_id: Optional[str],
    delta: float,
    applied_set: Set[str],
    now: datetime,
) -> None:
    if not client_sync_id or abs(delta) <= 1e-4 or client_sync_id in applied_set:
        return
    client = (
        db.query(Client)
        .filter(Client.sync_id == client_sync_id, Client.boutique_id == boutique_id)
        .first()
    )
    if client:
        client.balance = round(float(client.balance or 0.0) + delta, 2)
        client.updated_at = now


def adjust_supplier_debt_delta(
    db: Session,
    boutique_id: str,
    supplier_sync_id: Optional[str],
    delta: float,
    applied_set: Set[str],
    now: datetime,
) -> None:
    if not supplier_sync_id or abs(delta) <= 1e-4 or supplier_sync_id in applied_set:
        return
    sup = (
        db.query(Supplier)
        .filter(Supplier.sync_id == supplier_sync_id, Supplier.boutique_id == boutique_id)
        .first()
    )
    if sup:
        sup.balance = round(max(0.0, float(sup.balance or 0.0) + delta), 2)
        sup.updated_at = now


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
