from typing import Any, List, Optional
from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.orm import Session
from app.api import deps
from app.core.database import get_db
from app.core.security import get_password_hash, hash_pin
from app.models import User, Boutique, BoutiqueUserMembership, Magasin
from app.schemas.auth import UserBrief
from pydantic import BaseModel

router = APIRouter()

class UserCreate(BaseModel):
    username: str
    password: str
    email: Optional[str] = None
    full_name: Optional[str] = None
    role: str = "cashier"  # admin, merchant, manager, cashier
    pin: Optional[str] = None
    assigned_magasin_ids: Optional[List[str]] = None

class UserUpdate(BaseModel):
    email: Optional[str] = None
    full_name: Optional[str] = None
    role: Optional[str] = None
    is_active: Optional[bool] = None
    password: Optional[str] = None
    pin: Optional[str] = None
    assigned_magasin_ids: Optional[List[str]] = None

@router.get("", response_model=List[UserBrief])
def list_users(
    x_boutique_id: Optional[str] = Header(None, alias="X-Boutique-Id"),
    db: Session = Depends(get_db),
    current_user: User = Depends(deps.require_role(["superadmin", "admin", "merchant", "manager"])),
) -> Any:
    users = db.query(User).all()
    result = []
    for u in users:
        perms = u.permissions or []
        if u.role in ["superadmin", "admin", "merchant"]:
            perms = ["*"]
        elif u.role == "manager":
            perms = ["sales.*", "products.*", "categories.*", "clients.*", "suppliers.*", "reports.view"]
        elif u.role == "cashier":
            perms = ["sales.create", "sales.view_own", "products.view_price", "clients.create", "clients.view"]

        # Récupérer les magasins assignés pour la boutique
        assigned = []
        membership = db.query(BoutiqueUserMembership).filter(
            BoutiqueUserMembership.user_id == u.id
        )
        if x_boutique_id:
            membership = membership.filter(BoutiqueUserMembership.boutique_id == x_boutique_id)
        m = membership.first()
        if m and m.assigned_magasin_ids:
            assigned = m.assigned_magasin_ids

        result.append(UserBrief(
            id=u.id,
            username=u.username,
            email=u.email,
            full_name=u.full_name,
            role=u.role,
            permissions=perms,
            has_pin=bool(u.pin_hash),
            is_active=bool(u.is_active) if u.is_active is not None else True,
            assigned_magasin_ids=assigned,
        ))
    return result

@router.post("", response_model=UserBrief)
def create_user(
    data: UserCreate,
    x_boutique_id: Optional[str] = Header(None, alias="X-Boutique-Id"),
    db: Session = Depends(get_db),
    current_user: User = Depends(deps.require_role(["superadmin", "admin", "merchant"])),
) -> Any:
    if db.query(User).filter(User.username == data.username).first():
        raise HTTPException(status_code=400, detail="Ce nom d'utilisateur est déjà utilisé")
    if data.email and db.query(User).filter(User.email == data.email).first():
        raise HTTPException(status_code=400, detail="Cette adresse email est déjà utilisée")

    pin_hash = hash_pin(data.pin) if data.pin else None
    user = User(
        username=data.username,
        email=data.email,
        full_name=data.full_name,
        role=data.role,
        hashed_password=get_password_hash(data.password),
        pin_hash=pin_hash,
        is_active=True,
    )
    db.add(user)
    db.flush()

    if not x_boutique_id:
        first_b = db.query(Boutique).first()
        x_boutique_id = first_b.id if first_b else None

    if x_boutique_id:
        membership = BoutiqueUserMembership(
            boutique_id=x_boutique_id,
            user_id=user.id,
            role=data.role,
            assigned_magasin_ids=data.assigned_magasin_ids or [],
            is_active=True,
        )
        db.add(membership)

    db.commit()
    db.refresh(user)

    perms = ["*"] if user.role in ["superadmin", "admin", "merchant"] else (["sales.*", "products.*", "reports.view"] if user.role == "manager" else ["sales.create"])
    return UserBrief(
        id=user.id,
        username=user.username,
        email=user.email,
        full_name=user.full_name,
        role=user.role,
        permissions=perms,
        has_pin=bool(user.pin_hash),
        is_active=bool(user.is_active),
        assigned_magasin_ids=data.assigned_magasin_ids or [],
    )

@router.put("/{user_id}", response_model=UserBrief)
def update_user(
    user_id: str,
    data: UserUpdate,
    x_boutique_id: Optional[str] = Header(None, alias="X-Boutique-Id"),
    db: Session = Depends(get_db),
    current_user: User = Depends(deps.require_role(["superadmin", "admin", "merchant"])),
) -> Any:
    target = db.query(User).filter(User.id == user_id).first()
    if not target:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable")

    if data.email and data.email != target.email:
        existing_email = db.query(User).filter(User.email == data.email, User.id != user_id).first()
        if existing_email:
            raise HTTPException(status_code=400, detail="Cette adresse email est déjà utilisée")
        target.email = data.email

    if data.full_name is not None:
        target.full_name = data.full_name

    if data.role is not None:
        if target.id == current_user.id and data.role not in ["superadmin", "admin", "merchant"]:
            raise HTTPException(status_code=400, detail="Vous ne pouvez pas révoquer votre propre rôle d'administrateur.")
        target.role = data.role

    if data.is_active is not None:
        if target.id == current_user.id and not data.is_active:
            raise HTTPException(status_code=400, detail="Vous ne pouvez pas désactiver votre propre compte administrateur.")
        target.is_active = data.is_active

    if data.password:
        target.hashed_password = get_password_hash(data.password)

    if data.pin is not None:
        target.pin_hash = hash_pin(data.pin) if data.pin.strip() else None

    # Mettre à jour l'affectation des magasins
    if data.assigned_magasin_ids is not None:
        if not x_boutique_id:
            first_b = db.query(Boutique).first()
            x_boutique_id = first_b.id if first_b else None
        if x_boutique_id:
            m = db.query(BoutiqueUserMembership).filter(
                BoutiqueUserMembership.user_id == target.id,
                BoutiqueUserMembership.boutique_id == x_boutique_id
            ).first()
            if m:
                m.assigned_magasin_ids = data.assigned_magasin_ids
            else:
                db.add(BoutiqueUserMembership(
                    boutique_id=x_boutique_id,
                    user_id=target.id,
                    role=target.role,
                    assigned_magasin_ids=data.assigned_magasin_ids,
                    is_active=True
                ))

    db.commit()
    db.refresh(target)

    perms = ["*"] if target.role in ["superadmin", "admin", "merchant"] else (["sales.*", "products.*", "reports.view"] if target.role == "manager" else ["sales.create"])
    assigned = []
    if x_boutique_id:
        m = db.query(BoutiqueUserMembership).filter(
            BoutiqueUserMembership.user_id == target.id,
            BoutiqueUserMembership.boutique_id == x_boutique_id
        ).first()
        if m and m.assigned_magasin_ids:
            assigned = m.assigned_magasin_ids

    return UserBrief(
        id=target.id,
        username=target.username,
        email=target.email,
        full_name=target.full_name,
        role=target.role,
        permissions=perms,
        has_pin=bool(target.pin_hash),
        is_active=bool(target.is_active),
        assigned_magasin_ids=assigned,
    )

@router.delete("/{user_id}")
def delete_user(
    user_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(deps.require_role(["superadmin", "admin", "merchant"])),
) -> Any:
    target = db.query(User).filter(User.id == user_id).first()
    if not target:
        raise HTTPException(status_code=404, detail="Utilisateur introuvable")

    if target.id == current_user.id:
        raise HTTPException(status_code=400, detail="Vous ne pouvez pas supprimer votre propre compte administrateur.")

    db.delete(target)
    db.commit()
    return {"status": "success", "message": "Utilisateur supprimé avec succès"}
