from typing import Any, Dict, Optional
from sqlalchemy import case, func, or_
from sqlalchemy.orm import Session

from app.models import Magasin, Product, ProductMagasinAvailability, StockMagasin
from app.services.pagination_service import build_paginated_response, compute_offset
from app.services.product_magasin_service import enrich_products_for_context


def list_products_paginated_for_context(
    db: Session,
    boutique_id: str,
    magasin_id: Optional[str],
    search: Optional[str] = None,
    category_id: Optional[str] = None,
    stock_status: Optional[str] = None,
    only_available: bool = False,
    sort: Optional[str] = None,
    page: int = 1,
    limit: int = 50,
) -> Dict[str, Any]:
    """Return paginated products with global magasin-aware stock KPI summary."""
    base = db.query(Product).filter(
        Product.boutique_id == boutique_id,
        Product.deleted_at.is_(None),
    )

    if magasin_id:
        base = base.outerjoin(
            StockMagasin,
            (StockMagasin.product_sync_id == Product.sync_id)
            & (StockMagasin.magasin_id == magasin_id)
            & (StockMagasin.boutique_id == boutique_id),
        ).outerjoin(
            ProductMagasinAvailability,
            (ProductMagasinAvailability.product_sync_id == Product.sync_id)
            & (ProductMagasinAvailability.magasin_id == magasin_id)
            & (ProductMagasinAvailability.boutique_id == boutique_id),
        )
        if only_available:
            base = base.filter(
                or_(
                    ProductMagasinAvailability.is_available.is_(None),
                    ProductMagasinAvailability.is_available == True,
                )
            )
        eff_stock = func.coalesce(StockMagasin.quantity, 0.0)
        eff_min = func.coalesce(StockMagasin.min_stock, Product.min_stock, 5.0)
        eff_price = func.coalesce(ProductMagasinAvailability.custom_price, Product.price)
    else:
        sm_sum_subq = (
            db.query(
                StockMagasin.product_sync_id.label("pid"),
                func.coalesce(func.sum(StockMagasin.quantity), 0.0).label("qty"),
            )
            .join(Magasin, Magasin.id == StockMagasin.magasin_id)
            .filter(StockMagasin.boutique_id == boutique_id, Magasin.is_active == True)
            .group_by(StockMagasin.product_sync_id)
            .subquery()
        )
        base = base.outerjoin(sm_sum_subq, sm_sum_subq.c.pid == Product.sync_id)
        eff_stock = func.coalesce(sm_sum_subq.c.qty, Product.stock, 0.0)
        eff_min = func.coalesce(Product.min_stock, 5.0)
        eff_price = Product.price

    s_total, s_in, s_low, s_out = base.with_entities(
        func.count(Product.sync_id),
        func.coalesce(func.sum(case((eff_stock > eff_min, 1), else_=0)), 0),
        func.coalesce(func.sum(case(((eff_stock > 0) & (eff_stock <= eff_min), 1), else_=0)), 0),
        func.coalesce(func.sum(case((eff_stock <= 0, 1), else_=0)), 0),
    ).one()

    summary = {
        "total": int(s_total or 0),
        "in_stock": int(s_in or 0),
        "low_stock": int(s_low or 0),
        "out_of_stock": int(s_out or 0),
    }

    filtered = base
    if search and search.strip():
        term = f"%{search.strip()}%"
        filtered = filtered.filter(or_(Product.name.ilike(term), Product.barcode.ilike(term)))
    if category_id and category_id != "all":
        filtered = filtered.filter(Product.category_sync_id == category_id)
    if stock_status == "rupture":
        filtered = filtered.filter(eff_stock <= 0)
    elif stock_status == "low":
        filtered = filtered.filter((eff_stock > 0) & (eff_stock <= eff_min))
    elif stock_status == "normal":
        filtered = filtered.filter(eff_stock > eff_min)

    if sort == "price_desc":
        filtered = filtered.order_by(eff_price.desc(), Product.name.asc())
    elif sort == "price_asc":
        filtered = filtered.order_by(eff_price.asc(), Product.name.asc())
    elif sort == "stock_asc":
        filtered = filtered.order_by(eff_stock.asc(), Product.name.asc())
    elif sort == "stock_desc":
        filtered = filtered.order_by(eff_stock.desc(), Product.name.asc())
    else:
        filtered = filtered.order_by(Product.name.asc())

    total = int(filtered.with_entities(func.count(Product.sync_id)).scalar() or 0)
    products = filtered.offset(compute_offset(page, limit)).limit(limit).all()
    items = enrich_products_for_context(db, boutique_id, magasin_id, products)
    return build_paginated_response(
        items=items,
        total=total,
        page=page,
        limit=limit,
        summary=summary,
    )
