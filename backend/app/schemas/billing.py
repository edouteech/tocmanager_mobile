from datetime import datetime
from typing import Any, Dict, List, Literal, Optional
from pydantic import BaseModel, ConfigDict


class CheckoutRequest(BaseModel):
    plan_code: str
    billing_cycle: Literal["monthly", "yearly"] = "monthly"
    network: str
    phone: str


class CheckoutResponse(BaseModel):
    transaction_id: str
    reference: str
    external_reference: Optional[str] = None
    flow_type: str
    status: str
    payment_url: Optional[str] = None
    amount: float
    currency: str


class TransactionStatusOut(BaseModel):
    id: str
    reference: str
    external_reference: Optional[str] = None
    provider_code: str
    flow_type: str
    status: str
    payment_url: Optional[str] = None
    amount: float
    currency: str
    network: str
    paid_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


class InvoiceOut(BaseModel):
    id: str
    invoice_number: str
    transaction_id: str
    boutique_id: str
    plan_name: str
    billing_cycle: str
    amount: float
    currency: str
    period_start: datetime
    period_end: datetime
    issued_at: datetime

    model_config = ConfigDict(from_attributes=True)


class PaymentCountryOut(BaseModel):
    code: str
    name: str
    dial_code: str
    networks: List[str]


class PaymentProviderPublicOut(BaseModel):
    code: str
    name: str
    is_active: bool
    mode: str
    countries: List[PaymentCountryOut]


class PaymentMethodsOut(BaseModel):
    providers: List[PaymentProviderPublicOut]
    extra: Optional[Dict[str, Any]] = None
