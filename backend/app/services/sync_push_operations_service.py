from datetime import datetime
from typing import List, Optional, Set
from sqlalchemy.orm import Session

from app.models import Approvisionnement, AuditLog, Decaissement, Product, Supplier
from app.schemas.sync import SyncPushRequest
from app.services.stock_service import adjust_magasin_stock
from app.services.sync_push_master_service import belongs_to_other_boutique
from app.services.tenant_context_service import TenantContext, resolve_operational_magasin


def push_decaissements_approvisionnements_and_audits(
    db: Session,
    ctx: TenantContext,
    payload: SyncPushRequest,
    now: datetime,
    synced_uuids: List[str],
    errors: List[str],
    suppliers_overwritten: Optional[Set[str]] = None,
) -> None:
    """Sync offline decaissements, approvisionnements, and audit logs for ctx.boutique."""
    boutique_id = ctx.boutique.id
    current_user = ctx.user
    sup_overwritten = suppliers_overwritten or set()

    for d in payload.decaissements:
        try:
            with db.begin_nested():
                existing = db.query(Decaissement).filter(Decaissement.sync_id == d.sync_id).first()
                if belongs_to_other_boutique(existing, boutique_id):
                    errors.append(f"Decaissement {d.sync_id}: cross-boutique access denied")
                    continue
                d_uid = d.user_id or current_user.id
                d_uname = d.user_name or (current_user.full_name or current_user.username)
                if existing:
                    existing.title = d.title
                    existing.amount = d.amount
                    existing.category = d.category
                    existing.beneficiary = d.beneficiary
                    existing.payment_method = d.payment_method
                    existing.date = d.date
                    existing.notes = d.notes
                    existing.deleted_at = d.deleted_at
                    existing.updated_at = d.updated_at or now
                else:
                    d_mag = resolve_operational_magasin(
                        db, ctx, body_magasin_id=d.magasin_id, allow_warehouse=True, allow_single_assigned_fallback=True
                    )
                    db.add(Decaissement(
                        sync_id=d.sync_id, boutique_id=boutique_id, magasin_id=d_mag.id,
                        title=d.title, amount=d.amount, category=d.category, beneficiary=d.beneficiary,
                        payment_method=d.payment_method, date=d.date, notes=d.notes,
                        user_id=d_uid, user_name=d_uname, created_at=d.date,
                        updated_at=d.updated_at or d.date, deleted_at=d.deleted_at,
                    ))
                    if not db.query(AuditLog.id).filter(AuditLog.id == f"audit-{d.sync_id}").first():
                        db.add(AuditLog(
                            id=f"audit-{d.sync_id}", boutique_id=boutique_id, user_id=d_uid, user_name=d_uname,
                            action="EXPENSE_CREATE", entity_type="decaissement", entity_id=d.sync_id,
                            details={"title": d.title, "amount": d.amount, "category": d.category, "beneficiary": d.beneficiary},
                            created_at=d.date,
                        ))
                synced_uuids.append(d.sync_id)
        except Exception as exc:
            errors.append(f"Decaissement {d.sync_id}: {exc}")

    for a in payload.approvisionnements:
        try:
            with db.begin_nested():
                existing = db.query(Approvisionnement).filter(Approvisionnement.sync_id == a.sync_id).first()
                if belongs_to_other_boutique(existing, boutique_id):
                    errors.append(f"Approvisionnement {a.sync_id}: cross-boutique access denied")
                    continue
                a_uid = a.user_id or current_user.id
                a_uname = a.user_name or (current_user.full_name or current_user.username)
                if existing:
                    existing.supplier_sync_id = a.supplier_sync_id
                    existing.supplier_name = a.supplier_name
                    existing.product_sync_id = a.product_sync_id
                    existing.product_name = a.product_name
                    existing.quantity = a.quantity
                    existing.unit_cost = a.unit_cost
                    existing.total_cost = a.total_cost
                    existing.payment_status = a.payment_status
                    existing.date = a.date
                    existing.notes = a.notes
                    existing.deleted_at = a.deleted_at
                    existing.updated_at = a.updated_at or now
                else:
                    a_mag = resolve_operational_magasin(
                        db, ctx, body_magasin_id=a.magasin_id, allow_warehouse=True, allow_single_assigned_fallback=True
                    )
                    db.add(Approvisionnement(
                        sync_id=a.sync_id, boutique_id=boutique_id, magasin_id=a_mag.id,
                        supplier_sync_id=a.supplier_sync_id, supplier_name=a.supplier_name,
                        product_sync_id=a.product_sync_id, product_name=a.product_name,
                        quantity=a.quantity, unit_cost=a.unit_cost, total_cost=a.total_cost,
                        payment_status=a.payment_status, date=a.date, notes=a.notes,
                        user_id=a_uid, user_name=a_uname, created_at=a.date,
                        updated_at=a.updated_at or a.date, deleted_at=a.deleted_at,
                    ))
                    if not db.query(AuditLog.id).filter(AuditLog.id == f"audit-{a.sync_id}").first():
                        db.add(AuditLog(
                            id=f"audit-{a.sync_id}", boutique_id=boutique_id, user_id=a_uid, user_name=a_uname,
                            action="STOCK_SUPPLY", entity_type="approvisionnement", entity_id=a.sync_id,
                            details={"product_name": a.product_name, "quantity": a.quantity, "unit_cost": a.unit_cost, "total_cost": a.total_cost},
                            created_at=a.date,
                        ))
                    if not payload.is_initial_sync and a.deleted_at is None:
                        if a.product_sync_id:
                            prod = db.query(Product).filter(
                                Product.sync_id == a.product_sync_id, Product.boutique_id == boutique_id
                            ).first()
                            if prod:
                                adjust_magasin_stock(
                                    db=db, boutique_id=boutique_id, magasin_id=a_mag.id, product=prod,
                                    quantity_delta=a.quantity, enforce_sufficient=False, new_unit_cost=a.unit_cost,
                                    movement_type="supply", reference_type="approvisionnement", reference_id=a.sync_id,
                                    reason=f"Sync réception {a.supplier_name or ''}".strip(), user_id=a_uid, user_name=a_uname,
                                )
                        paid = a.paid_amount if a.paid_amount is not None else (
                            float(a.total_cost) if (a.payment_status or "").lower().startswith("pay") else 0.0
                        )
                        debt = max(0.0, float(a.total_cost) - float(paid))
                        if a.supplier_sync_id and debt > 0 and a.supplier_sync_id not in sup_overwritten:
                            sup = db.query(Supplier).filter(
                                Supplier.sync_id == a.supplier_sync_id, Supplier.boutique_id == boutique_id
                            ).first()
                            if sup:
                                sup.balance = round(float(sup.balance or 0.0) + debt, 2)
                                sup.updated_at = now
                synced_uuids.append(a.sync_id)
        except Exception as exc:
            errors.append(f"Approvisionnement {a.sync_id}: {exc}")

    for al in payload.audit_logs:
        try:
            with db.begin_nested():
                existing_al = db.query(AuditLog).filter(AuditLog.id == al.sync_id).first()
                if existing_al and existing_al.boutique_id != boutique_id:
                    errors.append(f"AuditLog {al.sync_id}: cross-boutique access denied")
                    continue
                if not existing_al:
                    db.add(AuditLog(
                        id=al.sync_id, boutique_id=boutique_id,
                        user_id=al.user_id or current_user.id,
                        user_name=al.user_name or (current_user.full_name or current_user.username),
                        action=al.action, entity_type=al.entity_type, entity_id=al.entity_id,
                        details=al.details, created_at=al.created_at,
                    ))
                synced_uuids.append(al.sync_id)
        except Exception as exc:
            errors.append(f"AuditLog {al.sync_id}: {exc}")
