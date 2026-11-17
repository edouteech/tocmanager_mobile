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

class SaasPlan(Base):
    __tablename__ = "saas_plans"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    name = Column(String(100), nullable=False) # Gratuit, Pro, Entreprise
    code = Column(String(50), unique=True, nullable=False, index=True) # free, pro, enterprise
    description = Column(Text, nullable=True)
    price_monthly = Column(Float, nullable=False, default=0.0)
    price_yearly = Column(Float, nullable=False, default=0.0)
    currency = Column(String(10), default="XOF")
    trial_period_days = Column(Integer, default=0) # ex: 14 jours pour Pro, 0 pour Gratuit
    is_active = Column(Boolean, default=True)
    badge = Column(String(50), nullable=True) # POPULAIRE, ESSAI 14J, RECOMMANDÉ
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)

    features = relationship("SaasPlanFeature", back_populates="plan", cascade="all, delete-orphan")
    subscriptions = relationship("SaasSubscription", back_populates="plan")

class SaasPlanFeature(Base):
    __tablename__ = "saas_plan_features"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    plan_id = Column(String(36), ForeignKey("saas_plans.id", ondelete="CASCADE"), nullable=False)
    feature_code = Column(String(100), nullable=False, index=True)
    feature_name = Column(String(200), nullable=False)
    value_type = Column(String(20), default="boolean") # boolean, limit_number, text
    boolean_value = Column(Boolean, default=False)
    int_limit = Column(Integer, default=0) # ex: 1 magasin, 100 produits (-1 = illimité)
    created_at = Column(DateTime(timezone=True), default=utc_now)

    plan = relationship("SaasPlan", back_populates="features")

class Boutique(Base):
    """
    Représente l'entité commerciale / l'entreprise cliente du SaaS.
    Chaque boutique a ses propres magasins, produits, clients et ventes.
    """
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
    schema_name = Column(String(63), unique=True, nullable=True) # tenant_btq_<uuid4>
    owner_user_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)

    subscriptions = relationship("SaasSubscription", back_populates="boutique", cascade="all, delete-orphan")
    memberships = relationship("BoutiqueUserMembership", back_populates="boutique", cascade="all, delete-orphan")

class BoutiqueUserMembership(Base):
    """
    Associe un utilisateur à une boutique, avec un rôle spécifique
    et une liste de magasins assignés.
    """
    __tablename__ = "boutique_user_memberships"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    boutique_id = Column(String(36), ForeignKey("boutiques.id", ondelete="CASCADE"), nullable=False)
    user_id = Column(String(36), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    role = Column(String(50), default="cashier") # owner, manager, cashier
    assigned_magasin_ids = Column(JSON, default=list) # Liste des IDs de magasins autorisés [] = tous si owner
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)

    boutique = relationship("Boutique", back_populates="memberships")

class SaasSubscription(Base):
    __tablename__ = "saas_subscriptions"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    boutique_id = Column(String(36), ForeignKey("boutiques.id", ondelete="CASCADE"), nullable=False)
    plan_id = Column(String(36), ForeignKey("saas_plans.id"), nullable=False)
    status = Column(String(50), default="active") # trialing, active, past_due, canceled
    billing_cycle = Column(String(20), default="monthly") # monthly, yearly
    trial_starts_at = Column(DateTime(timezone=True), nullable=True)
    trial_ends_at = Column(DateTime(timezone=True), nullable=True)
    current_period_start = Column(DateTime(timezone=True), default=utc_now)
    current_period_end = Column(DateTime(timezone=True), nullable=True)
    canceled_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)

    boutique = relationship("Boutique", back_populates="subscriptions")
    plan = relationship("SaasPlan", back_populates="subscriptions")

class Magasin(Base):
    """
    Point de vente physique ou entrepôt d'une boutique.
    """
    __tablename__ = "magasins"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    boutique_id = Column(String(36), ForeignKey("boutiques.id", ondelete="CASCADE"), nullable=True)
    name = Column(String(255), nullable=False)
    code = Column(String(50), nullable=True)
    address = Column(Text, nullable=True)
    phone = Column(String(50), nullable=True)
    is_warehouse = Column(Boolean, default=False) # Si c'est un dépôt/réserve ou un point de vente
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)

class StockMagasin(Base):
    """
    Stock distinct par magasin physique pour un produit donné.
    """
    __tablename__ = "stocks_magasin"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    magasin_id = Column(String(36), ForeignKey("magasins.id", ondelete="CASCADE"), nullable=False, index=True)
    product_sync_id = Column(String(36), ForeignKey("products.sync_id", ondelete="CASCADE"), nullable=False, index=True)
    quantity = Column(Float, nullable=False, default=0.0)
    min_stock = Column(Float, nullable=False, default=5.0)
    cost_price = Column(Float, nullable=False, default=0.0)
    average_cost_price = Column(Float, nullable=True, default=0.0)
    last_updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)

class ProductMagasinAvailability(Base):
    """
    Disponibilité et prix spécifique d'un produit par magasin.
    """
    __tablename__ = "product_magasin_availability"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    magasin_id = Column(String(36), ForeignKey("magasins.id", ondelete="CASCADE"), nullable=False, index=True)
    product_sync_id = Column(String(36), ForeignKey("products.sync_id", ondelete="CASCADE"), nullable=False, index=True)
    is_available = Column(Boolean, default=True)
    custom_price = Column(Float, nullable=True) # None si prix standard d'entreprise utilisé
    created_at = Column(DateTime(timezone=True), default=utc_now)

class PlatformAuditLog(Base):
    """
    Journal d'audit de la plateforme SaaS (actions Super-Admin et système).
    """
    __tablename__ = "platform_audit_logs"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    admin_user_id = Column(String(36), nullable=True)
    admin_username = Column(String(255), nullable=True)
    action = Column(String(100), nullable=False) # PLAN_CREATE, PLAN_UPDATE, BOUTIQUE_SUSPEND, TRIAL_EXTEND
    target_entity = Column(String(50), nullable=True) # plan, boutique, subscription
    target_id = Column(String(100), nullable=True)
    details = Column(JSON, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)
