from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.api import deps
from app.core.database import get_db
from app.schemas.inventory import TransferCreate, TransferOut, TransferReceiveRequest
from app.services.entitlements import check_feature_access
from app.services.tenant_context_service import TenantContext, resolve_read_magasin_id
from app.services.transfer_service import (
    cancel_transfer,
    create_transfer,
    list_transfers,
    receive_transfer,
)

router = APIRouter()


@router.get("", response_model=List[TransferOut])
def get_transfers(
    status_filter: Optional[str] = Query(None, alias="status"),
    limit: int = Query(100, ge=1, le=500),
    ctx: TenantContext = Depends(deps.require_tenant_role(["owner", "store_admin", "manager"])),
    db: Session = Depends(get_db),
):
    check_feature_access(db, ctx.boutique.id, "stock_transfers")
    resolve_read_magasin_id(ctx)
    return list_transfers(db, ctx, status_filter=status_filter, limit=limit)


@router.post("", response_model=TransferOut, status_code=status.HTTP_201_CREATED)
def post_transfer(
    payload: TransferCreate,
    ctx: TenantContext = Depends(deps.require_tenant_role(["owner", "store_admin", "manager"])),
    db: Session = Depends(get_db),
):
    check_feature_access(db, ctx.boutique.id, "stock_transfers")
    return create_transfer(db, ctx, payload)


@router.post("/{transfer_id}/receive", response_model=TransferOut)
def post_receive_transfer(
    transfer_id: str,
    payload: TransferReceiveRequest = TransferReceiveRequest(),
    ctx: TenantContext = Depends(deps.require_tenant_role(["owner", "store_admin", "manager"])),
    db: Session = Depends(get_db),
):
    check_feature_access(db, ctx.boutique.id, "stock_transfers")
    return receive_transfer(db, ctx, transfer_id, payload)


@router.post("/{transfer_id}/cancel", response_model=TransferOut)
def post_cancel_transfer(
    transfer_id: str,
    ctx: TenantContext = Depends(deps.require_tenant_role(["owner", "store_admin", "manager"])),
    db: Session = Depends(get_db),
):
    check_feature_access(db, ctx.boutique.id, "stock_transfers")
    return cancel_transfer(db, ctx, transfer_id)
