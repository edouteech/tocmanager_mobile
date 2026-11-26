from datetime import datetime
from typing import List, Optional, Set
from sqlalchemy.orm import Session

from app.models import Approvisionnement, AuditLog, Decaissement, Product
from app.schemas.sync import SyncPushRequest
from app.services.stock_service import adjust_magasin_stock
from app.services.sync_push_helpers import (
    adjust_supplier_debt_delta,
    belongs_to_other_boutique,
    compute_appro_debt,
    is_stale_update,
    recompute_magasin_pamp,
)
from app.services.tenant_context_service import TenantContext, resolve_operational_magasin


def _apply_existing_appro_update(
    db: Session,
    ctx: TenantContext,
    payload: SyncPushRequest,
    existing: Approvisionnement,
    a,
    now: datetime,
    a_uid: str,
    a_uname: str,
    sup_applied: Set[str],
) -> None:
    boutique_id = ctx.boutique.id
    was_active = existing.deleted_at is None
    now_active = a.deleted_at is None
    old_qty = float(existing.quantity or 0.0) if was_active else 0.0
    old_prod_id = existing.product_sync_id
    old_sup_id = existing.supplier_sync_id
    old_debt = compute_appro_debt(existing.total_cost, None, existing.payment_status) if was_active else 0.0
    mag_id = existing.magasin_id or a.magasin_id or ctx.requested_magasin_id

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

    if payload.is_initial_sync:
        return

    new_qty = float(a.quantity or 0.0) if now_active else 0.0
    new_prod_id = a.product_sync_id
    if mag_id:
        if old_prod_id == new_prod_id and new_prod_id:
            prod = db.query(Product).filter(Product.sync_id == new_prod_id, Product.boutique_id == boutique_id).first()
            if prod:
                delta_qty = round(new_qty - old_qty, 4)
                if abs(delta_qty) > 1e-6:
                    adjust_magasin_stock(
                        db=db, boutique_id=boutique_id, magasin_id=mag_id, product=prod,
                        quantity_delta=delta_qty, enforce_sufficient=False, movement_type="adjustment",
                        reference_type="approvisionnement", reference_id=a.sync_id,
                        reason=f"Sync appro edit {a.supplier_name or ''}".strip(), user_id=a_uid, user_name=a_uname,
                    )
                recompute_magasin_pamp(db, boutique_id, mag_id, prod)
        else:
            if old_prod_id and old_qty > 0:
                old_prod = db.query(Product).filter(Product.sync_id == old_prod_id, Product.boutique_id == boutique_id).first()
                if old_prod:
                    adjust_magasin_stock(
                        db=db, boutique_id=boutique_id, magasin_id=mag_id, product=old_prod,
                        quantity_delta=-old_qty, enforce_sufficient=False, movement_type="adjustment",
                        reference_type="approvisionnement", reference_id=a.sync_id, user_id=a_uid, user_name=a_uname,
                    )
                    recompute_magasin_pamp(db, boutique_id, mag_id, old_prod)
            if new_prod_id and new_qty > 0:
                new_prod = db.query(Product).filter(Product.sync_id == new_prod_id, Product.boutique_id == boutique_id).first()
                if new_prod:
                    adjust_magasin_stock(
                        db=db, boutique_id=boutique_id, magasin_id=mag_id, product=new_prod,
                        quantity_delta=new_qty, enforce_sufficient=False, new_unit_cost=a.unit_cost,
                        movement_type="supply", reference_type="approvisionnement", reference_id=a.sync_id,
                        user_id=a_uid, user_name=a_uname,
                    )
                    recompute_magasin_pamp(db, boutique_id, mag_id, new_prod)

    new_debt = compute_appro_debt(a.total_cost, a.paid_amount, a.payment_status) if now_active else 0.0
    if old_sup_id == a.supplier_sync_id:
        adjust_supplier_debt_delta(db, boutique_id, old_sup_id, new_debt - old_debt, sup_applied, now)
    else:
        adjust_supplier_debt_delta(db, boutique_id, old_sup_id, -old_debt, sup_applied, now)
        adjust_supplier_debt_delta(db, boutique_id, a.supplier_sync_id, new_debt, sup_applied, now)


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
    sup_applied = suppliers_overwritten or set()

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
                    if is_stale_update(existing.updated_at, d.updated_at):
                        synced_uuids.append(d.sync_id)
                        continue
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
                    if is_stale_update(existing.updated_at, a.updated_at):
                        synced_uuids.append(a.sync_id)
                        continue
                    _apply_existing_appro_update(db, ctx, payload, existing, a, now, a_uid, a_uname, sup_applied)
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
                        debt = compute_appro_debt(a.total_cost, a.paid_amount, a.payment_status)
                        adjust_supplier_debt_delta(db, boutique_id, a.supplier_sync_id, debt, sup_applied, now)
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
