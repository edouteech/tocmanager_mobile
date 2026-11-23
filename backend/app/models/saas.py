from sqlalchemy import (
    Column, String, Integer, Float, Boolean, Text, ForeignKey, DateTime, JSON, UniqueConstraint, Index
)
from sqlalchemy.orm import relationship
from app.core.database import Base
from app.models.common import generate_uuid, utc_now


class SaasPlan(Base):
    __tablename__ = "saas_plans"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    name = Column(String(100), nullable=False)
    code = Column(String(50), unique=True, nullable=False, index=True)
    description = Column(Text, nullable=True)
    price_monthly = Column(Float, nullable=False, default=0.0)
    price_yearly = Column(Float, nullable=False, default=0.0)
    currency = Column(String(10), default="XOF")
    trial_period_days = Column(Integer, default=0)
    is_active = Column(Boolean, default=True)
    badge = Column(String(50), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)

    features = relationship("SaasPlanFeature", back_populates="plan", cascade="all, delete-orphan")
    subscriptions = relationship("SaasSubscription", back_populates="plan")


class SaasPlanFeature(Base):
    __tablename__ = "saas_plan_features"
    __table_args__ = (
        UniqueConstraint("plan_id", "feature_code", name="uq_plan_feature_code"),
    )

    id = Column(String(36), primary_key=True, default=generate_uuid)
    plan_id = Column(String(36), ForeignKey("saas_plans.id", ondelete="CASCADE"), nullable=False)
    feature_code = Column(String(100), nullable=False, index=True)
    feature_name = Column(String(200), nullable=False)
    category = Column(String(50), nullable=False, default="modules", index=True)
    description = Column(Text, nullable=True)
    display_order = Column(Integer, nullable=False, default=0)
    show_on_pricing = Column(Boolean, nullable=False, default=True)
    value_type = Column(String(20), default="boolean")
    boolean_value = Column(Boolean, default=False)
    int_limit = Column(Integer, default=0)
    created_at = Column(DateTime(timezone=True), default=utc_now)

    plan = relationship("SaasPlan", back_populates="features")


class Boutique(Base):
    """Commercial tenant entity owning magasins, products, clients, and sales."""

    __tablename__ = "boutiques"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    slug = Column(String(100), unique=True, index=True, nullable=False)
    name = Column(String(255), nullable=False)
    company_name = Column(String(255), nullable=True)
    currency = Column(String(10), default="XOF")
    country = Column(String(100), default="Sénégal")
    phone = Column(String(50), nullable=True)
    email = Column(String(255), nullable=True)
    address = Column(Text, nullable=True)
    logo_url = Column(Text, nullable=True)
    schema_name = Column(String(63), unique=True, nullable=True)
    owner_user_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    has_used_trial = Column(Boolean, nullable=False, default=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)

    subscriptions = relationship("SaasSubscription", back_populates="boutique", cascade="all, delete-orphan")
    memberships = relationship("BoutiqueUserMembership", back_populates="boutique", cascade="all, delete-orphan")


class BoutiqueUserMembership(Base):
    """Links a user to a boutique with a tenant role and allowed magasin IDs."""

    __tablename__ = "boutique_user_memberships"
    __table_args__ = (
        UniqueConstraint("boutique_id", "user_id", name="uq_membership_boutique_user"),
    )

    id = Column(String(36), primary_key=True, default=generate_uuid)
    boutique_id = Column(String(36), ForeignKey("boutiques.id", ondelete="CASCADE"), nullable=False)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    role = Column(String(50), default="cashier")
    assigned_magasin_ids = Column(JSON, default=list)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)

    boutique = relationship("Boutique", back_populates="memberships")


class SaasSubscription(Base):
    __tablename__ = "saas_subscriptions"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    boutique_id = Column(String(36), ForeignKey("boutiques.id", ondelete="CASCADE"), nullable=False)
    plan_id = Column(String(36), ForeignKey("saas_plans.id"), nullable=False)
    status = Column(String(50), default="active")
    billing_cycle = Column(String(20), default="monthly")
    trial_starts_at = Column(DateTime(timezone=True), nullable=True)
    trial_ends_at = Column(DateTime(timezone=True), nullable=True)
    has_used_trial = Column(Boolean, nullable=False, default=False)
    current_period_start = Column(DateTime(timezone=True), default=utc_now)
    current_period_end = Column(DateTime(timezone=True), nullable=True)
    canceled_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)

    boutique = relationship("Boutique", back_populates="subscriptions")
    plan = relationship("SaasPlan", back_populates="subscriptions")


class Magasin(Base):
    """Physical point of sale or warehouse belonging to a boutique."""

    __tablename__ = "magasins"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    boutique_id = Column(String(36), ForeignKey("boutiques.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(255), nullable=False)
    code = Column(String(50), nullable=True)
    address = Column(Text, nullable=True)
    phone = Column(String(50), nullable=True)
    is_warehouse = Column(Boolean, default=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)


class StockMagasin(Base):
    """Distinct inventory stock per magasin for a given product."""

    __tablename__ = "stocks_magasin"
    __table_args__ = (
        UniqueConstraint("magasin_id", "product_sync_id", name="uq_stocks_magasin_mag_prod"),
        Index("ix_stocks_magasin_boutique_magasin", "boutique_id", "magasin_id"),
    )

    id = Column(String(36), primary_key=True, default=generate_uuid)
    boutique_id = Column(String(36), ForeignKey("boutiques.id", ondelete="CASCADE"), nullable=False, index=True)
    magasin_id = Column(String(36), ForeignKey("magasins.id", ondelete="CASCADE"), nullable=False, index=True)
    product_sync_id = Column(String(36), ForeignKey("products.sync_id", ondelete="CASCADE"), nullable=False, index=True)
    quantity = Column(Float, nullable=False, default=0.0)
    min_stock = Column(Float, nullable=False, default=5.0)
    cost_price = Column(Float, nullable=False, default=0.0)
    average_cost_price = Column(Float, nullable=True, default=0.0)
    last_updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)


class ProductMagasinAvailability(Base):
    """Product availability and optional price override per magasin."""

    __tablename__ = "product_magasin_availability"
    __table_args__ = (
        UniqueConstraint("magasin_id", "product_sync_id", name="uq_prod_mag_avail_mag_prod"),
    )

    id = Column(String(36), primary_key=True, default=generate_uuid)
    boutique_id = Column(String(36), ForeignKey("boutiques.id", ondelete="CASCADE"), nullable=False, index=True)
    magasin_id = Column(String(36), ForeignKey("magasins.id", ondelete="CASCADE"), nullable=False, index=True)
    product_sync_id = Column(String(36), ForeignKey("products.sync_id", ondelete="CASCADE"), nullable=False, index=True)
    is_available = Column(Boolean, default=True)
    custom_price = Column(Float, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)


class PlatformAuditLog(Base):
    """SaaS platform-level audit journal for superadmin actions."""

    __tablename__ = "platform_audit_logs"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    admin_user_id = Column(String(36), nullable=True)
    admin_username = Column(String(255), nullable=True)
    action = Column(String(100), nullable=False)
    target_entity = Column(String(50), nullable=True)
    target_id = Column(String(100), nullable=True)
    details = Column(JSON, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)
