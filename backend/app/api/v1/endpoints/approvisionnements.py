from typing import Any, Optional
from datetime import date, datetime, timezone
import uuid
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, or_
from sqlalchemy.orm import Session

from app.api import deps
from app.core.database import get_db
from app.models import Approvisionnement, Product, Supplier, AuditLog
from app.schemas.entities import ApprovisionnementCreate, ApprovisionnementResponse
from app.services.entitlements import check_feature_access
from app.services.pagination_service import paginate_sqlalchemy
from app.services.stock_service import adjust_magasin_stock
from app.services.tenant_context_service import (
    TenantContext,
    resolve_operational_magasin,
    resolve_read_magasin_id,
)

router = APIRouter()


@router.get("", response_model=Any)
def list_approvisionnements(
    product_sync_id: Optional[str] = Query(None),
    supplier_sync_id: Optional[str] = Query(None),
    q: Optional[str] = Query(None),
    start_date: Optional[date] = Query(None),
    end_date: Optional[date] = Query(None),
    paginated: bool = False,
    page: int = Query(1, ge=1),
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
    ctx: TenantContext = Depends(deps.require_tenant_role(["owner", "store_admin", "manager"])),
    db: Session = Depends(get_db),
):
    check_feature_access(db, ctx.boutique.id, "module_supplies")
    magasin_id = resolve_read_magasin_id(ctx)
    base_query = db.query(Approvisionnement).filter(
        Approvisionnement.boutique_id == ctx.boutique.id,
        Approvisionnement.deleted_at.is_(None),
    )
    if magasin_id:
        base_query = base_query.filter(Approvisionnement.magasin_id == magasin_id)
    query = base_query
    if product_sync_id:
        query = query.filter(Approvisionnement.product_sync_id == product_sync_id)
    if supplier_sync_id:
        query = query.filter(Approvisionnement.supplier_sync_id == supplier_sync_id)
    if q and q.strip():
        term = f"%{q.strip()}%"
        query = query.filter(
            or_(
                Approvisionnement.product_name.ilike(term),
                Approvisionnement.supplier_name.ilike(term),
            )
        )
    if start_date:
        query = query.filter(func.date(Approvisionnement.date) >= start_date)
    if end_date:
        query = query.filter(func.date(Approvisionnement.date) <= end_date)

    ordered = query.order_by(Approvisionnement.date.desc())
    if not paginated:
        return [
            ApprovisionnementResponse.model_validate(a).model_dump()
            for a in ordered.offset(offset).limit(limit).all()
        ]

    total_count, total_cost, total_qty = base_query.with_entities(
        func.count(Approvisionnement.sync_id),
        func.coalesce(func.sum(Approvisionnement.total_cost), 0.0),
        func.coalesce(func.sum(Approvisionnement.quantity), 0.0),
    ).one()
    filtered_cost = query.with_entities(func.coalesce(func.sum(Approvisionnement.total_cost), 0.0)).scalar() or 0.0
    summary = {
        "total_count": int(total_count or 0),
        "total_cost": float(total_cost or 0.0),
        "total_quantity": float(total_qty or 0.0),
        "filtered_cost": float(filtered_cost or 0.0),
    }
    return paginate_sqlalchemy(
        ordered,
        page=page,
        limit=limit,
        summary=summary,
        serializer=lambda a: ApprovisionnementResponse.model_validate(a).model_dump(),
    )


@router.post("", response_model=ApprovisionnementResponse, status_code=status.HTTP_201_CREATED)
def create_approvisionnement(
    app_in: ApprovisionnementCreate,
    ctx: TenantContext = Depends(deps.require_tenant_role(["owner", "store_admin", "manager"])),
    db: Session = Depends(get_db),
):
    check_feature_access(db, ctx.boutique.id, "module_supplies")
    magasin = resolve_operational_magasin(
        db, ctx, body_magasin_id=app_in.magasin_id, allow_warehouse=True
    )
    current_user = ctx.user
    prod = (
        db.query(Product)
        .filter(
            Product.sync_id == app_in.product_sync_id,
            Product.boutique_id == ctx.boutique.id,
            Product.deleted_at.is_(None),
        )
        .first()
    )
    if not prod:
        raise HTTPException(status_code=404, detail="Produit sélectionné introuvable")

    supplier = None
    supplier_name = app_in.supplier_name
    if app_in.supplier_sync_id:
        supplier = (
            db.query(Supplier)
            .filter(
                Supplier.sync_id == app_in.supplier_sync_id,
                Supplier.boutique_id == ctx.boutique.id,
                Supplier.deleted_at.is_(None),
            )
            .first()
        )
        if not supplier:
            raise HTTPException(status_code=404, detail="Fournisseur sélectionné introuvable")
        supplier_name = supplier.name

    total_cost = round(app_in.quantity * app_in.unit_cost, 2)
    now = datetime.now(timezone.utc)
    supply_date = app_in.date or now
    appro_sync_id = str(uuid.uuid4())
    op_uname = current_user.full_name or current_user.username

    adjust_magasin_stock(
        db=db,
        boutique_id=ctx.boutique.id,
        magasin_id=magasin.id,
        product=prod,
        quantity_delta=app_in.quantity,
        enforce_sufficient=False,
        new_unit_cost=app_in.unit_cost,
        movement_type="supply",
        reference_type="approvisionnement",
        reference_id=appro_sync_id,
        reason=f"Réception {supplier_name or 'fournisseur'}",
        user_id=current_user.id,
        user_name=op_uname,
    )

    if app_in.payment_status == "À crédit" and supplier:
        supplier.balance += total_cost
        supplier.updated_at = now

    appro = Approvisionnement(
        sync_id=appro_sync_id,
        boutique_id=ctx.boutique.id,
        magasin_id=magasin.id,
        supplier_sync_id=app_in.supplier_sync_id,
        supplier_name=supplier_name,
        product_sync_id=prod.sync_id,
        product_name=prod.name,
        quantity=app_in.quantity,
        unit_cost=app_in.unit_cost,
        total_cost=total_cost,
        payment_status=app_in.payment_status,
        date=supply_date,
        notes=app_in.notes,
        user_id=current_user.id,
        user_name=current_user.full_name or current_user.username,
        created_at=now,
        updated_at=now,
    )
    db.add(appro)
    db.flush()

    db.add(AuditLog(
        boutique_id=ctx.boutique.id,
        user_id=current_user.id,
        user_name=current_user.full_name or current_user.username,
        action="STOCK_SUPPLY",
        entity_type="approvisionnement",
        entity_id=appro.sync_id,
        details={
            "product_name": prod.name,
            "quantity": app_in.quantity,
            "unit_cost": app_in.unit_cost,
            "total_cost": total_cost,
            "new_stock": prod.stock,
            "supplier": supplier_name,
            "payment_status": app_in.payment_status,
        },
        created_at=now,
    ))
    db.commit()
    db.refresh(appro)
    return appro
