from datetime import datetime, timedelta, timezone
import hashlib
import secrets
from typing import Optional, Tuple

from fastapi import HTTPException, status
from jose import JWTError, jwt
import pyotp
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import get_password_hash, verify_password
from app.models import AuditLog, AuthActionToken, User
from app.services.auth_service import issue_token_pair, revoke_all_user_tokens
from app.services.notification_service import send_email_verification, send_password_reset
from app.services.tenant_context_service import resolve_audit_boutique_id

EMAIL_VERIFY_TTL_MINUTES = 60 * 24
PASSWORD_RESET_TTL_MINUTES = 30
MIN_PASSWORD_LENGTH = 8


def _ensure_utc(dt: Optional[datetime]) -> Optional[datetime]:
    if dt is None:
        return None
    return dt if dt.tzinfo is not None else dt.replace(tzinfo=timezone.utc)


def _hash_action_token(raw_token: str) -> str:
    return hashlib.sha256(raw_token.encode("utf-8")).hexdigest()


def _issue_action_token(db: Session, user: User, purpose: str, ttl_minutes: int) -> str:
    now = datetime.now(timezone.utc)
    db.query(AuthActionToken).filter(
        AuthActionToken.user_id == user.id,
        AuthActionToken.purpose == purpose,
        AuthActionToken.used_at.is_(None),
    ).update({"used_at": now}, synchronize_session=False)

    raw_token = secrets.token_urlsafe(32)
    db.add(AuthActionToken(
        user_id=user.id,
        purpose=purpose,
        token_hash=_hash_action_token(raw_token),
        expires_at=now + timedelta(minutes=ttl_minutes),
        created_at=now,
    ))
    db.flush()
    return raw_token


def _consume_action_token(db: Session, raw_token: str, purpose: str) -> Tuple[AuthActionToken, User]:
    token_val = (raw_token or "").strip()
    if not token_val:
        raise HTTPException(status_code=400, detail="Jeton invalide ou manquant")

    record = db.query(AuthActionToken).filter(
        AuthActionToken.token_hash == _hash_action_token(token_val),
        AuthActionToken.purpose == purpose,
    ).first()
    if not record or record.used_at is not None:
        raise HTTPException(status_code=400, detail="Jeton invalide ou deja utilise")

    now = datetime.now(timezone.utc)
    exp = _ensure_utc(record.expires_at)
    if exp is None or exp <= now:
        raise HTTPException(status_code=400, detail="Jeton expire")

    user = db.query(User).filter(User.id == record.user_id, User.is_active == True).first()
    if not user:
        raise HTTPException(status_code=400, detail="Compte associe introuvable ou inactif")

    record.used_at = now
    return record, user


def request_email_verification(db: Session, user: User) -> str:
    if not user.email:
        raise HTTPException(status_code=400, detail="Aucune adresse email configuree sur ce compte")
    raw_token = _issue_action_token(db, user, "email_verify", EMAIL_VERIFY_TTL_MINUTES)
    db.commit()
    return send_email_verification(user.email, user.full_name or user.username, raw_token)


def verify_email_with_token(db: Session, raw_token: str) -> User:
    _, user = _consume_action_token(db, raw_token, "email_verify")
    user.email_verified_at = datetime.now(timezone.utc)
    db.add(AuditLog(
        boutique_id=resolve_audit_boutique_id(db, user),
        user_id=user.id,
        user_name=user.full_name or user.username,
        action="EMAIL_VERIFIED",
        entity_type="auth",
    ))
    db.commit()
    db.refresh(user)
    return user


def request_password_reset(db: Session, raw_email: str) -> Optional[str]:
    normalized = (raw_email or "").strip().lower()
    if not normalized:
        return None
    user = db.query(User).filter(User.email == normalized, User.is_active == True).first()
    if not user or not user.email:
        return None
    raw_token = _issue_action_token(db, user, "password_reset", PASSWORD_RESET_TTL_MINUTES)
    db.commit()
    send_password_reset(user.email, user.full_name or user.username, raw_token)
    return raw_token


def reset_password_with_token(db: Session, raw_token: str, new_password: str) -> User:
    if len(new_password or "") < MIN_PASSWORD_LENGTH:
        raise HTTPException(
            status_code=400,
            detail=f"Le mot de passe doit comporter au moins {MIN_PASSWORD_LENGTH} caracteres",
        )
    _, user = _consume_action_token(db, raw_token, "password_reset")
    user.hashed_password = get_password_hash(new_password)
    revoke_all_user_tokens(db, user.id)
    db.add(AuditLog(
        boutique_id=resolve_audit_boutique_id(db, user),
        user_id=user.id,
        user_name=user.full_name or user.username,
        action="PASSWORD_RESET",
        entity_type="auth",
    ))
    db.commit()
    db.refresh(user)
    return user


def setup_superadmin_2fa(db: Session, user: User) -> Tuple[str, str]:
    secret = pyotp.random_base32()
    user.totp_secret = secret
    user.totp_enabled = False
    db.commit()
    label = user.email or user.username
    uri = pyotp.TOTP(secret).provisioning_uri(name=label, issuer_name="TocManager Admin")
    return secret, uri


def confirm_superadmin_2fa(db: Session, user: User, code: str) -> User:
    if not user.totp_secret:
        raise HTTPException(status_code=400, detail="Initialisez d'abord la configuration 2FA")
    if not pyotp.TOTP(user.totp_secret).verify((code or "").strip(), valid_window=1):
        raise HTTPException(status_code=400, detail="Code TOTP invalide")
    user.totp_enabled = True
    db.add(AuditLog(
        boutique_id=None,
        user_id=user.id,
        user_name=user.full_name or user.username,
        action="2FA_ENABLED",
        entity_type="auth",
    ))
    db.commit()
    db.refresh(user)
    return user


def disable_superadmin_2fa(db: Session, user: User, password: str, code: str) -> User:
    if not verify_password(password, user.hashed_password):
        raise HTTPException(status_code=400, detail="Mot de passe incorrect")
    if user.totp_enabled and user.totp_secret:
        if not pyotp.TOTP(user.totp_secret).verify((code or "").strip(), valid_window=1):
            raise HTTPException(status_code=400, detail="Code TOTP invalide")
    user.totp_enabled = False
    user.totp_secret = None
    db.commit()
    db.refresh(user)
    return user


def verify_superadmin_2fa_challenge(
    db: Session,
    challenge_token: str,
    code: str,
    device_id: Optional[str] = None,
) -> Tuple[User, str, str]:
    try:
        payload = jwt.decode(challenge_token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        user_id = payload.get("sub")
        if not user_id or payload.get("type") != "2fa_challenge":
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Jeton 2FA invalide")
    except JWTError:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Jeton 2FA invalide ou expire")

    user = db.query(User).filter(User.id == str(user_id), User.is_active == True).first()
    if not user or user.role != "superadmin" or not user.totp_enabled or not user.totp_secret:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Configuration 2FA invalide")

    if not pyotp.TOTP(user.totp_secret).verify((code or "").strip(), valid_window=1):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Code TOTP invalide")

    access_token, refresh_tok, _ = issue_token_pair(db, user, device_id=device_id)
    db.add(AuditLog(
        boutique_id=None,
        user_id=user.id,
        user_name=user.full_name or user.username,
        action="LOGIN_2FA",
        entity_type="auth",
        details={"username": user.username},
    ))
    db.commit()
    return user, access_token, refresh_tok
