from datetime import datetime, timezone
from typing import List
from sqlalchemy.orm import Session

from app.models import AuditLog, Client, Product, Vente, VenteItem
from app.schemas.sync import SyncPushRequest, SyncPushResult
from app.services.stock_service import adjust_magasin_stock
from app.services.sync_push_master_service import belongs_to_other_boutique, push_master_entities
from app.services.sync_push_operations_service import push_decaissements_approvisionnements_and_audits
from app.services.tenant_context_service import TenantContext, resolve_operational_magasin


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
                cl_ok = db.query(Client.sync_id).filter(Client.sync_id == client_ref, Client.boutique_id == boutique_id).first()
                if not cl_ok:
                    errors.append(f"Vente {v.sync_id}: unknown client in boutique")
                    continue

            v_mag = resolve_operational_magasin(
                db, ctx, body_magasin_id=v.magasin_id, allow_warehouse=False, allow_single_assigned_fallback=True
            )
            v_uid = v.user_id or current_user.id
            v_uname = v.user_name or (current_user.full_name or current_user.username)
            db.add(Vente(
                sync_id=v.sync_id, boutique_id=boutique_id, magasin_id=v_mag.id,
                ticket_number=v.ticket_number, client_sync_id=client_ref, client_name=v.client_name,
                user_id=v_uid, user_name=v_uname, total_amount=v.total_amount, paid_amount=v.paid_amount,
                discount_amount=v.discount_amount, payment_method=v.payment_method, notes=v.notes,
                created_at=v.created_at, updated_at=v.updated_at or v.created_at,
            ))

            for item in v.items:
                db.add(VenteItem(
                    sync_id=item.sync_id or None, vente_sync_id=v.sync_id, product_sync_id=item.product_sync_id,
                    product_name=item.product_name, quantity=item.quantity, unit_price=item.unit_price,
                    cost_price=item.cost_price, total=item.total,
                ))
                if not payload.is_initial_sync and item.product_sync_id:
                    prod = db.query(Product).filter(Product.sync_id == item.product_sync_id, Product.boutique_id == boutique_id).first()
                    if prod:
                        adjust_magasin_stock(
                            db=db, boutique_id=boutique_id, magasin_id=v_mag.id, product=prod,
                            quantity_delta=-item.quantity, enforce_sufficient=False,
                            movement_type="sale", reference_type="vente", reference_id=v.sync_id,
                            reason=f"Sync vente {v.ticket_number}", user_id=v_uid, user_name=v_uname,
                        )

            if not payload.is_initial_sync and client_ref and v.paid_amount < v.total_amount:
                target_client = db.query(Client).filter(Client.sync_id == client_ref, Client.boutique_id == boutique_id).first()
                if target_client:
                    target_client.balance += v.total_amount - v.paid_amount
                    target_client.updated_at = now

            db.add(AuditLog(
                id=f"audit-{v.sync_id}", boutique_id=boutique_id, user_id=v_uid, user_name=v_uname,
                action="SALE_CREATE", entity_type="vente", entity_id=v.sync_id,
                details={
                    "ticket_number": v.ticket_number, "total_amount": v.total_amount, "paid_amount": v.paid_amount,
                    "client_name": v.client_name, "payment_method": v.payment_method, "item_count": len(v.items),
                },
                created_at=v.created_at,
            ))
            synced_uuids.append(v.sync_id)
        except Exception as exc:
            errors.append(f"Vente {v.sync_id}: {exc}")

    push_decaissements_approvisionnements_and_audits(db, ctx, payload, now, synced_uuids, errors)
    db.commit()
    return SyncPushResult(
        synced_count=len(synced_uuids), rejected_count=len(errors), synced_uuids=synced_uuids, errors=errors,
    )
