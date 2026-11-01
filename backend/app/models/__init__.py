import uuid
from datetime import datetime, timezone
from sqlalchemy import (
    Column, String, Integer, Float, Boolean, Text, ForeignKey, DateTime, JSON
)
from sqlalchemy.orm import relationship
from app.core.database import Base

def generate_uuid() -> str:
    return str(uuid.uuid4())

def utc_now() -> datetime:
    return datetime.now(timezone.utc)

class User(Base):
    __tablename__ = "users"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    username = Column(String(100), unique=True, index=True, nullable=False)
    email = Column(String(255), unique=True, index=True, nullable=True)
    full_name = Column(String(255), nullable=True)
    hashed_password = Column(String(255), nullable=False)
    pin_hash = Column(String(255), nullable=True)
    role = Column(String(50), nullable=False, default="cashier")  # admin, manager, cashier
    permissions = Column(JSON, nullable=True)  # List of allowed permissions
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)

class Category(Base):
    __tablename__ = "categories"

    sync_id = Column(String(36), primary_key=True, default=generate_uuid)
    name = Column(String(150), nullable=False)
    description = Column(Text, nullable=True)
    color = Column(String(30), nullable=True)
    icon = Column(String(50), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)
    deleted_at = Column(DateTime(timezone=True), nullable=True)

    products = relationship("Product", back_populates="category")

class Product(Base):
    __tablename__ = "products"

    sync_id = Column(String(36), primary_key=True, default=generate_uuid)
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
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)
    deleted_at = Column(DateTime(timezone=True), nullable=True)

    category = relationship("Category", back_populates="products")

class Client(Base):
    __tablename__ = "clients"

    sync_id = Column(String(36), primary_key=True, default=generate_uuid)
    name = Column(String(255), nullable=False)
    phone = Column(String(50), nullable=True)
    email = Column(String(255), nullable=True)
    address = Column(Text, nullable=True)
    balance = Column(Float, nullable=False, default=0.0)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)
    deleted_at = Column(DateTime(timezone=True), nullable=True)

class Supplier(Base):
    __tablename__ = "suppliers"

    sync_id = Column(String(36), primary_key=True, default=generate_uuid)
    name = Column(String(255), nullable=False)
    contact_person = Column(String(255), nullable=True)
    phone = Column(String(50), nullable=True)
    email = Column(String(255), nullable=True)
    address = Column(Text, nullable=True)
    balance = Column(Float, nullable=False, default=0.0)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)
    deleted_at = Column(DateTime(timezone=True), nullable=True)

class Vente(Base):
    __tablename__ = "ventes"

    sync_id = Column(String(36), primary_key=True, default=generate_uuid)
    ticket_number = Column(String(100), index=True, nullable=False)
    client_sync_id = Column(String(36), ForeignKey("clients.sync_id"), nullable=True)
    client_name = Column(String(255), nullable=True)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=True)
    total_amount = Column(Float, nullable=False, default=0.0)
    paid_amount = Column(Float, nullable=False, default=0.0)
    discount_amount = Column(Float, nullable=False, default=0.0)
    payment_method = Column(String(50), nullable=False, default="Espèces")
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)
    deleted_at = Column(DateTime(timezone=True), nullable=True)

    items = relationship("VenteItem", back_populates="vente", cascade="all, delete-orphan")

class VenteItem(Base):
    __tablename__ = "vente_items"

    sync_id = Column(String(36), primary_key=True, default=generate_uuid)
    vente_sync_id = Column(String(36), ForeignKey("ventes.sync_id", ondelete="CASCADE"), nullable=False)
    product_sync_id = Column(String(36), nullable=True)
    product_name = Column(String(255), nullable=False)
    quantity = Column(Float, nullable=False, default=1.0)
    unit_price = Column(Float, nullable=False, default=0.0)
    cost_price = Column(Float, nullable=False, default=0.0)
    total = Column(Float, nullable=False, default=0.0)

    vente = relationship("Vente", back_populates="items")

class Approvisionnement(Base):
    __tablename__ = "approvisionnements"

    sync_id = Column(String(36), primary_key=True, default=generate_uuid)
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
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)
    deleted_at = Column(DateTime(timezone=True), nullable=True)

class Decaissement(Base):
    __tablename__ = "decaissements"

    sync_id = Column(String(36), primary_key=True, default=generate_uuid)
    title = Column(String(255), nullable=False)
    amount = Column(Float, nullable=False, default=0.0)
    category = Column(String(100), nullable=True)
    beneficiary = Column(String(255), nullable=True)
    payment_method = Column(String(50), default="Espèces")
    date = Column(DateTime(timezone=True), default=utc_now)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)
    deleted_at = Column(DateTime(timezone=True), nullable=True)

class SyncEvent(Base):
    __tablename__ = "sync_events"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(String(36), nullable=True)
    device_id = Column(String(100), nullable=True)
    action = Column(String(50), nullable=False)  # PUSH, PULL
    entity_type = Column(String(50), nullable=False)
    entity_uuid = Column(String(36), nullable=False)
    synced_at = Column(DateTime(timezone=True), default=utc_now)
