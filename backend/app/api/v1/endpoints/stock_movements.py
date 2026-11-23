from datetime import datetime, timezone
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.api import deps
from app.core.database import get_db
from app.models import AuditLog, Magasin, Product, StockMovement
from app.schemas.inventory import StockAdjustRequest, StockMovementOut
from app.services.stock_service import adjust_magasin_stock, ensure_stock_row
from app.services.tenant_context_service import (
    TenantContext,
    resolve_operational_magasin,
    resolve_read_magasin_id,
)

router = APIRouter()


@router.get("", response_model=List[StockMovementOut])
def list_stock_movements(
    product_sync_id: Optional[str] = Query(None),
    magasin_id: Optional[str] = Query(None),
    movement_type: Optional[str] = Query(None),
    start_date: Optional[datetime] = Query(None),
    end_date: Optional[datetime] = Query(None),
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
    ctx: TenantContext = Depends(deps.require_tenant_role(["owner", "store_admin", "manager"])),
    db: Session = Depends(get_db),
):
    active_mag = resolve_read_magasin_id(ctx)
    effective_mag = magasin_id or active_mag

    query = db.query(StockMovement).filter(StockMovement.boutique_id == ctx.boutique.id)
    if effective_mag:
        query = query.filter(StockMovement.magasin_id == effective_mag)
    if product_sync_id:
        query = query.filter(StockMovement.product_sync_id == product_sync_id)
    if movement_type:
        query = query.filter(StockMovement.movement_type == movement_type)
    if start_date:
        query = query.filter(StockMovement.created_at >= start_date)
    if end_date:
        query = query.filter(StockMovement.created_at <= end_date)

    rows = query.order_by(StockMovement.created_at.desc()).offset(offset).limit(limit).all()
    mags = {m.id: m.name for m in db.query(Magasin).filter(Magasin.boutique_id == ctx.boutique.id).all()}
    prods = {p.sync_id: p.name for p in db.query(Product).filter(Product.boutique_id == ctx.boutique.id).all()}

    return [
        StockMovementOut(
            id=r.id,
            magasin_id=r.magasin_id,
            magasin_name=mags.get(r.magasin_id),
            product_sync_id=r.product_sync_id,
            product_name=prods.get(r.product_sync_id),
            movement_type=r.movement_type,
            quantity_delta=r.quantity_delta,
            balance_before=r.balance_before,
            balance_after=r.balance_after,
            reference_type=r.reference_type,
            reference_id=r.reference_id,
            reason=r.reason,
            user_id=r.user_id,
            user_name=r.user_name,
            created_at=r.created_at,
        )
        for r in rows
    ]


@router.post("/adjust", response_model=StockMovementOut, status_code=status.HTTP_201_CREATED)
def adjust_inventory(
    payload: StockAdjustRequest,
    ctx: TenantContext = Depends(deps.require_tenant_role(["owner", "store_admin", "manager"])),
    db: Session = Depends(get_db),
):
    if payload.counted_quantity is None and payload.quantity_delta is None:
        raise HTTPException(
            status_code=400,
            detail="Fournissez 'counted_quantity' ou 'quantity_delta' pour ajuster le stock.",
        )

    magasin = resolve_operational_magasin(
        db, ctx, body_magasin_id=payload.magasin_id, allow_warehouse=True
    )
    prod = db.query(Product).filter(
        Product.sync_id == payload.product_sync_id,
        Product.boutique_id == ctx.boutique.id,
        Product.deleted_at.is_(None),
    ).first()
    if not prod:
        raise HTTPException(status_code=404, detail="Produit introuvable dans cette boutique.")

    sm = ensure_stock_row(db, ctx.boutique.id, magasin.id, prod)
    delta = (
        round(payload.counted_quantity - float(sm.quantity or 0.0), 4)
        if payload.counted_quantity is not None
        else float(payload.quantity_delta or 0.0)
    )

    uid = ctx.user.id
    uname = ctx.user.full_name or ctx.user.username
    _, before, after = adjust_magasin_stock(
        db=db,
        boutique_id=ctx.boutique.id,
        magasin_id=magasin.id,
        product=prod,
        quantity_delta=delta,
        enforce_sufficient=(delta < 0),
        movement_type=payload.movement_type,
        reference_type="inventory",
        reference_id=magasin.id,
        reason=payload.reason.strip(),
        user_id=uid,
        user_name=uname,
    )

    now = datetime.now(timezone.utc)
    db.add(AuditLog(
        boutique_id=ctx.boutique.id,
        user_id=uid,
        user_name=uname,
        action="STOCK_ADJUST",
        entity_type="product",
        entity_id=prod.sync_id,
        details={
            "magasin": magasin.name,
            "movement_type": payload.movement_type,
            "before": before,
            "after": after,
            "delta": delta,
            "reason": payload.reason.strip(),
        },
        created_at=now,
    ))
    db.commit()

    latest = (
        db.query(StockMovement)
        .filter(
            StockMovement.boutique_id == ctx.boutique.id,
            StockMovement.magasin_id == magasin.id,
            StockMovement.product_sync_id == prod.sync_id,
        )
        .order_by(StockMovement.created_at.desc())
        .first()
    )
    return StockMovementOut(
        id=latest.id,
        magasin_id=magasin.id,
        magasin_name=magasin.name,
        product_sync_id=prod.sync_id,
        product_name=prod.name,
        movement_type=latest.movement_type,
        quantity_delta=latest.quantity_delta,
        balance_before=latest.balance_before,
        balance_after=latest.balance_after,
        reference_type=latest.reference_type,
        reference_id=latest.reference_id,
        reason=latest.reason,
        user_id=latest.user_id,
        user_name=latest.user_name,
        created_at=latest.created_at,
    )
