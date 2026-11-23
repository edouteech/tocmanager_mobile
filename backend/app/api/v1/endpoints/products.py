from typing import Any, List, Optional
from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.api import deps
from app.core.database import get_db
from app.models import Category, Magasin, Product
from app.schemas.entities import ProductMagasinConfigUpdate, ProductMagasinItemOut
from app.schemas.sync import ProductSync
from app.services.entitlements import check_quota_limit
from app.services.product_magasin_service import (
    get_product_magasins_matrix,
    list_products_for_context,
    upsert_product_magasin_config,
)
from app.services.stock_service import (
    ensure_stock_row,
    initialize_product_magasin_stocks,
    sync_product_total_stock,
)
from app.services.tenant_context_service import (
    TenantContext,
    resolve_operational_magasin,
    resolve_read_magasin_id,
)
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
    only_available: bool = False,
    ctx: TenantContext = Depends(deps.get_tenant_context),
    db: Session = Depends(get_db),
) -> Any:
    magasin_id = resolve_read_magasin_id(ctx)
    return list_products_for_context(
        db=db,
        boutique_id=ctx.boutique.id,
        magasin_id=magasin_id,
        search=search,
        category_id=category_id,
        only_available=only_available,
        skip=skip,
        limit=limit,
    )


@router.post("", response_model=ProductSync)
def create_product(
    data: ProductCreate,
    ctx: TenantContext = Depends(deps.require_tenant_role(["owner", "store_admin", "manager"])),
    db: Session = Depends(get_db),
) -> Any:
    current_count = (
        db.query(Product)
        .filter(Product.boutique_id == ctx.boutique.id, Product.deleted_at.is_(None))
        .count()
    )
    check_quota_limit(db, ctx.boutique.id, "max_products", current_count)
    _ensure_category_in_boutique(db, data.category_sync_id, ctx.boutique.id)
    target_mag_id = None
    if data.magasin_id or ctx.requested_magasin_id:
        target_mag_id = resolve_operational_magasin(
            db, ctx, body_magasin_id=data.magasin_id, allow_warehouse=True
        ).id

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
    db.flush()
    initialize_product_magasin_stocks(
        db=db,
        boutique_id=ctx.boutique.id,
        product=product,
        target_magasin_id=target_mag_id,
        initial_stock=data.stock,
    )
    db.commit()
    db.refresh(product)
    return product


@router.put("/{sync_id}", response_model=ProductSync)
def update_product(
    sync_id: str,
    data: ProductUpdate,
    ctx: TenantContext = Depends(deps.require_tenant_role(["owner", "store_admin", "manager"])),
    db: Session = Depends(get_db),
) -> Any:
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

    if ctx.requested_magasin_id and ("stock" in update_data or "min_stock" in update_data):
        sm = ensure_stock_row(db, ctx.boutique.id, ctx.requested_magasin_id, product)
        if "stock" in update_data and data.stock is not None:
            sm.quantity = float(data.stock)
        if "min_stock" in update_data and data.min_stock is not None:
            sm.min_stock = float(data.min_stock)
        sync_product_total_stock(db, ctx.boutique.id, product)
    elif "stock" in update_data and data.stock is not None:
        mags = db.query(Magasin).filter(Magasin.boutique_id == ctx.boutique.id, Magasin.is_active == True).all()
        if len(mags) == 1:
            sm = ensure_stock_row(db, ctx.boutique.id, mags[0].id, product)
            sm.quantity = float(data.stock)
            sync_product_total_stock(db, ctx.boutique.id, product)

    product.updated_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(product)
    return product


@router.get("/{sync_id}/magasins", response_model=List[ProductMagasinItemOut])
def get_product_magasins(
    sync_id: str,
    ctx: TenantContext = Depends(deps.get_tenant_context),
    db: Session = Depends(get_db),
) -> Any:
    resolve_read_magasin_id(ctx)
    return get_product_magasins_matrix(db, ctx.boutique.id, sync_id)


@router.put("/{sync_id}/magasins/{magasin_id}", response_model=ProductMagasinItemOut)
def update_product_magasin(
    sync_id: str,
    magasin_id: str,
    payload: ProductMagasinConfigUpdate,
    ctx: TenantContext = Depends(deps.require_tenant_role(["owner", "store_admin", "manager"])),
    db: Session = Depends(get_db),
) -> Any:
    resolve_operational_magasin(db, ctx, body_magasin_id=magasin_id, allow_warehouse=True)
    return upsert_product_magasin_config(
        db=db,
        boutique_id=ctx.boutique.id,
        product_sync_id=sync_id,
        magasin_id=magasin_id,
        is_available=payload.is_available,
        custom_price=payload.custom_price,
        clear_custom_price=payload.clear_custom_price,
        min_stock=payload.min_stock,
    )


@router.delete("/{sync_id}")
def delete_product(
    sync_id: str,
    ctx: TenantContext = Depends(deps.require_tenant_role(["owner", "store_admin", "manager"])),
    db: Session = Depends(get_db),
) -> Any:
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
