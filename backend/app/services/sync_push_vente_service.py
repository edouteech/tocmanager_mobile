from datetime import datetime
from typing import Dict, List, Set
import uuid
from sqlalchemy.orm import Session

from app.models import AuditLog, Client, Product, Vente, VenteItem
from app.schemas.sync import SyncPushRequest
from app.services.stock_service import adjust_magasin_stock
from app.services.sync_push_helpers import (
    adjust_client_credit_delta,
    belongs_to_other_boutique,
    is_stale_update,
)
from app.services.tenant_context_service import TenantContext, resolve_operational_magasin


def _resolve_unique_ticket_number(
    db: Session,
    boutique_id: str,
    ticket_number: str,
    vente_sync_id: str,
) -> str:
    conflict = (
        db.query(Vente.sync_id)
        .filter(
            Vente.boutique_id == boutique_id,
            Vente.ticket_number == ticket_number,
            Vente.sync_id != vente_sync_id,
        )
        .first()
    )
    if not conflict:
        return ticket_number
    suffix = vente_sync_id.replace("-", "")[:4].upper() or uuid.uuid4().hex[:4].upper()
    candidate = f"{ticket_number[:90]}-{suffix}"
    while (
        db.query(Vente.sync_id)
        .filter(Vente.boutique_id == boutique_id, Vente.ticket_number == candidate)
        .first()
    ):
        candidate = f"{ticket_number[:90]}-{uuid.uuid4().hex[:4].upper()}"
    return candidate


def _collect_item_quantities(items) -> Dict[str, float]:
    qty_map: Dict[str, float] = {}
    for it in items:
        if it.product_sync_id:
            qty_map[it.product_sync_id] = qty_map.get(it.product_sync_id, 0.0) + float(it.quantity or 0.0)
    return qty_map


def _apply_existing_vente_update(
    db: Session,
    ctx: TenantContext,
    payload: SyncPushRequest,
    existing: Vente,
    v,
    now: datetime,
    v_uid: str,
    v_uname: str,
    clients_balance_applied: Set[str],
) -> None:
    boutique_id = ctx.boutique.id
    was_cancelled = (existing.deleted_at is not None) or (existing.status == "cancelled")
    now_cancelled = (v.deleted_at is not None) or (v.status == "cancelled")
    old_credit = 0.0 if was_cancelled else max(0.0, float(existing.total_amount or 0.0) - float(existing.paid_amount or 0.0))
    old_client_ref = existing.client_sync_id
    mag_id = existing.magasin_id or ctx.requested_magasin_id
    old_items = db.query(VenteItem).filter(VenteItem.vente_sync_id == existing.sync_id).all()
    old_qty_by_prod = {} if was_cancelled else _collect_item_quantities(old_items)

    existing.client_sync_id = v.client_sync_id
    existing.client_name = v.client_name
    existing.total_amount = v.total_amount
    existing.paid_amount = v.paid_amount
    existing.discount_amount = v.discount_amount
    existing.payment_method = v.payment_method
    existing.notes = v.notes
    existing.updated_at = v.updated_at or now

    if now_cancelled:
        existing.deleted_at = v.deleted_at or now
        existing.status = "cancelled"
        if not payload.is_initial_sync and not was_cancelled:
            if mag_id:
                for prod_sync_id, qty in old_qty_by_prod.items():
                    if qty <= 0:
                        continue
                    prod = db.query(Product).filter(
                        Product.sync_id == prod_sync_id, Product.boutique_id == boutique_id
                    ).first()
                    if prod:
                        adjust_magasin_stock(
                            db=db, boutique_id=boutique_id, magasin_id=mag_id, product=prod,
                            quantity_delta=qty, enforce_sufficient=False, movement_type="return",
                            reference_type="vente", reference_id=v.sync_id,
                            reason=f"Sync annulation vente {existing.ticket_number}",
                            user_id=v_uid, user_name=v_uname,
                        )
            adjust_client_credit_delta(db, boutique_id, old_client_ref, -old_credit, clients_balance_applied, now)
        return

    existing.deleted_at = None
    existing.status = v.status or "completed"
    if v.items:
        db.query(VenteItem).filter(VenteItem.vente_sync_id == existing.sync_id).delete()
        for item in v.items:
            db.add(VenteItem(
                sync_id=item.sync_id or None, vente_sync_id=v.sync_id, product_sync_id=item.product_sync_id,
                product_name=item.product_name, quantity=item.quantity, unit_price=item.unit_price,
                cost_price=item.cost_price, total=item.total,
            ))
        new_qty_by_prod = _collect_item_quantities(v.items)
        if not payload.is_initial_sync and mag_id:
            for prod_sync_id in set(old_qty_by_prod) | set(new_qty_by_prod):
                stock_delta = round(old_qty_by_prod.get(prod_sync_id, 0.0) - new_qty_by_prod.get(prod_sync_id, 0.0), 4)
                if abs(stock_delta) <= 1e-6:
                    continue
                prod = db.query(Product).filter(
                    Product.sync_id == prod_sync_id, Product.boutique_id == boutique_id
                ).first()
                if prod:
                    adjust_magasin_stock(
                        db=db, boutique_id=boutique_id, magasin_id=mag_id, product=prod,
                        quantity_delta=stock_delta, enforce_sufficient=False, movement_type="adjustment",
                        reference_type="vente", reference_id=v.sync_id,
                        reason=f"Sync édition vente {existing.ticket_number}",
                        user_id=v_uid, user_name=v_uname,
                    )

    if not payload.is_initial_sync:
        new_credit = max(0.0, float(v.total_amount) - float(v.paid_amount))
        if old_client_ref == v.client_sync_id:
            adjust_client_credit_delta(db, boutique_id, old_client_ref, new_credit - old_credit, clients_balance_applied, now)
        else:
            adjust_client_credit_delta(db, boutique_id, old_client_ref, -old_credit, clients_balance_applied, now)
            adjust_client_credit_delta(db, boutique_id, v.client_sync_id, new_credit, clients_balance_applied, now)


def push_ventes(
    db: Session,
    ctx: TenantContext,
    payload: SyncPushRequest,
    now: datetime,
    synced_uuids: List[str],
    errors: List[str],
    clients_balance_applied: Set[str],
) -> None:
    """Sync offline ventes and edit/cancellation stock & credit deltas."""
    boutique_id = ctx.boutique.id
    current_user = ctx.user
    for v in payload.ventes:
        try:
            with db.begin_nested():
                existing = db.query(Vente).filter(Vente.sync_id == v.sync_id).first()
                if belongs_to_other_boutique(existing, boutique_id):
                    errors.append(f"Vente {v.sync_id}: cross-boutique access denied")
                    continue
                client_ref = v.client_sync_id
                if client_ref:
                    cl_ok = db.query(Client.sync_id).filter(
                        Client.sync_id == client_ref, Client.boutique_id == boutique_id
                    ).first()
                    if not cl_ok:
                        errors.append(f"Vente {v.sync_id}: unknown client in boutique")
                        continue

                v_uid = v.user_id or current_user.id
                v_uname = v.user_name or (current_user.full_name or current_user.username)
                if existing:
                    if is_stale_update(existing.updated_at, v.updated_at):
                        synced_uuids.append(v.sync_id)
                        continue
                    _apply_existing_vente_update(
                        db, ctx, payload, existing, v, now, v_uid, v_uname, clients_balance_applied
                    )
                    db.flush()
                    synced_uuids.append(v.sync_id)
                    continue

                v_mag = resolve_operational_magasin(
                    db, ctx, body_magasin_id=v.magasin_id, allow_warehouse=False, allow_single_assigned_fallback=True
                )
                v_status = "cancelled" if v.deleted_at is not None else v.status
                resolved_ticket = _resolve_unique_ticket_number(db, boutique_id, v.ticket_number, v.sync_id)
                db.add(Vente(
                    sync_id=v.sync_id, boutique_id=boutique_id, magasin_id=v_mag.id,
                    ticket_number=resolved_ticket, client_sync_id=client_ref, client_name=v.client_name,
                    user_id=v_uid, user_name=v_uname, total_amount=v.total_amount, paid_amount=v.paid_amount,
                    discount_amount=v.discount_amount, payment_method=v.payment_method, status=v_status,
                    notes=v.notes, created_at=v.created_at, updated_at=v.updated_at or v.created_at,
                    deleted_at=v.deleted_at,
                ))
                for item in v.items:
                    db.add(VenteItem(
                        sync_id=item.sync_id or None, vente_sync_id=v.sync_id, product_sync_id=item.product_sync_id,
                        product_name=item.product_name, quantity=item.quantity, unit_price=item.unit_price,
                        cost_price=item.cost_price, total=item.total,
                    ))
                    if not payload.is_initial_sync and v.deleted_at is None and item.product_sync_id:
                        prod = db.query(Product).filter(
                            Product.sync_id == item.product_sync_id, Product.boutique_id == boutique_id
                        ).first()
                        if prod:
                            adjust_magasin_stock(
                                db=db, boutique_id=boutique_id, magasin_id=v_mag.id, product=prod,
                                quantity_delta=-item.quantity, enforce_sufficient=False, movement_type="sale",
                                reference_type="vente", reference_id=v.sync_id,
                                reason=f"Sync vente {resolved_ticket}", user_id=v_uid, user_name=v_uname,
                            )
                if not payload.is_initial_sync and v.deleted_at is None and v.paid_amount < v.total_amount:
                    adjust_client_credit_delta(
                        db, boutique_id, client_ref, float(v.total_amount) - float(v.paid_amount),
                        clients_balance_applied, now,
                    )
                if not db.query(AuditLog.id).filter(AuditLog.id == f"audit-{v.sync_id}").first():
                    db.add(AuditLog(
                        id=f"audit-{v.sync_id}", boutique_id=boutique_id, user_id=v_uid, user_name=v_uname,
                        action="SALE_CREATE", entity_type="vente", entity_id=v.sync_id,
                        details={
                            "ticket_number": resolved_ticket, "total_amount": v.total_amount, "paid_amount": v.paid_amount,
                            "client_name": v.client_name, "payment_method": v.payment_method, "item_count": len(v.items),
                        },
                        created_at=v.created_at,
                    ))
                db.flush()
                synced_uuids.append(v.sync_id)
        except Exception as exc:
            errors.append(f"Vente {v.sync_id}: {exc}")
