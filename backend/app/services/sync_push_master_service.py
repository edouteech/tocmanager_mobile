from datetime import datetime
from typing import List
from fastapi import HTTPException
from sqlalchemy.orm import Session
from app.models import AuditLog, Category, Client, Product, Supplier
from app.schemas.sync import SyncPushRequest
from app.services.entitlements import check_quota_limit
from app.services.tenant_context_service import TenantContext


def belongs_to_other_boutique(record, boutique_id: str) -> bool:
    return record is not None and record.boutique_id is not None and record.boutique_id != boutique_id


def push_master_entities(
    db: Session,
    ctx: TenantContext,
    payload: SyncPushRequest,
    now: datetime,
    synced_uuids: List[str],
    errors: List[str],
) -> None:
    """Synchronise catégories, produits, fournisseurs et clients dans ctx.boutique.id."""
    boutique_id = ctx.boutique.id
    current_user = ctx.user

    for cat in payload.categories:
        try:
            existing = db.query(Category).filter(Category.sync_id == cat.sync_id).first()
            if belongs_to_other_boutique(existing, boutique_id):
                errors.append(f"Category {cat.sync_id}: cross-boutique access denied")
                continue
            if existing:
                existing.name = cat.name
                existing.description = cat.description
                existing.color = cat.color
                existing.icon = cat.icon
                existing.updated_at = cat.updated_at or now
            else:
                db.add(Category(
                    sync_id=cat.sync_id,
                    boutique_id=boutique_id,
                    name=cat.name,
                    description=cat.description,
                    color=cat.color,
                    icon=cat.icon,
                    created_at=cat.updated_at or now,
                    updated_at=cat.updated_at or now,
                ))
            synced_uuids.append(cat.sync_id)
        except Exception as exc:
            errors.append(f"Category {cat.sync_id}: {exc}")

    prod_count = (
        db.query(Product).filter(Product.boutique_id == boutique_id, Product.deleted_at.is_(None)).count()
    )
    for prod in payload.products:
        try:
            existing = db.query(Product).filter(Product.sync_id == prod.sync_id).first()
            if belongs_to_other_boutique(existing, boutique_id):
                errors.append(f"Product {prod.sync_id}: cross-boutique access denied")
                continue
            if prod.category_sync_id:
                cat_ok = (
                    db.query(Category.sync_id)
                    .filter(Category.sync_id == prod.category_sync_id, Category.boutique_id == boutique_id)
                    .first()
                )
                if not cat_ok:
                    errors.append(f"Product {prod.sync_id}: unknown category in boutique")
                    continue
            if existing:
                existing.name = prod.name
                existing.category_sync_id = prod.category_sync_id
                existing.price = prod.price
                existing.cost_price = prod.cost_price
                existing.average_cost_price = prod.average_cost_price or 0.0
                existing.stock = prod.stock
                existing.min_stock = prod.min_stock
                existing.barcode = prod.barcode
                existing.unit = prod.unit
                existing.is_active = prod.is_active
                existing.updated_at = prod.updated_at or now
            else:
                check_quota_limit(db, boutique_id, "max_products", prod_count)
                prod_count += 1
                db.add(Product(
                    sync_id=prod.sync_id,
                    boutique_id=boutique_id,
                    name=prod.name,
                    category_sync_id=prod.category_sync_id,
                    price=prod.price,
                    cost_price=prod.cost_price,
                    average_cost_price=prod.average_cost_price or 0.0,
                    stock=prod.stock,
                    min_stock=prod.min_stock,
                    barcode=prod.barcode,
                    unit=prod.unit or "pièce",
                    is_active=prod.is_active,
                    created_at=prod.updated_at or now,
                    updated_at=prod.updated_at or now,
                ))
            synced_uuids.append(prod.sync_id)
        except HTTPException:
            raise
        except Exception as exc:
            errors.append(f"Product {prod.sync_id}: {exc}")

    sup_count = (
        db.query(Supplier).filter(Supplier.boutique_id == boutique_id, Supplier.deleted_at.is_(None)).count()
    )
    for sup in payload.suppliers:
        try:
            existing = db.query(Supplier).filter(Supplier.sync_id == sup.sync_id).first()
            if belongs_to_other_boutique(existing, boutique_id):
                errors.append(f"Supplier {sup.sync_id}: cross-boutique access denied")
                continue
            if existing:
                existing.name = sup.name
                existing.contact_person = sup.contact_person
                existing.phone = sup.phone
                existing.email = sup.email
                existing.address = sup.address
                existing.balance = sup.balance
                existing.notes = sup.notes
                existing.updated_at = sup.updated_at or now
            else:
                check_quota_limit(db, boutique_id, "max_suppliers", sup_count)
                sup_count += 1
                db.add(Supplier(
                    sync_id=sup.sync_id,
                    boutique_id=boutique_id,
                    name=sup.name,
                    contact_person=sup.contact_person,
                    phone=sup.phone,
                    email=sup.email,
                    address=sup.address,
                    balance=sup.balance,
                    notes=sup.notes,
                    user_id=sup.user_id or current_user.id,
                    user_name=sup.user_name or (current_user.full_name or current_user.username),
                    created_at=sup.updated_at or now,
                    updated_at=sup.updated_at or now,
                ))
            synced_uuids.append(sup.sync_id)
        except HTTPException:
            raise
        except Exception as exc:
            errors.append(f"Supplier {sup.sync_id}: {exc}")

    cl_count = (
        db.query(Client).filter(Client.boutique_id == boutique_id, Client.deleted_at.is_(None)).count()
    )
    for cl in payload.clients:
        try:
            existing = db.query(Client).filter(Client.sync_id == cl.sync_id).first()
            if belongs_to_other_boutique(existing, boutique_id):
                errors.append(f"Client {cl.sync_id}: cross-boutique access denied")
                continue
            cl_uid = cl.user_id or current_user.id
            cl_uname = cl.user_name or (current_user.full_name or current_user.username)
            if existing:
                existing.name = cl.name
                existing.phone = cl.phone
                existing.email = cl.email
                existing.address = cl.address
                existing.balance = cl.balance
                existing.notes = cl.notes
                existing.user_id = cl_uid
                existing.user_name = cl_uname
                existing.updated_at = cl.updated_at or now
            else:
                check_quota_limit(db, boutique_id, "max_clients", cl_count)
                cl_count += 1
                db.add(Client(
                    sync_id=cl.sync_id,
                    boutique_id=boutique_id,
                    name=cl.name,
                    phone=cl.phone,
                    email=cl.email,
                    address=cl.address,
                    balance=cl.balance,
                    notes=cl.notes,
                    user_id=cl_uid,
                    user_name=cl_uname,
                    created_at=cl.updated_at or now,
                    updated_at=cl.updated_at or now,
                ))
                db.add(AuditLog(
                    id=f"audit-{cl.sync_id}",
                    boutique_id=boutique_id,
                    user_id=cl_uid,
                    user_name=cl_uname,
                    action="CLIENT_CREATE",
                    entity_type="client",
                    entity_id=cl.sync_id,
                    details={"name": cl.name, "phone": cl.phone, "balance": cl.balance},
                    created_at=cl.updated_at or now,
                ))
            synced_uuids.append(cl.sync_id)
        except HTTPException:
            raise
        except Exception as exc:
            errors.append(f"Client {cl.sync_id}: {exc}")
