from typing import List
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.api import deps
from app.core.database import get_db
from app.models import User
from app.schemas.saas import (
    BoutiqueOut,
    BoutiqueCreate,
    MagasinOut,
    MagasinCreate,
    MagasinUpdate,
    CurrentPlanStatusOut,
)
from app.services.tenant_context_service import TenantContext
from app.services.tenant_service import (
    list_accessible_boutiques,
    create_boutique_for_owner,
    list_ctx_magasins,
    create_ctx_magasin,
    update_ctx_magasin,
)
from app.services.tenant_plan_service import (
    get_ctx_plan_status,
    upgrade_ctx_plan,
)

router = APIRouter()


@router.get("/boutiques", response_model=List[BoutiqueOut])
def get_user_boutiques(
    current_user: User = Depends(deps.get_current_user),
    db: Session = Depends(get_db),
):
    return list_accessible_boutiques(db, current_user)


@router.post("/boutiques", response_model=BoutiqueOut)
def create_additional_boutique(
    payload: BoutiqueCreate,
    current_user: User = Depends(deps.get_current_user),
    db: Session = Depends(get_db),
):
    return create_boutique_for_owner(db, current_user, payload)


@router.get("/magasins", response_model=List[MagasinOut])
def list_magasins(
    ctx: TenantContext = Depends(deps.get_tenant_context),
    db: Session = Depends(get_db),
):
    return list_ctx_magasins(db, ctx)


@router.post("/magasins", response_model=MagasinOut)
def create_magasin(
    payload: MagasinCreate,
    ctx: TenantContext = Depends(deps.require_tenant_role(["owner", "store_admin"])),
    db: Session = Depends(get_db),
):
    return create_ctx_magasin(db, ctx, payload)


@router.put("/magasins/{magasin_id}", response_model=MagasinOut)
def update_magasin(
    magasin_id: str,
    payload: MagasinUpdate,
    ctx: TenantContext = Depends(deps.require_tenant_role(["owner", "store_admin"])),
    db: Session = Depends(get_db),
):
    return update_ctx_magasin(db, ctx, magasin_id, payload)


@router.get("/current-plan", response_model=CurrentPlanStatusOut)
def get_current_plan_status(
    ctx: TenantContext = Depends(deps.get_tenant_context),
    db: Session = Depends(get_db),
):
    return get_ctx_plan_status(db, ctx)


@router.post("/upgrade-plan")
def upgrade_plan(
    payload: dict,
    ctx: TenantContext = Depends(deps.require_tenant_role(["owner"])),
    db: Session = Depends(get_db),
):
    return upgrade_ctx_plan(db, ctx, payload.get("plan_code", "pro"))
