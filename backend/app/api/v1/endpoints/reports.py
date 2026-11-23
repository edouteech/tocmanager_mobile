from typing import Any, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from pydantic import BaseModel

from app.api import deps
from app.core.database import get_db
from app.schemas.entities import FinancialReportResponse
from app.services.dashboard_report_service import compute_dashboard_stats
from app.services.entitlements import check_feature_access
from app.services.report_service import compute_financial_report
from app.services.tenant_context_service import TenantContext

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
    categories_count: int = 0
    stock_value: float = 0.0
    stock_cost: float = 0.0


@router.get("/dashboard", response_model=DashboardStats)
def get_dashboard_stats(
    ctx: TenantContext = Depends(deps.require_tenant_role(["owner", "store_admin", "manager"])),
    db: Session = Depends(get_db),
) -> Any:
    check_feature_access(db, ctx.boutique.id, "dashboard_kpis")
    return DashboardStats(**compute_dashboard_stats(db, ctx.boutique.id))


@router.get("/financial", response_model=FinancialReportResponse)
def get_financial_report(
    preset: Optional[str] = Query(None),
    start_date: Optional[datetime] = Query(None),
    end_date: Optional[datetime] = Query(None),
    ctx: TenantContext = Depends(deps.require_tenant_role(["owner", "store_admin", "manager"])),
    db: Session = Depends(get_db),
) -> Any:
    check_feature_access(db, ctx.boutique.id, "pnl_reports")
    return compute_financial_report(
        db=db,
        boutique_id=ctx.boutique.id,
        preset=preset,
        start_date=start_date,
        end_date=end_date,
    )
