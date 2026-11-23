from datetime import datetime, timezone
from typing import List
from sqlalchemy.orm import Session
from app.models import (
    Product, Client, Vente, VenteItem, Approvisionnement, Decaissement, AuditLog
)
from app.schemas.sync import SyncPushRequest, SyncPushResult
from app.services.sync_push_master_service import (
    belongs_to_other_boutique,
    push_master_entities,
)
from app.services.tenant_context_service import TenantContext


def push_boutique_changes(
    db: Session,
    ctx: TenantContext,
    payload: SyncPushRequest,
) -> SyncPushResult:
    """Reçoit un lot hors-ligne strictement cloisonné à ctx.boutique.id."""
    boutique_id = ctx.boutique.id
    magasin_id = ctx.requested_magasin_id
    current_user = ctx.user
    now = datetime.now(timezone.utc)
    synced_uuids: List[str] = []
    errors: List[str] = []

    push_master_entities(db, ctx, payload, now, synced_uuids, errors)

    for v in payload.ventes:
        try:
            existing = db.query(Vente).filter(Vente.sync_id == v.sync_id).first()
            if belongs_to_other_boutique(existing, boutique_id):
                errors.append(f"Vente {v.sync_id}: cross-boutique access denied")
                continue
            if existing:
                synced_uuids.append(v.sync_id)
                continue

            client_ref = v.client_sync_id
            if client_ref:
                cl_ok = (
                    db.query(Client.sync_id)
                    .filter(Client.sync_id == client_ref, Client.boutique_id == boutique_id)
                    .first()
                )
                if not cl_ok:
                    errors.append(f"Vente {v.sync_id}: unknown client in boutique")
                    continue

            v_uid = v.user_id or current_user.id
            v_uname = v.user_name or (current_user.full_name or current_user.username)
            db.add(Vente(
                sync_id=v.sync_id,
                boutique_id=boutique_id,
                magasin_id=magasin_id,
                ticket_number=v.ticket_number,
                client_sync_id=client_ref,
                client_name=v.client_name,
                user_id=v_uid,
                user_name=v_uname,
                total_amount=v.total_amount,
                paid_amount=v.paid_amount,
                discount_amount=v.discount_amount,
                payment_method=v.payment_method,
                notes=v.notes,
                created_at=v.created_at,
                updated_at=v.updated_at or v.created_at,
            ))

            for item in v.items:
                db.add(VenteItem(
                    sync_id=item.sync_id or None,
                    vente_sync_id=v.sync_id,
                    product_sync_id=item.product_sync_id,
                    product_name=item.product_name,
                    quantity=item.quantity,
                    unit_price=item.unit_price,
                    cost_price=item.cost_price,
                    total=item.total,
                ))
                if not payload.is_initial_sync and item.product_sync_id:
                    prod = db.query(Product).filter(
                        Product.sync_id == item.product_sync_id, Product.boutique_id == boutique_id
                    ).first()
                    if prod:
                        prod.stock -= item.quantity
                        prod.updated_at = now

            if not payload.is_initial_sync and client_ref and v.paid_amount < v.total_amount:
                target_client = db.query(Client).filter(
                    Client.sync_id == client_ref, Client.boutique_id == boutique_id
                ).first()
                if target_client:
                    target_client.balance += v.total_amount - v.paid_amount
                    target_client.updated_at = now

            db.add(AuditLog(
                id=f"audit-{v.sync_id}",
                boutique_id=boutique_id,
                user_id=v_uid,
                user_name=v_uname,
                action="SALE_CREATE",
                entity_type="vente",
                entity_id=v.sync_id,
                details={
                    "ticket_number": v.ticket_number,
                    "total_amount": v.total_amount,
                    "paid_amount": v.paid_amount,
                    "client_name": v.client_name,
                    "payment_method": v.payment_method,
                    "item_count": len(v.items),
                },
                created_at=v.created_at,
            ))
            synced_uuids.append(v.sync_id)
        except Exception as exc:
            errors.append(f"Vente {v.sync_id}: {exc}")

    for d in payload.decaissements:
        try:
            existing = db.query(Decaissement).filter(Decaissement.sync_id == d.sync_id).first()
            if belongs_to_other_boutique(existing, boutique_id):
                errors.append(f"Decaissement {d.sync_id}: cross-boutique access denied")
                continue
            d_uid = d.user_id or current_user.id
            d_uname = d.user_name or (current_user.full_name or current_user.username)
            if not existing:
                db.add(Decaissement(
                    sync_id=d.sync_id,
                    boutique_id=boutique_id,
                    magasin_id=magasin_id,
                    title=d.title,
                    amount=d.amount,
                    category=d.category,
                    beneficiary=d.beneficiary,
                    payment_method=d.payment_method,
                    date=d.date,
                    notes=d.notes,
                    user_id=d_uid,
                    user_name=d_uname,
                    created_at=d.date,
                    updated_at=d.updated_at or d.date,
                ))
                db.add(AuditLog(
                    id=f"audit-{d.sync_id}",
                    boutique_id=boutique_id,
                    user_id=d_uid,
                    user_name=d_uname,
                    action="EXPENSE_CREATE",
                    entity_type="decaissement",
                    entity_id=d.sync_id,
                    details={"title": d.title, "amount": d.amount, "category": d.category, "beneficiary": d.beneficiary},
                    created_at=d.date,
                ))
            synced_uuids.append(d.sync_id)
        except Exception as exc:
            errors.append(f"Decaissement {d.sync_id}: {exc}")

    for a in payload.approvisionnements:
        try:
            existing = db.query(Approvisionnement).filter(Approvisionnement.sync_id == a.sync_id).first()
            if belongs_to_other_boutique(existing, boutique_id):
                errors.append(f"Approvisionnement {a.sync_id}: cross-boutique access denied")
                continue
            a_uid = a.user_id or current_user.id
            a_uname = a.user_name or (current_user.full_name or current_user.username)
            if not existing:
                db.add(Approvisionnement(
                    sync_id=a.sync_id,
                    boutique_id=boutique_id,
                    magasin_id=magasin_id,
                    supplier_sync_id=a.supplier_sync_id,
                    supplier_name=a.supplier_name,
                    product_sync_id=a.product_sync_id,
                    product_name=a.product_name,
                    quantity=a.quantity,
                    unit_cost=a.unit_cost,
                    total_cost=a.total_cost,
                    payment_status=a.payment_status,
                    date=a.date,
                    notes=a.notes,
                    user_id=a_uid,
                    user_name=a_uname,
                    created_at=a.date,
                    updated_at=a.updated_at or a.date,
                ))
                db.add(AuditLog(
                    id=f"audit-{a.sync_id}",
                    boutique_id=boutique_id,
                    user_id=a_uid,
                    user_name=a_uname,
                    action="STOCK_SUPPLY",
                    entity_type="approvisionnement",
                    entity_id=a.sync_id,
                    details={"product_name": a.product_name, "quantity": a.quantity, "unit_cost": a.unit_cost, "total_cost": a.total_cost},
                    created_at=a.date,
                ))
                if not payload.is_initial_sync and a.product_sync_id:
                    prod = db.query(Product).filter(
                        Product.sync_id == a.product_sync_id, Product.boutique_id == boutique_id
                    ).first()
                    if prod:
                        prod.stock += a.quantity
                        prod.updated_at = now
            synced_uuids.append(a.sync_id)
        except Exception as exc:
            errors.append(f"Approvisionnement {a.sync_id}: {exc}")

    for al in payload.audit_logs:
        try:
            existing_al = db.query(AuditLog).filter(AuditLog.id == al.sync_id).first()
            if existing_al and existing_al.boutique_id != boutique_id:
                errors.append(f"AuditLog {al.sync_id}: cross-boutique access denied")
                continue
            if not existing_al:
                db.add(AuditLog(
                    id=al.sync_id,
                    boutique_id=boutique_id,
                    user_id=al.user_id or current_user.id,
                    user_name=al.user_name or (current_user.full_name or current_user.username),
                    action=al.action,
                    entity_type=al.entity_type,
                    entity_id=al.entity_id,
                    details=al.details,
                    created_at=al.created_at,
                ))
            synced_uuids.append(al.sync_id)
        except Exception as exc:
            errors.append(f"AuditLog {al.sync_id}: {exc}")

    db.commit()
    return SyncPushResult(
        synced_count=len(synced_uuids),
        rejected_count=len(errors),
        synced_uuids=synced_uuids,
        errors=errors,
    )
