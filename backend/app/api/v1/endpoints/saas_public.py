from typing import List
from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session

from app.api.deps import get_onboarding_user
from app.core.database import get_db
from app.core.rate_limit import limiter
from app.models import PlatformAuditLog, SaasPlan, User
from app.schemas.saas import (
    FeatureCatalogItemOut,
    ProvisionTenantRequest,
    PublicContactRequest,
    RegisterCredentialsRequest,
    SaasPlanOut,
)
from app.services.feature_catalog import serialize_feature_catalog
from app.services.onboarding_service import (
    provision_initial_tenant,
    register_or_resume_onboarding_user,
)

router = APIRouter()


@router.get("/plans", response_model=List[SaasPlanOut])
def get_public_plans(db: Session = Depends(get_db)):
    """Retourne la liste des forfaits actifs pour la page de pricing vitrine."""
    return db.query(SaasPlan).filter(SaasPlan.is_active == True).order_by(SaasPlan.price_monthly.asc()).all()


@router.get("/features-catalog", response_model=List[FeatureCatalogItemOut])
def get_public_features_catalog():
    """Retourne le catalogue officiel des 28 droits et quotas."""
    return serialize_feature_catalog()


@router.post("/auth/register-credentials")
@limiter.limit("5/minute")
def register_credentials(request: Request, payload: RegisterCredentialsRequest, db: Session = Depends(get_db)):
    """
    Étape 1 de l'inscription : création rapide des identifiants utilisateur ou reprise
    sécurisée de l'étape 2 si le compte est actif et ne possède pas encore de boutique.
    """
    _ = request
    return register_or_resume_onboarding_user(
        db=db,
        full_name=payload.full_name,
        username_or_email=payload.username_or_email,
        password=payload.password,
    )


@router.post("/tenant/provision")
def provision_tenant(
    payload: ProvisionTenantRequest,
    current_user: User = Depends(get_onboarding_user),
    db: Session = Depends(get_db),
):
    """
    Étape 2 de l'inscription : configuration de l'entreprise / boutique initiale,
    du magasin principal et affectation du plan SaaS (gratuit ou période d'essai).
    """
    return provision_initial_tenant(db=db, current_user=current_user, payload=payload)


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
