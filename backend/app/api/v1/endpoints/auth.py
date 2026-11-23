from typing import Any
from fastapi import APIRouter, Depends, HTTPException, Request, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from app.api import deps
from app.core.database import get_db
from app.core.permissions import get_permissions_for_role
from app.core.rate_limit import limiter
from app.core.security import verify_password, get_password_hash, hash_pin
from app.models import User, AuditLog
from app.schemas.auth import (
    Token,
    LoginRequest,
    RefreshRequest,
    LogoutRequest,
    PinVerifyRequest,
    SetPinRequest,
    UserBrief,
)
from app.services.auth_service import (
    issue_token_pair,
    rotate_refresh_token,
    logout_user_sessions,
    revoke_all_user_tokens,
    verify_user_pin_attempt,
)
from app.services.tenant_context_service import resolve_audit_boutique_id

router = APIRouter()


def _user_to_brief(user: User) -> UserBrief:
    return UserBrief(
        id=user.id,
        username=user.username,
        email=user.email,
        full_name=user.full_name,
        role=user.role,
        permissions=get_permissions_for_role(user.role, user.permissions),
        has_pin=bool(user.pin_hash),
    )


def _execute_login(login_data: LoginRequest, db: Session) -> Token:
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

    access_token, refresh_tok, _ = issue_token_pair(
        db, user, device_id=login_data.device_id
    )
    db.add(AuditLog(
        boutique_id=resolve_audit_boutique_id(db, user),
        user_id=user.id,
        user_name=user.full_name or user.username,
        action="LOGIN",
        entity_type="auth",
        details={"username": user.username, "role": user.role},
    ))
    db.commit()

    return Token(
        access_token=access_token,
        refresh_token=refresh_tok,
        token_type="bearer",
        user=_user_to_brief(user),
    )


@router.post("/login", response_model=Token)
@limiter.limit("10/minute")
def login(
    request: Request,
    login_data: LoginRequest,
    db: Session = Depends(get_db),
) -> Any:
    """Authentification standard email ou username + mot de passe."""
    _ = request
    return _execute_login(login_data, db)


@router.post("/login/form", response_model=Token)
@limiter.limit("10/minute")
def login_form(
    request: Request,
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db),
) -> Any:
    """OAuth2 compatible endpoint pour Swagger UI."""
    _ = request
    return _execute_login(
        LoginRequest(username_or_email=form_data.username, password=form_data.password),
        db,
    )


@router.post("/refresh", response_model=Token)
@limiter.limit("20/minute")
def refresh_token(
    request: Request,
    refresh_data: RefreshRequest,
    db: Session = Depends(get_db),
) -> Any:
    """Rafraîchissement du JWT expiré avec rotation et détection de réutilisation."""
    _ = request
    user, new_access, new_refresh = rotate_refresh_token(db, refresh_data.refresh_token)
    return Token(
        access_token=new_access,
        refresh_token=new_refresh,
        token_type="bearer",
        user=_user_to_brief(user),
    )


@router.post("/logout")
def logout(
    logout_data: LogoutRequest = LogoutRequest(),
    current_user: User = Depends(deps.get_current_user),
    db: Session = Depends(get_db),
) -> Any:
    """Révoque le refresh token courant ou toutes les sessions de l'utilisateur."""
    revoked = logout_user_sessions(
        db,
        current_user,
        raw_refresh_token=logout_data.refresh_token,
        all_devices=logout_data.all_devices,
    )
    return {"status": "success", "revoked_count": revoked}


@router.post("/verify-pin", response_model=UserBrief)
@limiter.limit("5/minute")
def verify_user_pin(
    request: Request,
    pin_data: PinVerifyRequest,
    current_user: User = Depends(deps.get_current_user),
    db: Session = Depends(get_db),
) -> Any:
    """Vérification du code PIN pour déverrouiller la session courante."""
    _ = request
    verified_user = verify_user_pin_attempt(db, current_user, pin_data.pin)
    return _user_to_brief(verified_user)


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
    current_user.pin_failed_attempts = 0
    current_user.pin_locked_until = None
    revoke_all_user_tokens(db, current_user.id)

    db.add(AuditLog(
        boutique_id=resolve_audit_boutique_id(db, current_user),
        user_id=current_user.id,
        user_name=current_user.full_name or current_user.username,
        action="PIN_SET",
        entity_type="auth",
        details={"pin_length": len(pin_data.pin)},
    ))
    db.commit()
    db.refresh(current_user)
    return _user_to_brief(current_user)


@router.get("/me", response_model=UserBrief)
def get_current_user_profile(
    current_user: User = Depends(deps.get_onboarding_user),
) -> Any:
    """Récupère les informations du profil utilisateur connecté."""
    return _user_to_brief(current_user)
