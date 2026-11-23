from typing import Optional
from pydantic import BaseModel


class ProductCreate(BaseModel):
    name: str
    category_sync_id: Optional[str] = None
    price: float
    cost_price: float = 0.0
    stock: float = 0.0
    min_stock: float = 5.0
    barcode: Optional[str] = None
    unit: Optional[str] = "pièce"
    image_path: Optional[str] = None
    magasin_id: Optional[str] = None


class ProductUpdate(BaseModel):
    name: Optional[str] = None
    category_sync_id: Optional[str] = None
    price: Optional[float] = None
    cost_price: Optional[float] = None
    stock: Optional[float] = None
    min_stock: Optional[float] = None
    barcode: Optional[str] = None
    unit: Optional[str] = None
    image_path: Optional[str] = None
    is_active: Optional[bool] = None
