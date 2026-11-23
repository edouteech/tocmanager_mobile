from sqlalchemy import Column, DateTime, Float, ForeignKey, Index, String, Text, UniqueConstraint
from sqlalchemy.orm import relationship

from app.core.database import Base
from app.models.common import generate_uuid, utc_now


class StockTransfer(Base):
    __tablename__ = "stock_transfers"
    __table_args__ = (
        UniqueConstraint("boutique_id", "reference", name="uq_stock_transfers_boutique_ref"),
        Index("ix_stock_transfers_btq_status_created", "boutique_id", "status", "created_at"),
    )

    id = Column(String(36), primary_key=True, default=generate_uuid)
    boutique_id = Column(String(36), ForeignKey("boutiques.id", ondelete="CASCADE"), nullable=False, index=True)
    reference = Column(String(50), nullable=False)
    from_magasin_id = Column(String(36), ForeignKey("magasins.id"), nullable=False, index=True)
    to_magasin_id = Column(String(36), ForeignKey("magasins.id"), nullable=False, index=True)
    status = Column(String(30), nullable=False, default="in_transit")
    notes = Column(Text, nullable=True)
    created_by_user_id = Column(String(36), nullable=True)
    created_by_name = Column(String(255), nullable=True)
    shipped_at = Column(DateTime(timezone=True), nullable=True)
    received_at = Column(DateTime(timezone=True), nullable=True)
    received_by_user_id = Column(String(36), nullable=True)
    received_by_name = Column(String(255), nullable=True)
    canceled_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)

    items = relationship("StockTransferItem", back_populates="transfer", cascade="all, delete-orphan")


class StockTransferItem(Base):
    __tablename__ = "stock_transfer_items"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    transfer_id = Column(String(36), ForeignKey("stock_transfers.id", ondelete="CASCADE"), nullable=False, index=True)
    product_sync_id = Column(String(36), ForeignKey("products.sync_id"), nullable=False, index=True)
    product_name = Column(String(255), nullable=False)
    quantity_sent = Column(Float, nullable=False)
    quantity_received = Column(Float, nullable=True)
    unit_cost = Column(Float, nullable=False, default=0.0)

    transfer = relationship("StockTransfer", back_populates="items")


class StockMovement(Base):
    __tablename__ = "stock_movements"
    __table_args__ = (
        Index("ix_stock_movements_btq_mag_prod_created", "boutique_id", "magasin_id", "product_sync_id", "created_at"),
    )

    id = Column(String(36), primary_key=True, default=generate_uuid)
    boutique_id = Column(String(36), ForeignKey("boutiques.id", ondelete="CASCADE"), nullable=False, index=True)
    magasin_id = Column(String(36), ForeignKey("magasins.id"), nullable=False, index=True)
    product_sync_id = Column(String(36), ForeignKey("products.sync_id"), nullable=False, index=True)
    movement_type = Column(String(30), nullable=False)
    quantity_delta = Column(Float, nullable=False)
    balance_before = Column(Float, nullable=False)
    balance_after = Column(Float, nullable=False)
    reference_type = Column(String(30), nullable=True)
    reference_id = Column(String(36), nullable=True)
    reason = Column(Text, nullable=True)
    user_id = Column(String(36), nullable=True)
    user_name = Column(String(255), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now, index=True)
