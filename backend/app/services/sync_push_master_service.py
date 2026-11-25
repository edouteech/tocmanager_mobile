from datetime import datetime, timezone
from typing import Dict, List, Optional, Set, Tuple
from fastapi import HTTPException
from sqlalchemy.orm import Session
from app.models import AuditLog, Category, Client, Product, Supplier
from app.schemas.sync import SyncPushRequest
from app.services.entitlements import check_quota_limit
from app.services.stock_service import initialize_product_magasin_stocks
from app.services.sync_push_helpers import (
    apply_pushed_product_stock,
    belongs_to_other_boutique,
    should_apply_incoming_balance as _should_apply_incoming_balance,
)
from app.services.tenant_context_service import TenantContext


def push_master_entities(
    db: Session,
    ctx: TenantContext,
    payload: SyncPushRequest,
    now: datetime,
    synced_uuids: List[str],
    errors: List[str],
    vente_qty_deltas: Optional[Dict[str, float]] = None,
    appro_qty_deltas: Optional[Dict[str, float]] = None,
    credit_vente_clients: Optional[Dict[str, Tuple[float, datetime]]] = None,
    credit_appro_suppliers: Optional[Dict[str, Tuple[float, datetime]]] = None,
    quota_exceptions: Optional[List[HTTPException]] = None,
) -> Tuple[Set[str], Set[str]]:
    """Sync categories, products, suppliers, and clients for ctx.boutique.id."""
    boutique_id = ctx.boutique.id
    current_user = ctx.user
    v_deltas = vente_qty_deltas or {}
    a_deltas = appro_qty_deltas or {}
    cv_clients = credit_vente_clients or {}
    ca_suppliers = credit_appro_suppliers or {}
    clients_overwritten: Set[str] = set()
    suppliers_overwritten: Set[str] = set()

    for cat in payload.categories:
        try:
            with db.begin_nested():
                existing = db.query(Category).filter(Category.sync_id == cat.sync_id).first()
                if belongs_to_other_boutique(existing, boutique_id):
                    errors.append(f"Category {cat.sync_id}: cross-boutique access denied")
                    continue
                if existing:
                    existing.name = cat.name
                    existing.description = cat.description
                    existing.color = cat.color
                    existing.icon = cat.icon
                    existing.deleted_at = cat.deleted_at
                    existing.updated_at = cat.updated_at or now
                else:
                    db.add(Category(
                        sync_id=cat.sync_id, boutique_id=boutique_id, name=cat.name,
                        description=cat.description, color=cat.color, icon=cat.icon,
                        created_at=cat.updated_at or now, updated_at=cat.updated_at or now,
                        deleted_at=cat.deleted_at,
                    ))
                synced_uuids.append(cat.sync_id)
        except Exception as exc:
            errors.append(f"Category {cat.sync_id}: {exc}")

    prod_count = db.query(Product).filter(Product.boutique_id == boutique_id, Product.deleted_at.is_(None)).count()
    for prod in payload.products:
        try:
            with db.begin_nested():
                existing = db.query(Product).filter(Product.sync_id == prod.sync_id).first()
                if belongs_to_other_boutique(existing, boutique_id):
                    errors.append(f"Product {prod.sync_id}: cross-boutique access denied")
                    continue
                if prod.category_sync_id:
                    cat_ok = db.query(Category.sync_id).filter(
                        Category.sync_id == prod.category_sync_id, Category.boutique_id == boutique_id
                    ).first()
                    if not cat_ok:
                        errors.append(f"Product {prod.sync_id}: unknown category in boutique")
                        continue
                touched = (prod.sync_id in v_deltas) or (prod.sync_id in a_deltas)
                if existing:
                    existing.name = prod.name
                    existing.category_sync_id = prod.category_sync_id
                    existing.price = prod.price
                    existing.cost_price = prod.cost_price
                    existing.average_cost_price = prod.average_cost_price or 0.0
                    if payload.is_initial_sync or not touched:
                        apply_pushed_product_stock(
                            db, ctx, existing, prod.stock, prod.min_stock, prod.magasin_id
                        )
                    existing.min_stock = prod.min_stock
                    existing.barcode = prod.barcode
                    existing.unit = prod.unit
                    existing.is_active = prod.is_active
                    existing.deleted_at = prod.deleted_at
                    existing.updated_at = prod.updated_at or now
                else:
                    if prod.deleted_at is None:
                        check_quota_limit(db, boutique_id, "max_products", prod_count)
                        prod_count += 1
                    net_delta = a_deltas.get(prod.sync_id, 0.0) - v_deltas.get(prod.sync_id, 0.0)
                    init_stock = float(prod.stock) if payload.is_initial_sync else max(0.0, float(prod.stock) - net_delta)
                    new_prod = Product(
                        sync_id=prod.sync_id, boutique_id=boutique_id, name=prod.name,
                        category_sync_id=prod.category_sync_id, price=prod.price, cost_price=prod.cost_price,
                        average_cost_price=prod.average_cost_price or 0.0, stock=init_stock, min_stock=prod.min_stock,
                        barcode=prod.barcode, unit=prod.unit or "pièce", is_active=prod.is_active,
                        created_at=prod.updated_at or now, updated_at=prod.updated_at or now,
                        deleted_at=prod.deleted_at,
                    )
                    db.add(new_prod)
                    db.flush()
                    initialize_product_magasin_stocks(
                        db=db, boutique_id=boutique_id, product=new_prod,
                        target_magasin_id=prod.magasin_id or ctx.requested_magasin_id,
                        initial_stock=init_stock,
                    )
                synced_uuids.append(prod.sync_id)
        except HTTPException as http_exc:
            if quota_exceptions is not None:
                quota_exceptions.append(http_exc)
            detail = http_exc.detail
            msg = detail.get("message") or detail.get("error") if isinstance(detail, dict) else str(detail)
            errors.append(f"Product {prod.sync_id}: {msg}")
        except Exception as exc:
            errors.append(f"Product {prod.sync_id}: {exc}")

    sup_count = db.query(Supplier).filter(Supplier.boutique_id == boutique_id, Supplier.deleted_at.is_(None)).count()
    for sup in payload.suppliers:
        try:
            with db.begin_nested():
                existing = db.query(Supplier).filter(Supplier.sync_id == sup.sync_id).first()
                if belongs_to_other_boutique(existing, boutique_id):
                    errors.append(f"Supplier {sup.sync_id}: cross-boutique access denied")
                    continue
                tx_info = ca_suppliers.get(sup.sync_id)
                if existing:
                    existing.name = sup.name
                    existing.contact_person = sup.contact_person
                    existing.phone = sup.phone
                    existing.email = sup.email
                    existing.address = sup.address
                    existing.notes = sup.notes
                    existing.deleted_at = sup.deleted_at
                    existing.updated_at = sup.updated_at or now
                    if payload.is_initial_sync or tx_info is None:
                        existing.balance = sup.balance
                    elif _should_apply_incoming_balance(sup.updated_at, tx_info[1]):
                        existing.balance = sup.balance
                        suppliers_overwritten.add(sup.sync_id)
                else:
                    if sup.deleted_at is None:
                        check_quota_limit(db, boutique_id, "max_suppliers", sup_count)
                        sup_count += 1
                    init_bal = float(sup.balance) if (payload.is_initial_sync or tx_info is None) else max(0.0, float(sup.balance) - tx_info[0])
                    db.add(Supplier(
                        sync_id=sup.sync_id, boutique_id=boutique_id, name=sup.name,
                        contact_person=sup.contact_person, phone=sup.phone, email=sup.email,
                        address=sup.address, balance=init_bal, notes=sup.notes,
                        user_id=sup.user_id or current_user.id,
                        user_name=sup.user_name or (current_user.full_name or current_user.username),
                        created_at=sup.updated_at or now, updated_at=sup.updated_at or now,
                        deleted_at=sup.deleted_at,
                    ))
                synced_uuids.append(sup.sync_id)
        except HTTPException as http_exc:
            if quota_exceptions is not None:
                quota_exceptions.append(http_exc)
            detail = http_exc.detail
            msg = detail.get("message") or detail.get("error") if isinstance(detail, dict) else str(detail)
            errors.append(f"Supplier {sup.sync_id}: {msg}")
        except Exception as exc:
            errors.append(f"Supplier {sup.sync_id}: {exc}")

    cl_count = db.query(Client).filter(Client.boutique_id == boutique_id, Client.deleted_at.is_(None)).count()
    for cl in payload.clients:
        try:
            with db.begin_nested():
                existing = db.query(Client).filter(Client.sync_id == cl.sync_id).first()
                if belongs_to_other_boutique(existing, boutique_id):
                    errors.append(f"Client {cl.sync_id}: cross-boutique access denied")
                    continue
                cl_uid = cl.user_id or current_user.id
                cl_uname = cl.user_name or (current_user.full_name or current_user.username)
                tx_info = cv_clients.get(cl.sync_id)
                if existing:
                    existing.name = cl.name
                    existing.phone = cl.phone
                    existing.email = cl.email
                    existing.address = cl.address
                    existing.notes = cl.notes
                    existing.user_id = cl_uid
                    existing.user_name = cl_uname
                    existing.deleted_at = cl.deleted_at
                    existing.updated_at = cl.updated_at or now
                    if payload.is_initial_sync or tx_info is None:
                        existing.balance = cl.balance
                    elif _should_apply_incoming_balance(cl.updated_at, tx_info[1]):
                        existing.balance = cl.balance
                        clients_overwritten.add(cl.sync_id)
                else:
                    if cl.deleted_at is None:
                        check_quota_limit(db, boutique_id, "max_clients", cl_count)
                        cl_count += 1
                    init_bal = float(cl.balance) if (payload.is_initial_sync or tx_info is None) else max(0.0, float(cl.balance) - tx_info[0])
                    db.add(Client(
                        sync_id=cl.sync_id, boutique_id=boutique_id, name=cl.name,
                        phone=cl.phone, email=cl.email, address=cl.address,
                        balance=init_bal, notes=cl.notes, user_id=cl_uid, user_name=cl_uname,
                        created_at=cl.updated_at or now, updated_at=cl.updated_at or now,
                        deleted_at=cl.deleted_at,
                    ))
                    if not db.query(AuditLog.id).filter(AuditLog.id == f"audit-{cl.sync_id}").first():
                        db.add(AuditLog(
                            id=f"audit-{cl.sync_id}", boutique_id=boutique_id, user_id=cl_uid,
                            user_name=cl_uname, action="CLIENT_CREATE", entity_type="client",
                            entity_id=cl.sync_id, details={"name": cl.name, "phone": cl.phone, "balance": init_bal},
                            created_at=cl.updated_at or now,
                        ))
                synced_uuids.append(cl.sync_id)
        except HTTPException as http_exc:
            if quota_exceptions is not None:
                quota_exceptions.append(http_exc)
            detail = http_exc.detail
            msg = detail.get("message") or detail.get("error") if isinstance(detail, dict) else str(detail)
            errors.append(f"Client {cl.sync_id}: {msg}")
        except Exception as exc:
            errors.append(f"Client {cl.sync_id}: {exc}")

    return clients_overwritten, suppliers_overwritten
