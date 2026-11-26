from datetime import datetime, timezone
from typing import Dict, List, Tuple
import uuid
from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models import Approvisionnement, AuditLog, Client, Product, Vente, VenteItem
from app.schemas.sync import SyncPushRequest, SyncPushResult
from app.services.stock_service import adjust_magasin_stock
from app.services.sync_push_master_service import belongs_to_other_boutique, push_master_entities
from app.services.sync_push_operations_service import push_decaissements_approvisionnements_and_audits
from app.services.tenant_context_service import TenantContext, resolve_operational_magasin


def _collect_batch_movements(db: Session, payload: SyncPushRequest):
    vente_qty_deltas: Dict[str, float] = {}
    appro_qty_deltas: Dict[str, float] = {}
    credit_vente_clients: Dict[str, Tuple[float, datetime]] = {}
    credit_appro_suppliers: Dict[str, Tuple[float, datetime]] = {}

    if payload.is_initial_sync:
        return vente_qty_deltas, appro_qty_deltas, credit_vente_clients, credit_appro_suppliers

    v_ids = [v.sync_id for v in payload.ventes]
    existing_ventes = {
        r[0] for r in db.query(Vente.sync_id).filter(Vente.sync_id.in_(v_ids)).all()
    } if v_ids else set()
    for v in payload.ventes:
        if v.sync_id in existing_ventes or v.deleted_at is not None:
            continue
        for item in v.items:
            if item.product_sync_id:
                vente_qty_deltas[item.product_sync_id] = vente_qty_deltas.get(item.product_sync_id, 0.0) + float(item.quantity)
        if v.client_sync_id and v.paid_amount < v.total_amount:
            credit = float(v.total_amount) - float(v.paid_amount)
            prev = credit_vente_clients.get(v.client_sync_id)
            v_dt = v.updated_at or v.created_at
            credit_vente_clients[v.client_sync_id] = (
                (prev[0] if prev else 0.0) + credit,
                max(prev[1], v_dt) if prev else v_dt,
            )

    a_ids = [a.sync_id for a in payload.approvisionnements]
    existing_appros = {
        r[0] for r in db.query(Approvisionnement.sync_id).filter(Approvisionnement.sync_id.in_(a_ids)).all()
    } if a_ids else set()
    for a in payload.approvisionnements:
        if a.sync_id in existing_appros or a.deleted_at is not None:
            continue
        if a.product_sync_id:
            appro_qty_deltas[a.product_sync_id] = appro_qty_deltas.get(a.product_sync_id, 0.0) + float(a.quantity)
        paid = a.paid_amount if a.paid_amount is not None else (
            float(a.total_cost) if (a.payment_status or "").lower().startswith("pay") else 0.0
        )
        debt = max(0.0, float(a.total_cost) - float(paid))
        if a.supplier_sync_id and debt > 0:
            prev = credit_appro_suppliers.get(a.supplier_sync_id)
            a_dt = a.updated_at or a.date
            credit_appro_suppliers[a.supplier_sync_id] = (
                (prev[0] if prev else 0.0) + debt,
                max(prev[1], a_dt) if prev else a_dt,
            )

    return vente_qty_deltas, appro_qty_deltas, credit_vente_clients, credit_appro_suppliers


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


def push_boutique_changes(
    db: Session,
    ctx: TenantContext,
    payload: SyncPushRequest,
) -> SyncPushResult:
    """Reçoit un lot hors-ligne strictement cloisonné à ctx.boutique.id."""
    boutique_id = ctx.boutique.id
    current_user = ctx.user
    now = datetime.now(timezone.utc)
    synced_uuids: List[str] = []
    errors: List[str] = []
    quota_exceptions: List[HTTPException] = []

    v_deltas, a_deltas, cv_clients, ca_suppliers = _collect_batch_movements(db, payload)
    clients_overwritten, suppliers_overwritten = push_master_entities(
        db, ctx, payload, now, synced_uuids, errors,
        vente_qty_deltas=v_deltas, appro_qty_deltas=a_deltas,
        credit_vente_clients=cv_clients, credit_appro_suppliers=ca_suppliers,
        quota_exceptions=quota_exceptions,
    )

    for v in payload.ventes:
        try:
            with db.begin_nested():
                existing = db.query(Vente).filter(Vente.sync_id == v.sync_id).first()
                if belongs_to_other_boutique(existing, boutique_id):
                    errors.append(f"Vente {v.sync_id}: cross-boutique access denied")
                    continue
                if existing:
                    existing.paid_amount = v.paid_amount
                    existing.discount_amount = v.discount_amount
                    existing.payment_method = v.payment_method
                    existing.notes = v.notes
                    existing.updated_at = v.updated_at or now
                    if v.deleted_at is not None or v.status == "cancelled":
                        existing.deleted_at = v.deleted_at or now
                        existing.status = "cancelled"
                    else:
                        existing.status = v.status
                    synced_uuids.append(v.sync_id)
                    continue

                client_ref = v.client_sync_id
                if client_ref:
                    cl_ok = db.query(Client.sync_id).filter(
                        Client.sync_id == client_ref, Client.boutique_id == boutique_id
                    ).first()
                    if not cl_ok:
                        errors.append(f"Vente {v.sync_id}: unknown client in boutique")
                        continue

                v_mag = resolve_operational_magasin(
                    db, ctx, body_magasin_id=v.magasin_id, allow_warehouse=False, allow_single_assigned_fallback=True
                )
                v_uid = v.user_id or current_user.id
                v_uname = v.user_name or (current_user.full_name or current_user.username)
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
                                quantity_delta=-item.quantity, enforce_sufficient=False,
                                movement_type="sale", reference_type="vente", reference_id=v.sync_id,
                                reason=f"Sync vente {resolved_ticket}", user_id=v_uid, user_name=v_uname,
                            )

                if (
                    not payload.is_initial_sync
                    and v.deleted_at is None
                    and client_ref
                    and client_ref not in clients_overwritten
                    and v.paid_amount < v.total_amount
                ):
                    target_client = db.query(Client).filter(
                        Client.sync_id == client_ref, Client.boutique_id == boutique_id
                    ).first()
                    if target_client:
                        target_client.balance += v.total_amount - v.paid_amount
                        target_client.updated_at = now

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

    push_decaissements_approvisionnements_and_audits(
        db, ctx, payload, now, synced_uuids, errors, suppliers_overwritten=suppliers_overwritten
    )
    if not synced_uuids and quota_exceptions:
        db.rollback()
        raise quota_exceptions[0]
    db.commit()
    return SyncPushResult(
        synced_count=len(synced_uuids), rejected_count=len(errors), synced_uuids=synced_uuids, errors=errors,
    )
