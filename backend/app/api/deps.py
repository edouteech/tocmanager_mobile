from typing import List, Callable, Optional
from fastapi import Depends, Header, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError
from sqlalchemy.orm import Session
from app.core.config import settings
from app.core.database import get_db
from app.models import User
from app.services.tenant_context_service import TenantContext, resolve_tenant_context

oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"{settings.API_V1_STR}/auth/login/form")


def _resolve_user_from_token(
    db: Session, token: str, allow_onboarding: bool
) -> User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Identifiants d'authentification invalides ou expirés",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id: Optional[str] = payload.get("sub")
        token_type: Optional[str] = payload.get("type")
        token_scope: Optional[str] = payload.get("scope")
        if user_id is None or (token_type and token_type != "access"):
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    if not allow_onboarding and token_scope == "onboarding":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Veuillez finaliser la configuration de votre boutique",
        )

    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise credentials_exception
    if not user.is_active:
        raise HTTPException(status_code=400, detail="Compte utilisateur inactif")
    return user


def get_current_user(
    db: Session = Depends(get_db),
    token: str = Depends(oauth2_scheme),
) -> User:
    return _resolve_user_from_token(db, token, allow_onboarding=False)


def get_onboarding_user(
    db: Session = Depends(get_db),
    token: str = Depends(oauth2_scheme),
) -> User:
    return _resolve_user_from_token(db, token, allow_onboarding=True)


def get_tenant_context(
    x_boutique_id: Optional[str] = Header(None, alias="X-Boutique-Id"),
    x_magasin_id: Optional[str] = Header(None, alias="X-Magasin-Id"),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> TenantContext:
    return resolve_tenant_context(
        db=db,
        current_user=current_user,
        x_boutique_id=x_boutique_id,
        x_magasin_id=x_magasin_id,
    )


def require_role(allowed_roles: List[str]) -> Callable:
    def role_checker(current_user: User = Depends(get_current_user)) -> User:
        if current_user.role == "superadmin":
            return current_user
        if current_user.role == "merchant" and (
            "admin" in allowed_roles or "manager" in allowed_roles or "merchant" in allowed_roles
        ):
            return current_user
        if current_user.role not in allowed_roles and current_user.role != "admin":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Permissions insuffisantes pour cette opération",
            )
        return current_user

    return role_checker
