from typing import Any, List, Optional
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.api import deps
from app.core.database import get_db
from app.models import Category, Product, User
from app.schemas.sync import ProductSync
from app.services.tenant_context_service import TenantContext
from pydantic import BaseModel

router = APIRouter()


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


def _ensure_category_in_boutique(
    db: Session, category_sync_id: Optional[str], boutique_id: str
) -> None:
    if not category_sync_id:
        return
    cat = (
        db.query(Category.sync_id)
        .filter(
            Category.sync_id == category_sync_id,
            Category.boutique_id == boutique_id,
            Category.deleted_at.is_(None),
        )
        .first()
    )
    if not cat:
        raise HTTPException(status_code=404, detail="Catégorie introuvable dans cette boutique")


@router.get("", response_model=List[ProductSync])
def list_products(
    skip: int = 0,
    limit: int = 100,
    search: Optional[str] = None,
    category_id: Optional[str] = None,
    ctx: TenantContext = Depends(deps.get_tenant_context),
    db: Session = Depends(get_db),
) -> Any:
    query = db.query(Product).filter(
        Product.boutique_id == ctx.boutique.id,
        Product.deleted_at.is_(None),
    )
    if search:
        query = query.filter(Product.name.ilike(f"%{search}%"))
    if category_id:
        query = query.filter(Product.category_sync_id == category_id)
    return query.offset(skip).limit(limit).all()


@router.post("", response_model=ProductSync)
def create_product(
    data: ProductCreate,
    ctx: TenantContext = Depends(deps.get_tenant_context),
    current_user: User = Depends(deps.require_role(["admin", "manager"])),
    db: Session = Depends(get_db),
) -> Any:
    _ = current_user
    _ensure_category_in_boutique(db, data.category_sync_id, ctx.boutique.id)
    now = datetime.now(timezone.utc)
    product = Product(
        boutique_id=ctx.boutique.id,
        name=data.name,
        category_sync_id=data.category_sync_id,
        price=data.price,
        cost_price=data.cost_price,
        stock=data.stock,
        min_stock=data.min_stock,
        barcode=data.barcode,
        unit=data.unit,
        image_path=data.image_path,
        created_at=now,
        updated_at=now,
    )
    db.add(product)
    db.commit()
    db.refresh(product)
    return product


@router.put("/{sync_id}", response_model=ProductSync)
def update_product(
    sync_id: str,
    data: ProductUpdate,
    ctx: TenantContext = Depends(deps.get_tenant_context),
    current_user: User = Depends(deps.require_role(["admin", "manager"])),
    db: Session = Depends(get_db),
) -> Any:
    _ = current_user
    product = (
        db.query(Product)
        .filter(
            Product.sync_id == sync_id,
            Product.boutique_id == ctx.boutique.id,
            Product.deleted_at.is_(None),
        )
        .first()
    )
    if not product:
        raise HTTPException(status_code=404, detail="Produit non trouvé")

    update_data = data.model_dump(exclude_unset=True)
    if "category_sync_id" in update_data:
        _ensure_category_in_boutique(db, update_data["category_sync_id"], ctx.boutique.id)

    for field, value in update_data.items():
        setattr(product, field, value)

    product.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(product)
    return product


@router.delete("/{sync_id}")
def delete_product(
    sync_id: str,
    ctx: TenantContext = Depends(deps.get_tenant_context),
    current_user: User = Depends(deps.require_role(["admin", "manager"])),
    db: Session = Depends(get_db),
) -> Any:
    _ = current_user
    product = (
        db.query(Product)
        .filter(Product.sync_id == sync_id, Product.boutique_id == ctx.boutique.id)
        .first()
    )
    if not product:
        raise HTTPException(status_code=404, detail="Produit non trouvé")
    product.deleted_at = datetime.now(timezone.utc)
    product.updated_at = datetime.now(timezone.utc)
    db.commit()
    return {"status": "deleted", "sync_id": sync_id}
