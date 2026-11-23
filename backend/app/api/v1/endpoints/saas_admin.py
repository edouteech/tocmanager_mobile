from datetime import datetime, timezone, timedelta
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.core.database import get_db
from app.models import (
    User, Boutique, Magasin, SaasPlan, SaasPlanFeature, SaasSubscription, Vente, PlatformAuditLog
)
from app.schemas.saas import (
    FeatureCatalogItemOut, SaasPlanOut, SaasPlanCreate, SaasPlanUpdate, BoutiqueOut
)
from app.services.feature_catalog import (
    serialize_feature_catalog,
    sync_plan_features_from_catalog,
)
from app.api.deps import get_current_user

router = APIRouter()

def require_superadmin(user: User = Depends(get_current_user)):
    """Strict access control reserved exclusively for platform superadmins."""
    if user.role != "superadmin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Accès réservé aux super-administrateurs de la plateforme."
        )
    return user

@router.get("/kpis")
def get_platform_kpis(
    admin: User = Depends(require_superadmin),
    db: Session = Depends(get_db)
):
    """Calcule les indicateurs macroscopiques SaaS pour le dashboard Super-Admin."""
    total_boutiques = db.query(Boutique).count()
    active_boutiques = db.query(Boutique).filter(Boutique.is_active == True).count()
    total_magasins = db.query(Magasin).count()

    trialing_subs = db.query(SaasSubscription).filter(SaasSubscription.status == "trialing").count()
    active_subs = db.query(SaasSubscription).filter(SaasSubscription.status == "active").count()

    # Estimation MRR
    plans = db.query(SaasPlan).all()
    plan_prices = {p.id: p.price_monthly for p in plans}
    mrr = sum(
        plan_prices.get(sub.plan_id, 0.0)
        for sub in db.query(SaasSubscription).filter(SaasSubscription.status.in_(["active", "trialing"])).all()
    )

    # Volume total des ventes (GMV)
    total_gmv = db.query(func.coalesce(func.sum(Vente.total_amount), 0.0)).filter(Vente.deleted_at.is_(None)).scalar() or 0.0

    return {
        "mrr": mrr,
        "arr": mrr * 12,
        "total_boutiques": total_boutiques,
        "active_boutiques": active_boutiques,
        "total_magasins": total_magasins,
        "trialing_subscriptions": trialing_subs,
        "active_subscriptions": active_subs,
        "total_gmv": float(total_gmv),
        "currency": "XOF",
    }

@router.get("/features-catalog", response_model=List[FeatureCatalogItemOut])
def admin_get_features_catalog(
    admin: User = Depends(require_superadmin),
):
    _ = admin
    return serialize_feature_catalog()


@router.get("/plans", response_model=List[SaasPlanOut])
def admin_list_plans(
    admin: User = Depends(require_superadmin),
    db: Session = Depends(get_db)
):
    """Liste exhaustive des forfaits, actifs ou inactifs."""
    return db.query(SaasPlan).order_by(SaasPlan.price_monthly.asc()).all()

@router.post("/plans", response_model=SaasPlanOut)
def admin_create_plan(
    payload: SaasPlanCreate,
    admin: User = Depends(require_superadmin),
    db: Session = Depends(get_db)
):
    """Création d'un nouveau forfait par l'administrateur."""
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

    # Log d'audit
    audit = PlatformAuditLog(
        admin_user_id=admin.id,
        admin_username=admin.username,
        action="PLAN_CREATE",
        target_entity="plan",
        target_id=plan.id,
        details={"name": plan.name, "code": plan.code, "price_monthly": plan.price_monthly}
    )
    db.add(audit)
    db.commit()
    db.refresh(plan)
    return plan

@router.put("/plans/{plan_id}", response_model=SaasPlanOut)
def admin_update_plan(
    plan_id: str,
    payload: SaasPlanUpdate,
    admin: User = Depends(require_superadmin),
    db: Session = Depends(get_db)
):
    """Mise à jour d'un forfait (tarifs, options, durée d'essai)."""
    plan = db.query(SaasPlan).filter(SaasPlan.id == plan_id).first()
    if not plan:
        raise HTTPException(status_code=404, detail="Plan non trouvé.")

    if payload.name is not None:
        plan.name = payload.name
    if payload.description is not None:
        plan.description = payload.description
    if payload.price_monthly is not None:
        plan.price_monthly = payload.price_monthly
    if payload.price_yearly is not None:
        plan.price_yearly = payload.price_yearly
    if payload.trial_period_days is not None:
        plan.trial_period_days = payload.trial_period_days
    if payload.badge is not None:
        plan.badge = payload.badge
    if payload.is_active is not None:
        plan.is_active = payload.is_active

    if payload.features is not None:
        sync_plan_features_from_catalog(
            db, plan, provided_features=payload.features, use_plan_defaults=False
        )

    audit = PlatformAuditLog(
        admin_user_id=admin.id,
        admin_username=admin.username,
        action="PLAN_UPDATE",
        target_entity="plan",
        target_id=plan.id,
        details={"name": plan.name, "price_monthly": plan.price_monthly}
    )
    db.add(audit)
    db.commit()
    db.refresh(plan)
    return plan

@router.get("/boutiques")
def admin_list_boutiques(
    admin: User = Depends(require_superadmin),
    db: Session = Depends(get_db)
):
    """Liste toutes les boutiques clientes avec informations sur le propriétaire et l'abonnement."""
    boutiques = db.query(Boutique).all()
    results = []
    for b in boutiques:
        owner = db.query(User).filter(User.id == b.owner_user_id).first()
        magasin_count = db.query(Magasin).filter(Magasin.boutique_id == b.id).count()
        sub = db.query(SaasSubscription).filter(SaasSubscription.boutique_id == b.id).first()
        plan = db.query(SaasPlan).filter(SaasPlan.id == sub.plan_id).first() if sub else None

        results.append({
            "id": b.id,
            "slug": b.slug,
            "name": b.name,
            "company_name": b.company_name,
            "currency": b.currency,
            "country": b.country,
            "phone": b.phone,
            "is_active": b.is_active,
            "created_at": b.created_at,
            "owner_name": owner.full_name if owner else "Inconnu",
            "owner_email": owner.email if owner else owner.username if owner else "Inconnu",
            "magasin_count": magasin_count,
            "subscription": {
                "status": sub.status if sub else "none",
                "plan_name": plan.name if plan else "Gratuit",
                "plan_code": plan.code if plan else "free",
                "trial_ends_at": sub.trial_ends_at if sub else None,
            }
        })
    return results

@router.put("/boutiques/{boutique_id}/status")
def admin_toggle_boutique_status(
    boutique_id: str,
    payload: dict,
    admin: User = Depends(require_superadmin),
    db: Session = Depends(get_db)
):
    """Active ou suspend une boutique."""
    boutique = db.query(Boutique).filter(Boutique.id == boutique_id).first()
    if not boutique:
        raise HTTPException(status_code=404, detail="Boutique non trouvée.")

    is_active = payload.get("is_active", True)
    boutique.is_active = is_active

    audit = PlatformAuditLog(
        admin_user_id=admin.id,
        admin_username=admin.username,
        action="BOUTIQUE_STATUS_TOGGLE",
        target_entity="boutique",
        target_id=boutique.id,
        details={"name": boutique.name, "is_active": is_active}
    )
    db.add(audit)
    db.commit()
    return {"success": True, "boutique_id": boutique.id, "is_active": boutique.is_active}

@router.post("/boutiques/{boutique_id}/extend-trial")
def admin_extend_trial(
    boutique_id: str,
    payload: dict,
    admin: User = Depends(require_superadmin),
    db: Session = Depends(get_db)
):
    """Prolonge manuellement la période d'essai d'une boutique (ex: +7 jours, +14 jours)."""
    sub = db.query(SaasSubscription).filter(SaasSubscription.boutique_id == boutique_id).first()
    if not sub:
        raise HTTPException(status_code=404, detail="Abonnement non trouvé pour cette boutique.")

    additional_days = int(payload.get("days", 14))
    base_date = sub.trial_ends_at or datetime.now(timezone.utc)
    if base_date < datetime.now(timezone.utc):
        base_date = datetime.now(timezone.utc)

    sub.trial_ends_at = base_date + timedelta(days=additional_days)
    sub.status = "trialing"

    audit = PlatformAuditLog(
        admin_user_id=admin.id,
        admin_username=admin.username,
        action="TRIAL_EXTEND",
        target_entity="subscription",
        target_id=sub.id,
        details={"boutique_id": boutique_id, "additional_days": additional_days, "new_trial_ends_at": sub.trial_ends_at.isoformat()}
    )
    db.add(audit)
    db.commit()
    return {"success": True, "trial_ends_at": sub.trial_ends_at}
