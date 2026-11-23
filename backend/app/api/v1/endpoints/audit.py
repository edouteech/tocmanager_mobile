from typing import Any, List, Optional
from datetime import datetime, timedelta, timezone
from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from sqlalchemy.orm import Session
from sqlalchemy import desc

from app.api import deps
from app.core.database import get_db
from app.models import AuditLog
from app.services.entitlements import check_feature_access, get_audit_retention_days
from app.services.tenant_context_service import TenantContext

router = APIRouter()


class AuditLogItem(BaseModel):
    id: str
    user_id: Optional[str] = None
    user_name: Optional[str] = None
    action: str
    entity_type: Optional[str] = None
    entity_id: Optional[str] = None
    details: Optional[Any] = None
    created_at: datetime

    model_config = {"from_attributes": True}


class AuditLogListResponse(BaseModel):
    total: int
    items: List[AuditLogItem]
    retention_days_applied: Optional[int] = None


@router.get("/logs", response_model=AuditLogListResponse)
def get_audit_logs(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=200),
    action: Optional[str] = None,
    user_id: Optional[str] = None,
    entity_type: Optional[str] = None,
    ctx: TenantContext = Depends(deps.require_tenant_role(["owner", "store_admin"])),
    db: Session = Depends(get_db),
) -> Any:
    """Récupère l'historique d'audit cloisonné à la boutique active."""
    check_feature_access(db, ctx.boutique.id, "module_audit_logs")
    retention_days = get_audit_retention_days(db, ctx.boutique.id)
    query = db.query(AuditLog).filter(AuditLog.boutique_id == ctx.boutique.id)
    if retention_days > 0:
        floor_dt = datetime.now(timezone.utc) - timedelta(days=retention_days)
        query = query.filter(AuditLog.created_at >= floor_dt)

    if action:
        query = query.filter(AuditLog.action == action)
    if user_id:
        query = query.filter(AuditLog.user_id == user_id)
    if entity_type:
        query = query.filter(AuditLog.entity_type == entity_type)

    total = query.count()
    items = query.order_by(desc(AuditLog.created_at)).offset(skip).limit(limit).all()
    return AuditLogListResponse(
        total=total,
        items=items,
        retention_days_applied=retention_days if retention_days > 0 else None,
    )
