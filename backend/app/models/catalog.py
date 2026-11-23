from sqlalchemy import Column, String, Float, Boolean, Text, ForeignKey, DateTime, Index
from sqlalchemy.orm import relationship
from app.core.database import Base
from app.models.common import generate_uuid, utc_now


class Category(Base):
    __tablename__ = "categories"
    __table_args__ = (
        Index("ix_categories_boutique_deleted_created", "boutique_id", "deleted_at", "created_at"),
    )

    sync_id = Column(String(36), primary_key=True, default=generate_uuid)
    boutique_id = Column(String(36), ForeignKey("boutiques.id"), nullable=False, index=True)
    name = Column(String(150), nullable=False)
    description = Column(Text, nullable=True)
    color = Column(String(30), nullable=True)
    icon = Column(String(50), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now, index=True)
    deleted_at = Column(DateTime(timezone=True), nullable=True)

    products = relationship("Product", back_populates="category")


class Product(Base):
    __tablename__ = "products"
    __table_args__ = (
        Index("ix_products_boutique_deleted_created", "boutique_id", "deleted_at", "created_at"),
    )

    sync_id = Column(String(36), primary_key=True, default=generate_uuid)
    boutique_id = Column(String(36), ForeignKey("boutiques.id"), nullable=False, index=True)
    name = Column(String(255), nullable=False)
    category_sync_id = Column(String(36), ForeignKey("categories.sync_id"), nullable=True)
    price = Column(Float, nullable=False, default=0.0)
    cost_price = Column(Float, nullable=False, default=0.0)
    average_cost_price = Column(Float, nullable=True, default=0.0)
    stock = Column(Float, nullable=False, default=0.0)
    min_stock = Column(Float, nullable=False, default=5.0)
    barcode = Column(String(100), nullable=True)
    unit = Column(String(50), nullable=True, default="pièce")
    image_path = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now, index=True)
    deleted_at = Column(DateTime(timezone=True), nullable=True)

    category = relationship("Category", back_populates="products")


class Client(Base):
    __tablename__ = "clients"
    __table_args__ = (
        Index("ix_clients_boutique_deleted_created", "boutique_id", "deleted_at", "created_at"),
    )

    sync_id = Column(String(36), primary_key=True, default=generate_uuid)
    boutique_id = Column(String(36), ForeignKey("boutiques.id"), nullable=False, index=True)
    name = Column(String(255), nullable=False)
    phone = Column(String(50), nullable=True)
    email = Column(String(255), nullable=True)
    address = Column(Text, nullable=True)
    balance = Column(Float, nullable=False, default=0.0)
    notes = Column(Text, nullable=True)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=True)
    user_name = Column(String(255), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now, index=True)
    deleted_at = Column(DateTime(timezone=True), nullable=True)


class Supplier(Base):
    __tablename__ = "suppliers"
    __table_args__ = (
        Index("ix_suppliers_boutique_deleted_created", "boutique_id", "deleted_at", "created_at"),
    )

    sync_id = Column(String(36), primary_key=True, default=generate_uuid)
    boutique_id = Column(String(36), ForeignKey("boutiques.id"), nullable=False, index=True)
    name = Column(String(255), nullable=False)
    contact_person = Column(String(255), nullable=True)
    phone = Column(String(50), nullable=True)
    email = Column(String(255), nullable=True)
    address = Column(Text, nullable=True)
    balance = Column(Float, nullable=False, default=0.0)
    notes = Column(Text, nullable=True)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=True)
    user_name = Column(String(255), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now, index=True)
    deleted_at = Column(DateTime(timezone=True), nullable=True)
