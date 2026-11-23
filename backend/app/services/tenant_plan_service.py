from datetime import datetime, timedelta, timezone
from typing import Any, Dict
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models import SaasPlan, SaasSubscription
from app.services.entitlements import get_boutique_usage, resolve_effective_plan
from app.services.tenant_context_service import TenantContext


def _as_utc(dt: datetime | None) -> datetime | None:
    if dt is None:
        return None
    return dt if dt.tzinfo is not None else dt.replace(tzinfo=timezone.utc)


def get_ctx_plan_status(db: Session, ctx: TenantContext) -> Dict[str, Any]:
    boutique_id = ctx.boutique.id
    plan, sub, features_map = resolve_effective_plan(db, boutique_id)
    usage = get_boutique_usage(db, boutique_id, ctx.boutique.owner_user_id)

    now = datetime.now(timezone.utc)
    trial_active = False
    trial_days_left = 0
    if sub and sub.status == "trialing" and sub.trial_ends_at:
        trial_ends = _as_utc(sub.trial_ends_at)
        if trial_ends and trial_ends > now:
            trial_active = True
            trial_days_left = max(0, (trial_ends - now).days)

    has_used_trial = bool(ctx.boutique.has_used_trial or (sub and sub.has_used_trial))
    status_label = sub.status if sub else "active"
    if plan.code == "free" and status_label in ("expired", "canceled"):
        status_label = "free" if status_label == "expired" else status_label

    return {
        "plan_id": plan.id or "free",
        "plan_name": plan.name,
        "plan_code": plan.code,
        "status": status_label,
        "trial_active": trial_active,
        "trial_days_left": trial_days_left,
        "features": features_map,
        "can_access_stock_transfers": bool(features_map.get("stock_transfers", False)),
        "can_access_pnl_reports": bool(features_map.get("pnl_reports", False)),
        "can_access_data_exports": bool(features_map.get("data_exports", False)),
        "boutiques_used": usage["boutiques_used"],
        "boutiques_limit": int(features_map.get("max_boutiques", 1)),
        "magasins_used": usage["magasins_used"],
        "magasins_limit": int(features_map.get("max_magasins", 1)),
        "products_used": usage["products_used"],
        "products_limit": int(features_map.get("max_products", 100)),
        "users_used": usage["users_used"],
        "users_limit": int(features_map.get("max_users", 2)),
        "clients_used": usage["clients_used"],
        "clients_limit": int(features_map.get("max_clients", 50)),
        "suppliers_used": usage["suppliers_used"],
        "suppliers_limit": int(features_map.get("max_suppliers", 10)),
        "audit_retention_days": int(features_map.get("audit_retention_days", 3)),
        "has_used_trial": has_used_trial,
        "billing_cycle": sub.billing_cycle if sub else "monthly",
        "current_period_end": sub.current_period_end if sub else None,
    }


def upgrade_ctx_plan(db: Session, ctx: TenantContext, target_plan_code: str) -> Dict[str, Any]:
    target_plan = db.query(SaasPlan).filter(SaasPlan.code == target_plan_code).first()
    if not target_plan:
        raise HTTPException(status_code=404, detail="Plan sélectionné introuvable.")

    boutique = ctx.boutique
    sub = db.query(SaasSubscription).filter(SaasSubscription.boutique_id == boutique.id).first()
    now = datetime.now(timezone.utc)
    has_used_trial = bool(boutique.has_used_trial or (sub and sub.has_used_trial))

    if target_plan.code == "free":
        if not sub:
            sub = SaasSubscription(boutique_id=boutique.id, plan_id=target_plan.id, status="active")
            db.add(sub)
        else:
            sub.plan_id = target_plan.id
            sub.status = "active"
        db.commit()
        return {
            "success": True,
            "message": "Vous êtes passé sur le Plan Gratuit.",
            "plan_code": target_plan.code,
            "plan_name": target_plan.name,
            "trial_active": False,
            "trial_ends_at": None,
        }

    if target_plan.trial_period_days > 0 and not has_used_trial:
        trial_end = now + timedelta(days=target_plan.trial_period_days)
        if not sub:
            sub = SaasSubscription(
                boutique_id=boutique.id,
                plan_id=target_plan.id,
                status="trialing",
                has_used_trial=True,
                trial_starts_at=now,
                trial_ends_at=trial_end,
            )
            db.add(sub)
        else:
            sub.plan_id = target_plan.id
            sub.status = "trialing"
            sub.has_used_trial = True
            sub.trial_starts_at = now
            sub.trial_ends_at = trial_end
        boutique.has_used_trial = True
        db.commit()
        return {
            "success": True,
            "message": f"Essai gratuit de {target_plan.trial_period_days} jours activé sur {target_plan.name}.",
            "plan_code": target_plan.code,
            "plan_name": target_plan.name,
            "trial_active": True,
            "trial_ends_at": sub.trial_ends_at,
        }

    raise HTTPException(
        status_code=status.HTTP_402_PAYMENT_REQUIRED,
        detail={
            "error": "PAYMENT_REQUIRED",
            "plan_code": target_plan.code,
            "checkout_url": "/api/v1/billing/checkout",
            "message": f"Un paiement Mobile Money est requis pour activer le {target_plan.name}.",
        },
    )
