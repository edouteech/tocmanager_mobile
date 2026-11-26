from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from fastapi import HTTPException
from sqlalchemy import func, or_
from sqlalchemy.orm import Session

from app.models import Magasin, Product, ProductMagasinAvailability, StockMagasin
from app.services.stock_service import ensure_stock_row


def list_products_for_context(
    db: Session,
    boutique_id: str,
    magasin_id: Optional[str],
    search: Optional[str] = None,
    category_id: Optional[str] = None,
    only_available: bool = False,
    skip: int = 0,
    limit: int = 100,
) -> List[Dict[str, Any]]:
    """Return products enriched with magasin-level stock, availability, and custom pricing."""
    query = db.query(Product).filter(Product.boutique_id == boutique_id, Product.deleted_at.is_(None))
    if search:
        term = f"%{search.strip()}%"
        query = query.filter(or_(Product.name.ilike(term), Product.barcode.ilike(term)))
    if category_id:
        query = query.filter(Product.category_sync_id == category_id)
    if magasin_id and only_available:
        query = query.outerjoin(
            ProductMagasinAvailability,
            (ProductMagasinAvailability.product_sync_id == Product.sync_id)
            & (ProductMagasinAvailability.magasin_id == magasin_id),
        ).filter(or_(ProductMagasinAvailability.is_available.is_(None), ProductMagasinAvailability.is_available == True))

    products = query.order_by(Product.name.asc()).offset(skip).limit(limit).all()
    return enrich_products_for_context(db, boutique_id, magasin_id, products)


def enrich_products_for_context(
    db: Session,
    boutique_id: str,
    magasin_id: Optional[str],
    products: List[Product],
) -> List[Dict[str, Any]]:
    """Enrich product ORM models with active magasin stock, availability, and custom pricing."""
    if not products:
        return []
    prod_ids = [p.sync_id for p in products]

    sm_map: Dict[str, StockMagasin] = {}
    av_map: Dict[str, ProductMagasinAvailability] = {}
    sm_totals: Dict[str, float] = {}
    if magasin_id:
        sm_map = {
            r.product_sync_id: r
            for r in db.query(StockMagasin).filter(
                StockMagasin.boutique_id == boutique_id,
                StockMagasin.magasin_id == magasin_id,
                StockMagasin.product_sync_id.in_(prod_ids),
            ).all()
        }
        av_map = {
            r.product_sync_id: r
            for r in db.query(ProductMagasinAvailability).filter(
                ProductMagasinAvailability.boutique_id == boutique_id,
                ProductMagasinAvailability.magasin_id == magasin_id,
                ProductMagasinAvailability.product_sync_id.in_(prod_ids),
            ).all()
        }
    else:
        sum_rows = (
            db.query(StockMagasin.product_sync_id, func.coalesce(func.sum(StockMagasin.quantity), 0.0))
            .join(Magasin, Magasin.id == StockMagasin.magasin_id)
            .filter(
                StockMagasin.boutique_id == boutique_id,
                Magasin.is_active == True,
                StockMagasin.product_sync_id.in_(prod_ids),
            )
            .group_by(StockMagasin.product_sync_id)
            .all()
        )
        sm_totals = {pid: float(qty) for pid, qty in sum_rows}

    result: List[Dict[str, Any]] = []
    for p in products:
        if magasin_id:
            sm = sm_map.get(p.sync_id)
            av = av_map.get(p.sync_id)
            custom_price = av.custom_price if av else None
            effective_price = custom_price if custom_price is not None else float(p.price)
            stock_val = float(sm.quantity) if sm else 0.0
            min_val = float(sm.min_stock) if sm else float(p.min_stock or 5.0)
            cost_val = float(sm.cost_price) if sm else float(p.cost_price or 0.0)
            pamp_val = float(sm.average_cost_price) if (sm and sm.average_cost_price is not None) else float(p.average_cost_price or 0.0)
            is_avail = bool(av.is_available) if av else True
        else:
            stock_val = sm_totals.get(p.sync_id, float(p.stock or 0.0))
            min_val = float(p.min_stock or 5.0)
            cost_val = float(p.cost_price or 0.0)
            pamp_val = float(p.average_cost_price or 0.0)
            effective_price = float(p.price)
            is_avail = True
            custom_price = None
        result.append({
            "sync_id": p.sync_id,
            "name": p.name,
            "category_sync_id": p.category_sync_id,
            "price": effective_price,
            "cost_price": cost_val,
            "average_cost_price": pamp_val,
            "stock": stock_val,
            "min_stock": min_val,
            "barcode": p.barcode,
            "unit": p.unit,
            "image_path": p.image_path,
            "is_active": p.is_active,
            "updated_at": p.updated_at,
            "deleted_at": p.deleted_at,
            "custom_price": custom_price,
            "is_available": is_avail,
            "magasin_id": magasin_id,
        })
    return result


def get_product_magasins_matrix(
    db: Session, boutique_id: str, product_sync_id: str
) -> List[Dict[str, Any]]:
    """Return full stock, min_stock, availability and custom price matrix per magasin."""
    product = db.query(Product).filter(
        Product.sync_id == product_sync_id, Product.boutique_id == boutique_id, Product.deleted_at.is_(None)
    ).first()
    if not product:
        raise HTTPException(status_code=404, detail="Produit non trouvé")

    magasins = db.query(Magasin).filter(Magasin.boutique_id == boutique_id).order_by(Magasin.created_at.asc()).all()
    sm_map = {r.magasin_id: r for r in db.query(StockMagasin).filter(StockMagasin.boutique_id == boutique_id, StockMagasin.product_sync_id == product_sync_id).all()}
    av_map = {r.magasin_id: r for r in db.query(ProductMagasinAvailability).filter(ProductMagasinAvailability.boutique_id == boutique_id, ProductMagasinAvailability.product_sync_id == product_sync_id).all()}

    matrix: List[Dict[str, Any]] = []
    for mag in magasins:
        sm = sm_map.get(mag.id)
        av = av_map.get(mag.id)
        custom_price = av.custom_price if av else None
        matrix.append({
            "magasin_id": mag.id,
            "magasin_name": mag.name,
            "magasin_code": mag.code,
            "is_warehouse": bool(mag.is_warehouse),
            "is_active": bool(mag.is_active),
            "is_available": bool(av.is_available) if av else True,
            "custom_price": custom_price,
            "effective_price": custom_price if custom_price is not None else float(product.price),
            "quantity": float(sm.quantity) if sm else 0.0,
            "min_stock": float(sm.min_stock) if sm else float(product.min_stock or 5.0),
        })
    return matrix


def upsert_product_magasin_config(
    db: Session,
    boutique_id: str,
    product_sync_id: str,
    magasin_id: str,
    is_available: Optional[bool] = None,
    custom_price: Optional[float] = None,
    clear_custom_price: bool = False,
    min_stock: Optional[float] = None,
) -> Dict[str, Any]:
    """Update product availability, custom price, and min_stock threshold for a magasin."""
    product = db.query(Product).filter(Product.sync_id == product_sync_id, Product.boutique_id == boutique_id, Product.deleted_at.is_(None)).first()
    if not product:
        raise HTTPException(status_code=404, detail="Produit non trouvé")
    mag = db.query(Magasin).filter(Magasin.id == magasin_id, Magasin.boutique_id == boutique_id).first()
    if not mag:
        raise HTTPException(status_code=404, detail="Magasin non trouvé")

    avail = db.query(ProductMagasinAvailability).filter(ProductMagasinAvailability.magasin_id == magasin_id, ProductMagasinAvailability.product_sync_id == product_sync_id).first()
    if not avail:
        avail = ProductMagasinAvailability(boutique_id=boutique_id, magasin_id=magasin_id, product_sync_id=product_sync_id, is_available=True)
        db.add(avail)
    if is_available is not None:
        avail.is_available = is_available
    if clear_custom_price:
        avail.custom_price = None
    elif custom_price is not None:
        avail.custom_price = custom_price

    sm = ensure_stock_row(db, boutique_id, magasin_id, product)
    if min_stock is not None:
        sm.min_stock = min_stock
    product.updated_at = datetime.now(timezone.utc)
    db.commit()
    return [row for row in get_product_magasins_matrix(db, boutique_id, product_sync_id) if row["magasin_id"] == magasin_id][0]
