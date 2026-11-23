from typing import Any, Callable, Dict, List, Optional, Tuple
from fastapi import Depends, Header, HTTPException, Request, status
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError
from sqlalchemy.orm import Session
from app.core.config import settings
from app.core.database import get_db
from app.core.permissions import normalize_tenant_role
from app.models import User
from app.services.tenant_context_service import TenantContext, resolve_tenant_context

oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"{settings.API_V1_STR}/auth/login/form")


def _decode_access_claims(token: str) -> Dict[str, Any]:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Identifiants d'authentification invalides ou expirés",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id: Optional[str] = payload.get("sub")
        token_type: Optional[str] = payload.get("type")
        if user_id is None or (token_type and token_type != "access"):
            raise credentials_exception
        return payload
    except JWTError:
        raise credentials_exception


def _resolve_user_from_token(
    db: Session,
    token: str,
    allow_onboarding: bool,
    request: Optional[Request] = None,
) -> Tuple[User, Dict[str, Any]]:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Identifiants d'authentification invalides ou expirés",
        headers={"WWW-Authenticate": "Bearer"},
    )
    payload = _decode_access_claims(token)
    user_id: str = str(payload["sub"])
    token_scope: Optional[str] = payload.get("scope")

    if not allow_onboarding and token_scope == "onboarding":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Veuillez finaliser la configuration de votre boutique",
        )

    if (
        request is not None
        and payload.get("read_only") is True
        and request.method.upper() not in ("GET", "HEAD", "OPTIONS")
        and not request.url.path.endswith("/auth/logout")
    ):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Mode support en lecture seule : toute modification est interdite.",
        )

    user = db.query(User).filter(User.id == user_id).first()
    if user is None:
        raise credentials_exception
    if not user.is_active:
        raise HTTPException(status_code=400, detail="Compte utilisateur inactif")
    return user, payload


def get_current_user(
    request: Request,
    db: Session = Depends(get_db),
    token: str = Depends(oauth2_scheme),
) -> User:
    user, _ = _resolve_user_from_token(db, token, allow_onboarding=False, request=request)
    return user


def get_onboarding_user(
    request: Request,
    db: Session = Depends(get_db),
    token: str = Depends(oauth2_scheme),
) -> User:
    user, _ = _resolve_user_from_token(db, token, allow_onboarding=True, request=request)
    return user


def get_tenant_context(
    request: Request,
    x_boutique_id: Optional[str] = Header(None, alias="X-Boutique-Id"),
    x_magasin_id: Optional[str] = Header(None, alias="X-Magasin-Id"),
    db: Session = Depends(get_db),
    token: str = Depends(oauth2_scheme),
) -> TenantContext:
    current_user, payload = _resolve_user_from_token(
        db, token, allow_onboarding=False, request=request
    )
    effective_boutique_id = (
        str(payload["impersonated_boutique_id"])
        if payload.get("read_only") is True and payload.get("impersonated_boutique_id")
        else x_boutique_id
    )
    return resolve_tenant_context(
        db=db,
        current_user=current_user,
        x_boutique_id=effective_boutique_id,
        x_magasin_id=x_magasin_id,
    )


def require_tenant_role(allowed_roles: List[str]) -> Callable:
    def role_checker(ctx: TenantContext = Depends(get_tenant_context)) -> TenantContext:
        effective_role = normalize_tenant_role(ctx.role)
        if effective_role not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Permissions insuffisantes pour cette opération",
            )
        return ctx

    return role_checker


def require_role(allowed_roles: List[str]) -> Callable:
    def role_checker(current_user: User = Depends(get_current_user)) -> User:
        if current_user.role == "superadmin":
            if "superadmin" in allowed_roles:
                return current_user
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Permissions insuffisantes pour cette opération",
            )
        effective_role = normalize_tenant_role(current_user.role)
        normalized_allowed = {
            r if r == "superadmin" else normalize_tenant_role(r) for r in allowed_roles
        }
        if effective_role not in normalized_allowed:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Permissions insuffisantes pour cette opération",
            )
        return current_user

    return role_checker
