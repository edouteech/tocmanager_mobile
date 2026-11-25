import uuid
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, Optional

from fastapi import HTTPException, status
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.core.security import create_access_token, get_password_hash, verify_password
from app.models import Boutique, BoutiqueUserMembership, Magasin, SaasPlan, SaasSubscription, User
from app.schemas.saas import ProvisionTenantRequest
from app.services.auth_service import issue_token_pair, user_to_brief
from app.services.seed_plans import seed_saas_plans


def set_pg_boutique_rls_context(db: Session, boutique_id: str) -> None:
    """Bind current_boutique_id on the PostgreSQL transaction before RLS-guarded inserts."""
    if db.bind is not None and db.bind.dialect.name == "postgresql":
        db.execute(
            text("SELECT set_config('app.current_boutique_id', :btq_id, true)"),
            {"btq_id": boutique_id},
        )


def _find_active_plan(db: Session, requested_code: Optional[str]) -> Optional[SaasPlan]:
    normalized = (requested_code or "").strip().lower()
    if normalized:
        requested = (
            db.query(SaasPlan)
            .filter(SaasPlan.code == normalized, SaasPlan.is_active == True)
            .first()
        )
        if requested:
            return requested

    free_plan = (
        db.query(SaasPlan)
        .filter(SaasPlan.code == "free", SaasPlan.is_active == True)
        .first()
    )
    if free_plan:
        return free_plan

    return (
        db.query(SaasPlan)
        .filter(SaasPlan.is_active == True)
        .order_by(SaasPlan.price_monthly.asc())
        .first()
    )


def resolve_subscription_plan(db: Session, requested_code: Optional[str]) -> SaasPlan:
    """Resolve an active SaaS plan, auto-seeding defaults if saas_plans is empty."""
    plan = _find_active_plan(db, requested_code)
    if plan is None:
        seed_saas_plans(db)
        plan = _find_active_plan(db, requested_code)
    if plan is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Aucun forfait SaaS disponible pour le moment. Veuillez réessayer.",
        )
    return plan


def _user_has_any_boutique(db: Session, user_id: str) -> bool:
    has_membership = (
        db.query(BoutiqueUserMembership.id)
        .filter(BoutiqueUserMembership.user_id == user_id)
        .first()
        is not None
    )
    if has_membership:
        return True
    return (
        db.query(Boutique.id)
        .filter(Boutique.owner_user_id == user_id)
        .first()
        is not None
    )


def _issue_onboarding_response(user: User, resumed: bool) -> Dict[str, Any]:
    access_token = create_access_token(
        data={"sub": user.id, "scope": "onboarding", "role": user.role}
    )
    return {
        "user_id": user.id,
        "username": user.username,
        "full_name": user.full_name,
        "access_token": access_token,
        "token_type": "bearer",
        "next_step": "provision_tenant",
        "resumed": resumed,
    }


def register_or_resume_onboarding_user(
    db: Session,
    full_name: str,
    username_or_email: str,
    password: str,
) -> Dict[str, Any]:
    """Create onboarding credentials or safely resume step 2 for an orphan account."""
    ident = username_or_email.strip().lower()
    cleaned_name = full_name.strip()
    existing = (
        db.query(User)
        .filter((User.username == ident) | (User.email == ident))
        .first()
    )

    if existing is not None:
        can_resume = (
            existing.is_active
            and existing.role != "superadmin"
            and not _user_has_any_boutique(db, existing.id)
            and verify_password(password, existing.hashed_password)
        )
        if not can_resume:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Un compte avec cet email ou identifiant existe déjà.",
            )
        if cleaned_name and existing.full_name != cleaned_name:
            existing.full_name = cleaned_name
            db.commit()
            db.refresh(existing)
        return _issue_onboarding_response(existing, resumed=True)

    user = User(
        username=ident,
        email=ident if "@" in ident else None,
        full_name=cleaned_name,
        hashed_password=get_password_hash(password),
        role="merchant",
        is_active=True,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return _issue_onboarding_response(user, resumed=False)


def provision_initial_tenant(
    db: Session,
    current_user: User,
    payload: ProvisionTenantRequest,
) -> Dict[str, Any]:
    """Provision initial boutique, main magasin, owner membership, and SaaS subscription."""
    plan = resolve_subscription_plan(db, payload.plan_code)

    base_slug = payload.boutique_name.strip().lower().replace(" ", "-")
    unique_slug = f"{base_slug}-{uuid.uuid4().hex[:6]}"

    trial_days = plan.trial_period_days or 0
    trial_active = trial_days > 0
    billing_cycle = payload.billing_cycle if payload.billing_cycle in ("monthly", "yearly") else "monthly"
    period_days = trial_days if trial_active else (365 if billing_cycle == "yearly" else 30)

    boutique = Boutique(
        slug=unique_slug,
        name=payload.boutique_name.strip(),
        company_name=payload.company_name or payload.boutique_name.strip(),
        currency=payload.currency,
        country=payload.country,
        phone=payload.phone,
        owner_user_id=current_user.id,
        has_used_trial=trial_active,
        is_active=True,
    )
    db.add(boutique)
    db.flush()

    set_pg_boutique_rls_context(db, boutique.id)

    magasin = Magasin(
        boutique_id=boutique.id,
        name=payload.magasin_name.strip() or "Magasin Principal",
        code="MAG-01",
        phone=payload.phone,
        is_warehouse=False,
        is_active=True,
    )
    db.add(magasin)
    db.flush()

    db.add(
        BoutiqueUserMembership(
            boutique_id=boutique.id,
            user_id=current_user.id,
            role="owner",
            assigned_magasin_ids=[magasin.id],
            is_active=True,
        )
    )

    now = datetime.now(timezone.utc)
    db.add(
        SaasSubscription(
            boutique_id=boutique.id,
            plan_id=plan.id,
            status="trialing" if trial_active else "active",
            billing_cycle=billing_cycle,
            has_used_trial=trial_active,
            trial_starts_at=now if trial_active else None,
            trial_ends_at=(now + timedelta(days=trial_days)) if trial_active else None,
            current_period_start=now,
            current_period_end=now + timedelta(days=period_days),
        )
    )
    db.flush()

    final_token, refresh_tok, _ = issue_token_pair(
        db,
        current_user,
        access_data={
            "role": current_user.role,
            "current_boutique_id": boutique.id,
            "current_magasin_id": magasin.id,
        },
    )
    db.commit()

    return {
        "success": True,
        "message": "Entreprise et boutique créées avec succès !",
        "boutique_id": boutique.id,
        "boutique_name": boutique.name,
        "magasin_id": magasin.id,
        "magasin_name": magasin.name,
        "plan_name": plan.name,
        "trial_active": trial_active,
        "trial_days": trial_days,
        "access_token": final_token,
        "refresh_token": refresh_tok,
        "token_type": "bearer",
        "user": user_to_brief(current_user),
    }
