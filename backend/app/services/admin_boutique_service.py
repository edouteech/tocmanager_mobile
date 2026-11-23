from typing import Any, Dict, List, Optional
from fastapi import HTTPException
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.models import (
    Boutique,
    BoutiqueUserMembership,
    Magasin,
    SaasInvoice,
    SaasPaymentTransaction,
    SaasPlan,
    SaasSubscription,
    User,
)


def list_admin_boutiques(
    db: Session,
    q: Optional[str] = None,
    status_filter: Optional[str] = None,
    plan_code: Optional[str] = None,
    paginated: bool = False,
    page: int = 1,
    limit: int = 25,
) -> Any:
    """List boutiques without N+1 queries; supports search, filters and pagination."""
    boutiques = db.query(Boutique).order_by(Boutique.created_at.desc()).all()
    if not boutiques:
        return {"items": [], "total": 0, "page": page, "limit": limit} if paginated else []

    owner_ids = list({b.owner_user_id for b in boutiques if b.owner_user_id})
    owners = {u.id: u for u in db.query(User).filter(User.id.in_(owner_ids)).all()} if owner_ids else {}

    mag_counts = dict(
        db.query(Magasin.boutique_id, func.count(Magasin.id))
        .group_by(Magasin.boutique_id)
        .all()
    )
    subs = {
        s.boutique_id: s
        for s in db.query(SaasSubscription).order_by(SaasSubscription.created_at.desc()).all()
    }
    plans = {p.id: p for p in db.query(SaasPlan).all()}

    search = (q or "").strip().lower()
    items: List[Dict[str, Any]] = []
    for b in boutiques:
        owner = owners.get(b.owner_user_id)
        sub = subs.get(b.id)
        plan = plans.get(sub.plan_id) if sub else None
        p_code = plan.code if plan else "free"
        sub_status = sub.status if sub else "none"
        owner_name = owner.full_name if owner and owner.full_name else (owner.username if owner else "Inconnu")
        owner_email = (owner.email or owner.username) if owner else "Inconnu"

        if search and not (
            search in (b.name or "").lower()
            or search in (b.company_name or "").lower()
            or search in owner_name.lower()
            or search in owner_email.lower()
        ):
            continue
        if status_filter == "active_only" and not b.is_active:
            continue
        if status_filter == "suspended" and b.is_active:
            continue
        if status_filter in ("active", "trialing", "past_due", "canceled") and sub_status != status_filter:
            continue
        if plan_code and p_code != plan_code:
            continue

        items.append({
            "id": b.id,
            "slug": b.slug,
            "name": b.name,
            "company_name": b.company_name,
            "currency": b.currency,
            "country": b.country,
            "phone": b.phone,
            "is_active": b.is_active,
            "created_at": b.created_at,
            "owner_name": owner_name,
            "owner_email": owner_email,
            "magasin_count": int(mag_counts.get(b.id, 0)),
            "subscription": {
                "status": sub_status,
                "plan_name": plan.name if plan else "Gratuit",
                "plan_code": p_code,
                "billing_cycle": sub.billing_cycle if sub else "monthly",
                "trial_ends_at": sub.trial_ends_at if sub else None,
                "current_period_end": sub.current_period_end if sub else None,
            },
        })

    if not paginated:
        return items

    total = len(items)
    start = max(0, (page - 1) * limit)
    return {"items": items[start : start + limit], "total": total, "page": page, "limit": limit}


def get_admin_boutique_detail(db: Session, boutique_id: str) -> Dict[str, Any]:
    boutique = db.query(Boutique).filter(Boutique.id == boutique_id).first()
    if not boutique:
        raise HTTPException(status_code=404, detail="Boutique non trouvée.")

    owner = db.query(User).filter(User.id == boutique.owner_user_id).first()
    sub = db.query(SaasSubscription).filter(SaasSubscription.boutique_id == boutique.id).first()
    plan = db.query(SaasPlan).filter(SaasPlan.id == sub.plan_id).first() if sub else None
    magasins = db.query(Magasin).filter(Magasin.boutique_id == boutique.id).order_by(Magasin.name.asc()).all()

    members_rows = (
        db.query(BoutiqueUserMembership, User)
        .join(User, User.id == BoutiqueUserMembership.user_id)
        .filter(BoutiqueUserMembership.boutique_id == boutique.id)
        .all()
    )
    txs = (
        db.query(SaasPaymentTransaction)
        .filter(SaasPaymentTransaction.boutique_id == boutique.id)
        .order_by(SaasPaymentTransaction.created_at.desc())
        .limit(10)
        .all()
    )
    invoices = (
        db.query(SaasInvoice)
        .filter(SaasInvoice.boutique_id == boutique.id)
        .order_by(SaasInvoice.issued_at.desc())
        .limit(10)
        .all()
    )

    return {
        "id": boutique.id,
        "slug": boutique.slug,
        "name": boutique.name,
        "company_name": boutique.company_name,
        "currency": boutique.currency,
        "country": boutique.country,
        "phone": boutique.phone,
        "email": boutique.email,
        "address": boutique.address,
        "is_active": boutique.is_active,
        "created_at": boutique.created_at,
        "owner": {
            "id": owner.id if owner else None,
            "username": owner.username if owner else None,
            "email": (owner.email or owner.username) if owner else "Inconnu",
            "full_name": owner.full_name if owner else "Inconnu",
        },
        "subscription": {
            "status": sub.status if sub else "none",
            "plan_name": plan.name if plan else "Gratuit",
            "plan_code": plan.code if plan else "free",
            "billing_cycle": sub.billing_cycle if sub else "monthly",
            "trial_ends_at": sub.trial_ends_at if sub else None,
            "current_period_end": sub.current_period_end if sub else None,
        },
        "magasins": [
            {"id": m.id, "name": m.name, "code": m.code, "is_warehouse": m.is_warehouse, "is_active": m.is_active}
            for m in magasins
        ],
        "members": [
            {
                "id": u.id,
                "username": u.username,
                "full_name": u.full_name,
                "role": mem.role,
                "is_active": bool(mem.is_active and u.is_active),
            }
            for mem, u in members_rows
        ],
        "transactions": [
            {"id": t.id, "reference": t.reference, "amount": t.amount, "currency": t.currency, "network": t.network, "status": t.status, "created_at": t.created_at}
            for t in txs
        ],
        "invoices": [
            {"id": inv.id, "invoice_number": inv.invoice_number, "plan_name": inv.plan_name, "amount": inv.amount, "currency": inv.currency, "issued_at": inv.issued_at}
            for inv in invoices
        ],
    }
