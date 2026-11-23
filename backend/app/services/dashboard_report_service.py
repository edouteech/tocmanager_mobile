from datetime import datetime, timezone
from typing import Dict, Optional
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models import (
    Category,
    Client,
    Decaissement,
    Magasin,
    Product,
    ProductMagasinAvailability,
    StockMagasin,
    Vente,
)


def compute_dashboard_stats(
    db: Session, boutique_id: str, magasin_id: Optional[str] = None
) -> Dict[str, float | int]:
    today = datetime.now(timezone.utc).date()

    v_base = db.query(Vente).filter(
        Vente.boutique_id == boutique_id,
        Vente.deleted_at.is_(None),
        Vente.status != "refunded",
    )
    if magasin_id:
        v_base = v_base.filter(Vente.magasin_id == magasin_id)
    total_sales = v_base.with_entities(
        func.coalesce(func.sum(Vente.total_amount), 0.0), func.count(Vente.sync_id)
    ).first()
    today_sales = (
        v_base.filter(func.date(Vente.created_at) == today)
        .with_entities(func.coalesce(func.sum(Vente.total_amount), 0.0), func.count(Vente.sync_id))
        .first()
    )
    receivables = (
        db.query(func.coalesce(func.sum(Client.balance), 0.0))
        .filter(Client.boutique_id == boutique_id, Client.balance > 0, Client.deleted_at.is_(None))
        .scalar()
        or 0.0
    )
    d_q = db.query(func.coalesce(func.sum(Decaissement.amount), 0.0)).filter(
        Decaissement.boutique_id == boutique_id, Decaissement.deleted_at.is_(None)
    )
    if magasin_id:
        d_q = d_q.filter(Decaissement.magasin_id == magasin_id)
    expenses = d_q.scalar() or 0.0

    prods_count = (
        db.query(func.count(Product.sync_id))
        .filter(Product.boutique_id == boutique_id, Product.deleted_at.is_(None))
        .scalar()
        or 0
    )
    categories_count = (
        db.query(func.count(Category.sync_id))
        .filter(Category.boutique_id == boutique_id, Category.deleted_at.is_(None))
        .scalar()
        or 0
    )

    if magasin_id:
        low_stock = (
            db.query(func.count(Product.sync_id))
            .outerjoin(
                StockMagasin,
                (StockMagasin.product_sync_id == Product.sync_id)
                & (StockMagasin.magasin_id == magasin_id),
            )
            .outerjoin(
                ProductMagasinAvailability,
                (ProductMagasinAvailability.product_sync_id == Product.sync_id)
                & (ProductMagasinAvailability.magasin_id == magasin_id),
            )
            .filter(
                Product.boutique_id == boutique_id,
                Product.deleted_at.is_(None),
                func.coalesce(ProductMagasinAvailability.is_available, True) == True,
                func.coalesce(StockMagasin.quantity, 0.0) <= func.coalesce(StockMagasin.min_stock, Product.min_stock),
            )
            .scalar()
            or 0
        )
        stock_value = (
            db.query(
                func.coalesce(
                    func.sum(
                        func.coalesce(ProductMagasinAvailability.custom_price, Product.price)
                        * StockMagasin.quantity
                    ),
                    0.0,
                )
            )
            .join(Product, Product.sync_id == StockMagasin.product_sync_id)
            .outerjoin(
                ProductMagasinAvailability,
                (ProductMagasinAvailability.product_sync_id == StockMagasin.product_sync_id)
                & (ProductMagasinAvailability.magasin_id == magasin_id),
            )
            .filter(
                StockMagasin.boutique_id == boutique_id,
                StockMagasin.magasin_id == magasin_id,
                Product.deleted_at.is_(None),
            )
            .scalar()
            or 0.0
        )
        stock_cost = (
            db.query(
                func.coalesce(
                    func.sum(
                        func.coalesce(
                            StockMagasin.average_cost_price,
                            StockMagasin.cost_price,
                            Product.average_cost_price,
                            Product.cost_price,
                        )
                        * StockMagasin.quantity
                    ),
                    0.0,
                )
            )
            .join(Product, Product.sync_id == StockMagasin.product_sync_id)
            .filter(
                StockMagasin.boutique_id == boutique_id,
                StockMagasin.magasin_id == magasin_id,
                Product.deleted_at.is_(None),
            )
            .scalar()
            or 0.0
        )
    else:
        low_stock = (
            db.query(func.count(Product.sync_id))
            .filter(
                Product.boutique_id == boutique_id,
                Product.deleted_at.is_(None),
                Product.stock <= Product.min_stock,
            )
            .scalar()
            or 0
        )
        sm_val = (
            db.query(
                func.coalesce(
                    func.sum(func.coalesce(ProductMagasinAvailability.custom_price, Product.price) * StockMagasin.quantity),
                    0.0,
                ),
                func.coalesce(
                    func.sum(
                        func.coalesce(StockMagasin.average_cost_price, StockMagasin.cost_price, Product.average_cost_price, Product.cost_price)
                        * StockMagasin.quantity
                    ),
                    0.0,
                ),
            )
            .join(Product, Product.sync_id == StockMagasin.product_sync_id)
            .join(Magasin, Magasin.id == StockMagasin.magasin_id)
            .outerjoin(
                ProductMagasinAvailability,
                (ProductMagasinAvailability.product_sync_id == StockMagasin.product_sync_id)
                & (ProductMagasinAvailability.magasin_id == StockMagasin.magasin_id),
            )
            .filter(StockMagasin.boutique_id == boutique_id, Magasin.is_active == True, Product.deleted_at.is_(None))
            .first()
        )
        stock_value, stock_cost = float(sm_val[0] or 0.0), float(sm_val[1] or 0.0)

    return {
        "total_sales_amount": float(total_sales[0] or 0.0),
        "total_sales_count": int(total_sales[1] or 0),
        "today_sales_amount": float(today_sales[0] or 0.0),
        "today_sales_count": int(today_sales[1] or 0),
        "total_receivables": float(receivables),
        "total_expenses": float(expenses),
        "products_count": int(prods_count),
        "low_stock_count": int(low_stock),
        "categories_count": int(categories_count),
        "stock_value": round(float(stock_value), 2),
        "stock_cost": round(float(stock_cost), 2),
    }
