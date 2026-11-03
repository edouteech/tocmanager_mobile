from typing import List, Optional
from datetime import datetime, timezone
import uuid
from fastapi import APIRouter, Depends, HTTPException, Query, status, Response
from sqlalchemy.orm import Session
from sqlalchemy import or_

from app.api import deps
from app.core.database import get_db
from app.models import Supplier, AuditLog, User
from app.schemas.entities import SupplierCreate, SupplierUpdate, SupplierResponse, SupplierPaymentRequest

router = APIRouter()

@router.get("", response_model=List[SupplierResponse])
def list_suppliers(
    q: Optional[str] = Query(None, description="Recherche par nom, contact ou téléphone"),
    only_creditors: bool = Query(False, description="Fournisseurs à qui on doit de l'argent"),
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
    current_user: User = Depends(deps.get_current_user),
    db: Session = Depends(get_db),
):
    """Liste les fournisseurs avec recherche et filtre de dettes."""
    query = db.query(Supplier).filter(Supplier.deleted_at.is_(None))

    if q:
        search = f"%{q.strip()}%"
        query = query.filter(
            or_(
                Supplier.name.ilike(search),
                Supplier.contact_person.ilike(search),
                Supplier.phone.ilike(search),
            )
        )

    if only_creditors:
        query = query.filter(Supplier.balance > 0)

    return query.order_by(Supplier.name.asc()).offset(offset).limit(limit).all()

@router.post("", response_model=SupplierResponse, status_code=status.HTTP_201_CREATED)
def create_supplier(
    supplier_in: SupplierCreate,
    current_user: User = Depends(deps.require_role(["admin", "manager"])),
    db: Session = Depends(get_db),
):
    """Enregistre un nouveau fournisseur."""
    now = datetime.now(timezone.utc)
    supplier = Supplier(
        sync_id=str(uuid.uuid4()),
        name=supplier_in.name.strip(),
        contact_person=supplier_in.contact_person,
        phone=supplier_in.phone,
        email=supplier_in.email,
        address=supplier_in.address,
        balance=supplier_in.balance,
        notes=supplier_in.notes,
        user_id=current_user.id,
        user_name=current_user.full_name or current_user.username,
        created_at=now,
        updated_at=now,
    )
    db.add(supplier)
    db.flush()

    db.add(AuditLog(
        user_id=current_user.id,
        user_name=current_user.full_name or current_user.username,
        action="SUPPLIER_CREATE",
        entity_type="supplier",
        entity_id=supplier.sync_id,
        details={"name": supplier.name, "contact": supplier.contact_person},
        created_at=now,
    ))
    db.commit()
    db.refresh(supplier)
    return supplier

@router.get("/{sync_id}", response_model=SupplierResponse)
def get_supplier(
    sync_id: str,
    current_user: User = Depends(deps.get_current_user),
    db: Session = Depends(get_db),
):
    """Détail d'un fournisseur."""
    supplier = db.query(Supplier).filter(Supplier.sync_id == sync_id, Supplier.deleted_at.is_(None)).first()
    if not supplier:
        raise HTTPException(status_code=404, detail="Fournisseur introuvable")
    return supplier

@router.put("/{sync_id}", response_model=SupplierResponse)
def update_supplier(
    sync_id: str,
    supplier_in: SupplierUpdate,
    current_user: User = Depends(deps.require_role(["admin", "manager"])),
    db: Session = Depends(get_db),
):
    """Modifie les informations d'un fournisseur."""
    supplier = db.query(Supplier).filter(Supplier.sync_id == sync_id, Supplier.deleted_at.is_(None)).first()
    if not supplier:
        raise HTTPException(status_code=404, detail="Fournisseur introuvable")

    update_data = supplier_in.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(supplier, field, value)

    now = datetime.now(timezone.utc)
    supplier.updated_at = now

    db.add(AuditLog(
        user_id=current_user.id,
        user_name=current_user.full_name or current_user.username,
        action="SUPPLIER_UPDATE",
        entity_type="supplier",
        entity_id=supplier.sync_id,
        details=update_data,
        created_at=now,
    ))
    db.commit()
    db.refresh(supplier)
    return supplier

@router.delete("/{sync_id}", status_code=status.HTTP_204_NO_CONTENT, response_class=Response)
def delete_supplier(
    sync_id: str,
    current_user: User = Depends(deps.require_role(["admin", "manager"])),
    db: Session = Depends(get_db),
):
    """Suppression logique d'un fournisseur."""
    supplier = db.query(Supplier).filter(Supplier.sync_id == sync_id, Supplier.deleted_at.is_(None)).first()
    if not supplier:
        raise HTTPException(status_code=404, detail="Fournisseur introuvable")

    now = datetime.now(timezone.utc)
    supplier.deleted_at = now
    supplier.updated_at = now

    db.add(AuditLog(
        user_id=current_user.id,
        user_name=current_user.full_name or current_user.username,
        action="SUPPLIER_DELETE",
        entity_type="supplier",
        entity_id=supplier.sync_id,
        details={"name": supplier.name},
        created_at=now,
    ))
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)

@router.post("/{sync_id}/payments", response_model=SupplierResponse)
def record_supplier_payment(
    sync_id: str,
    payment: SupplierPaymentRequest,
    current_user: User = Depends(deps.require_role(["admin", "manager"])),
    db: Session = Depends(get_db),
):
    """Enregistre un paiement versé au fournisseur (réduit notre dette envers lui)."""
    supplier = db.query(Supplier).filter(Supplier.sync_id == sync_id, Supplier.deleted_at.is_(None)).first()
    if not supplier:
        raise HTTPException(status_code=404, detail="Fournisseur introuvable")

    previous_balance = supplier.balance
    new_balance = max(0.0, supplier.balance - payment.amount)
    supplier.balance = new_balance

    now = datetime.now(timezone.utc)
    supplier.updated_at = now

    db.add(AuditLog(
        user_id=current_user.id,
        user_name=current_user.full_name or current_user.username,
        action="SUPPLIER_PAYMENT",
        entity_type="supplier",
        entity_id=supplier.sync_id,
        details={
            "supplier_name": supplier.name,
            "amount_paid": payment.amount,
            "payment_method": payment.payment_method,
            "previous_balance": previous_balance,
            "new_balance": new_balance,
            "notes": payment.notes,
        },
        created_at=now,
    ))
    db.commit()
    db.refresh(supplier)
    return supplier
