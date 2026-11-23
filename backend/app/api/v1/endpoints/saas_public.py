import uuid
from datetime import datetime, timezone, timedelta
from typing import List
from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.rate_limit import limiter
from app.core.security import get_password_hash, create_access_token
from app.models import (
    User, Boutique, BoutiqueUserMembership, Magasin, SaasPlan, SaasSubscription, PlatformAuditLog
)
from app.schemas.saas import (
    FeatureCatalogItemOut,
    PublicContactRequest,
    SaasPlanOut,
    RegisterCredentialsRequest,
    ProvisionTenantRequest,
)
from app.services.auth_service import issue_token_pair, user_to_brief
from app.services.feature_catalog import serialize_feature_catalog
from app.api.deps import get_onboarding_user

router = APIRouter()

@router.get("/plans", response_model=List[SaasPlanOut])
def get_public_plans(db: Session = Depends(get_db)):
    """Retourne la liste des forfaits actifs pour la page de pricing vitrine."""
    plans = db.query(SaasPlan).filter(SaasPlan.is_active == True).order_by(SaasPlan.price_monthly.asc()).all()
    return plans


@router.get("/features-catalog", response_model=List[FeatureCatalogItemOut])
def get_public_features_catalog():
    """Retourne le catalogue officiel des 28 droits et quotas."""
    return serialize_feature_catalog()

@router.post("/auth/register-credentials")
@limiter.limit("5/minute")
def register_credentials(request: Request, payload: RegisterCredentialsRequest, db: Session = Depends(get_db)):
    _ = request
    """
    Étape 1 de l'inscription : création rapide des identifiants utilisateur.
    Renvoie un token d'onboarding permettant de compléter l'étape 2 (création boutique).
    """
    # Vérifier l'unicité de l'identifiant
    ident = payload.username_or_email.strip().lower()
    existing = db.query(User).filter(
        (User.username == ident) | (User.email == ident)
    ).first()
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Un compte avec cet email ou identifiant existe déjà."
        )

    user = User(
        username=ident,
        email=ident if "@" in ident else None,
        full_name=payload.full_name.strip(),
        hashed_password=get_password_hash(payload.password),
        role="merchant", # Propriétaire de boutique
        is_active=True,
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    # Création du token d'onboarding
    access_token = create_access_token(
        data={"sub": user.id, "scope": "onboarding", "role": user.role}
    )

    return {
        "user_id": user.id,
        "username": user.username,
        "full_name": user.full_name,
        "access_token": access_token,
        "token_type": "bearer",
        "next_step": "provision_tenant"
    }

@router.post("/tenant/provision")
def provision_tenant(
    payload: ProvisionTenantRequest,
    current_user: User = Depends(get_onboarding_user),
    db: Session = Depends(get_db)
):
    """
    Étape 2 de l'inscription : configuration de l'entreprise / boutique initiale,
    du magasin principal et affectation du plan SaaS (gratuit ou période d'essai).
    """
    # Créer le slug de boutique
    base_slug = payload.boutique_name.strip().lower().replace(" ", "-")
    unique_slug = f"{base_slug}-{uuid.uuid4().hex[:6]}"
    schema_name = f"tenant_btq_{uuid.uuid4().hex[:12]}"

    boutique = Boutique(
        slug=unique_slug,
        name=payload.boutique_name.strip(),
        company_name=payload.company_name or payload.boutique_name.strip(),
        currency=payload.currency,
        country=payload.country,
        phone=payload.phone,
        schema_name=schema_name,
        owner_user_id=current_user.id,
        is_active=True,
    )
    db.add(boutique)
    db.flush()

    # Créer le premier magasin
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

    # Créer le membership du propriétaire
    membership = BoutiqueUserMembership(
        boutique_id=boutique.id,
        user_id=current_user.id,
        role="owner",
        assigned_magasin_ids=[magasin.id],
        is_active=True,
    )
    db.add(membership)

    # Récupérer le plan choisi
    plan = db.query(SaasPlan).filter(SaasPlan.code == payload.plan_code).first()
    if not plan:
        plan = db.query(SaasPlan).filter(SaasPlan.code == "free").first()

    now = datetime.now(timezone.utc)
    trial_days = plan.trial_period_days if plan else 0
    trial_active = trial_days > 0
    billing_cycle = payload.billing_cycle if payload.billing_cycle in ("monthly", "yearly") else "monthly"
    period_days = trial_days if trial_active else (365 if billing_cycle == "yearly" else 30)

    boutique.has_used_trial = trial_active
    subscription = SaasSubscription(
        boutique_id=boutique.id,
        plan_id=plan.id if plan else "free",
        status="trialing" if trial_active else "active",
        billing_cycle=billing_cycle,
        has_used_trial=trial_active,
        trial_starts_at=now if trial_active else None,
        trial_ends_at=(now + timedelta(days=trial_days)) if trial_active else None,
        current_period_start=now,
        current_period_end=now + timedelta(days=period_days),
    )
    db.add(subscription)
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
        "plan_name": plan.name if plan else "Plan Gratuit",
        "trial_active": trial_active,
        "trial_days": trial_days,
        "access_token": final_token,
        "refresh_token": refresh_tok,
        "token_type": "bearer",
        "user": user_to_brief(current_user),
    }


@router.post("/contact")
@limiter.limit("5/minute")
def submit_public_contact(
    request: Request,
    payload: PublicContactRequest,
    db: Session = Depends(get_db),
):
    """Receive a public contact / enterprise demo inquiry."""
    _ = request
    db.add(
        PlatformAuditLog(
            admin_username=payload.email,
            action="PUBLIC_CONTACT_MESSAGE",
            target_entity="contact",
            target_id=None,
            details=payload.model_dump(),
        )
    )
    db.commit()
    return {
        "success": True,
        "message": "Votre message a bien été reçu. Notre équipe vous contactera rapidement.",
    }
