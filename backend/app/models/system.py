from sqlalchemy import Column, String, Integer, Text, ForeignKey, DateTime, JSON, UniqueConstraint, Index
from app.core.database import Base
from app.models.common import generate_uuid, utc_now


class AuditLog(Base):
    __tablename__ = "audit_logs"
    __table_args__ = (
        Index("ix_audit_logs_boutique_created", "boutique_id", "created_at"),
    )

    id = Column(String(36), primary_key=True, default=generate_uuid)
    boutique_id = Column(String(36), ForeignKey("boutiques.id"), nullable=True, index=True)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=True)
    user_name = Column(String(255), nullable=True)
    action = Column(String(100), nullable=False)
    entity_type = Column(String(50), nullable=True)
    entity_id = Column(String(100), nullable=True)
    details = Column(JSON, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)


class SyncEvent(Base):
    __tablename__ = "sync_events"
    __table_args__ = (
        Index("ix_sync_events_boutique_magasin_synced", "boutique_id", "magasin_id", "synced_at"),
    )

    id = Column(Integer, primary_key=True, autoincrement=True)
    boutique_id = Column(String(36), nullable=True, index=True)
    magasin_id = Column(String(36), nullable=True, index=True)
    user_id = Column(String(36), nullable=True)
    device_id = Column(String(100), nullable=True)
    action = Column(String(50), nullable=False)
    entity_type = Column(String(50), nullable=False)
    entity_uuid = Column(String(36), nullable=False)
    synced_at = Column(DateTime(timezone=True), default=utc_now)


class StoreSetting(Base):
    __tablename__ = "store_settings"
    __table_args__ = (
        UniqueConstraint("boutique_id", "key", name="uq_store_settings_boutique_key"),
    )

    id = Column(String(36), primary_key=True, default=generate_uuid)
    boutique_id = Column(String(36), ForeignKey("boutiques.id", ondelete="CASCADE"), nullable=False, index=True)
    key = Column(String(100), nullable=False, index=True)
    value = Column(Text, nullable=True)
    description = Column(String(255), nullable=True)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)
