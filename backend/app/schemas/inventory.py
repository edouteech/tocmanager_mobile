from datetime import datetime
from typing import List, Literal, Optional
from pydantic import BaseModel, ConfigDict, Field


class TransferItemCreate(BaseModel):
    product_sync_id: str
    quantity_sent: float = Field(..., gt=0)


class TransferCreate(BaseModel):
    from_magasin_id: str
    to_magasin_id: str
    items: List[TransferItemCreate] = Field(..., min_length=1)
    notes: Optional[str] = None
    ship_immediately: bool = True


class TransferReceiveItem(BaseModel):
    product_sync_id: str
    quantity_received: float = Field(..., ge=0)


class TransferReceiveRequest(BaseModel):
    items: Optional[List[TransferReceiveItem]] = None
    notes: Optional[str] = None


class TransferItemOut(BaseModel):
    id: str
    product_sync_id: str
    product_name: str
    quantity_sent: float
    quantity_received: Optional[float] = None
    unit_cost: float

    model_config = ConfigDict(from_attributes=True)


class TransferOut(BaseModel):
    id: str
    reference: str
    from_magasin_id: str
    from_magasin_name: Optional[str] = None
    to_magasin_id: str
    to_magasin_name: Optional[str] = None
    status: str
    notes: Optional[str] = None
    created_by_user_id: Optional[str] = None
    created_by_name: Optional[str] = None
    shipped_at: Optional[datetime] = None
    received_at: Optional[datetime] = None
    received_by_name: Optional[str] = None
    canceled_at: Optional[datetime] = None
    created_at: datetime
    items: List[TransferItemOut] = []

    model_config = ConfigDict(from_attributes=True)


class StockMovementOut(BaseModel):
    id: str
    magasin_id: str
    magasin_name: Optional[str] = None
    product_sync_id: str
    product_name: Optional[str] = None
    movement_type: str
    quantity_delta: float
    balance_before: float
    balance_after: float
    reference_type: Optional[str] = None
    reference_id: Optional[str] = None
    reason: Optional[str] = None
    user_id: Optional[str] = None
    user_name: Optional[str] = None
    created_at: datetime


class StockAdjustRequest(BaseModel):
    magasin_id: Optional[str] = None
    product_sync_id: str
    counted_quantity: Optional[float] = Field(None, ge=0)
    quantity_delta: Optional[float] = None
    movement_type: Literal["adjustment", "loss"] = "adjustment"
    reason: str = Field(..., min_length=2)
