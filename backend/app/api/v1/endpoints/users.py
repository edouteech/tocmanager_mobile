from typing import Any, List, Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.api import deps
from app.core.database import get_db
from app.core.security import get_password_hash, hash_pin
from app.models import User
from app.schemas.auth import UserBrief
from pydantic import BaseModel, EmailStr

router = APIRouter()

class UserCreate(BaseModel):
    username: str
    password: str
    email: Optional[str] = None
    full_name: Optional[str] = None
    role: str = "cashier"  # admin, manager, cashier
    pin: Optional[str] = None

class UserUpdate(BaseModel):
    email: Optional[str] = None
    full_name: Optional[str] = None
    role: Optional[str] = None
    is_active: Optional[bool] = None
    password: Optional[str] = None
    pin: Optional[str] = None

@router.get("", response_model=List[UserBrief])
def list_users(
    db: Session = Depends(get_db),
    current_user: User = Depends(deps.require_role(["admin", "manager"])),
) -> Any:
    users = db.query(User).all()
    result = []
    for u in users:
        perms = u.permissions or []
        if u.role == "admin":
            perms = ["*"]
        elif u.role == "manager":
            perms = ["sales.*", "products.*", "categories.*", "clients.*", "suppliers.*", "reports.view"]
        elif u.role == "cashier":
            perms = ["sales.create", "sales.view_own", "products.view_price", "clients.create", "clients.view"]
        result.append(UserBrief(
            id=u.id,
            username=u.username,
            email=u.email,
            full_name=u.full_name,
            role=u.role,
            permissions=perms,
            has_pin=bool(u.pin_hash),
        ))
    return result

@router.post("", response_model=UserBrief)
def create_user(
    data: UserCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(deps.require_role(["admin"])),
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
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    perms = ["*"] if user.role == "admin" else (["sales.*", "products.*", "reports.view"] if user.role == "manager" else ["sales.create"])
    return UserBrief(
        id=user.id,
        username=user.username,
        email=user.email,
        full_name=user.full_name,
        role=user.role,
        permissions=perms,
        has_pin=bool(user.pin_hash),
    )
