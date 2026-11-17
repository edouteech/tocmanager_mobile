import uuid
from datetime import datetime, timezone, timedelta
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Header, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.models import (
    User, Boutique, BoutiqueUserMembership, Magasin, SaasPlan, SaasPlanFeature, SaasSubscription
)
from app.schemas.saas import (
    BoutiqueOut, BoutiqueCreate, MagasinOut, MagasinCreate, MagasinUpdate, CurrentPlanStatusOut
)
from app.api.deps import get_current_user

router = APIRouter()

@router.get("/boutiques", response_model=List[BoutiqueOut])
def get_user_boutiques(
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Renvoie la liste des boutiques accessibles par l'utilisateur connecté,
    avec son rôle et ses magasins assignés.
    """
    # Si superadmin, peut tout voir, sinon chercher dans memberships ou boutiques possédées
    if current_user.role in ["superadmin", "admin"]:
        all_boutiques = db.query(Boutique).filter(Boutique.is_active == True).all()
        results = []
        for b in all_boutiques:
            magasins = db.query(Magasin).filter(Magasin.boutique_id == b.id, Magasin.is_active == True).all()
            b_dict = {
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
                "user_role": "owner",
                "assigned_magasin_ids": [m.id for m in magasins],
            }
            results.append(b_dict)
        return results

    memberships = db.query(BoutiqueUserMembership).filter(
        BoutiqueUserMembership.user_id == current_user.id,
        BoutiqueUserMembership.is_active == True
    ).all()

    results = []
    for m in memberships:
        b = db.query(Boutique).filter(Boutique.id == m.boutique_id, Boutique.is_active == True).first()
        if b:
            magasins = db.query(Magasin).filter(Magasin.boutique_id == b.id, Magasin.is_active == True).all()
            # Si pas owner, restreindre magasins visibles si spécifiés
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

@router.post("/boutiques", response_model=BoutiqueOut)
def create_additional_boutique(
    payload: BoutiqueCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Permet à un propriétaire d'ajouter une nouvelle boutique commerciale."""
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

    membership = BoutiqueUserMembership(
        boutique_id=boutique.id,
        user_id=current_user.id,
        role="owner",
        assigned_magasin_ids=[magasin.id],
        is_active=True,
    )
    db.add(membership)

    # Assigner plan gratuit ou hériter
    plan = db.query(SaasPlan).filter(SaasPlan.code == (payload.plan_code or "free")).first()
    sub = SaasSubscription(
        boutique_id=boutique.id,
        plan_id=plan.id if plan else "free",
        status="active",
        billing_cycle="monthly",
    )
    db.add(sub)
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

@router.get("/magasins", response_model=List[MagasinOut])
def list_magasins(
    x_boutique_id: Optional[str] = Header(None, alias="X-Boutique-Id"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Liste les magasins rattachés à la boutique active."""
    query = db.query(Magasin).filter(Magasin.is_active == True)
    if x_boutique_id:
        query = query.filter(Magasin.boutique_id == x_boutique_id)

    magasins = query.all()
    # Si l'utilisateur n'est pas admin/owner, filtrer par ses affectations
    if current_user.role not in ["superadmin", "admin", "merchant"]:
        membership = db.query(BoutiqueUserMembership).filter(
            BoutiqueUserMembership.user_id == current_user.id,
            BoutiqueUserMembership.boutique_id == x_boutique_id
        ).first()
        if membership and membership.role != "owner" and membership.assigned_magasin_ids:
            magasins = [m for m in magasins if m.id in membership.assigned_magasin_ids]

    return magasins

@router.post("/magasins", response_model=MagasinOut)
def create_magasin(
    payload: MagasinCreate,
    x_boutique_id: Optional[str] = Header(None, alias="X-Boutique-Id"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Création d'un nouveau point de vente / magasin avec vérification de quota du plan."""
    if not x_boutique_id:
        first_b = db.query(Boutique).first()
        x_boutique_id = first_b.id if first_b else None

    # Vérification quota du plan
    sub = db.query(SaasSubscription).filter(SaasSubscription.boutique_id == x_boutique_id).first()
    if sub:
        plan = db.query(SaasPlan).filter(SaasPlan.id == sub.plan_id).first()
        if plan:
            feat = db.query(SaasPlanFeature).filter(
                SaasPlanFeature.plan_id == plan.id,
                SaasPlanFeature.feature_code == "max_magasins"
            ).first()
            if feat and feat.int_limit > 0:
                current_count = db.query(Magasin).filter(
                    Magasin.boutique_id == x_boutique_id,
                    Magasin.is_active == True
                ).count()
                if current_count >= feat.int_limit:
                    raise HTTPException(
                        status_code=status.HTTP_403_FORBIDDEN,
                        detail={
                            "error": "PLAN_QUOTA_EXCEEDED",
                            "feature": "max_magasins",
                            "limit": feat.int_limit,
                            "current": current_count,
                            "message": f"Votre plan {plan.name} est limité à {feat.int_limit} magasin(s). Passez au forfait supérieur pour ouvrir de nouveaux points de vente."
                        }
                    )

    magasin = Magasin(
        boutique_id=x_boutique_id,
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

@router.put("/magasins/{magasin_id}", response_model=MagasinOut)
def update_magasin(
    magasin_id: str,
    payload: MagasinUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    magasin = db.query(Magasin).filter(Magasin.id == magasin_id).first()
    if not magasin:
        raise HTTPException(status_code=404, detail="Magasin non trouvé.")

    if payload.name is not None:
        magasin.name = payload.name
    if payload.code is not None:
        magasin.code = payload.code
    if payload.address is not None:
        magasin.address = payload.address
    if payload.phone is not None:
        magasin.phone = payload.phone
    if payload.is_warehouse is not None:
        magasin.is_warehouse = payload.is_warehouse
    if payload.is_active is not None:
        magasin.is_active = payload.is_active

    db.commit()
    db.refresh(magasin)
    return magasin

@router.get("/current-plan", response_model=CurrentPlanStatusOut)
def get_current_plan_status(
    x_boutique_id: Optional[str] = Header(None, alias="X-Boutique-Id"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Renvoie le statut détaillé de l'abonnement de la boutique active,
    avec le décompte des jours d'essai restants et les features activées.
    """
    if not x_boutique_id:
        b = db.query(Boutique).first()
        x_boutique_id = b.id if b else "default"

    sub = db.query(SaasSubscription).filter(SaasSubscription.boutique_id == x_boutique_id).first()
    plan = None
    if sub:
        plan = db.query(SaasPlan).filter(SaasPlan.id == sub.plan_id).first()
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

    features_map = {}
    if plan:
        for f in plan.features:
            features_map[f.feature_code] = f.boolean_value if f.value_type == "boolean" else f.int_limit

    magasins_used = db.query(Magasin).filter(Magasin.boutique_id == x_boutique_id, Magasin.is_active == True).count()

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

@router.post("/upgrade-plan")
def upgrade_plan(
    payload: dict,
    x_boutique_id: Optional[str] = Header(None, alias="X-Boutique-Id"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Permet de passer à un forfait supérieur (ou démarrer l'essai gratuit du plan)."""
    target_plan_code = payload.get("plan_code", "pro")
    target_plan = db.query(SaasPlan).filter(SaasPlan.code == target_plan_code).first()
    if not target_plan:
        raise HTTPException(status_code=404, detail="Plan sélectionné introuvable.")

    if not x_boutique_id:
        b = db.query(Boutique).first()
        x_boutique_id = b.id if b else None

    sub = db.query(SaasSubscription).filter(SaasSubscription.boutique_id == x_boutique_id).first()
    now = datetime.now(timezone.utc)
    trial_days = target_plan.trial_period_days

    if not sub:
        sub = SaasSubscription(
            boutique_id=x_boutique_id,
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
        "trial_ends_at": sub.trial_ends_at
    }
