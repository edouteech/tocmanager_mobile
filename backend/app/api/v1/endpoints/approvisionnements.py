from typing import List, Optional
from datetime import datetime, timezone
import uuid
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.api import deps
from app.core.database import get_db
from app.models import Approvisionnement, Product, Supplier, AuditLog, User
from app.schemas.entities import ApprovisionnementCreate, ApprovisionnementResponse
from app.services.tenant_context_service import TenantContext

router = APIRouter()


@router.get("", response_model=List[ApprovisionnementResponse])
def list_approvisionnements(
    product_sync_id: Optional[str] = Query(None),
    supplier_sync_id: Optional[str] = Query(None),
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
    ctx: TenantContext = Depends(deps.get_tenant_context),
    db: Session = Depends(get_db),
):
    query = db.query(Approvisionnement).filter(
        Approvisionnement.boutique_id == ctx.boutique.id,
        Approvisionnement.deleted_at.is_(None),
    )
    if product_sync_id:
        query = query.filter(Approvisionnement.product_sync_id == product_sync_id)
    if supplier_sync_id:
        query = query.filter(Approvisionnement.supplier_sync_id == supplier_sync_id)
    return query.order_by(Approvisionnement.date.desc()).offset(offset).limit(limit).all()


@router.post("", response_model=ApprovisionnementResponse, status_code=status.HTTP_201_CREATED)
def create_approvisionnement(
    app_in: ApprovisionnementCreate,
    ctx: TenantContext = Depends(deps.get_tenant_context),
    current_user: User = Depends(deps.require_role(["admin", "manager"])),
    db: Session = Depends(get_db),
):
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

    old_stock = max(0.0, prod.stock)
    old_pamp = prod.average_cost_price or prod.cost_price or 0.0
    if (old_stock + app_in.quantity) > 0:
        new_pamp = round(
            ((old_stock * old_pamp) + (app_in.quantity * app_in.unit_cost))
            / (old_stock + app_in.quantity),
            2,
        )
    else:
        new_pamp = app_in.unit_cost

    prod.stock += app_in.quantity
    prod.cost_price = app_in.unit_cost
    prod.average_cost_price = new_pamp
    prod.updated_at = now

    if app_in.payment_status == "À crédit" and supplier:
        supplier.balance += total_cost
        supplier.updated_at = now

    appro = Approvisionnement(
        sync_id=str(uuid.uuid4()),
        boutique_id=ctx.boutique.id,
        magasin_id=ctx.requested_magasin_id,
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
