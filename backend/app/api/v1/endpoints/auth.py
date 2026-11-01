from typing import Any
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from app.api import deps
from app.core.database import get_db
from app.core.security import (
    verify_password,
    get_password_hash,
    hash_pin,
    verify_pin,
    create_access_token,
    create_refresh_token,
)
from app.core.config import settings
from app.models import User
from app.schemas.auth import (
    Token,
    LoginRequest,
    RefreshRequest,
    PinVerifyRequest,
    SetPinRequest,
    UserBrief,
)
from jose import jwt, JWTError

router = APIRouter()

def _user_to_brief(user: User) -> UserBrief:
    perms = user.permissions or []
    if user.role == "admin":
        perms = ["*"]
    elif user.role == "manager":
        perms = ["sales.*", "products.*", "categories.*", "clients.*", "suppliers.*", "reports.view"]
    elif user.role == "cashier":
        perms = ["sales.create", "sales.view_own", "products.view_price", "clients.create", "clients.view"]

    return UserBrief(
        id=user.id,
        username=user.username,
        email=user.email,
        full_name=user.full_name,
        role=user.role,
        permissions=perms,
        has_pin=bool(user.pin_hash),
    )

@router.post("/login", response_model=Token)
def login(
    login_data: LoginRequest,
    db: Session = Depends(get_db)
) -> Any:
    """Authentification standard email ou username + mot de passe."""
    user = (
        db.query(User)
        .filter(
            (User.username == login_data.username_or_email)
            | (User.email == login_data.username_or_email)
        )
        .first()
    )
    if not user or not verify_password(login_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Nom d'utilisateur ou mot de passe incorrect",
        )
    if not user.is_active:
        raise HTTPException(status_code=400, detail="Compte inactif")

    access_token = create_access_token(user.id)
    refresh_token = create_refresh_token(user.id)
    return Token(
        access_token=access_token,
        refresh_token=refresh_token,
        token_type="bearer",
        user=_user_to_brief(user),
    )

@router.post("/login/form", response_model=Token)
def login_form(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
) -> Any:
    """OAuth2 compatible endpoint pour Swagger UI."""
    return login(
        LoginRequest(username_or_email=form_data.username, password=form_data.password),
        db=db,
    )

@router.post("/refresh", response_model=Token)
def refresh_token(
    refresh_data: RefreshRequest,
    db: Session = Depends(get_db)
) -> Any:
    """Rafraîchissement du JWT expiré."""
    try:
        payload = jwt.decode(
            refresh_data.refresh_token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
        )
        user_id: str = payload.get("sub")
        token_type: str = payload.get("type")
        if not user_id or token_type != "refresh":
            raise HTTPException(status_code=401, detail="Refresh token invalide")
    except JWTError:
        raise HTTPException(status_code=401, detail="Refresh token invalide ou expiré")

    user = db.query(User).filter(User.id == user_id).first()
    if not user or not user.is_active:
        raise HTTPException(status_code=401, detail="Utilisateur inexistant ou inactif")

    new_access = create_access_token(user.id)
    new_refresh = create_refresh_token(user.id)
    return Token(
        access_token=new_access,
        refresh_token=new_refresh,
        token_type="bearer",
        user=_user_to_brief(user),
    )

@router.post("/verify-pin", response_model=UserBrief)
def verify_user_pin(
    pin_data: PinVerifyRequest,
    current_user: User = Depends(deps.get_current_user),
) -> Any:
    """Vérification du code PIN pour déverrouiller la session courante."""
    if not current_user.pin_hash:
        raise HTTPException(status_code=400, detail="Aucun code PIN n'a encore été configuré")
    if not verify_pin(pin_data.pin, current_user.pin_hash):
        raise HTTPException(status_code=400, detail="Code PIN erroné")
    return _user_to_brief(current_user)

@router.post("/set-pin", response_model=UserBrief)
def set_user_pin(
    pin_data: SetPinRequest,
    current_user: User = Depends(deps.get_current_user),
    db: Session = Depends(get_db),
) -> Any:
    """Définition ou modification du code PIN sécurisé."""
    if not verify_password(pin_data.current_password, current_user.hashed_password):
        raise HTTPException(status_code=400, detail="Mot de passe actuel incorrect")
    if len(pin_data.pin) not in (4, 6) or not pin_data.pin.isdigit():
        raise HTTPException(status_code=400, detail="Le code PIN doit comporter 4 ou 6 chiffres")

    current_user.pin_hash = hash_pin(pin_data.pin)
    db.commit()
    db.refresh(current_user)
    return _user_to_brief(current_user)

@router.get("/me", response_model=UserBrief)
def get_current_user_profile(
    current_user: User = Depends(deps.get_current_user)
) -> Any:
    """Récupère les informations du profil utilisateur connecté."""
    return _user_to_brief(current_user)
