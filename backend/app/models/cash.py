from sqlalchemy import Column, DateTime, Float, ForeignKey, Index, String, Text
from app.core.database import Base
from app.models.common import generate_uuid, utc_now


class CashRegisterSession(Base):
    __tablename__ = "cash_register_sessions"
    __table_args__ = (
        Index("ix_cash_sessions_btq_mag_status", "boutique_id", "magasin_id", "status"),
    )

    id = Column(String(36), primary_key=True, default=generate_uuid)
    boutique_id = Column(String(36), ForeignKey("boutiques.id", ondelete="CASCADE"), nullable=False, index=True)
    magasin_id = Column(String(36), ForeignKey("magasins.id"), nullable=False, index=True)
    opened_by_user_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    opened_by_name = Column(String(255), nullable=True)
    opened_at = Column(DateTime(timezone=True), default=utc_now, nullable=False)
    opening_balance = Column(Float, nullable=False, default=0.0)
    status = Column(String(20), nullable=False, default="open")
    expected_cash = Column(Float, nullable=True)
    expected_mobile_money = Column(Float, nullable=True)
    expected_card = Column(Float, nullable=True)
    declared_cash = Column(Float, nullable=True)
    discrepancy = Column(Float, nullable=True)
    closed_by_user_id = Column(String(36), ForeignKey("users.id"), nullable=True)
    closed_by_name = Column(String(255), nullable=True)
    closed_at = Column(DateTime(timezone=True), nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)


class ClientPayment(Base):
    __tablename__ = "client_payments"
    __table_args__ = (
        Index("ix_client_payments_btq_client_created", "boutique_id", "client_sync_id", "created_at"),
    )

    id = Column(String(36), primary_key=True, default=generate_uuid)
    boutique_id = Column(String(36), ForeignKey("boutiques.id", ondelete="CASCADE"), nullable=False, index=True)
    magasin_id = Column(String(36), ForeignKey("magasins.id"), nullable=True, index=True)
    client_sync_id = Column(String(36), ForeignKey("clients.sync_id", ondelete="CASCADE"), nullable=False, index=True)
    amount = Column(Float, nullable=False)
    payment_method = Column(String(50), nullable=False, default="Espèces")
    previous_balance = Column(Float, nullable=False)
    new_balance = Column(Float, nullable=False)
    notes = Column(Text, nullable=True)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=True)
    user_name = Column(String(255), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)


class SupplierPayment(Base):
    __tablename__ = "supplier_payments"
    __table_args__ = (
        Index("ix_supplier_payments_btq_sup_created", "boutique_id", "supplier_sync_id", "created_at"),
    )

    id = Column(String(36), primary_key=True, default=generate_uuid)
    boutique_id = Column(String(36), ForeignKey("boutiques.id", ondelete="CASCADE"), nullable=False, index=True)
    magasin_id = Column(String(36), ForeignKey("magasins.id"), nullable=True, index=True)
    supplier_sync_id = Column(String(36), ForeignKey("suppliers.sync_id", ondelete="CASCADE"), nullable=False, index=True)
    amount = Column(Float, nullable=False)
    payment_method = Column(String(50), nullable=False, default="Espèces")
    previous_balance = Column(Float, nullable=False)
    new_balance = Column(Float, nullable=False)
    notes = Column(Text, nullable=True)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=True)
    user_name = Column(String(255), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)
