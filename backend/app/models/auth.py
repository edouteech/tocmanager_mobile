import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, ForeignKey, DateTime
from app.core.database import Base


def _generate_uuid() -> str:
    return str(uuid.uuid4())


def _utc_now() -> datetime:
    return datetime.now(timezone.utc)


class RefreshToken(Base):
    """Jeton de rafraîchissement persistant permettant révocation et détection de réutilisation."""

    __tablename__ = "refresh_tokens"

    id = Column(String(36), primary_key=True, default=_generate_uuid)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    token_hash = Column(String(64), unique=True, nullable=False, index=True)
    family_id = Column(String(36), nullable=False, index=True)
    device_id = Column(String(100), nullable=True)
    expires_at = Column(DateTime(timezone=True), nullable=False)
    revoked_at = Column(DateTime(timezone=True), nullable=True)
    replaced_by_id = Column(String(36), nullable=True)
    created_at = Column(DateTime(timezone=True), default=_utc_now)
