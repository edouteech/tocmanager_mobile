import uuid
from datetime import datetime, timezone, timedelta
from typing import Any, Dict, List
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.permissions import normalize_tenant_role
from app.models import (
    User, Boutique, BoutiqueUserMembership, Magasin, SaasSubscription
)
from app.schemas.saas import BoutiqueCreate, MagasinCreate, MagasinUpdate
from app.services.entitlements import check_quota_limit, resolve_effective_plan
from app.services.onboarding_service import resolve_subscription_plan, set_pg_boutique_rls_context
from app.services.tenant_context_service import TenantContext


def list_accessible_boutiques(db: Session, current_user: User) -> List[Dict[str, Any]]:
    if current_user.role == "superadmin":
        return []

    memberships = (
        db.query(BoutiqueUserMembership)
        .filter(
            BoutiqueUserMembership.user_id == current_user.id,
            BoutiqueUserMembership.is_active == True,
        )
        .all()
    )

    results: List[Dict[str, Any]] = []
    for m in memberships:
        b = db.query(Boutique).filter(Boutique.id == m.boutique_id, Boutique.is_active == True).first()
        if not b:
            continue
        magasins = db.query(Magasin).filter(Magasin.boutique_id == b.id, Magasin.is_active == True).all()
        assigned = m.assigned_magasin_ids or []
        if m.role != "owner" and assigned:
            magasins = [mag for mag in magasins if mag.id in assigned]

        results.append({
            "id": b.id,
            "slug": b.slug,
            "name": b.name,
            "company_name": b.company_name,
            "currency": b.currency,
            "country": b.country,
            "phone": b.phone,
            "email": b.email,
            "address": b.address,
            "logo_url": b.logo_url,
            "owner_user_id": b.owner_user_id,
            "is_active": b.is_active,
            "created_at": b.created_at,
            "magasins": magasins,
            "user_role": m.role,
            "assigned_magasin_ids": assigned or [mag.id for mag in magasins],
        })
    return results


def create_boutique_for_owner(db: Session, current_user: User, payload: BoutiqueCreate) -> Dict[str, Any]:
    if current_user.role == "superadmin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Un super-administrateur ne peut pas posséder de boutique client.",
        )

    existing_boutiques = db.query(Boutique).filter(
        Boutique.owner_user_id == current_user.id, Boutique.is_active == True
    ).all()
    if existing_boutiques:
        best_limit = 1
        for eb in existing_boutiques:
            _, _, feats = resolve_effective_plan(db, eb.id)
            lim = int(feats.get("max_boutiques", 1))
            if lim == -1:
                best_limit = -1
                break
            if lim > best_limit:
                best_limit = lim
        if best_limit != -1 and len(existing_boutiques) >= best_limit:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail={
                    "error": "PLAN_QUOTA_EXCEEDED",
                    "feature": "max_boutiques",
                    "limit": best_limit,
                    "current": len(existing_boutiques),
                    "recommended_plan": "pro" if best_limit <= 1 else "enterprise",
                    "message": f"Quota de boutiques atteint ({len(existing_boutiques)}/{best_limit}). Passez au forfait supérieur.",
                },
            )

    owner_has_used_trial = any(b.has_used_trial for b in existing_boutiques)
    requested_plan = resolve_subscription_plan(db, payload.plan_code or "free")
    use_trial = bool(
        requested_plan.code != "free"
        and requested_plan.trial_period_days > 0
        and not owner_has_used_trial
    )
    assigned_plan = requested_plan if use_trial else resolve_subscription_plan(db, "free")

    base_slug = payload.name.strip().lower().replace(" ", "-")
    unique_slug = f"{base_slug}-{uuid.uuid4().hex[:6]}"
    boutique = Boutique(
        slug=unique_slug,
        name=payload.name.strip(),
        company_name=payload.company_name or payload.name.strip(),
        currency=payload.currency,
        country=payload.country,
        phone=payload.phone,
        email=payload.email,
        address=payload.address,
        owner_user_id=current_user.id,
        has_used_trial=use_trial,
        is_active=True,
    )
    db.add(boutique)
    db.flush()

    set_pg_boutique_rls_context(db, boutique.id)

    magasin = Magasin(
        boutique_id=boutique.id,
        name=payload.initial_magasin_name or "Magasin Principal",
        code="MAG-01",
        is_active=True,
    )
    db.add(magasin)
    db.flush()

    db.add(BoutiqueUserMembership(
        boutique_id=boutique.id,
        user_id=current_user.id,
        role="owner",
        assigned_magasin_ids=[magasin.id],
        is_active=True,
    ))

    now = datetime.now(timezone.utc)
    db.add(SaasSubscription(
        boutique_id=boutique.id,
        plan_id=assigned_plan.id,
        status="trialing" if use_trial else "active",
        billing_cycle="monthly",
        has_used_trial=use_trial,
        trial_starts_at=now if use_trial else None,
        trial_ends_at=(now + timedelta(days=assigned_plan.trial_period_days)) if use_trial else None,
    ))
    db.commit()
    db.refresh(boutique)

    return {
        "id": boutique.id,
        "slug": boutique.slug,
        "name": boutique.name,
        "company_name": boutique.company_name,
        "currency": boutique.currency,
        "country": boutique.country,
        "phone": boutique.phone,
        "email": boutique.email,
        "address": boutique.address,
        "logo_url": boutique.logo_url,
        "owner_user_id": boutique.owner_user_id,
        "is_active": boutique.is_active,
        "created_at": boutique.created_at,
        "magasins": [magasin],
        "user_role": "owner",
        "assigned_magasin_ids": [magasin.id],
    }


def list_ctx_magasins(db: Session, ctx: TenantContext) -> List[Magasin]:
    magasins = db.query(Magasin).filter(
        Magasin.boutique_id == ctx.boutique.id, Magasin.is_active == True
    ).all()
    if normalize_tenant_role(ctx.role) not in ("owner", "store_admin") and ctx.assigned_magasin_ids:
        magasins = [m for m in magasins if m.id in ctx.assigned_magasin_ids]
    return magasins


def create_ctx_magasin(db: Session, ctx: TenantContext, payload: MagasinCreate) -> Magasin:
    boutique_id = ctx.boutique.id
    current_count = db.query(Magasin).filter(
        Magasin.boutique_id == boutique_id, Magasin.is_active == True
    ).count()
    check_quota_limit(db, boutique_id, "max_magasins", current_count)

    magasin = Magasin(
        boutique_id=boutique_id,
        name=payload.name.strip(),
        code=payload.code or f"MAG-{uuid.uuid4().hex[:4].upper()}",
        address=payload.address,
        phone=payload.phone,
        is_warehouse=payload.is_warehouse,
        is_active=payload.is_active,
    )
    db.add(magasin)
    db.commit()
    db.refresh(magasin)
    return magasin


def update_ctx_magasin(
    db: Session, ctx: TenantContext, magasin_id: str, payload: MagasinUpdate
) -> Magasin:
    magasin = db.query(Magasin).filter(
        Magasin.id == magasin_id, Magasin.boutique_id == ctx.boutique.id
    ).first()
    if not magasin:
        raise HTTPException(status_code=404, detail="Magasin non trouvé.")

    for field in ("name", "code", "address", "phone", "is_warehouse", "is_active"):
        val = getattr(payload, field)
        if val is not None:
            setattr(magasin, field, val)
    db.commit()
    db.refresh(magasin)
    return magasin
