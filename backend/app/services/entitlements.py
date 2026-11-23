from datetime import datetime, timedelta, timezone
from typing import Any, Dict, Optional, Tuple
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models import (
    Boutique,
    BoutiqueUserMembership,
    Client,
    Magasin,
    Product,
    SaasPlan,
    SaasSubscription,
    Supplier,
)
from app.services.feature_catalog import FEATURE_CATALOG, FEATURE_CATALOG_BY_CODE

PAST_DUE_GRACE_DAYS = 3


def _as_utc(dt: Optional[datetime]) -> Optional[datetime]:
    if dt is None:
        return None
    return dt if dt.tzinfo is not None else dt.replace(tzinfo=timezone.utc)


def _safe_default_features() -> Dict[str, Any]:
    return {
        item.feature_code: (False if item.value_type == "boolean" else 0)
        for item in FEATURE_CATALOG
    }


def _fallback_free_plan(db: Session) -> SaasPlan:
    free_plan = db.query(SaasPlan).filter(SaasPlan.code == "free").first()
    if free_plan:
        return free_plan
    return SaasPlan(id="free", name="Plan Gratuit", code="free", currency="XOF", trial_period_days=0)


def resolve_effective_plan(
    db: Session, boutique_id: str
) -> Tuple[SaasPlan, Optional[SaasSubscription], Dict[str, Any]]:
    """Resolve effective plan (downgrading expired trials/canceled subs to free) and 28 features."""
    sub = db.query(SaasSubscription).filter(SaasSubscription.boutique_id == boutique_id).first()
    now = datetime.now(timezone.utc)
    free_plan = _fallback_free_plan(db)
    effective_plan: Optional[SaasPlan] = None

    if not sub:
        effective_plan = free_plan
    elif sub.status == "trialing":
        trial_end = _as_utc(sub.trial_ends_at)
        if trial_end is None or trial_end > now:
            effective_plan = db.query(SaasPlan).filter(SaasPlan.id == sub.plan_id).first() or free_plan
        else:
            sub.status = "expired"
            db.commit()
            effective_plan = free_plan
    elif sub.status in ("canceled", "expired"):
        effective_plan = free_plan
    elif sub.status == "past_due":
        period_end = _as_utc(sub.current_period_end)
        if period_end and (period_end + timedelta(days=PAST_DUE_GRACE_DAYS)) >= now:
            effective_plan = db.query(SaasPlan).filter(SaasPlan.id == sub.plan_id).first() or free_plan
        else:
            effective_plan = free_plan
    else:
        effective_plan = db.query(SaasPlan).filter(SaasPlan.id == sub.plan_id).first() or free_plan

    features_map = _safe_default_features()
    for feat in getattr(effective_plan, "features", []) or []:
        if feat.value_type == "boolean":
            features_map[feat.feature_code] = bool(feat.boolean_value)
        else:
            features_map[feat.feature_code] = int(feat.int_limit)
    return effective_plan, sub, features_map


def get_boutique_usage(db: Session, boutique_id: str, owner_user_id: str) -> Dict[str, int]:
    """Return active usage counts for all 6 quantifiable quotas of a boutique."""
    boutiques_used = db.query(Boutique).filter(
        Boutique.owner_user_id == owner_user_id, Boutique.is_active == True
    ).count()
    magasins_used = db.query(Magasin).filter(
        Magasin.boutique_id == boutique_id, Magasin.is_active == True
    ).count()
    products_used = db.query(Product).filter(
        Product.boutique_id == boutique_id, Product.deleted_at.is_(None)
    ).count()
    users_used = db.query(BoutiqueUserMembership).filter(
        BoutiqueUserMembership.boutique_id == boutique_id, BoutiqueUserMembership.is_active == True
    ).count()
    clients_used = db.query(Client).filter(
        Client.boutique_id == boutique_id, Client.deleted_at.is_(None)
    ).count()
    suppliers_used = db.query(Supplier).filter(
        Supplier.boutique_id == boutique_id, Supplier.deleted_at.is_(None)
    ).count()
    return {
        "boutiques_used": boutiques_used,
        "magasins_used": magasins_used,
        "products_used": products_used,
        "users_used": users_used,
        "clients_used": clients_used,
        "suppliers_used": suppliers_used,
    }


def next_recommended_plan(current_plan_code: str, fallback: str = "pro") -> str:
    if current_plan_code == "pro":
        return "enterprise"
    if current_plan_code == "enterprise":
        return "enterprise"
    return fallback


def check_feature_access(
    db: Session,
    boutique_id: str,
    feature_code: str,
    recommended_plan: str = "pro",
) -> None:
    plan, _, features = resolve_effective_plan(db, boutique_id)
    if bool(features.get(feature_code, False)):
        return
    defn = FEATURE_CATALOG_BY_CODE.get(feature_code)
    label = defn.feature_name if defn else feature_code
    rec = next_recommended_plan(plan.code, recommended_plan)
    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail={
            "error": "PLAN_FEATURE_LOCKED",
            "feature": feature_code,
            "current_plan": plan.code,
            "recommended_plan": rec,
            "message": f"La fonctionnalité '{label}' nécessite un forfait supérieur ({rec}).",
        },
    )


def check_quota_limit(
    db: Session,
    boutique_id: str,
    quota_code: str,
    current_count: int,
    recommended_plan: str = "pro",
) -> None:
    plan, _, features = resolve_effective_plan(db, boutique_id)
    limit = int(features.get(quota_code, 0))
    if limit == -1 or current_count < limit:
        return
    defn = FEATURE_CATALOG_BY_CODE.get(quota_code)
    label = defn.feature_name if defn else quota_code
    rec = next_recommended_plan(plan.code, recommended_plan)
    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail={
            "error": "PLAN_QUOTA_EXCEEDED",
            "feature": quota_code,
            "current_plan": plan.code,
            "recommended_plan": rec,
            "limit": limit,
            "current": current_count,
            "message": f"Quota '{label}' atteint ({current_count}/{limit}) pour votre forfait {plan.name}.",
        },
    )


def get_audit_retention_days(db: Session, boutique_id: str) -> int:
    _, _, features = resolve_effective_plan(db, boutique_id)
    return int(features.get("audit_retention_days", 3))
