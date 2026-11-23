from datetime import datetime, timezone
from typing import Any, Dict, List
from sqlalchemy import func, or_
from sqlalchemy.orm import Session

from app.models import Boutique, Magasin, SaasPlan, SaasSubscription, Vente

EXCHANGE_RATES_TO_XOF: Dict[str, float] = {
    "XOF": 1.0,
    "FCFA": 1.0,
    "XAF": 1.0,
    "EUR": 655.957,
    "USD": 610.0,
    "GNF": 0.071,
    "MAD": 61.0,
}


def convert_to_xof(amount: float, currency: str) -> float:
    rate = EXCHANGE_RATES_TO_XOF.get((currency or "XOF").upper(), 1.0)
    return float(amount or 0.0) * rate


def _month_key(dt: datetime | None) -> str | None:
    if not dt:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.strftime("%Y-%m")


def compute_platform_kpis(db: Session) -> Dict[str, Any]:
    """Compute exact multi-currency MRR, GMV, conversion, churn and growth KPIs."""
    total_boutiques = db.query(Boutique).count()
    active_boutiques = db.query(Boutique).filter(Boutique.is_active == True).count()
    total_magasins = db.query(Magasin).count()

    plans = {p.id: p for p in db.query(SaasPlan).all()}
    subscriptions = db.query(SaasSubscription).all()

    active_subs = 0
    trialing_subs = 0
    canceled_subs = 0
    paid_active_subs = 0
    mrr_by_currency: Dict[str, float] = {}
    mrr_xof = 0.0
    plan_dist: Dict[str, int] = {}

    for sub in subscriptions:
        plan = plans.get(sub.plan_id)
        plan_label = plan.name if plan else "Gratuit"
        plan_dist[plan_label] = plan_dist.get(plan_label, 0) + 1

        if sub.status == "active":
            active_subs += 1
            if plan and plan.price_monthly > 0:
                paid_active_subs += 1
            if plan:
                monthly_val = (
                    float(plan.price_yearly) / 12.0
                    if sub.billing_cycle == "yearly" and plan.price_yearly
                    else float(plan.price_monthly)
                )
                cur = (plan.currency or "XOF").upper()
                mrr_by_currency[cur] = round(mrr_by_currency.get(cur, 0.0) + monthly_val, 2)
                mrr_xof += convert_to_xof(monthly_val, cur)
        elif sub.status == "trialing":
            trialing_subs += 1
        elif sub.status == "canceled":
            canceled_subs += 1

    gmv_rows = (
        db.query(Boutique.currency, func.coalesce(func.sum(Vente.total_amount), 0.0))
        .join(Boutique, Boutique.id == Vente.boutique_id)
        .filter(
            Vente.deleted_at.is_(None),
            or_(Vente.status.is_(None), Vente.status != "refunded"),
        )
        .group_by(Boutique.currency)
        .all()
    )

    gmv_by_currency: Dict[str, float] = {}
    total_gmv_xof = 0.0
    for cur, amount in gmv_rows:
        code = (cur or "XOF").upper()
        val = round(float(amount or 0.0), 2)
        gmv_by_currency[code] = val
        total_gmv_xof += convert_to_xof(val, code)

    conv_base = paid_active_subs + trialing_subs + canceled_subs
    conversion_rate = round((paid_active_subs / conv_base) * 100.0, 1) if conv_base > 0 else 0.0
    churn_base = paid_active_subs + canceled_subs
    churn_rate = round((canceled_subs / churn_base) * 100.0, 1) if churn_base > 0 else 0.0

    boutique_dates = db.query(Boutique.created_at).all()
    signup_counts: Dict[str, int] = {}
    for (created_at,) in boutique_dates:
        key = _month_key(created_at)
        if key:
            signup_counts[key] = signup_counts.get(key, 0) + 1
    monthly_signups: List[Dict[str, Any]] = [
        {"month": k, "signups": signup_counts[k]} for k in sorted(signup_counts.keys())[-6:]
    ]

    mrr_rounded = round(mrr_xof, 2)
    return {
        "mrr": mrr_rounded,
        "arr": round(mrr_rounded * 12.0, 2),
        "mrr_by_currency": mrr_by_currency,
        "gmv_by_currency": gmv_by_currency,
        "conversion_rate": conversion_rate,
        "churn_rate": churn_rate,
        "total_boutiques": total_boutiques,
        "active_boutiques": active_boutiques,
        "total_magasins": total_magasins,
        "trialing_subscriptions": trialing_subs,
        "active_subscriptions": active_subs,
        "total_gmv": round(total_gmv_xof, 2),
        "currency": "XOF",
        "plan_distribution": [{"name": k, "count": v} for k, v in plan_dist.items()],
        "monthly_signups": monthly_signups,
    }
