from datetime import datetime, timedelta, timezone
from typing import Any, Dict
from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.core.security import create_access_token
from app.models import Boutique, PlatformAuditLog, SaasPlan, SaasSubscription, User
from app.schemas.admin import ManualPlanAssignRequest
from app.services.auth_service import user_to_brief


def _ensure_utc(dt: datetime | None) -> datetime | None:
    if dt is None:
        return None
    return dt if dt.tzinfo is not None else dt.replace(tzinfo=timezone.utc)


def extend_boutique_trial(db: Session, boutique_id: str, days: int, admin: User) -> Dict[str, Any]:
    sub = db.query(SaasSubscription).filter(SaasSubscription.boutique_id == boutique_id).first()
    if not sub:
        raise HTTPException(status_code=404, detail="Abonnement non trouvé pour cette boutique.")

    now = datetime.now(timezone.utc)
    base_date = _ensure_utc(sub.trial_ends_at) or now
    if base_date < now:
        base_date = now

    sub.trial_ends_at = base_date + timedelta(days=days)
    sub.status = "trialing"

    db.add(PlatformAuditLog(
        admin_user_id=admin.id,
        admin_username=admin.username,
        action="TRIAL_EXTEND",
        target_entity="subscription",
        target_id=sub.id,
        details={
            "boutique_id": boutique_id,
            "additional_days": days,
            "new_trial_ends_at": sub.trial_ends_at.isoformat(),
        },
    ))
    db.commit()
    return {"success": True, "trial_ends_at": sub.trial_ends_at}


def assign_boutique_plan(
    db: Session, boutique_id: str, payload: ManualPlanAssignRequest, admin: User
) -> Dict[str, Any]:
    boutique = db.query(Boutique).filter(Boutique.id == boutique_id).first()
    if not boutique:
        raise HTTPException(status_code=404, detail="Boutique non trouvée.")
    plan = db.query(SaasPlan).filter(SaasPlan.code == payload.plan_code).first()
    if not plan:
        raise HTTPException(status_code=404, detail="Forfait introuvable.")

    now = datetime.now(timezone.utc)
    end_dt = now + timedelta(days=payload.period_days)
    sub = db.query(SaasSubscription).filter(SaasSubscription.boutique_id == boutique.id).first()
    if not sub:
        sub = SaasSubscription(
            boutique_id=boutique.id,
            plan_id=plan.id,
            status=payload.status,
            billing_cycle=payload.billing_cycle,
            current_period_start=now,
            current_period_end=end_dt,
            trial_ends_at=end_dt if payload.status == "trialing" else None,
        )
        db.add(sub)
    else:
        sub.plan_id = plan.id
        sub.status = payload.status
        sub.billing_cycle = payload.billing_cycle
        sub.current_period_start = now
        sub.current_period_end = end_dt
        if payload.status == "trialing":
            sub.trial_ends_at = end_dt

    db.add(PlatformAuditLog(
        admin_user_id=admin.id,
        admin_username=admin.username,
        action="MANUAL_PLAN_CHANGE",
        target_entity="boutique",
        target_id=boutique.id,
        details={
            "plan_code": plan.code,
            "status": payload.status,
            "billing_cycle": payload.billing_cycle,
            "period_days": payload.period_days,
            "reason": payload.reason,
        },
    ))
    db.commit()
    return {"success": True, "boutique_id": boutique.id, "plan_code": plan.code, "status": sub.status}


def create_support_impersonation(db: Session, boutique_id: str, admin: User) -> Dict[str, Any]:
    boutique = db.query(Boutique).filter(Boutique.id == boutique_id).first()
    if not boutique:
        raise HTTPException(status_code=404, detail="Boutique non trouvée.")
    owner = db.query(User).filter(User.id == boutique.owner_user_id).first()
    if not owner or not owner.is_active:
        raise HTTPException(status_code=400, detail="Propriétaire introuvable ou inactif.")

    token = create_access_token(
        subject=owner.id,
        expires_delta=timedelta(minutes=30),
        data={
            "role": owner.role,
            "read_only": True,
            "impersonated_by": admin.id,
            "impersonated_boutique_id": boutique.id,
        },
    )
    db.add(PlatformAuditLog(
        admin_user_id=admin.id,
        admin_username=admin.username,
        action="SUPPORT_IMPERSONATE_START",
        target_entity="boutique",
        target_id=boutique.id,
        details={"boutique_name": boutique.name, "owner_username": owner.username, "read_only": True},
    ))
    db.commit()
    return {
        "access_token": token,
        "token_type": "bearer",
        "expires_in_minutes": 30,
        "read_only": True,
        "boutique_id": boutique.id,
        "boutique_name": boutique.name,
        "user": user_to_brief(owner),
    }
