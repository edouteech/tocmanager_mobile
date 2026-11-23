from sqlalchemy import Boolean, Column, DateTime, Float, ForeignKey, JSON, String, Text
from app.core.database import Base
from app.models.common import generate_uuid, utc_now


class PaymentProvider(Base):
    """Configurable SaaS payment aggregator (FeexPay REST v2 or future providers)."""

    __tablename__ = "payment_providers"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    code = Column(String(50), unique=True, nullable=False, index=True)
    name = Column(String(100), nullable=False)
    is_active = Column(Boolean, nullable=False, default=True)
    mode = Column(String(20), nullable=False, default="sandbox")
    countries = Column(JSON, default=list)
    networks = Column(JSON, default=list)
    config_encrypted = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)


class SaasPaymentTransaction(Base):
    """Tracks every subscription checkout attempt and confirmed provider reference."""

    __tablename__ = "saas_payment_transactions"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    reference = Column(String(100), unique=True, nullable=False, index=True)
    external_reference = Column(String(100), nullable=True, index=True)
    provider_code = Column(String(50), nullable=False, default="feexpay")
    boutique_id = Column(String(36), ForeignKey("boutiques.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id = Column(String(36), ForeignKey("users.id"), nullable=False)
    plan_id = Column(String(36), ForeignKey("saas_plans.id"), nullable=False)
    billing_cycle = Column(String(20), nullable=False, default="monthly")
    amount = Column(Float, nullable=False)
    currency = Column(String(10), nullable=False, default="XOF")
    phone = Column(String(30), nullable=False)
    network = Column(String(40), nullable=False)
    flow_type = Column(String(20), nullable=False, default="ussd_push")
    payment_url = Column(Text, nullable=True)
    status = Column(String(30), nullable=False, default="pending")
    raw_payload = Column(JSON, nullable=True)
    paid_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utc_now)
    updated_at = Column(DateTime(timezone=True), default=utc_now, onupdate=utc_now)


class SaasInvoice(Base):
    """Official invoice issued upon confirmed SaaS subscription payment."""

    __tablename__ = "saas_invoices"

    id = Column(String(36), primary_key=True, default=generate_uuid)
    invoice_number = Column(String(100), unique=True, nullable=False, index=True)
    transaction_id = Column(
        String(36), ForeignKey("saas_payment_transactions.id", ondelete="CASCADE"), unique=True, nullable=False
    )
    boutique_id = Column(String(36), ForeignKey("boutiques.id", ondelete="CASCADE"), nullable=False, index=True)
    plan_name = Column(String(100), nullable=False)
    billing_cycle = Column(String(20), nullable=False)
    amount = Column(Float, nullable=False)
    currency = Column(String(10), nullable=False, default="XOF")
    period_start = Column(DateTime(timezone=True), nullable=False)
    period_end = Column(DateTime(timezone=True), nullable=False)
    issued_at = Column(DateTime(timezone=True), default=utc_now)
