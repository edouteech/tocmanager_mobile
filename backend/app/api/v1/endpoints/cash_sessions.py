from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.api import deps
from app.core.database import get_db
from app.schemas.cash import CashSessionCloseRequest, CashSessionOpenRequest, CashSessionOut
from app.services.cash_session_service import (
    close_cash_session,
    get_current_cash_session,
    list_cash_sessions,
    open_cash_session,
)
from app.services.tenant_context_service import TenantContext

router = APIRouter()


@router.get("", response_model=List[CashSessionOut])
def get_sessions_history(
    limit: int = Query(100, ge=1, le=500),
    ctx: TenantContext = Depends(deps.require_tenant_role(["owner", "store_admin", "manager"])),
    db: Session = Depends(get_db),
):
    return list_cash_sessions(db, ctx, limit=limit)


@router.get("/current", response_model=Optional[CashSessionOut])
def get_my_current_session(
    magasin_id: Optional[str] = Query(None),
    ctx: TenantContext = Depends(deps.get_tenant_context),
    db: Session = Depends(get_db),
):
    return get_current_cash_session(db, ctx, magasin_id=magasin_id)


@router.post("/open", response_model=CashSessionOut, status_code=status.HTTP_201_CREATED)
def open_session(
    payload: CashSessionOpenRequest,
    ctx: TenantContext = Depends(deps.get_tenant_context),
    db: Session = Depends(get_db),
):
    return open_cash_session(db, ctx, payload)


@router.post("/{session_id}/close", response_model=CashSessionOut)
def close_session(
    session_id: str,
    payload: CashSessionCloseRequest,
    ctx: TenantContext = Depends(deps.get_tenant_context),
    db: Session = Depends(get_db),
):
    return close_cash_session(db, ctx, session_id, payload)
