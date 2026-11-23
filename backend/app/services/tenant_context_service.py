from dataclasses import dataclass
from typing import List, Optional
from fastapi import HTTPException, status
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.models import Boutique, BoutiqueUserMembership, Magasin, User


@dataclass
class TenantContext:
    user: User
    boutique: Boutique
    membership: BoutiqueUserMembership
    role: str
    assigned_magasin_ids: List[str]
    requested_magasin_id: Optional[str] = None


def resolve_tenant_context(
    db: Session,
    current_user: User,
    x_boutique_id: Optional[str] = None,
    x_magasin_id: Optional[str] = None,
) -> TenantContext:
    """Résout et valide le contexte boutique/magasin pour chaque route métier."""
    if current_user.role == "superadmin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Un super-administrateur plateforme ne peut pas exécuter d'opérations commerciales tenant.",
        )

    req_btq_id = x_boutique_id.strip() if isinstance(x_boutique_id, str) else None
    boutique: Optional[Boutique] = None
    membership: Optional[BoutiqueUserMembership] = None

    if req_btq_id:
        membership = (
            db.query(BoutiqueUserMembership)
            .filter(
                BoutiqueUserMembership.boutique_id == req_btq_id,
                BoutiqueUserMembership.user_id == current_user.id,
                BoutiqueUserMembership.is_active == True,
            )
            .first()
        )
        if not membership:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Accès non autorisé à cette boutique.",
            )
        boutique = db.query(Boutique).filter(Boutique.id == req_btq_id).first()
        if not boutique or not boutique.is_active:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Cette boutique est suspendue ou inactive.",
            )
    else:
        rows = (
            db.query(BoutiqueUserMembership, Boutique)
            .join(Boutique, Boutique.id == BoutiqueUserMembership.boutique_id)
            .filter(
                BoutiqueUserMembership.user_id == current_user.id,
                BoutiqueUserMembership.is_active == True,
                Boutique.is_active == True,
            )
            .all()
        )
        if not rows:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Aucune boutique active associée à ce compte.",
            )
        if len(rows) > 1:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="En-tête X-Boutique-Id requis pour sélectionner la boutique active.",
            )
        membership, boutique = rows[0]

    req_mag_id = x_magasin_id.strip() if isinstance(x_magasin_id, str) else None
    if req_mag_id in ("", "consolidated", "all"):
        req_mag_id = None

    assigned_magasin_ids = list(membership.assigned_magasin_ids or [])
    if req_mag_id:
        magasin = (
            db.query(Magasin)
            .filter(
                Magasin.id == req_mag_id,
                Magasin.boutique_id == boutique.id,
                Magasin.is_active == True,
            )
            .first()
        )
        if not magasin:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Magasin introuvable ou inactif dans cette boutique.",
            )
        if membership.role != "owner" and assigned_magasin_ids:
            if req_mag_id not in assigned_magasin_ids:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Accès non autorisé à ce magasin.",
                )

    if db.bind is not None and db.bind.dialect.name == "postgresql":
        db.execute(
            text("SELECT set_config('app.current_boutique_id', :btq_id, true)"),
            {"btq_id": boutique.id},
        )

    return TenantContext(
        user=current_user,
        boutique=boutique,
        membership=membership,
        role=membership.role,
        assigned_magasin_ids=assigned_magasin_ids,
        requested_magasin_id=req_mag_id,
    )


def resolve_audit_boutique_id(
    db: Session, user: User, x_boutique_id: Optional[str] = None
) -> Optional[str]:
    """Résout une boutique_id sûre pour les logs d'authentification sans échouer si absent."""
    if user.role == "superadmin":
        return None
    req_btq_id = x_boutique_id.strip() if isinstance(x_boutique_id, str) else None
    if req_btq_id:
        membership = (
            db.query(BoutiqueUserMembership)
            .filter(
                BoutiqueUserMembership.boutique_id == req_btq_id,
                BoutiqueUserMembership.user_id == user.id,
                BoutiqueUserMembership.is_active == True,
            )
            .first()
        )
        return req_btq_id if membership else None

    memberships = (
        db.query(BoutiqueUserMembership.boutique_id)
        .filter(
            BoutiqueUserMembership.user_id == user.id,
            BoutiqueUserMembership.is_active == True,
        )
        .limit(2)
        .all()
    )
    if len(memberships) == 1:
        return memberships[0][0]
    return None
