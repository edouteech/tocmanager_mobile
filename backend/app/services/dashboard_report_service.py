from datetime import datetime, timezone
from typing import Dict
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models import Category, Client, Decaissement, Product, Vente


def compute_dashboard_stats(db: Session, boutique_id: str) -> Dict[str, float | int]:
    today = datetime.now(timezone.utc).date()

    total_sales = (
        db.query(func.coalesce(func.sum(Vente.total_amount), 0.0), func.count(Vente.sync_id))
        .filter(Vente.boutique_id == boutique_id, Vente.deleted_at.is_(None))
        .first()
    )
    today_sales = (
        db.query(func.coalesce(func.sum(Vente.total_amount), 0.0), func.count(Vente.sync_id))
        .filter(
            Vente.boutique_id == boutique_id,
            Vente.deleted_at.is_(None),
            func.date(Vente.created_at) == today,
        )
        .first()
    )
    receivables = (
        db.query(func.coalesce(func.sum(Client.balance), 0.0))
        .filter(Client.boutique_id == boutique_id, Client.balance > 0, Client.deleted_at.is_(None))
        .scalar()
        or 0.0
    )
    expenses = (
        db.query(func.coalesce(func.sum(Decaissement.amount), 0.0))
        .filter(Decaissement.boutique_id == boutique_id, Decaissement.deleted_at.is_(None))
        .scalar()
        or 0.0
    )
    prods_count = (
        db.query(func.count(Product.sync_id))
        .filter(Product.boutique_id == boutique_id, Product.deleted_at.is_(None))
        .scalar()
        or 0
    )
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
    categories_count = (
        db.query(func.count(Category.sync_id))
        .filter(Category.boutique_id == boutique_id, Category.deleted_at.is_(None))
        .scalar()
        or 0
    )
    stock_value = (
        db.query(func.coalesce(func.sum(Product.price * Product.stock), 0.0))
        .filter(Product.boutique_id == boutique_id, Product.deleted_at.is_(None))
        .scalar()
        or 0.0
    )
    stock_cost = (
        db.query(func.coalesce(func.sum(Product.cost_price * Product.stock), 0.0))
        .filter(Product.boutique_id == boutique_id, Product.deleted_at.is_(None))
        .scalar()
        or 0.0
    )

    return {
        "total_sales_amount": float(total_sales[0]),
        "total_sales_count": int(total_sales[1]),
        "today_sales_amount": float(today_sales[0]),
        "today_sales_count": int(today_sales[1]),
        "total_receivables": float(receivables),
        "total_expenses": float(expenses),
        "products_count": int(prods_count),
        "low_stock_count": int(low_stock),
        "categories_count": int(categories_count),
        "stock_value": round(float(stock_value), 2),
        "stock_cost": round(float(stock_cost), 2),
    }
