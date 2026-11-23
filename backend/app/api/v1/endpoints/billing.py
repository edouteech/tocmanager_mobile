from typing import Any, Dict, List
from fastapi import APIRouter, Depends, HTTPException, Response
from sqlalchemy.orm import Session

from app.api import deps
from app.core.database import get_db
from app.models import SaasInvoice
from app.schemas.billing import (
    CheckoutRequest,
    CheckoutResponse,
    InvoiceOut,
    PaymentMethodsOut,
    TransactionStatusOut,
)
from app.services.invoice_pdf_service import generate_saas_invoice_pdf
from app.services.payments.billing_service import (
    initiate_checkout,
    list_payment_methods,
    process_feexpay_webhook,
    refresh_transaction_status,
)
from app.services.tenant_context_service import TenantContext

router = APIRouter()
webhook_router = APIRouter()


@router.get("/payment-methods", response_model=PaymentMethodsOut)
def get_payment_methods(db: Session = Depends(get_db)):
    return list_payment_methods(db)


@router.post("/checkout", response_model=CheckoutResponse)
def billing_checkout(
    payload: CheckoutRequest,
    ctx: TenantContext = Depends(deps.require_tenant_role(["owner"])),
    db: Session = Depends(get_db),
):
    tx = initiate_checkout(
        db=db,
        ctx=ctx,
        plan_code=payload.plan_code,
        billing_cycle=payload.billing_cycle,
        network=payload.network,
        phone=payload.phone,
    )
    return CheckoutResponse(
        transaction_id=tx.id,
        reference=tx.reference,
        external_reference=tx.external_reference,
        flow_type=tx.flow_type,
        status=tx.status,
        payment_url=tx.payment_url,
        amount=tx.amount,
        currency=tx.currency,
    )


@router.get("/status/{reference}", response_model=TransactionStatusOut)
def get_checkout_status(
    reference: str,
    ctx: TenantContext = Depends(deps.get_tenant_context),
    db: Session = Depends(get_db),
):
    return refresh_transaction_status(db=db, ctx=ctx, reference=reference)


@router.get("/invoices", response_model=List[InvoiceOut])
def list_boutique_invoices(
    ctx: TenantContext = Depends(deps.require_tenant_role(["owner", "store_admin"])),
    db: Session = Depends(get_db),
):
    return (
        db.query(SaasInvoice)
        .filter(SaasInvoice.boutique_id == ctx.boutique.id)
        .order_by(SaasInvoice.issued_at.desc())
        .all()
    )


@router.get("/invoices/{invoice_id}/pdf")
def download_invoice_pdf(
    invoice_id: str,
    ctx: TenantContext = Depends(deps.require_tenant_role(["owner", "store_admin"])),
    db: Session = Depends(get_db),
):
    invoice = (
        db.query(SaasInvoice)
        .filter(SaasInvoice.id == invoice_id, SaasInvoice.boutique_id == ctx.boutique.id)
        .first()
    )
    if not invoice:
        raise HTTPException(status_code=404, detail="Facture introuvable.")

    pdf_bytes = generate_saas_invoice_pdf(invoice, ctx.boutique)
    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f'attachment; filename="{invoice.invoice_number}.pdf"'},
    )


@webhook_router.post("/feexpay")
def feexpay_webhook(payload: Dict[str, Any], db: Session = Depends(get_db)):
    return process_feexpay_webhook(db=db, payload=payload)
