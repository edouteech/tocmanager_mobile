from datetime import datetime, timedelta, timezone
from typing import Any, Dict
from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models import Magasin, SaasPlan, SaasSubscription
from app.services.tenant_context_service import TenantContext


def get_ctx_plan_status(db: Session, ctx: TenantContext) -> Dict[str, Any]:
    boutique_id = ctx.boutique.id
    sub = db.query(SaasSubscription).filter(SaasSubscription.boutique_id == boutique_id).first()
    plan = db.query(SaasPlan).filter(SaasPlan.id == sub.plan_id).first() if sub else None
    if not plan:
        plan = db.query(SaasPlan).filter(SaasPlan.code == "free").first()

    now = datetime.now(timezone.utc)
    trial_active = False
    trial_days_left = 0
    if sub and sub.status == "trialing" and sub.trial_ends_at:
        trial_ends = sub.trial_ends_at
        if trial_ends.tzinfo is None:
            trial_ends = trial_ends.replace(tzinfo=timezone.utc)
        if trial_ends > now:
            trial_active = True
            trial_days_left = max(0, (trial_ends - now).days)
        else:
            sub.status = "canceled"
            db.commit()

    features_map: Dict[str, Any] = {}
    if plan:
        for f in plan.features:
            features_map[f.feature_code] = f.boolean_value if f.value_type == "boolean" else f.int_limit

    magasins_used = db.query(Magasin).filter(
        Magasin.boutique_id == boutique_id, Magasin.is_active == True
    ).count()

    return {
        "plan_id": plan.id if plan else "free",
        "plan_name": plan.name if plan else "Plan Gratuit",
        "plan_code": plan.code if plan else "free",
        "status": sub.status if sub else "active",
        "trial_active": trial_active,
        "trial_days_left": trial_days_left,
        "features": features_map,
        "can_access_stock_transfers": bool(features_map.get("stock_transfers", False)),
        "can_access_pnl_reports": bool(features_map.get("pnl_reports", False)),
        "can_access_data_exports": bool(features_map.get("data_exports", False)),
        "magasins_used": magasins_used,
        "magasins_limit": features_map.get("max_magasins", 1),
    }


def upgrade_ctx_plan(db: Session, ctx: TenantContext, target_plan_code: str) -> Dict[str, Any]:
    target_plan = db.query(SaasPlan).filter(SaasPlan.code == target_plan_code).first()
    if not target_plan:
        raise HTTPException(status_code=404, detail="Plan sélectionné introuvable.")

    boutique_id = ctx.boutique.id
    sub = db.query(SaasSubscription).filter(SaasSubscription.boutique_id == boutique_id).first()
    now = datetime.now(timezone.utc)
    trial_days = target_plan.trial_period_days

    if not sub:
        sub = SaasSubscription(
            boutique_id=boutique_id,
            plan_id=target_plan.id,
            status="trialing" if trial_days > 0 else "active",
            trial_starts_at=now if trial_days > 0 else None,
            trial_ends_at=(now + timedelta(days=trial_days)) if trial_days > 0 else None,
        )
        db.add(sub)
    else:
        sub.plan_id = target_plan.id
        if trial_days > 0 and sub.trial_ends_at is None:
            sub.status = "trialing"
            sub.trial_starts_at = now
            sub.trial_ends_at = now + timedelta(days=trial_days)
        else:
            sub.status = "active"

    db.commit()
    return {
        "success": True,
        "message": f"Félicitations ! Vous êtes désormais sur le {target_plan.name}.",
        "plan_code": target_plan.code,
        "plan_name": target_plan.name,
        "trial_active": sub.status == "trialing",
        "trial_ends_at": sub.trial_ends_at,
    }
