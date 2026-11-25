from sqlalchemy import Column, String, Float, Text, ForeignKey, DateTime, UniqueConstraint, Index
from sqlalchemy.orm import relationship
from app.core.database import Base
from app.models.common import generate_uuid, utc_now


class Vente(Base):
    __tablename__ = "ventes"
    __table_args__ = (
        UniqueConstraint("boutique_id", "ticket_number", name="uq_ventes_boutique_ticket"),
        Index("ix_ventes_boutique_deleted_created", "boutique_id", "deleted_at", "created_at"),
        Index("ix_ventes_boutique_magasin_created", "boutique_id", "magasin_id", "created_at"),
    )

    sync_id = Column(String(36), primary_key=True, default=generate_uuid)
    boutique_id = Column(String(36), ForeignKey("boutiques.id"), nullable=False, index=True)
    magasin_id = Column(String(36), ForeignKey("magasins.id"), nullable=True, index=True)
    ticket_number = Column(String(100), index=True, nullable=False)
    client_sync_id = Column(String(36), ForeignKey("clients.sync_id"), nullable=True)
    client_name = Column(String(255), nullable=True)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=True)
    user_name = Column(String(255), nullable=True)
    total_amount = Column(Float, nullable=False, default=0.0)
    paid_amount = Column(Float, nullable=False, default=0.0)
    discount_amount = Column(Float, nullable=False, default=0.0)
    payment_method = Column(String(50), nullable=False, default="Espèces")
    status = Column(String(30), nullable=False, default="completed")
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now, index=True)
    deleted_at = Column(DateTime(timezone=True), nullable=True)

    items = relationship("VenteItem", back_populates="vente", cascade="all, delete-orphan")


class VenteItem(Base):
    __tablename__ = "vente_items"

    sync_id = Column(String(36), primary_key=True, default=generate_uuid)
    vente_sync_id = Column(
        String(36), ForeignKey("ventes.sync_id", ondelete="CASCADE"), nullable=False, index=True
    )
    product_sync_id = Column(String(36), nullable=True)
    product_name = Column(String(255), nullable=False)
    quantity = Column(Float, nullable=False, default=1.0)
    unit_price = Column(Float, nullable=False, default=0.0)
    cost_price = Column(Float, nullable=False, default=0.0)
    total = Column(Float, nullable=False, default=0.0)
    refunded_quantity = Column(Float, nullable=False, default=0.0)

    vente = relationship("Vente", back_populates="items")


class Approvisionnement(Base):
    __tablename__ = "approvisionnements"
    __table_args__ = (
        Index("ix_approvisionnements_boutique_deleted_created", "boutique_id", "deleted_at", "created_at"),
        Index("ix_approvisionnements_boutique_magasin_created", "boutique_id", "magasin_id", "created_at"),
    )

    sync_id = Column(String(36), primary_key=True, default=generate_uuid)
    boutique_id = Column(String(36), ForeignKey("boutiques.id"), nullable=False, index=True)
    magasin_id = Column(String(36), ForeignKey("magasins.id"), nullable=True, index=True)
    supplier_sync_id = Column(String(36), ForeignKey("suppliers.sync_id"), nullable=True)
    supplier_name = Column(String(255), nullable=True)
    product_sync_id = Column(String(36), nullable=True)
    product_name = Column(String(255), nullable=False)
    quantity = Column(Float, nullable=False, default=0.0)
    unit_cost = Column(Float, nullable=False, default=0.0)
    total_cost = Column(Float, nullable=False, default=0.0)
    payment_status = Column(String(50), default="Payé")
    date = Column(DateTime(timezone=True), default=utc_now)
    notes = Column(Text, nullable=True)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=True)
    user_name = Column(String(255), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now, index=True)
    deleted_at = Column(DateTime(timezone=True), nullable=True)


class Decaissement(Base):
    __tablename__ = "decaissements"
    __table_args__ = (
        Index("ix_decaissements_boutique_deleted_created", "boutique_id", "deleted_at", "created_at"),
        Index("ix_decaissements_boutique_magasin_created", "boutique_id", "magasin_id", "created_at"),
    )

    sync_id = Column(String(36), primary_key=True, default=generate_uuid)
    boutique_id = Column(String(36), ForeignKey("boutiques.id"), nullable=False, index=True)
    magasin_id = Column(String(36), ForeignKey("magasins.id"), nullable=True, index=True)
    title = Column(String(255), nullable=False)
    amount = Column(Float, nullable=False, default=0.0)
    category = Column(String(100), nullable=True)
    beneficiary = Column(String(255), nullable=True)
    payment_method = Column(String(50), default="Espèces")
    date = Column(DateTime(timezone=True), default=utc_now)
    notes = Column(Text, nullable=True)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=True)
    user_name = Column(String(255), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now, index=True)
    deleted_at = Column(DateTime(timezone=True), nullable=True)
