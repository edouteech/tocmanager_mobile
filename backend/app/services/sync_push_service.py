from datetime import datetime, timezone
from typing import Dict, List, Tuple
from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models import Approvisionnement, Vente
from app.schemas.sync import SyncPushRequest, SyncPushResult
from app.services.sync_push_master_service import push_master_entities
from app.services.sync_push_operations_service import push_decaissements_approvisionnements_and_audits
from app.services.sync_push_vente_service import push_ventes
from app.services.tenant_context_service import TenantContext


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


def push_boutique_changes(
    db: Session,
    ctx: TenantContext,
    payload: SyncPushRequest,
) -> SyncPushResult:
    """Reçoit un lot hors-ligne strictement cloisonné à ctx.boutique.id."""
    now = datetime.now(timezone.utc)
    synced_uuids: List[str] = []
    errors: List[str] = []
    quota_exceptions: List[HTTPException] = []

    v_deltas, a_deltas, cv_clients, ca_suppliers = _collect_batch_movements(db, payload)
    clients_balance_applied, suppliers_balance_applied = push_master_entities(
        db, ctx, payload, now, synced_uuids, errors,
        vente_qty_deltas=v_deltas, appro_qty_deltas=a_deltas,
        credit_vente_clients=cv_clients, credit_appro_suppliers=ca_suppliers,
        quota_exceptions=quota_exceptions,
    )
    push_ventes(db, ctx, payload, now, synced_uuids, errors, clients_balance_applied)
    push_decaissements_approvisionnements_and_audits(
        db, ctx, payload, now, synced_uuids, errors, suppliers_overwritten=suppliers_balance_applied
    )
    if not synced_uuids and quota_exceptions:
        db.rollback()
        raise quota_exceptions[0]
    db.commit()
    return SyncPushResult(
        synced_count=len(synced_uuids), rejected_count=len(errors), synced_uuids=synced_uuids, errors=errors,
    )
