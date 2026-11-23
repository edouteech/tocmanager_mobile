from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session

from app.api.v1.endpoints.admin_deps import require_superadmin
from app.api.v1.endpoints.saas_admin_platform import router as platform_router
from app.core.database import get_db
from app.models import Boutique, PlatformAuditLog, SaasPlan, User
from app.schemas.admin import (
    ExtendTrialRequest,
    ManualPlanAssignRequest,
    ToggleBoutiqueStatusRequest,
)
from app.schemas.saas import FeatureCatalogItemOut, SaasPlanCreate, SaasPlanOut, SaasPlanUpdate
from app.services.admin_boutique_actions_service import (
    assign_boutique_plan,
    create_support_impersonation,
    extend_boutique_trial,
)
from app.services.admin_boutique_service import (
    get_admin_boutique_detail,
    list_admin_boutiques,
)
from app.services.admin_kpi_service import compute_platform_kpis
from app.services.feature_catalog import (
    serialize_feature_catalog,
    sync_plan_features_from_catalog,
)

router = APIRouter()
router.include_router(platform_router)


@router.get("/kpis")
def get_platform_kpis(
    admin: User = Depends(require_superadmin),
    db: Session = Depends(get_db),
):
    _ = admin
    return compute_platform_kpis(db)


@router.get("/features-catalog", response_model=List[FeatureCatalogItemOut])
def admin_get_features_catalog(admin: User = Depends(require_superadmin)):
    _ = admin
    return serialize_feature_catalog()


@router.get("/plans", response_model=List[SaasPlanOut])
def admin_list_plans(
    admin: User = Depends(require_superadmin),
    db: Session = Depends(get_db),
):
    _ = admin
    return db.query(SaasPlan).order_by(SaasPlan.price_monthly.asc()).all()


@router.post("/plans", response_model=SaasPlanOut)
def admin_create_plan(
    payload: SaasPlanCreate,
    admin: User = Depends(require_superadmin),
    db: Session = Depends(get_db),
):
    existing = db.query(SaasPlan).filter(SaasPlan.code == payload.code).first()
    if existing:
        raise HTTPException(status_code=400, detail="Un plan avec ce code technique existe déjà.")

    plan = SaasPlan(
        name=payload.name,
        code=payload.code,
        description=payload.description,
        price_monthly=payload.price_monthly,
        price_yearly=payload.price_yearly,
        currency=payload.currency,
        trial_period_days=payload.trial_period_days,
        badge=payload.badge,
        is_active=payload.is_active,
    )
    db.add(plan)
    db.flush()
    sync_plan_features_from_catalog(
        db, plan, provided_features=payload.features, use_plan_defaults=False
    )
    db.add(PlatformAuditLog(
        admin_user_id=admin.id,
        admin_username=admin.username,
        action="PLAN_CREATE",
        target_entity="plan",
        target_id=plan.id,
        details={"name": plan.name, "code": plan.code, "price_monthly": plan.price_monthly},
    ))
    db.commit()
    db.refresh(plan)
    return plan


@router.put("/plans/{plan_id}", response_model=SaasPlanOut)
def admin_update_plan(
    plan_id: str,
    payload: SaasPlanUpdate,
    admin: User = Depends(require_superadmin),
    db: Session = Depends(get_db),
):
    plan = db.query(SaasPlan).filter(SaasPlan.id == plan_id).first()
    if not plan:
        raise HTTPException(status_code=404, detail="Plan non trouvé.")

    for field in ("name", "description", "price_monthly", "price_yearly", "trial_period_days", "badge", "is_active"):
        val = getattr(payload, field)
        if val is not None:
            setattr(plan, field, val)

    if payload.features is not None:
        sync_plan_features_from_catalog(
            db, plan, provided_features=payload.features, use_plan_defaults=False
        )

    db.add(PlatformAuditLog(
        admin_user_id=admin.id,
        admin_username=admin.username,
        action="PLAN_UPDATE",
        target_entity="plan",
        target_id=plan.id,
        details={"name": plan.name, "price_monthly": plan.price_monthly},
    ))
    db.commit()
    db.refresh(plan)
    return plan


@router.get("/boutiques")
def admin_list_boutiques(
    q: Optional[str] = Query(None),
    status_filter: Optional[str] = Query(None, alias="status"),
    plan_code: Optional[str] = Query(None),
    paginated: bool = Query(False),
    page: int = Query(1, ge=1),
    limit: int = Query(25, ge=1, le=200),
    admin: User = Depends(require_superadmin),
    db: Session = Depends(get_db),
):
    _ = admin
    return list_admin_boutiques(
        db, q=q, status_filter=status_filter, plan_code=plan_code, paginated=paginated, page=page, limit=limit
    )


@router.get("/boutiques/{boutique_id}")
def admin_get_boutique_detail(
    boutique_id: str,
    admin: User = Depends(require_superadmin),
    db: Session = Depends(get_db),
):
    _ = admin
    return get_admin_boutique_detail(db, boutique_id)


@router.put("/boutiques/{boutique_id}/status")
def admin_toggle_boutique_status(
    boutique_id: str,
    payload: ToggleBoutiqueStatusRequest,
    admin: User = Depends(require_superadmin),
    db: Session = Depends(get_db),
):
    boutique = db.query(Boutique).filter(Boutique.id == boutique_id).first()
    if not boutique:
        raise HTTPException(status_code=404, detail="Boutique non trouvée.")
    boutique.is_active = payload.is_active
    db.add(PlatformAuditLog(
        admin_user_id=admin.id,
        admin_username=admin.username,
        action="BOUTIQUE_STATUS_TOGGLE",
        target_entity="boutique",
        target_id=boutique.id,
        details={"name": boutique.name, "is_active": boutique.is_active},
    ))
    db.commit()
    return {"success": True, "boutique_id": boutique.id, "is_active": boutique.is_active}


@router.put("/boutiques/{boutique_id}/plan")
def admin_assign_boutique_plan(
    boutique_id: str,
    payload: ManualPlanAssignRequest,
    admin: User = Depends(require_superadmin),
    db: Session = Depends(get_db),
):
    return assign_boutique_plan(db, boutique_id, payload, admin)


@router.post("/boutiques/{boutique_id}/extend-trial")
def admin_extend_trial(
    boutique_id: str,
    payload: ExtendTrialRequest,
    admin: User = Depends(require_superadmin),
    db: Session = Depends(get_db),
):
    return extend_boutique_trial(db, boutique_id, payload.days, admin)


@router.post("/boutiques/{boutique_id}/impersonate")
def admin_impersonate_boutique(
    boutique_id: str,
    admin: User = Depends(require_superadmin),
    db: Session = Depends(get_db),
):
    return create_support_impersonation(db, boutique_id, admin)
