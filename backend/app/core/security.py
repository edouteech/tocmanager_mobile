from datetime import datetime, timedelta, timezone
from typing import Optional, Any, Union, Dict
import hashlib
import bcrypt
from jose import jwt
from app.core.config import settings

def verify_password(plain_password: str, hashed_password: str) -> bool:
    try:
        return bcrypt.checkpw(plain_password.encode("utf-8"), hashed_password.encode("utf-8"))
    except Exception:
        return False

def get_password_hash(password: str) -> str:
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(password.encode("utf-8"), salt).decode("utf-8")

def hash_pin(pin: str, salt: Optional[str] = None) -> str:
    """Hashes a numeric PIN (e.g. 4 or 6 digits) with a secure salt."""
    if not salt:
        salt = settings.SECRET_KEY[:16]
    combined = f"{pin}:{salt}:{settings.SECRET_KEY}"
    return hashlib.sha256(combined.encode("utf-8")).hexdigest()

def verify_pin(plain_pin: str, hashed_pin: str, salt: Optional[str] = None) -> bool:
    return hash_pin(plain_pin, salt) == hashed_pin

def create_access_token(
    subject: Optional[Union[str, Any]] = None,
    expires_delta: Optional[timedelta] = None,
    data: Optional[Dict[str, Any]] = None
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

def create_refresh_token(subject: Union[str, Any], expires_delta: Optional[timedelta] = None) -> str:
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=settings.REFRESH_TOKEN_EXPIRE_MINUTES)
    to_encode = {"exp": expire, "sub": str(subject), "type": "refresh"}
    return jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
