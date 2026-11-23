from typing import Any, Dict, List, Optional
from sqlalchemy.orm import Session

from app.models import (
    Boutique,
    PlatformAuditLog,
    SaasPaymentTransaction,
    SaasPlan,
    SaasSubscription,
)


def list_admin_subscriptions_data(
    db: Session,
    sub_status: Optional[str] = None,
    tx_status: Optional[str] = None,
    page: int = 1,
    limit: int = 25,
) -> Dict[str, Any]:
    boutiques = {b.id: b for b in db.query(Boutique).all()}
    plans = {p.id: p for p in db.query(SaasPlan).all()}

    subs_query = db.query(SaasSubscription).order_by(SaasSubscription.updated_at.desc())
    if sub_status:
        subs_query = subs_query.filter(SaasSubscription.status == sub_status)
    all_subs = subs_query.all()

    start = max(0, (page - 1) * limit)
    sub_items: List[Dict[str, Any]] = []
    for sub in all_subs[start : start + limit]:
        btq = boutiques.get(sub.boutique_id)
        plan = plans.get(sub.plan_id)
        sub_items.append({
            "id": sub.id,
            "boutique_id": sub.boutique_id,
            "boutique_name": btq.name if btq else "Inconnue",
            "plan_name": plan.name if plan else "Gratuit",
            "plan_code": plan.code if plan else "free",
            "status": sub.status,
            "billing_cycle": sub.billing_cycle,
            "trial_ends_at": sub.trial_ends_at,
            "current_period_end": sub.current_period_end,
            "updated_at": sub.updated_at,
        })

    tx_query = db.query(SaasPaymentTransaction).order_by(SaasPaymentTransaction.created_at.desc())
    if tx_status:
        tx_query = tx_query.filter(SaasPaymentTransaction.status == tx_status)
    all_txs = tx_query.all()
    tx_items: List[Dict[str, Any]] = []
    for tx in all_txs[start : start + limit]:
        btq = boutiques.get(tx.boutique_id)
        plan = plans.get(tx.plan_id)
        tx_items.append({
            "id": tx.id,
            "reference": tx.reference,
            "external_reference": tx.external_reference,
            "boutique_id": tx.boutique_id,
            "boutique_name": btq.name if btq else "Inconnue",
            "plan_name": plan.name if plan else "Plan SaaS",
            "billing_cycle": tx.billing_cycle,
            "amount": tx.amount,
            "currency": tx.currency,
            "phone": tx.phone,
            "network": tx.network,
            "flow_type": tx.flow_type,
            "status": tx.status,
            "paid_at": tx.paid_at,
            "created_at": tx.created_at,
        })

    return {
        "items": sub_items,
        "total": len(all_subs),
        "transactions": tx_items,
        "transactions_total": len(all_txs),
        "page": page,
        "limit": limit,
    }


def list_platform_audit_data(
    db: Session,
    action: Optional[str] = None,
    q: Optional[str] = None,
    page: int = 1,
    limit: int = 50,
) -> Dict[str, Any]:
    query = db.query(PlatformAuditLog).order_by(PlatformAuditLog.created_at.desc())
    if action:
        query = query.filter(PlatformAuditLog.action == action.strip())
    rows = query.all()

    term = (q or "").strip().lower()
    if term:
        rows = [
            r
            for r in rows
            if term in (r.action or "").lower()
            or term in (r.admin_username or "").lower()
            or term in (r.target_entity or "").lower()
            or term in (r.target_id or "").lower()
        ]

    start = max(0, (page - 1) * limit)
    paged = rows[start : start + limit]
    return {
        "items": [
            {
                "id": r.id,
                "admin_user_id": r.admin_user_id,
                "admin_username": r.admin_username,
                "action": r.action,
                "target_entity": r.target_entity,
                "target_id": r.target_id,
                "details": r.details,
                "created_at": r.created_at,
            }
            for r in paged
        ],
        "total": len(rows),
        "page": page,
        "limit": limit,
    }
