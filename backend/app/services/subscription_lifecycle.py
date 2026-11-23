from datetime import datetime, timedelta, timezone
from typing import Dict
from sqlalchemy.orm import Session

from app.models import PlatformAuditLog, SaasSubscription
from app.services.entitlements import PAST_DUE_GRACE_DAYS


def _as_utc(dt: datetime | None) -> datetime | None:
    if dt is None:
        return None
    return dt if dt.tzinfo is not None else dt.replace(tzinfo=timezone.utc)


def sync_subscriptions_lifecycle(db: Session) -> Dict[str, int]:
    """Advance subscription lifecycle transitions (trial expired, past_due, canceled)."""
    now = datetime.now(timezone.utc)
    counts = {"trials_expired": 0, "marked_past_due": 0, "canceled_after_grace": 0}

    subs = db.query(SaasSubscription).all()
    for sub in subs:
        trial_end = _as_utc(sub.trial_ends_at)
        period_end = _as_utc(sub.current_period_end)

        if sub.status == "trialing" and trial_end and trial_end <= now:
            sub.status = "expired"
            counts["trials_expired"] += 1
            db.add(PlatformAuditLog(
                action="SUBSCRIPTION_TRIAL_EXPIRED",
                target_entity="subscription",
                target_id=sub.id,
                details={"boutique_id": sub.boutique_id},
            ))
        elif sub.status == "active" and period_end and period_end <= now:
            sub.status = "past_due"
            counts["marked_past_due"] += 1
            db.add(PlatformAuditLog(
                action="SUBSCRIPTION_PAST_DUE",
                target_entity="subscription",
                target_id=sub.id,
                details={"boutique_id": sub.boutique_id},
            ))
        elif sub.status == "past_due" and period_end and (period_end + timedelta(days=PAST_DUE_GRACE_DAYS)) <= now:
            sub.status = "canceled"
            sub.canceled_at = now
            counts["canceled_after_grace"] += 1
            db.add(PlatformAuditLog(
                action="SUBSCRIPTION_CANCELED_UNPAID",
                target_entity="subscription",
                target_id=sub.id,
                details={"boutique_id": sub.boutique_id},
            ))

    db.commit()
    return counts
