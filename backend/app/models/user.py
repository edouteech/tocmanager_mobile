from sqlalchemy import Column, String, Integer, Boolean, DateTime, JSON
from app.core.database import Base
from app.models.common import generate_uuid, utc_now


class User(Base):
    __tablename__ = "users"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    username = Column(String(100), unique=True, index=True, nullable=False)
    email = Column(String(255), unique=True, index=True, nullable=True)
    full_name = Column(String(255), nullable=True)
    hashed_password = Column(String(255), nullable=False)
    pin_hash = Column(String(255), nullable=True)
    pin_failed_attempts = Column(Integer, nullable=False, default=0)
    pin_locked_until = Column(DateTime(timezone=True), nullable=True)
    email_verified_at = Column(DateTime(timezone=True), nullable=True)
    totp_secret = Column(String(64), nullable=True)
    totp_enabled = Column(Boolean, nullable=False, default=False)
    role = Column(String(50), nullable=False, default="cashier")  # superadmin, owner, merchant, store_admin, manager, cashier
    permissions = Column(JSON, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)
