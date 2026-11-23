from datetime import datetime, timezone
from typing import Optional, Tuple
from fastapi import HTTPException, status
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models import Magasin, Product, ProductMagasinAvailability, StockMagasin


def _row_query(query, db: Session):
    if db.bind and db.bind.dialect.name == "postgresql":
        return query.with_for_update()
    return query


def ensure_stock_row(
    db: Session,
    boutique_id: str,
    magasin_id: str,
    product: Product,
    for_update: bool = False,
) -> StockMagasin:
    """Fetch or create a StockMagasin row for (magasin_id, product.sync_id)."""
    q = db.query(StockMagasin).filter(
        StockMagasin.boutique_id == boutique_id,
        StockMagasin.magasin_id == magasin_id,
        StockMagasin.product_sync_id == product.sync_id,
    )
    row = (_row_query(q, db) if for_update else q).first()
    if not row:
        row = StockMagasin(
            boutique_id=boutique_id,
            magasin_id=magasin_id,
            product_sync_id=product.sync_id,
            quantity=0.0,
            min_stock=product.min_stock or 5.0,
            cost_price=product.cost_price or 0.0,
            average_cost_price=product.average_cost_price or product.cost_price or 0.0,
        )
        db.add(row)
        db.flush()
    return row


def sync_product_total_stock(db: Session, boutique_id: str, product: Product) -> float:
    """Recompute Product.stock as sum of active magasins' StockMagasin.quantity."""
    total = (
        db.query(func.coalesce(func.sum(StockMagasin.quantity), 0.0))
        .join(Magasin, Magasin.id == StockMagasin.magasin_id)
        .filter(
            StockMagasin.boutique_id == boutique_id,
            StockMagasin.product_sync_id == product.sync_id,
            Magasin.is_active == True,
        )
        .scalar()
        or 0.0
    )
    product.stock = round(float(total), 4)
    product.updated_at = datetime.now(timezone.utc)
    return product.stock


def check_and_get_availability(
    db: Session, boutique_id: str, magasin_id: str, product: Product
) -> Tuple[Optional[ProductMagasinAvailability], float]:
    """Ensure product is enabled in magasin and return its effective selling price."""
    avail = (
        db.query(ProductMagasinAvailability)
        .filter(
            ProductMagasinAvailability.boutique_id == boutique_id,
            ProductMagasinAvailability.magasin_id == magasin_id,
            ProductMagasinAvailability.product_sync_id == product.sync_id,
        )
        .first()
    )
    if avail and avail.is_available is False:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Le produit '{product.name}' est désactivé dans ce magasin.",
        )
    effective_price = avail.custom_price if (avail and avail.custom_price is not None) else product.price
    return avail, float(effective_price or 0.0)


def adjust_magasin_stock(
    db: Session,
    boutique_id: str,
    magasin_id: str,
    product: Product,
    quantity_delta: float,
    enforce_sufficient: bool = True,
    new_unit_cost: Optional[float] = None,
) -> Tuple[StockMagasin, float, float]:
    """Atomically increment/decrement StockMagasin and refresh weighted average cost."""
    row = ensure_stock_row(db, boutique_id, magasin_id, product, for_update=True)
    before = float(row.quantity or 0.0)
    after = round(before + float(quantity_delta), 4)
    if enforce_sufficient and quantity_delta < 0 and after < -1e-6:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Stock insuffisant pour '{product.name}' (Disponible: {before}, Demandé: {abs(quantity_delta)})",
        )
    if new_unit_cost is not None and quantity_delta > 0:
        pos_before = max(0.0, before)
        old_pamp = float(row.average_cost_price or row.cost_price or product.average_cost_price or 0.0)
        denom = pos_before + quantity_delta
        row.average_cost_price = round(((pos_before * old_pamp) + (quantity_delta * new_unit_cost)) / denom, 2) if denom > 0 else new_unit_cost
        row.cost_price = new_unit_cost
        product.cost_price = new_unit_cost
        product.average_cost_price = row.average_cost_price

    row.quantity = max(0.0, after) if enforce_sufficient else after
    row.last_updated_at = datetime.now(timezone.utc)
    sync_product_total_stock(db, boutique_id, product)
    return row, before, float(row.quantity)


def initialize_product_magasin_stocks(
    db: Session,
    boutique_id: str,
    product: Product,
    target_magasin_id: Optional[str],
    initial_stock: float,
) -> None:
    """Create initial StockMagasin and ProductMagasinAvailability entries for boutique magasins."""
    magasins = (
        db.query(Magasin)
        .filter(Magasin.boutique_id == boutique_id, Magasin.is_active == True)
        .order_by(Magasin.is_warehouse.asc(), Magasin.created_at.asc())
        .all()
    )
    if not magasins:
        return
    credit_mag_id = target_magasin_id or magasins[0].id
    for mag in magasins:
        qty = float(initial_stock) if mag.id == credit_mag_id else 0.0
        sm = ensure_stock_row(db, boutique_id, mag.id, product)
        sm.quantity = qty
        sm.min_stock = product.min_stock or 5.0
        sm.cost_price = product.cost_price or 0.0
        sm.average_cost_price = product.average_cost_price or product.cost_price or 0.0
        avail = db.query(ProductMagasinAvailability).filter(
            ProductMagasinAvailability.magasin_id == mag.id,
            ProductMagasinAvailability.product_sync_id == product.sync_id,
        ).first()
        if not avail:
            db.add(ProductMagasinAvailability(
                boutique_id=boutique_id,
                magasin_id=mag.id,
                product_sync_id=product.sync_id,
                is_available=True,
            ))
    db.flush()
    sync_product_total_stock(db, boutique_id, product)


def backfill_product_stocks_to_main_magasin(db: Session) -> None:
    """Idempotently populate StockMagasin rows for legacy products without per-magasin stock."""
    existing_pids = {row[0] for row in db.query(StockMagasin.product_sync_id).distinct().all()}
    for prod in db.query(Product).filter(Product.deleted_at.is_(None)).all():
        if prod.sync_id in existing_pids:
            continue
        mag = (
            db.query(Magasin)
            .filter(Magasin.boutique_id == prod.boutique_id, Magasin.is_active == True)
            .order_by(Magasin.is_warehouse.asc(), Magasin.created_at.asc())
            .first()
        )
        if not mag:
            continue
        db.add(StockMagasin(
            boutique_id=prod.boutique_id,
            magasin_id=mag.id,
            product_sync_id=prod.sync_id,
            quantity=float(prod.stock or 0.0),
            min_stock=float(prod.min_stock or 5.0),
            cost_price=float(prod.cost_price or 0.0),
            average_cost_price=float(prod.average_cost_price or prod.cost_price or 0.0),
        ))
        db.add(ProductMagasinAvailability(
            boutique_id=prod.boutique_id,
            magasin_id=mag.id,
            product_sync_id=prod.sync_id,
            is_available=True,
        ))
    db.commit()
