from dataclasses import dataclass
from typing import List, Optional
from fastapi import HTTPException, status
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.core.permissions import normalize_tenant_role
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

    eff_role = normalize_tenant_role(membership.role)
    assigned_magasin_ids = list(membership.assigned_magasin_ids or [])

    raw_mag = x_magasin_id.strip() if isinstance(x_magasin_id, str) else None
    req_mag_id = None if raw_mag in (None, "", "consolidated", "all") else raw_mag

    if raw_mag in ("consolidated", "all"):
        if eff_role not in ("owner", "store_admin") and (
            eff_role != "manager" or bool(assigned_magasin_ids)
        ):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Accès consolidé multi-magasins interdit pour ce profil.",
            )

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
        if eff_role not in ("owner", "store_admin") and assigned_magasin_ids:
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


def resolve_read_magasin_id(ctx: TenantContext) -> Optional[str]:
    """Return active magasin_id filter, or None when consolidated access is allowed."""
    if ctx.requested_magasin_id:
        return ctx.requested_magasin_id
    eff_role = normalize_tenant_role(ctx.role)
    if eff_role in ("owner", "store_admin"):
        return None
    if eff_role == "manager" and not ctx.assigned_magasin_ids:
        return None
    raise HTTPException(
        status_code=status.HTTP_403_FORBIDDEN,
        detail="La vue consolidée multi-magasins est interdite pour ce rôle. Sélectionnez un magasin.",
    )


def resolve_operational_magasin(
    db: Session,
    ctx: TenantContext,
    body_magasin_id: Optional[str] = None,
    allow_warehouse: bool = True,
    allow_single_assigned_fallback: bool = False,
) -> Magasin:
    """Resolve and authorize a concrete active Magasin for stock/POS writes."""
    candidate_id = (body_magasin_id or "").strip() if body_magasin_id else None
    if candidate_id in ("", "consolidated", "all"):
        candidate_id = None
    target_id = candidate_id or ctx.requested_magasin_id

    eff_role = normalize_tenant_role(ctx.role)
    if not target_id:
        if allow_single_assigned_fallback and len(ctx.assigned_magasin_ids) == 1:
            target_id = ctx.assigned_magasin_ids[0]
        elif eff_role == "cashier" or (eff_role == "manager" and ctx.assigned_magasin_ids):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Sélectionnez un magasin assigné via X-Magasin-Id pour cette opération.",
            )
        else:
            active_mags = (
                db.query(Magasin)
                .filter(Magasin.boutique_id == ctx.boutique.id, Magasin.is_active == True)
                .order_by(Magasin.is_warehouse.asc(), Magasin.created_at.asc())
                .all()
            )
            if len(active_mags) == 1:
                magasin = active_mags[0]
            elif len(active_mags) > 1:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Veuillez sélectionner un magasin pour enregistrer cette opération.",
                )
            else:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Aucun magasin actif trouvé dans cette boutique.",
                )
            if not allow_warehouse and magasin.is_warehouse:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Impossible d'enregistrer une vente directe depuis un entrepôt de réserve",
                )
            return magasin

    magasin = db.query(Magasin).filter(
        Magasin.id == target_id, Magasin.boutique_id == ctx.boutique.id, Magasin.is_active == True
    ).first()
    if not magasin:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Magasin introuvable ou inactif dans cette boutique.")
    if eff_role not in ("owner", "store_admin") and ctx.assigned_magasin_ids:
        if magasin.id not in ctx.assigned_magasin_ids:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Accès non autorisé à ce magasin.")
    if not allow_warehouse and magasin.is_warehouse:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Impossible d'enregistrer une vente directe depuis un entrepôt de réserve")
    return magasin


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
