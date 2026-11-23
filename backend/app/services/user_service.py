from typing import Any, Dict, List, Optional, Tuple
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.permissions import get_permissions_for_role, normalize_tenant_role
from app.core.security import get_password_hash, hash_pin
from app.models import AuditLog, BoutiqueUserMembership, Magasin, User
from app.schemas.users import UserCreate, UserUpdate
from app.services.auth_service import revoke_all_user_tokens
from app.services.tenant_context_service import TenantContext


def _validate_assigned_magasins(
    db: Session, boutique_id: str, magasin_ids: Optional[List[str]]
) -> List[str]:
    if not magasin_ids:
        return []
    unique_ids = list(dict.fromkeys(magasin_ids))
    rows = (
        db.query(Magasin.id)
        .filter(Magasin.boutique_id == boutique_id, Magasin.id.in_(unique_ids))
        .all()
    )
    found_ids = {r[0] for r in rows}
    if len(found_ids) != len(unique_ids):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Un ou plusieurs magasins sélectionnés n'appartiennent pas à cette boutique",
        )
    return unique_ids


def _format_user_row(user: User, membership: BoutiqueUserMembership) -> Dict[str, Any]:
    effective_role = normalize_tenant_role(membership.role or user.role)
    return {
        "id": user.id,
        "username": user.username,
        "email": user.email,
        "full_name": user.full_name,
        "role": effective_role,
        "permissions": get_permissions_for_role(effective_role, user.permissions),
        "has_pin": bool(user.pin_hash),
        "is_active": bool(user.is_active and membership.is_active),
        "assigned_magasin_ids": membership.assigned_magasin_ids or [],
    }


def _get_boutique_member_or_404(
    db: Session, boutique_id: str, user_id: str
) -> Tuple[User, BoutiqueUserMembership]:
    row = (
        db.query(User, BoutiqueUserMembership)
        .join(BoutiqueUserMembership, BoutiqueUserMembership.user_id == User.id)
        .filter(
            BoutiqueUserMembership.boutique_id == boutique_id,
            BoutiqueUserMembership.user_id == user_id,
            User.role != "superadmin",
        )
        .first()
    )
    if not row:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable")
    return row


def list_boutique_users(db: Session, ctx: TenantContext) -> List[Dict[str, Any]]:
    rows = (
        db.query(User, BoutiqueUserMembership)
        .join(BoutiqueUserMembership, BoutiqueUserMembership.user_id == User.id)
        .filter(
            BoutiqueUserMembership.boutique_id == ctx.boutique.id,
            User.role != "superadmin",
        )
        .order_by(User.created_at.desc())
        .all()
    )
    return [_format_user_row(user, membership) for user, membership in rows]


def create_boutique_user(db: Session, ctx: TenantContext, data: UserCreate) -> Dict[str, Any]:
    username = data.username.strip()
    if db.query(User).filter(User.username == username).first():
        raise HTTPException(status_code=400, detail="Ce nom d'utilisateur est déjà utilisé")

    email = data.email.strip().lower() if data.email else None
    if email and db.query(User).filter(User.email == email).first():
        raise HTTPException(status_code=400, detail="Cet email est déjà utilisé")

    valid_magasins = _validate_assigned_magasins(
        db, ctx.boutique.id, data.assigned_magasin_ids
    )
    perms = get_permissions_for_role(data.role)

    new_user = User(
        username=username,
        email=email,
        full_name=data.full_name,
        hashed_password=get_password_hash(data.password),
        pin_hash=hash_pin(data.pin) if data.pin else None,
        role=data.role,
        permissions=perms,
        is_active=True,
    )
    db.add(new_user)
    db.flush()

    membership = BoutiqueUserMembership(
        boutique_id=ctx.boutique.id,
        user_id=new_user.id,
        role=data.role,
        assigned_magasin_ids=valid_magasins,
        is_active=True,
    )
    db.add(membership)
    db.add(AuditLog(
        boutique_id=ctx.boutique.id,
        user_id=ctx.user.id,
        user_name=ctx.user.full_name or ctx.user.username,
        action="USER_CREATE",
        entity_type="user",
        entity_id=new_user.id,
        details={"username": new_user.username, "role": data.role},
    ))
    db.commit()
    db.refresh(new_user)
    db.refresh(membership)
    return _format_user_row(new_user, membership)


def update_boutique_user(
    db: Session, ctx: TenantContext, user_id: str, data: UserUpdate
) -> Dict[str, Any]:
    user, membership = _get_boutique_member_or_404(db, ctx.boutique.id, user_id)

    if user.id == ctx.user.id and data.is_active is False:
        raise HTTPException(status_code=400, detail="Vous ne pouvez pas désactiver votre propre compte")

    is_target_owner = user.id == ctx.boutique.owner_user_id
    if is_target_owner:
        if ctx.user.id != ctx.boutique.owner_user_id or data.role is not None or data.is_active is False:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Action interdite sur le compte propriétaire de la boutique",
            )

    if data.full_name is not None:
        user.full_name = data.full_name
    if data.email is not None:
        clean_email = data.email.strip().lower() or None
        if clean_email:
            dup = db.query(User).filter(User.email == clean_email, User.id != user.id).first()
            if dup:
                raise HTTPException(status_code=400, detail="Cet email est déjà utilisé")
        user.email = clean_email
    if data.password is not None:
        user.hashed_password = get_password_hash(data.password)
    if data.pin is not None:
        user.pin_hash = hash_pin(data.pin)
        user.pin_failed_attempts = 0
        user.pin_locked_until = None
    if data.role is not None:
        user.role = data.role
        user.permissions = get_permissions_for_role(data.role)
        membership.role = data.role
    if data.assigned_magasin_ids is not None:
        membership.assigned_magasin_ids = _validate_assigned_magasins(
            db, ctx.boutique.id, data.assigned_magasin_ids
        )
    if data.is_active is not None:
        user.is_active = data.is_active
        membership.is_active = data.is_active
        if not data.is_active:
            revoke_all_user_tokens(db, user.id)

    db.add(AuditLog(
        boutique_id=ctx.boutique.id,
        user_id=ctx.user.id,
        user_name=ctx.user.full_name or ctx.user.username,
        action="USER_UPDATE",
        entity_type="user",
        entity_id=user.id,
        details={"target_username": user.username, "role": membership.role, "is_active": membership.is_active},
    ))
    db.commit()
    db.refresh(user)
    db.refresh(membership)
    return _format_user_row(user, membership)


def delete_boutique_user(db: Session, ctx: TenantContext, user_id: str) -> Dict[str, str]:
    user, membership = _get_boutique_member_or_404(db, ctx.boutique.id, user_id)

    if user.id == ctx.user.id:
        raise HTTPException(status_code=400, detail="Vous ne pouvez pas supprimer votre propre compte")
    if user.id == ctx.boutique.owner_user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Impossible de supprimer le propriétaire de la boutique",
        )

    username = user.username
    revoke_all_user_tokens(db, user.id)
    db.delete(membership)
    db.flush()

    remaining = db.query(BoutiqueUserMembership).filter(BoutiqueUserMembership.user_id == user.id).count()
    if remaining == 0:
        db.delete(user)

    db.add(AuditLog(
        boutique_id=ctx.boutique.id,
        user_id=ctx.user.id,
        user_name=ctx.user.full_name or ctx.user.username,
        action="USER_DELETE",
        entity_type="user",
        entity_id=user_id,
        details={"deleted_username": username},
    ))
    db.commit()
    return {"status": "success", "message": "Utilisateur supprimé"}
