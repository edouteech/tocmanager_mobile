import uuid
from typing import Any, Dict, Optional
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.models import PlatformAuditLog, SaasPaymentTransaction, SaasPlan
from app.services.payments.feexpay_catalog import NETWORK_SLUGS
from app.services.payments.gateway_protocol import PaymentGatewayProtocol
from app.services.payments.payment_manager import get_feexpay_gateway, resolve_feexpay_config
from app.services.payments.subscription_activation import apply_transaction_status
from app.services.tenant_context_service import TenantContext


def list_payment_methods(db: Session) -> Dict[str, Any]:
    cfg = resolve_feexpay_config(db)
    allowed_networks = set(cfg["networks"])
    countries = []
    for c in cfg["countries"]:
        filtered = [n for n in c["networks"] if n in allowed_networks]
        if filtered:
            countries.append({**c, "networks": filtered})
    return {
        "providers": [
            {
                "code": cfg["code"],
                "name": cfg["name"],
                "is_active": cfg["is_active"],
                "mode": cfg["mode"],
                "countries": countries,
            }
        ]
    }


def initiate_checkout(
    db: Session,
    ctx: TenantContext,
    plan_code: str,
    billing_cycle: str,
    network: str,
    phone: str,
    gateway: Optional[PaymentGatewayProtocol] = None,
) -> SaasPaymentTransaction:
    plan = db.query(SaasPlan).filter(SaasPlan.code == plan_code, SaasPlan.is_active == True).first()
    if not plan or plan.code == "free":
        raise HTTPException(status_code=400, detail="Forfait payant invalide.")
    if billing_cycle not in ("monthly", "yearly"):
        raise HTTPException(status_code=400, detail="Cycle de facturation invalide (monthly ou yearly).")
    norm_network = network.strip().upper()
    if norm_network not in NETWORK_SLUGS:
        raise HTTPException(status_code=400, detail=f"Réseau de paiement non supporté : {network}")

    cfg = resolve_feexpay_config(db)
    if not cfg["is_active"] or norm_network not in cfg["networks"]:
        raise HTTPException(status_code=400, detail="Ce réseau de paiement est désactivé.")

    amount = float(plan.price_yearly if billing_cycle == "yearly" else plan.price_monthly)
    if amount <= 0:
        raise HTTPException(status_code=400, detail="Le montant du forfait doit être positif.")

    tx = SaasPaymentTransaction(
        reference=f"TOC-{uuid.uuid4().hex[:10].upper()}",
        provider_code="feexpay",
        boutique_id=ctx.boutique.id,
        user_id=ctx.user.id,
        plan_id=plan.id,
        billing_cycle=billing_cycle,
        amount=amount,
        currency=plan.currency or "XOF",
        phone=phone.strip(),
        network=norm_network,
        status="pending",
    )
    db.add(tx)
    db.commit()
    db.refresh(tx)

    gw = gateway or get_feexpay_gateway(db)
    try:
        res = gw.initiate(
            reference=tx.reference,
            amount=tx.amount,
            phone=tx.phone,
            network=tx.network,
            fullname=ctx.user.full_name or ctx.user.username,
            email=ctx.user.email or ctx.boutique.email or "billing@tocmanager.com",
            description=f"Abonnement TocManager {plan.name} - {ctx.boutique.name}",
        )
    except Exception as exc:
        tx.status = "failed"
        tx.raw_payload = {"error": str(exc)}
        db.commit()
        raise HTTPException(status_code=status.HTTP_502_BAD_GATEWAY, detail=f"Erreur FeexPay : {exc}")

    tx.flow_type = res.flow_type
    tx.payment_url = res.payment_url
    tx.external_reference = res.external_reference
    tx.raw_payload = res.raw_payload
    db.commit()

    if res.status == "successful":
        return apply_transaction_status(db, tx, "successful", external_reference=res.external_reference, raw_payload=res.raw_payload)
    db.refresh(tx)
    return tx


def process_feexpay_webhook(
    db: Session, payload: Dict[str, Any], gateway: Optional[PaymentGatewayProtocol] = None
) -> Dict[str, Any]:
    gw = gateway or get_feexpay_gateway(db)
    parsed = gw.parse_callback(payload)
    tx = None
    if parsed.reference:
        tx = db.query(SaasPaymentTransaction).filter(SaasPaymentTransaction.reference == parsed.reference).first()
    if not tx and parsed.external_reference:
        tx = db.query(SaasPaymentTransaction).filter(
            SaasPaymentTransaction.external_reference == parsed.external_reference
        ).first()
    if not tx or tx.status == "successful":
        return {"status": "ignored_or_already_processed"}

    if parsed.status == "successful" and getattr(gw, "requires_callback_confirmation", True):
        confirm_ref = parsed.external_reference or tx.external_reference or tx.reference
        check = gw.check_status(confirm_ref)
        if not check or check.status != "successful":
            db.add(PlatformAuditLog(
                action="FEEXPAY_UNCONFIRMED_CALLBACK",
                target_entity="transaction",
                target_id=tx.id,
                details={"reference": tx.reference, "callback_status": parsed.status, "verified_status": check.status if check else None},
            ))
            db.commit()
            return {"status": "unconfirmed", "verified_status": check.status if check else None}
        apply_transaction_status(
            db, tx, "successful", external_reference=check.external_reference or parsed.external_reference,
            reported_amount=check.amount if check.amount is not None else parsed.amount,
            raw_payload=check.raw_payload,
        )
        return {"status": "confirmed"}

    apply_transaction_status(
        db, tx, parsed.status, external_reference=parsed.external_reference,
        reported_amount=parsed.amount, raw_payload=parsed.raw_payload,
    )
    return {"status": tx.status}


def refresh_transaction_status(
    db: Session, ctx: TenantContext, reference: str, gateway: Optional[PaymentGatewayProtocol] = None
) -> SaasPaymentTransaction:
    tx = (
        db.query(SaasPaymentTransaction)
        .filter(SaasPaymentTransaction.reference == reference, SaasPaymentTransaction.boutique_id == ctx.boutique.id)
        .first()
    )
    if not tx:
        raise HTTPException(status_code=404, detail="Transaction introuvable.")
    if tx.status != "successful":
        gw = gateway or get_feexpay_gateway(db)
        check = gw.check_status(tx.external_reference or tx.reference)
        if check:
            tx = apply_transaction_status(
                db, tx, check.status, external_reference=check.external_reference,
                reported_amount=check.amount, raw_payload=check.raw_payload,
            )
    return tx
