from typing import Any, Dict, List, Optional
from datetime import date, datetime, timedelta, timezone
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import func, desc

from app.api import deps
from app.core.database import get_db
from app.models import Vente, VenteItem, Product, Client, Decaissement, User
from app.schemas.entities import (
    FinancialReportResponse, FinancialKPIs, TopProductItem, ExpenseCategoryItem
)
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

@router.get("/financial", response_model=FinancialReportResponse)
def get_financial_report(
    start_date: Optional[datetime] = Query(None),
    end_date: Optional[datetime] = Query(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(deps.require_role(["admin", "manager"])),
) -> Any:
    """Rapport de rentabilité complet : Compte de résultat, COGS, Marge brute, Dépenses et Résultat Net."""
    now = datetime.now(timezone.utc)
    # Période par défaut : les 30 derniers jours si non spécifiée
    if not start_date:
        start_date = now - timedelta(days=30)
    if not end_date:
        end_date = now

    # 1. Requête Ventes dans la période
    vente_q = db.query(Vente).filter(
        Vente.deleted_at.is_(None),
        Vente.created_at >= start_date,
        Vente.created_at <= end_date,
    )
    ventes = vente_q.all()

    gross_sales = sum(v.total_amount for v in ventes)
    discount_amount = sum(v.discount_amount for v in ventes)
    net_sales = gross_sales

    # 2. Calcul du COGS via VenteItem
    vente_ids = [v.sync_id for v in ventes]
    cogs = 0.0
    top_prods_map: Dict[str, Dict[str, float]] = {}

    if vente_ids:
        items = db.query(VenteItem).filter(VenteItem.vente_sync_id.in_(vente_ids)).all()
        for it in items:
            item_cogs = round(it.quantity * (it.cost_price or 0.0), 2)
            cogs += item_cogs

            pname = it.product_name
            if pname not in top_prods_map:
                top_prods_map[pname] = {"quantity": 0.0, "revenue": 0.0, "profit": 0.0}
            top_prods_map[pname]["quantity"] += it.quantity
            top_prods_map[pname]["revenue"] += it.total
            top_prods_map[pname]["profit"] += (it.total - item_cogs)

    gross_margin = round(net_sales - cogs, 2)
    gross_margin_rate = round((gross_margin / net_sales * 100), 2) if net_sales > 0 else 0.0

    # 3. Requête Décaissements dans la période
    dec_q = db.query(Decaissement).filter(
        Decaissement.deleted_at.is_(None),
        Decaissement.date >= start_date,
        Decaissement.date <= end_date,
    )
    decaissements = dec_q.all()
    total_expenses = round(sum(d.amount for d in decaissements), 2)

    net_profit = round(gross_margin - total_expenses, 2)
    net_margin_rate = round((net_profit / net_sales * 100), 2) if net_sales > 0 else 0.0

    # 4. Top produits
    sorted_prods = sorted(top_prods_map.items(), key=lambda x: x[1]["revenue"], reverse=True)[:10]
    top_products = [
        TopProductItem(
            product_name=name,
            quantity_sold=data["quantity"],
            total_revenue=round(data["revenue"], 2),
            total_profit=round(data["profit"], 2),
        )
        for name, data in sorted_prods
    ]

    # 5. Répartition des dépenses par catégorie
    cat_exp_map: Dict[str, float] = {}
    for d in decaissements:
        cat_name = d.category or "Général"
        cat_exp_map[cat_name] = cat_exp_map.get(cat_name, 0.0) + d.amount

    expenses_by_category = [
        ExpenseCategoryItem(
            category=cat,
            total_amount=round(amount, 2),
            percentage=round((amount / total_expenses * 100), 2) if total_expenses > 0 else 0.0,
        )
        for cat, amount in sorted(cat_exp_map.items(), key=lambda x: x[1], reverse=True)
    ]

    # 6. Évolution mensuelle (derniers 6 mois)
    monthly_trend = []
    for i in range(5, -1, -1):
        m_start = datetime(now.year, now.month, 1, tzinfo=timezone.utc) - timedelta(days=i*30)
        m_end = m_start + timedelta(days=30)
        month_label = m_start.strftime("%b %Y")

        m_sales = db.query(func.coalesce(func.sum(Vente.total_amount), 0.0)).filter(
            Vente.deleted_at.is_(None),
            Vente.created_at >= m_start,
            Vente.created_at < m_end,
        ).scalar() or 0.0

        m_exp = db.query(func.coalesce(func.sum(Decaissement.amount), 0.0)).filter(
            Decaissement.deleted_at.is_(None),
            Decaissement.date >= m_start,
            Decaissement.date < m_end,
        ).scalar() or 0.0

        monthly_trend.append({
            "period": month_label,
            "sales": round(float(m_sales), 2),
            "expenses": round(float(m_exp), 2),
            "profit": round(float(m_sales) - float(m_exp), 2),
        })

    return FinancialReportResponse(
        start_date=start_date.isoformat(),
        end_date=end_date.isoformat(),
        kpis=FinancialKPIs(
            gross_sales=round(gross_sales, 2),
            discount_amount=round(discount_amount, 2),
            net_sales=round(net_sales, 2),
            cogs=round(cogs, 2),
            gross_margin=gross_margin,
            gross_margin_rate=gross_margin_rate,
            total_expenses=total_expenses,
            net_profit=net_profit,
            net_margin_rate=net_margin_rate,
        ),
        top_products=top_products,
        expenses_by_category=expenses_by_category,
        monthly_trend=monthly_trend,
    )
