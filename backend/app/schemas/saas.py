from typing import List, Optional, Any, Dict
from pydantic import BaseModel, ConfigDict, field_validator
from datetime import datetime
from app.services.feature_catalog import validate_plan_features

class SaasPlanFeatureOut(BaseModel):
    id: str
    feature_code: str
    feature_name: str
    category: str = "modules"
    description: Optional[str] = None
    display_order: int = 0
    show_on_pricing: bool = True
    value_type: str
    boolean_value: bool
    int_limit: int

    model_config = ConfigDict(from_attributes=True)


class FeatureCatalogItemOut(BaseModel):
    feature_code: str
    feature_name: str
    category: str
    value_type: str
    description: str
    display_order: int
    show_on_pricing: bool
    defaults: Dict[str, Any]

class SaasPlanOut(BaseModel):
    id: str
    name: str
    code: str
    description: Optional[str] = None
    price_monthly: float
    price_yearly: float
    currency: str
    trial_period_days: int
    badge: Optional[str] = None
    is_active: bool
    features: List[SaasPlanFeatureOut] = []

    model_config = ConfigDict(from_attributes=True)

class SaasPlanCreate(BaseModel):
    name: str
    code: str
    description: Optional[str] = None
    price_monthly: float = 0.0
    price_yearly: float = 0.0
    currency: str = "XOF"
    trial_period_days: int = 0
    badge: Optional[str] = None
    is_active: bool = True
    features: Optional[List[Dict[str, Any]]] = None

    @field_validator("features")
    @classmethod
    def check_features(cls, value: Optional[List[Dict[str, Any]]]):
        validate_plan_features(value)
        return value

class SaasPlanUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    price_monthly: Optional[float] = None
    price_yearly: Optional[float] = None
    trial_period_days: Optional[int] = None
    badge: Optional[str] = None
    is_active: Optional[bool] = None
    features: Optional[List[Dict[str, Any]]] = None

    @field_validator("features")
    @classmethod
    def check_features(cls, value: Optional[List[Dict[str, Any]]]):
        validate_plan_features(value)
        return value

class MagasinOut(BaseModel):
    id: str
    boutique_id: Optional[str] = None
    name: str
    code: Optional[str] = None
    address: Optional[str] = None
    phone: Optional[str] = None
    is_warehouse: bool
    is_active: bool
    created_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)

class MagasinCreate(BaseModel):
    name: str
    code: Optional[str] = None
    address: Optional[str] = None
    phone: Optional[str] = None
    is_warehouse: bool = False
    is_active: bool = True

class MagasinUpdate(BaseModel):
    name: Optional[str] = None
    code: Optional[str] = None
    address: Optional[str] = None
    phone: Optional[str] = None
    is_warehouse: Optional[bool] = None
    is_active: Optional[bool] = None

class BoutiqueOut(BaseModel):
    id: str
    slug: str
    name: str
    company_name: Optional[str] = None
    currency: str
    country: str
    phone: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    logo_url: Optional[str] = None
    owner_user_id: str
    is_active: bool
    created_at: Optional[datetime] = None
    magasins: List[MagasinOut] = []
    user_role: Optional[str] = None
    assigned_magasin_ids: List[str] = []

    model_config = ConfigDict(from_attributes=True)

class BoutiqueCreate(BaseModel):
    name: str
    company_name: Optional[str] = None
    currency: str = "XOF"
    country: str = "Sénégal"
    phone: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    initial_magasin_name: Optional[str] = "Magasin Principal"
    plan_code: Optional[str] = "free"

# Inscription Étape 1
class RegisterCredentialsRequest(BaseModel):
    full_name: str
    username_or_email: str
    password: str
    phone: Optional[str] = None

# Inscription Étape 2 (Onboarding entreprise & 1ère boutique)
class ProvisionTenantRequest(BaseModel):
    boutique_name: str
    company_name: Optional[str] = None
    currency: str = "XOF"
    country: str = "Sénégal"
    phone: Optional[str] = None
    magasin_name: str = "Magasin Principal"
    plan_code: str = "free" # free, pro, enterprise

class CurrentPlanStatusOut(BaseModel):
    plan_id: str
    plan_name: str
    plan_code: str
    status: str # trialing, active, past_due, canceled
    trial_active: bool
    trial_days_left: int
    features: Dict[str, Any] # code -> boolean or int_limit
    can_access_stock_transfers: bool
    can_access_pnl_reports: bool
    can_access_data_exports: bool
    boutiques_used: int = 1
    boutiques_limit: int = 1
    magasins_used: int
    magasins_limit: int # -1 = unlimited
    products_used: int = 0
    products_limit: int = 100
    users_used: int = 1
    users_limit: int = 2
    clients_used: int = 0
    clients_limit: int = 50
    suppliers_used: int = 0
    suppliers_limit: int = 10
    audit_retention_days: int = 3
    has_used_trial: bool = False
    billing_cycle: str = "monthly"
    current_period_end: Optional[datetime] = None
