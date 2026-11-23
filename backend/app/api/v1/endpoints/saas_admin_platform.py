from typing import Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.api.v1.endpoints.admin_deps import require_superadmin
from app.core.database import get_db
from app.models import User
from app.schemas.admin import PaymentProviderUpdateRequest
from app.services.admin_audit_service import (
    list_admin_subscriptions_data,
    list_platform_audit_data,
)
from app.services.admin_provider_service import (
    get_payment_provider_admin,
    list_payment_providers_admin,
    update_payment_provider_admin,
)

router = APIRouter()


@router.get("/payment-providers")
def admin_list_payment_providers(
    admin: User = Depends(require_superadmin),
    db: Session = Depends(get_db),
):
    _ = admin
    return list_payment_providers_admin(db)


@router.get("/payment-providers/{code}")
def admin_get_payment_provider(
    code: str,
    admin: User = Depends(require_superadmin),
    db: Session = Depends(get_db),
):
    _ = admin
    return get_payment_provider_admin(db, code)


@router.put("/payment-providers/{code}")
def admin_update_payment_provider(
    code: str,
    payload: PaymentProviderUpdateRequest,
    admin: User = Depends(require_superadmin),
    db: Session = Depends(get_db),
):
    return update_payment_provider_admin(db, code, payload, admin)


@router.get("/subscriptions")
def admin_list_subscriptions(
    status_filter: Optional[str] = Query(None, alias="status"),
    tx_status: Optional[str] = Query(None),
    page: int = Query(1, ge=1),
    limit: int = Query(25, ge=1, le=200),
    admin: User = Depends(require_superadmin),
    db: Session = Depends(get_db),
):
    _ = admin
    return list_admin_subscriptions_data(
        db, sub_status=status_filter, tx_status=tx_status, page=page, limit=limit
    )


@router.get("/audit")
def admin_list_audit_logs(
    action: Optional[str] = Query(None),
    q: Optional[str] = Query(None),
    page: int = Query(1, ge=1),
    limit: int = Query(50, ge=1, le=200),
    admin: User = Depends(require_superadmin),
    db: Session = Depends(get_db),
):
    _ = admin
    return list_platform_audit_data(db, action=action, q=q, page=page, limit=limit)
