from datetime import datetime, timedelta, timezone
from typing import Optional, Tuple
import uuid
from fastapi import HTTPException, status
from jose import JWTError, jwt
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import (
    create_access_token,
    create_refresh_token,
    generate_jti,
    hash_jti,
    hash_pin,
    is_legacy_pin_hash,
    verify_pin,
)
from app.models import AuditLog, RefreshToken, User
from app.services.tenant_context_service import resolve_audit_boutique_id

MAX_PIN_ATTEMPTS = 5
PIN_LOCK_MINUTES = 15


def _ensure_utc(dt: Optional[datetime]) -> Optional[datetime]:
    if dt is None:
        return None
    return dt if dt.tzinfo is not None else dt.replace(tzinfo=timezone.utc)


def revoke_token_family(db: Session, family_id: str, now: Optional[datetime] = None) -> int:
    """Révoque tous les jetons actifs d'une famille suite à une réutilisation suspecte."""
    ts = now or datetime.now(timezone.utc)
    updated = (
        db.query(RefreshToken)
        .filter(RefreshToken.family_id == family_id, RefreshToken.revoked_at.is_(None))
        .update({"revoked_at": ts}, synchronize_session=False)
    )
    return int(updated)


def revoke_all_user_tokens(db: Session, user_id: str, now: Optional[datetime] = None) -> int:
    """Révoque l'ensemble des sessions actives d'un utilisateur."""
    ts = now or datetime.now(timezone.utc)
    updated = (
        db.query(RefreshToken)
        .filter(RefreshToken.user_id == user_id, RefreshToken.revoked_at.is_(None))
        .update({"revoked_at": ts}, synchronize_session=False)
    )
    return int(updated)


def issue_token_pair(
    db: Session,
    user: User,
    device_id: Optional[str] = None,
    family_id: Optional[str] = None,
) -> Tuple[str, str, RefreshToken]:
    """Émet une paire JWT access + refresh persistant en base."""
    now = datetime.now(timezone.utc)
    jti = generate_jti()
    fid = family_id or str(uuid.uuid4())
    expires_at = now + timedelta(minutes=settings.REFRESH_TOKEN_EXPIRE_MINUTES)

    rt_record = RefreshToken(
        user_id=user.id,
        token_hash=hash_jti(jti),
        family_id=fid,
        device_id=device_id,
        expires_at=expires_at,
        created_at=now,
    )
    db.add(rt_record)
    db.flush()

    access_token = create_access_token(user.id)
    refresh_token = create_refresh_token(user.id, jti=jti)
    return access_token, refresh_token, rt_record


def rotate_refresh_token(db: Session, raw_refresh_token: str) -> Tuple[User, str, str]:
    """Vérifie le refresh token, détecte toute réutilisation et effectue une rotation atomique."""
    try:
        payload = jwt.decode(
            raw_refresh_token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
        )
        user_id: Optional[str] = payload.get("sub")
        token_type: Optional[str] = payload.get("type")
        jti: Optional[str] = payload.get("jti")
        if not user_id or token_type != "refresh" or not jti:
            raise HTTPException(status_code=401, detail="Refresh token invalide")
    except JWTError:
        raise HTTPException(status_code=401, detail="Refresh token invalide ou expiré")

    token_digest = hash_jti(jti)
    stored = db.query(RefreshToken).filter(RefreshToken.token_hash == token_digest).first()
    if not stored:
        raise HTTPException(status_code=401, detail="Session introuvable ou révoquée")

    now = datetime.now(timezone.utc)
    if stored.revoked_at is not None:
        # Compromission possible : révoquer toute la famille de tokens associée.
        revoke_token_family(db, stored.family_id, now=now)
        db.commit()
        raise HTTPException(status_code=401, detail="Refresh token déjà utilisé ou révoqué")

    expires_at = _ensure_utc(stored.expires_at)
    if expires_at is None or expires_at <= now:
        stored.revoked_at = now
        db.commit()
        raise HTTPException(status_code=401, detail="Refresh token expiré")

    user = db.query(User).filter(User.id == user_id).first()
    if not user or not user.is_active:
        revoke_token_family(db, stored.family_id, now=now)
        db.commit()
        raise HTTPException(status_code=401, detail="Utilisateur inexistant ou inactif")

    new_access, new_refresh, new_record = issue_token_pair(
        db, user, device_id=stored.device_id, family_id=stored.family_id
    )
    stored.revoked_at = now
    stored.replaced_by_id = new_record.id

    db.add(AuditLog(
        boutique_id=resolve_audit_boutique_id(db, user),
        user_id=user.id,
        user_name=user.full_name or user.username,
        action="TOKEN_REFRESH",
        entity_type="auth",
        details={"type": "sliding_rotation", "family_id": stored.family_id},
    ))
    db.commit()
    return user, new_access, new_refresh


def logout_user_sessions(
    db: Session,
    user: User,
    raw_refresh_token: Optional[str] = None,
    all_devices: bool = False,
) -> int:
    """Révoque la session courante ou toutes les sessions de l'utilisateur."""
    now = datetime.now(timezone.utc)
    revoked = 0

    if all_devices:
        revoked = revoke_all_user_tokens(db, user.id, now=now)
    elif raw_refresh_token:
        try:
            payload = jwt.decode(
                raw_refresh_token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
            )
            jti = payload.get("jti")
            if jti:
                stored = (
                    db.query(RefreshToken)
                    .filter(
                        RefreshToken.token_hash == hash_jti(jti),
                        RefreshToken.user_id == user.id,
                        RefreshToken.revoked_at.is_(None),
                    )
                    .first()
                )
                if stored:
                    stored.revoked_at = now
                    revoked = 1
        except JWTError:
            pass

    db.add(AuditLog(
        boutique_id=resolve_audit_boutique_id(db, user),
        user_id=user.id,
        user_name=user.full_name or user.username,
        action="LOGOUT",
        entity_type="auth",
        details={"all_devices": all_devices, "revoked_count": revoked},
    ))
    db.commit()
    return revoked


def verify_user_pin_attempt(db: Session, user: User, plain_pin: str) -> User:
    """Vérifie le PIN avec verrouillage après 5 échecs et migration SHA-256 -> bcrypt."""
    if not user.pin_hash:
        raise HTTPException(status_code=400, detail="Aucun code PIN n'a encore été configuré")

    now = datetime.now(timezone.utc)
    locked_until = _ensure_utc(user.pin_locked_until)
    if locked_until and locked_until > now:
        raise HTTPException(
            status_code=status.HTTP_423_LOCKED,
            detail="Trop de tentatives PIN erronées. Réessayez plus tard.",
        )

    if locked_until and locked_until <= now:
        user.pin_failed_attempts = 0
        user.pin_locked_until = None

    if not verify_pin(plain_pin, user.pin_hash):
        attempts = (user.pin_failed_attempts or 0) + 1
        user.pin_failed_attempts = attempts
        if attempts >= MAX_PIN_ATTEMPTS:
            user.pin_locked_until = now + timedelta(minutes=PIN_LOCK_MINUTES)
            db.commit()
            raise HTTPException(
                status_code=status.HTTP_423_LOCKED,
                detail="Code PIN verrouillé après 5 tentatives erronées.",
            )
        db.commit()
        raise HTTPException(status_code=400, detail="Code PIN erroné")

    user.pin_failed_attempts = 0
    user.pin_locked_until = None
    if is_legacy_pin_hash(user.pin_hash):
        user.pin_hash = hash_pin(plain_pin)

    db.add(AuditLog(
        boutique_id=resolve_audit_boutique_id(db, user),
        user_id=user.id,
        user_name=user.full_name or user.username,
        action="PIN_VERIFY",
        entity_type="auth",
        details={"result": "success"},
    ))
    db.commit()
    db.refresh(user)
    return user
