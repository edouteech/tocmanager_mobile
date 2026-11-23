from typing import Optional, Tuple
from datetime import datetime, timedelta, timezone
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.models import Vente, VenteItem, Product, Decaissement, Category
from app.schemas.entities import (
    FinancialReportResponse, FinancialKPIs, TopProductItem, ExpenseCategoryItem
)


def _resolve_period_bounds(
    preset: Optional[str],
    start_date: Optional[datetime],
    end_date: Optional[datetime],
    now: datetime,
) -> Tuple[datetime, datetime]:
    if preset:
        p = preset.lower()
        if p == "today":
            start_date = datetime(now.year, now.month, now.day, 0, 0, 0, tzinfo=timezone.utc)
            end_date = datetime(now.year, now.month, now.day, 23, 59, 59, 999999, tzinfo=timezone.utc)
        elif p in ("thisweek", "week"):
            start_of_week = now - timedelta(days=now.weekday())
            start_date = datetime(start_of_week.year, start_of_week.month, start_of_week.day, 0, 0, 0, tzinfo=timezone.utc)
            end_date = start_date + timedelta(days=6, hours=23, minutes=59, seconds=59)
        elif p in ("thismonth", "month"):
            start_date = datetime(now.year, now.month, 1, 0, 0, 0, tzinfo=timezone.utc)
            next_m = datetime(now.year + 1, 1, 1, tzinfo=timezone.utc) if now.month == 12 else datetime(now.year, now.month + 1, 1, tzinfo=timezone.utc)
            end_date = next_m - timedelta(microseconds=1)
        elif p in ("thisyear", "year"):
            start_date = datetime(now.year, 1, 1, 0, 0, 0, tzinfo=timezone.utc)
            end_date = datetime(now.year, 12, 31, 23, 59, 59, 999999, tzinfo=timezone.utc)
        elif p in ("all", "alltime"):
            start_date = datetime(2000, 1, 1, 0, 0, 0, tzinfo=timezone.utc)
            end_date = datetime(2100, 1, 1, 0, 0, 0, tzinfo=timezone.utc)

    if not start_date:
        start_date = datetime(now.year, now.month, 1, 0, 0, 0, tzinfo=timezone.utc)
    if not end_date:
        next_m = datetime(now.year + 1, 1, 1, tzinfo=timezone.utc) if now.month == 12 else datetime(now.year, now.month + 1, 1, tzinfo=timezone.utc)
        end_date = next_m - timedelta(microseconds=1)
    return start_date, end_date


def compute_financial_report(
    db: Session,
    boutique_id: str,
    preset: Optional[str] = None,
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
) -> FinancialReportResponse:
    now = datetime.now(timezone.utc)
    start_date, end_date = _resolve_period_bounds(preset, start_date, end_date, now)

    ventes = (
        db.query(Vente)
        .filter(
            Vente.boutique_id == boutique_id,
            Vente.deleted_at.is_(None),
            Vente.created_at >= start_date,
            Vente.created_at <= end_date,
        )
        .all()
    )
    gross_sales = sum(v.total_amount for v in ventes)
    discount_amount = sum(v.discount_amount for v in ventes)
    net_sales = gross_sales

    vente_ids = [v.sync_id for v in ventes]
    cogs = 0.0
    top_prods_map: Dict[str, Dict[str, float]] = {}
    if vente_ids:
        for it in db.query(VenteItem).filter(VenteItem.vente_sync_id.in_(vente_ids)).all():
            item_cogs = round(it.quantity * (it.cost_price or 0.0), 2)
            cogs += item_cogs
            entry = top_prods_map.setdefault(
                it.product_name, {"quantity": 0.0, "revenue": 0.0, "profit": 0.0}
            )
            entry["quantity"] += it.quantity
            entry["revenue"] += it.total
            entry["profit"] += it.total - item_cogs

    gross_margin = round(net_sales - cogs, 2)
    gross_margin_rate = round((gross_margin / net_sales * 100), 2) if net_sales > 0 else 0.0

    decaissements = (
        db.query(Decaissement)
        .filter(
            Decaissement.boutique_id == boutique_id,
            Decaissement.deleted_at.is_(None),
            Decaissement.date >= start_date,
            Decaissement.date <= end_date,
        )
        .all()
    )
    total_expenses = round(sum(d.amount for d in decaissements), 2)
    net_profit = round(gross_margin - total_expenses, 2)
    net_margin_rate = round((net_profit / net_sales * 100), 2) if net_sales > 0 else 0.0
    net_cashflow = round(net_sales - total_expenses, 2)

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

    monthly_trend = []
    for i in range(5, -1, -1):
        m_start = datetime(now.year, now.month, 1, tzinfo=timezone.utc) - timedelta(days=i * 30)
        m_end = m_start + timedelta(days=30)
        m_sales = (
            db.query(func.coalesce(func.sum(Vente.total_amount), 0.0))
            .filter(
                Vente.boutique_id == boutique_id,
                Vente.deleted_at.is_(None),
                Vente.created_at >= m_start,
                Vente.created_at < m_end,
            )
            .scalar()
            or 0.0
        )
        m_exp = (
            db.query(func.coalesce(func.sum(Decaissement.amount), 0.0))
            .filter(
                Decaissement.boutique_id == boutique_id,
                Decaissement.deleted_at.is_(None),
                Decaissement.date >= m_start,
                Decaissement.date < m_end,
            )
            .scalar()
            or 0.0
        )
        monthly_trend.append({
            "period": m_start.strftime("%b %Y"),
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
            net_cashflow=net_cashflow,
        ),
        top_products=top_products,
        expenses_by_category=expenses_by_category,
        monthly_trend=monthly_trend,
    )
