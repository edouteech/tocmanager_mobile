import uuid
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, Optional
from sqlalchemy.orm import Session

from app.models import PlatformAuditLog, SaasInvoice, SaasPaymentTransaction, SaasPlan, SaasSubscription
from app.services.payments.gateway_protocol import redact_payload


def _activate_subscription_and_invoice(db: Session, tx: SaasPaymentTransaction, now: datetime) -> None:
    plan = db.query(SaasPlan).filter(SaasPlan.id == tx.plan_id).first()
    sub = db.query(SaasSubscription).filter(SaasSubscription.boutique_id == tx.boutique_id).first()
    duration_days = 365 if tx.billing_cycle == "yearly" else 30

    anchor = now
    if sub and sub.current_period_end:
        cur_end = sub.current_period_end
        if cur_end.tzinfo is None:
            cur_end = cur_end.replace(tzinfo=timezone.utc)
        if cur_end > now and sub.status == "active" and sub.plan_id == tx.plan_id:
            anchor = cur_end

    period_end = anchor + timedelta(days=duration_days)
    if not sub:
        sub = SaasSubscription(
            boutique_id=tx.boutique_id,
            plan_id=tx.plan_id,
            status="active",
            billing_cycle=tx.billing_cycle,
            current_period_start=now,
            current_period_end=period_end,
        )
        db.add(sub)
    else:
        sub.plan_id = tx.plan_id
        sub.status = "active"
        sub.billing_cycle = tx.billing_cycle
        sub.current_period_start = now
        sub.current_period_end = period_end
        sub.canceled_at = None

    existing_inv = db.query(SaasInvoice).filter(SaasInvoice.transaction_id == tx.id).first()
    if not existing_inv:
        inv_num = f"INV-TOC-{now.strftime('%Y%m')}-{uuid.uuid4().hex[:4].upper()}"
        db.add(SaasInvoice(
            invoice_number=inv_num,
            transaction_id=tx.id,
            boutique_id=tx.boutique_id,
            plan_name=plan.name if plan else "Plan SaaS",
            billing_cycle=tx.billing_cycle,
            amount=tx.amount,
            currency=tx.currency,
            period_start=now,
            period_end=period_end,
            issued_at=now,
        ))

    db.add(PlatformAuditLog(
        action="SUBSCRIPTION_PAYMENT_SUCCESS",
        target_entity="subscription",
        target_id=tx.boutique_id,
        details={"reference": tx.reference, "amount": tx.amount, "currency": tx.currency, "plan_id": tx.plan_id},
    ))


def apply_transaction_status(
    db: Session,
    tx: SaasPaymentTransaction,
    new_status: str,
    external_reference: Optional[str] = None,
    reported_amount: Optional[float] = None,
    raw_payload: Optional[Dict[str, Any]] = None,
) -> SaasPaymentTransaction:
    query = db.query(SaasPaymentTransaction).filter(SaasPaymentTransaction.id == tx.id)
    if db.bind is not None and db.bind.dialect.name == "postgresql":
        query = query.with_for_update()
    locked_tx = query.first() or tx

    if locked_tx.status == "successful":
        return locked_tx

    if external_reference:
        locked_tx.external_reference = external_reference
    if raw_payload is not None:
        locked_tx.raw_payload = redact_payload(raw_payload)

    if new_status == "successful" and reported_amount is not None and float(reported_amount) < float(locked_tx.amount):
        locked_tx.status = "amount_mismatch"
        db.add(PlatformAuditLog(
            action="FEEXPAY_AMOUNT_MISMATCH",
            target_entity="transaction",
            target_id=locked_tx.id,
            details={"reference": locked_tx.reference, "expected": locked_tx.amount, "received": reported_amount},
        ))
        db.commit()
        db.refresh(locked_tx)
        return locked_tx

    now = datetime.now(timezone.utc)
    locked_tx.status = new_status
    if new_status == "successful":
        locked_tx.paid_at = now
        _activate_subscription_and_invoice(db, locked_tx, now)

    db.commit()
    db.refresh(locked_tx)
    return locked_tx
