from typing import Any, List
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api import deps
from app.core.database import get_db
from app.schemas.auth import UserBrief
from app.schemas.users import UserCreate, UserUpdate
from app.services.tenant_context_service import TenantContext
from app.services.user_service import (
    create_boutique_user,
    delete_boutique_user,
    list_boutique_users,
    update_boutique_user,
)

router = APIRouter()


@router.get("", response_model=List[UserBrief])
def list_users(
    ctx: TenantContext = Depends(deps.require_tenant_role(["owner", "store_admin", "manager"])),
    db: Session = Depends(get_db),
) -> Any:
    return list_boutique_users(db, ctx)


@router.post("", response_model=UserBrief)
def create_user(
    data: UserCreate,
    ctx: TenantContext = Depends(deps.require_tenant_role(["owner", "store_admin"])),
    db: Session = Depends(get_db),
) -> Any:
    return create_boutique_user(db, ctx, data)


@router.put("/{user_id}", response_model=UserBrief)
def update_user(
    user_id: str,
    data: UserUpdate,
    ctx: TenantContext = Depends(deps.require_tenant_role(["owner", "store_admin"])),
    db: Session = Depends(get_db),
) -> Any:
    return update_boutique_user(db, ctx, user_id, data)


@router.delete("/{user_id}")
def delete_user(
    user_id: str,
    ctx: TenantContext = Depends(deps.require_tenant_role(["owner", "store_admin"])),
    db: Session = Depends(get_db),
) -> Any:
    return delete_boutique_user(db, ctx, user_id)
