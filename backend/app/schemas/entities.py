from typing import Optional, List, Dict, Any
from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field

# --- Clients ---
class ClientBase(BaseModel):
    name: str
    phone: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    notes: Optional[str] = None

class ClientCreate(ClientBase):
    balance: float = 0.0

class ClientUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    notes: Optional[str] = None
    balance: Optional[float] = None

class DebtPaymentRequest(BaseModel):
    amount: float = Field(..., gt=0, description="Montant du remboursement")
    payment_method: str = "Espèces"
    notes: Optional[str] = None

class ClientResponse(ClientBase):
    sync_id: str
    balance: float
    user_id: Optional[str] = None
    user_name: Optional[str] = None
    created_at: datetime
    updated_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)

# --- Suppliers ---
class SupplierBase(BaseModel):
    name: str
    contact_person: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    notes: Optional[str] = None

class SupplierCreate(SupplierBase):
    balance: float = 0.0

class SupplierUpdate(BaseModel):
    name: Optional[str] = None
    contact_person: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    notes: Optional[str] = None
    balance: Optional[float] = None

class SupplierPaymentRequest(BaseModel):
    amount: float = Field(..., gt=0, description="Montant versé au fournisseur")
    payment_method: str = "Espèces"
    notes: Optional[str] = None

class SupplierResponse(SupplierBase):
    sync_id: str
    balance: float
    user_id: Optional[str] = None
    user_name: Optional[str] = None
    created_at: datetime
    updated_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)

# --- Approvisionnements / Stock In ---
class ApprovisionnementCreate(BaseModel):
    supplier_sync_id: Optional[str] = None
    supplier_name: Optional[str] = None
    product_sync_id: str
    product_name: Optional[str] = None
    quantity: float = Field(..., gt=0)
    unit_cost: float = Field(..., ge=0)
    payment_status: str = "Payé"  # "Payé" ou "À crédit"
    notes: Optional[str] = None
    date: Optional[datetime] = None

class ApprovisionnementResponse(BaseModel):
    sync_id: str
    supplier_sync_id: Optional[str] = None
    supplier_name: Optional[str] = None
    product_sync_id: Optional[str] = None
    product_name: str
    quantity: float
    unit_cost: float
    total_cost: float
    payment_status: str
    date: datetime
    notes: Optional[str] = None
    user_id: Optional[str] = None
    user_name: Optional[str] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

# --- Decaissements / Expenses ---
class DecaissementCreate(BaseModel):
    title: str
    amount: float = Field(..., gt=0)
    category: Optional[str] = "Général"
    beneficiary: Optional[str] = None
    payment_method: str = "Espèces"
    notes: Optional[str] = None
    date: Optional[datetime] = None

class DecaissementResponse(BaseModel):
    sync_id: str
    title: str
    amount: float
    category: Optional[str] = None
    beneficiary: Optional[str] = None
    payment_method: str
    date: datetime
    notes: Optional[str] = None
    user_id: Optional[str] = None
    user_name: Optional[str] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)

# --- Categories ---
class CategoryBase(BaseModel):
    name: str
    description: Optional[str] = None
    color: Optional[str] = "#4F46E5"
    icon: Optional[str] = "Package"

class CategoryCreate(CategoryBase):
    pass

class CategoryUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    color: Optional[str] = None
    icon: Optional[str] = None

class CategoryResponse(CategoryBase):
    sync_id: str
    created_at: datetime
    updated_at: Optional[datetime] = None
    products_count: Optional[int] = 0

    model_config = ConfigDict(from_attributes=True)

# --- Store Settings ---
class StoreSettings(BaseModel):
    store_name: str = "TocManager Store"
    currency: str = "FCFA"
    phone: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    tax_rate: float = 0.0
    low_stock_threshold: float = 5.0
    rccm: Optional[str] = None
    nif: Optional[str] = None

# --- Financial Reports / P&L ---
class FinancialKPIs(BaseModel):
    gross_sales: float
    discount_amount: float
    net_sales: float
    cogs: float  # Coût des marchandises vendues
    gross_margin: float  # net_sales - cogs
    gross_margin_rate: float  # % de marge brute
    total_expenses: float
    net_profit: float  # gross_margin - total_expenses
    net_margin_rate: float  # % de résultat net

class TopProductItem(BaseModel):
    product_name: str
    quantity_sold: float
    total_revenue: float
    total_profit: float

class ExpenseCategoryItem(BaseModel):
    category: str
    total_amount: float
    percentage: float

class FinancialReportResponse(BaseModel):
    start_date: str
    end_date: str
    kpis: FinancialKPIs
    top_products: List[TopProductItem]
    expenses_by_category: List[ExpenseCategoryItem]
    monthly_trend: List[Dict[str, Any]]

# --- Ventes / POS Sales ---
class VenteItemCreate(BaseModel):
    product_sync_id: str
    quantity: float = Field(..., gt=0)
    unit_price: float = Field(..., ge=0)
    cost_price: Optional[float] = None
    product_name: Optional[str] = None

class VenteCreate(BaseModel):
    client_sync_id: Optional[str] = None
    client_name: Optional[str] = None
    items: List[VenteItemCreate]
    discount_amount: float = 0.0
    paid_amount: float = Field(..., ge=0)
    payment_method: str = "Espèces"
    notes: Optional[str] = None

