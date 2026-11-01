from typing import Any, Dict
from datetime import date, datetime, timedelta, timezone
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.api import deps
from app.core.database import get_db
from app.models import Vente, VenteItem, Product, Client, Decaissement, User
from pydantic import BaseModel

router = APIRouter()

class DashboardStats(BaseModel):
    total_sales_amount: float
    total_sales_count: int
    today_sales_amount: float
    today_sales_count: int
    total_receivables: float
    total_expenses: float
    products_count: int
    low_stock_count: int

@router.get("/dashboard", response_model=DashboardStats)
def get_dashboard_stats(
    db: Session = Depends(get_db),
    current_user: User = Depends(deps.require_role(["admin", "manager"])),
) -> Any:
    today = datetime.now(timezone.utc).date()

    # Total Sales
    total_sales = db.query(
        func.coalesce(func.sum(Vente.total_amount), 0.0),
        func.count(Vente.sync_id)
    ).filter(Vente.deleted_at.is_(None)).first()

    # Today's Sales
    today_sales = db.query(
        func.coalesce(func.sum(Vente.total_amount), 0.0),
        func.count(Vente.sync_id)
    ).filter(Vente.deleted_at.is_(None), func.date(Vente.created_at) == today).first()

    # Client Receivables (Balance)
    receivables = db.query(func.coalesce(func.sum(Client.balance), 0.0)).filter(
        Client.balance > 0, Client.deleted_at.is_(None)
    ).scalar() or 0.0

    # Expenses (Decaissements)
    expenses = db.query(func.coalesce(func.sum(Decaissement.amount), 0.0)).filter(
        Decaissement.deleted_at.is_(None)
    ).scalar() or 0.0

    # Products count & Low Stock
    prods_count = db.query(func.count(Product.sync_id)).filter(Product.deleted_at.is_(None)).scalar() or 0
    low_stock = db.query(func.count(Product.sync_id)).filter(
        Product.deleted_at.is_(None),
        Product.stock <= Product.min_stock
    ).scalar() or 0

    return DashboardStats(
        total_sales_amount=float(total_sales[0]),
        total_sales_count=int(total_sales[1]),
        today_sales_amount=float(today_sales[0]),
        today_sales_count=int(today_sales[1]),
        total_receivables=float(receivables),
        total_expenses=float(expenses),
        products_count=int(prods_count),
        low_stock_count=int(low_stock),
    )
