from typing import Dict, List, Optional, Tuple
from datetime import datetime, timedelta, timezone
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models import Decaissement, Vente, VenteItem
from app.schemas.entities import (
    ExpenseCategoryItem,
    FinancialKPIs,
    FinancialReportResponse,
    TopProductItem,
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


def _calendar_month_window(ref: datetime, months_back: int) -> Tuple[datetime, datetime]:
    total_m = (ref.year * 12 + (ref.month - 1)) - months_back
    year, zero_month = divmod(total_m, 12)
    month = zero_month + 1
    m_start = datetime(year, month, 1, 0, 0, 0, tzinfo=timezone.utc)
    if month == 12:
        m_end = datetime(year + 1, 1, 1, 0, 0, 0, tzinfo=timezone.utc)
    else:
        m_end = datetime(year, month + 1, 1, 0, 0, 0, tzinfo=timezone.utc)
    return m_start, m_end


def compute_financial_report(
    db: Session,
    boutique_id: str,
    preset: Optional[str] = None,
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    magasin_id: Optional[str] = None,
) -> FinancialReportResponse:
    now = datetime.now(timezone.utc)
    start_date, end_date = _resolve_period_bounds(preset, start_date, end_date, now)

    v_filters = [
        Vente.boutique_id == boutique_id,
        Vente.deleted_at.is_(None),
        Vente.status != "refunded",
        Vente.created_at >= start_date,
        Vente.created_at <= end_date,
    ]
    if magasin_id:
        v_filters.append(Vente.magasin_id == magasin_id)

    sales_agg = db.query(
        func.coalesce(func.sum(Vente.total_amount), 0.0),
        func.coalesce(func.sum(Vente.discount_amount), 0.0),
    ).filter(*v_filters).first()
    net_sales = float(sales_agg[0] or 0.0)
    discount_amount = float(sales_agg[1] or 0.0)
    gross_sales = round(net_sales + discount_amount, 2)

    active_qty = VenteItem.quantity - func.coalesce(VenteItem.refunded_quantity, 0.0)
    cogs = float(
        db.query(func.coalesce(func.sum(active_qty * VenteItem.cost_price), 0.0))
        .join(Vente, VenteItem.vente_sync_id == Vente.sync_id)
        .filter(*v_filters)
        .scalar()
        or 0.0
    )

    gross_margin = round(net_sales - cogs, 2)
    gross_margin_rate = round((gross_margin / net_sales * 100), 2) if net_sales > 0 else 0.0

    d_filters = [
        Decaissement.boutique_id == boutique_id,
        Decaissement.deleted_at.is_(None),
        Decaissement.date >= start_date,
        Decaissement.date <= end_date,
    ]
    if magasin_id:
        d_filters.append(Decaissement.magasin_id == magasin_id)

    cat_rows = (
        db.query(
            func.coalesce(Decaissement.category, "Général"),
            func.coalesce(func.sum(Decaissement.amount), 0.0),
        )
        .filter(*d_filters)
        .group_by(func.coalesce(Decaissement.category, "Général"))
        .order_by(func.sum(Decaissement.amount).desc())
        .all()
    )
    total_expenses = round(sum(float(r[1] or 0.0) for r in cat_rows), 2)
    expenses_by_category = [
        ExpenseCategoryItem(
            category=cat or "Général",
            total_amount=round(float(amount or 0.0), 2),
            percentage=round((float(amount or 0.0) / total_expenses * 100), 2) if total_expenses > 0 else 0.0,
        )
        for cat, amount in cat_rows
    ]

    net_profit = round(gross_margin - total_expenses, 2)
    net_margin_rate = round((net_profit / net_sales * 100), 2) if net_sales > 0 else 0.0
    net_cashflow = round(net_sales - total_expenses, 2)

    top_rows = (
        db.query(
            VenteItem.product_name,
            func.coalesce(func.sum(VenteItem.quantity), 0.0),
            func.coalesce(func.sum(VenteItem.total), 0.0),
            func.coalesce(func.sum(VenteItem.total - (active_qty * VenteItem.cost_price)), 0.0),
        )
        .join(Vente, VenteItem.vente_sync_id == Vente.sync_id)
        .filter(*v_filters)
        .group_by(VenteItem.product_name)
        .order_by(func.sum(VenteItem.total).desc())
        .limit(10)
        .all()
    )
    top_products = [
        TopProductItem(
            product_name=row[0],
            quantity_sold=round(float(row[1] or 0.0), 4),
            total_revenue=round(float(row[2] or 0.0), 2),
            total_profit=round(float(row[3] or 0.0), 2),
        )
        for row in top_rows
    ]

    monthly_trend: List[Dict] = []
    for i in range(5, -1, -1):
        m_start, m_end = _calendar_month_window(now, i)
        mv_filters = [
            Vente.boutique_id == boutique_id,
            Vente.deleted_at.is_(None),
            Vente.status != "refunded",
            Vente.created_at >= m_start,
            Vente.created_at < m_end,
        ]
        md_filters = [
            Decaissement.boutique_id == boutique_id,
            Decaissement.deleted_at.is_(None),
            Decaissement.date >= m_start,
            Decaissement.date < m_end,
        ]
        if magasin_id:
            mv_filters.append(Vente.magasin_id == magasin_id)
            md_filters.append(Decaissement.magasin_id == magasin_id)

        m_sales = float(db.query(func.coalesce(func.sum(Vente.total_amount), 0.0)).filter(*mv_filters).scalar() or 0.0)
        m_cogs = float(
            db.query(func.coalesce(func.sum(active_qty * VenteItem.cost_price), 0.0))
            .join(Vente, VenteItem.vente_sync_id == Vente.sync_id)
            .filter(*mv_filters)
            .scalar()
            or 0.0
        )
        m_exp = float(db.query(func.coalesce(func.sum(Decaissement.amount), 0.0)).filter(*md_filters).scalar() or 0.0)
        monthly_trend.append({
            "period": m_start.strftime("%b %Y"),
            "sales": round(m_sales, 2),
            "cogs": round(m_cogs, 2),
            "expenses": round(m_exp, 2),
            "profit": round(m_sales - m_cogs - m_exp, 2),
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
