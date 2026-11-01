from typing import List, Optional, Any
from datetime import datetime
from pydantic import BaseModel, Field

class VenteItemSync(BaseModel):
    sync_id: Optional[str] = None
    product_sync_id: Optional[str] = None
    product_name: str
    quantity: float
    unit_price: float
    cost_price: float = 0.0
    total: float

class VenteSync(BaseModel):
    sync_id: str
    ticket_number: str
    client_sync_id: Optional[str] = None
    client_name: Optional[str] = "Occasionnel"
    user_id: Optional[str] = None
    user_name: Optional[str] = None
    total_amount: float
    paid_amount: float
    discount_amount: float = 0.0
    payment_method: str = "Espèces"
    notes: Optional[str] = None
    created_at: datetime
    updated_at: Optional[datetime] = None
    items: List[VenteItemSync] = []

class ProductSync(BaseModel):
    sync_id: str
    name: str
    category_sync_id: Optional[str] = None
    price: float
    cost_price: float = 0.0
    average_cost_price: Optional[float] = 0.0
    stock: float
    min_stock: float = 5.0
    barcode: Optional[str] = None
    unit: Optional[str] = "pièce"
    image_path: Optional[str] = None
    is_active: bool = True
    updated_at: datetime
    deleted_at: Optional[datetime] = None

class CategorySync(BaseModel):
    sync_id: str
    name: str
    description: Optional[str] = None
    color: Optional[str] = None
    icon: Optional[str] = None
    updated_at: datetime
    deleted_at: Optional[datetime] = None

class ClientSync(BaseModel):
    sync_id: str
    name: str
    phone: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    balance: float = 0.0
    notes: Optional[str] = None
    user_id: Optional[str] = None
    user_name: Optional[str] = None
    updated_at: datetime
    deleted_at: Optional[datetime] = None

class SupplierSync(BaseModel):
    sync_id: str
    name: str
    contact_person: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    balance: float = 0.0
    notes: Optional[str] = None
    user_id: Optional[str] = None
    user_name: Optional[str] = None
    updated_at: datetime
    deleted_at: Optional[datetime] = None

class DecaissementSync(BaseModel):
    sync_id: str
    title: str
    amount: float
    category: Optional[str] = None
    beneficiary: Optional[str] = None
    payment_method: str = "Espèces"
    date: datetime
    notes: Optional[str] = None
    user_id: Optional[str] = None
    user_name: Optional[str] = None
    updated_at: datetime
    deleted_at: Optional[datetime] = None

class ApprovisionnementSync(BaseModel):
    sync_id: str
    supplier_sync_id: Optional[str] = None
    supplier_name: Optional[str] = None
    product_sync_id: Optional[str] = None
    product_name: str
    quantity: float
    unit_cost: float
    total_cost: float
    payment_status: str = "Payé"
    date: datetime
    notes: Optional[str] = None
    user_id: Optional[str] = None
    user_name: Optional[str] = None
    updated_at: datetime
    deleted_at: Optional[datetime] = None

class AuditLogSync(BaseModel):
    sync_id: str
    user_id: Optional[str] = None
    user_name: Optional[str] = None
    action: str
    entity_type: Optional[str] = None
    entity_id: Optional[str] = None
    details: Optional[Any] = None
    created_at: datetime

class SyncPushRequest(BaseModel):
    device_id: Optional[str] = None
    ventes: List[VenteSync] = []
    clients: List[ClientSync] = []
    decaissements: List[DecaissementSync] = []
    approvisionnements: List[ApprovisionnementSync] = []
    audit_logs: List[AuditLogSync] = []

class SyncPushResult(BaseModel):
    synced_count: int
    rejected_count: int
    synced_uuids: List[str]
    errors: List[str] = []

class SyncPullResponse(BaseModel):
    server_time: datetime
    categories: List[CategorySync] = []
    products: List[ProductSync] = []
    clients: List[ClientSync] = []
    suppliers: List[SupplierSync] = []
    ventes: List[VenteSync] = []
    decaissements: List[DecaissementSync] = []
    approvisionnements: List[ApprovisionnementSync] = []
