from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, ConfigDict, Field


class CashSessionOpenRequest(BaseModel):
    magasin_id: Optional[str] = None
    opening_balance: float = Field(0.0, ge=0)
    notes: Optional[str] = None


class CashSessionCloseRequest(BaseModel):
    declared_cash: float = Field(..., ge=0)
    notes: Optional[str] = None


class CashSessionOut(BaseModel):
    id: str
    magasin_id: str
    magasin_name: Optional[str] = None
    opened_by_user_id: str
    opened_by_name: Optional[str] = None
    opened_at: datetime
    opening_balance: float
    status: str
    expected_cash: Optional[float] = None
    expected_mobile_money: Optional[float] = None
    expected_card: Optional[float] = None
    declared_cash: Optional[float] = None
    discrepancy: Optional[float] = None
    closed_by_name: Optional[str] = None
    closed_at: Optional[datetime] = None
    notes: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


class SaleRefundItemInput(BaseModel):
    vente_item_sync_id: str
    quantity: float = Field(..., gt=0)


class SaleRefundRequest(BaseModel):
    items: Optional[List[SaleRefundItemInput]] = None
    reason: str = Field(..., min_length=2)


class PaymentLedgerOut(BaseModel):
    id: str
    magasin_id: Optional[str] = None
    client_sync_id: Optional[str] = None
    supplier_sync_id: Optional[str] = None
    amount: float
    payment_method: str
    previous_balance: float
    new_balance: float
    notes: Optional[str] = None
    user_id: Optional[str] = None
    user_name: Optional[str] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
