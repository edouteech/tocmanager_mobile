import uuid
from datetime import datetime, timezone, timedelta
from typing import Any, Dict, List
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models import (
    User, Boutique, BoutiqueUserMembership, Magasin, SaasPlan, SaasPlanFeature, SaasSubscription
)
from app.schemas.saas import BoutiqueCreate, MagasinCreate, MagasinUpdate
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
        is_active=True,
    )
    db.add(boutique)
    db.flush()

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

    plan = db.query(SaasPlan).filter(SaasPlan.code == (payload.plan_code or "free")).first()
    db.add(SaasSubscription(
        boutique_id=boutique.id,
        plan_id=plan.id if plan else "free",
        status="active",
        billing_cycle="monthly",
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
    if ctx.role != "owner" and ctx.assigned_magasin_ids:
        magasins = [m for m in magasins if m.id in ctx.assigned_magasin_ids]
    return magasins


def create_ctx_magasin(db: Session, ctx: TenantContext, payload: MagasinCreate) -> Magasin:
    boutique_id = ctx.boutique.id
    sub = db.query(SaasSubscription).filter(SaasSubscription.boutique_id == boutique_id).first()
    if sub:
        plan = db.query(SaasPlan).filter(SaasPlan.id == sub.plan_id).first()
        if plan:
            feat = db.query(SaasPlanFeature).filter(
                SaasPlanFeature.plan_id == plan.id,
                SaasPlanFeature.feature_code == "max_magasins",
            ).first()
            if feat and feat.int_limit > 0:
                current_count = db.query(Magasin).filter(
                    Magasin.boutique_id == boutique_id, Magasin.is_active == True
                ).count()
                if current_count >= feat.int_limit:
                    raise HTTPException(
                        status_code=status.HTTP_403_FORBIDDEN,
                        detail={
                            "error": "PLAN_QUOTA_EXCEEDED",
                            "feature": "max_magasins",
                            "limit": feat.int_limit,
                            "current": current_count,
                            "message": f"Votre plan {plan.name} est limité à {feat.int_limit} magasin(s). Passez au forfait supérieur pour ouvrir de nouveaux points de vente.",
                        },
                    )

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
