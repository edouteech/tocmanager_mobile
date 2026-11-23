from datetime import datetime, timedelta, timezone
from typing import Optional, Any, Union, Dict
import hashlib
import hmac
import secrets
import bcrypt
from jose import jwt
from app.core.config import settings

BCRYPT_PIN_ROUNDS = 12


def verify_password(plain_password: str, hashed_password: str) -> bool:
    try:
        return bcrypt.checkpw(plain_password.encode("utf-8"), hashed_password.encode("utf-8"))
    except Exception:
        return False


def get_password_hash(password: str) -> str:
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(password.encode("utf-8"), salt).decode("utf-8")


def legacy_pin_digest(pin: str, salt: Optional[str] = None) -> str:
    """Ancien format SHA-256 conservé uniquement pour migration transparente vers bcrypt."""
    effective_salt = salt or settings.SECRET_KEY[:16]
    combined = f"{pin}:{effective_salt}:{settings.SECRET_KEY}"
    return hashlib.sha256(combined.encode("utf-8")).hexdigest()


def is_legacy_pin_hash(hashed_pin: Optional[str]) -> bool:
    return bool(hashed_pin) and not hashed_pin.startswith("$2")


def hash_pin(pin: str, salt: Optional[str] = None) -> str:
    """Hache un code PIN numérique avec bcrypt et un sel aléatoire unique."""
    _ = salt  # Paramètre conservé pour compatibilité d'appel; bcrypt génère son propre sel.
    return bcrypt.hashpw(pin.encode("utf-8"), bcrypt.gensalt(rounds=BCRYPT_PIN_ROUNDS)).decode("utf-8")


def verify_pin(plain_pin: str, hashed_pin: str, salt: Optional[str] = None) -> bool:
    if not hashed_pin:
        return False
    if hashed_pin.startswith("$2"):
        try:
            return bcrypt.checkpw(plain_pin.encode("utf-8"), hashed_pin.encode("utf-8"))
        except Exception:
            return False
    expected = legacy_pin_digest(plain_pin, salt)
    return hmac.compare_digest(expected, hashed_pin)


def generate_jti() -> str:
    return secrets.token_urlsafe(32)


def hash_jti(jti: str) -> str:
    return hashlib.sha256(jti.encode("utf-8")).hexdigest()


def create_access_token(
    subject: Optional[Union[str, Any]] = None,
    expires_delta: Optional[timedelta] = None,
    data: Optional[Dict[str, Any]] = None,
) -> str:
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)

    to_encode: Dict[str, Any] = {"exp": expire, "type": "access"}
    if data:
        to_encode.update(data)
    if subject is not None:
        to_encode["sub"] = str(subject)
    elif "sub" in to_encode:
        to_encode["sub"] = str(to_encode["sub"])

    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)


def create_refresh_token(
    subject: Union[str, Any],
    expires_delta: Optional[timedelta] = None,
    jti: Optional[str] = None,
) -> str:
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=settings.REFRESH_TOKEN_EXPIRE_MINUTES)
    to_encode = {
        "exp": expire,
        "sub": str(subject),
        "type": "refresh",
        "jti": jti or generate_jti(),
    }
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
