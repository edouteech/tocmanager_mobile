from typing import Any, Dict, List, Literal, Optional
from pydantic import BaseModel, Field


class ExtendTrialRequest(BaseModel):
    days: int = Field(..., ge=1, le=365)


class ToggleBoutiqueStatusRequest(BaseModel):
    is_active: bool = True


class ManualPlanAssignRequest(BaseModel):
    plan_code: str
    status: Literal["active", "trialing", "past_due", "canceled"] = "active"
    billing_cycle: Literal["monthly", "yearly"] = "monthly"
    period_days: int = Field(default=30, ge=1, le=730)
    reason: Optional[str] = None


class ProviderModeCreds(BaseModel):
    api_key: Optional[str] = None
    api_id: Optional[str] = None


class PaymentProviderUpdateRequest(BaseModel):
    name: Optional[str] = None
    is_active: Optional[bool] = None
    mode: Optional[Literal["sandbox", "live"]] = None
    base_url: Optional[str] = None
    countries: Optional[List[Dict[str, Any]]] = None
    networks: Optional[List[str]] = None
    sandbox: Optional[ProviderModeCreds] = None
    live: Optional[ProviderModeCreds] = None
