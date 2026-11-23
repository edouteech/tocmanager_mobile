from datetime import datetime, timezone
from typing import List
from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.models import AuditLog, Client, ClientPayment, Supplier, SupplierPayment
from app.schemas.entities import DebtPaymentRequest, SupplierPaymentRequest
from app.services.entitlements import check_feature_access
from app.services.tenant_context_service import TenantContext


def list_client_payments_svc(
    db: Session, ctx: TenantContext, sync_id: str
) -> List[ClientPayment]:
    client = db.query(Client).filter(
        Client.sync_id == sync_id, Client.boutique_id == ctx.boutique.id, Client.deleted_at.is_(None)
    ).first()
    if not client:
        raise HTTPException(status_code=404, detail="Client introuvable")
    return (
        db.query(ClientPayment)
        .filter(ClientPayment.boutique_id == ctx.boutique.id, ClientPayment.client_sync_id == sync_id)
        .order_by(ClientPayment.created_at.desc())
        .all()
    )


def record_client_payment_svc(
    db: Session, ctx: TenantContext, sync_id: str, payment: DebtPaymentRequest
) -> Client:
    check_feature_access(db, ctx.boutique.id, "module_credit_sales")
    client = db.query(Client).filter(
        Client.sync_id == sync_id, Client.boutique_id == ctx.boutique.id, Client.deleted_at.is_(None)
    ).first()
    if not client:
        raise HTTPException(status_code=404, detail="Client introuvable")

    previous_balance = float(client.balance or 0.0)
    if not payment.allow_overpayment and payment.amount > previous_balance + 1e-6:
        raise HTTPException(
            status_code=400,
            detail=f"Montant payé ({payment.amount}) supérieur à la créance due ({previous_balance}).",
        )
    new_balance = round(max(0.0, previous_balance - payment.amount), 2)
    client.balance = new_balance
    now = datetime.now(timezone.utc)
    client.updated_at = now
    uname = ctx.user.full_name or ctx.user.username

    db.add(ClientPayment(
        boutique_id=ctx.boutique.id,
        magasin_id=payment.magasin_id or ctx.requested_magasin_id,
        client_sync_id=client.sync_id,
        amount=round(payment.amount, 2),
        payment_method=payment.payment_method,
        previous_balance=previous_balance,
        new_balance=new_balance,
        notes=payment.notes,
        user_id=ctx.user.id,
        user_name=uname,
        created_at=now,
    ))
    db.add(AuditLog(
        boutique_id=ctx.boutique.id, user_id=ctx.user.id, user_name=uname,
        action="DEBT_PAYMENT", entity_type="client", entity_id=client.sync_id,
        details={
            "client_name": client.name, "amount_paid": payment.amount, "payment_method": payment.payment_method,
            "previous_balance": previous_balance, "new_balance": new_balance, "notes": payment.notes,
        },
        created_at=now,
    ))
    db.commit()
    db.refresh(client)
    return client


def list_supplier_payments_svc(
    db: Session, ctx: TenantContext, sync_id: str
) -> List[SupplierPayment]:
    check_feature_access(db, ctx.boutique.id, "module_suppliers")
    supplier = db.query(Supplier).filter(
        Supplier.sync_id == sync_id, Supplier.boutique_id == ctx.boutique.id, Supplier.deleted_at.is_(None)
    ).first()
    if not supplier:
        raise HTTPException(status_code=404, detail="Fournisseur introuvable")
    return (
        db.query(SupplierPayment)
        .filter(SupplierPayment.boutique_id == ctx.boutique.id, SupplierPayment.supplier_sync_id == sync_id)
        .order_by(SupplierPayment.created_at.desc())
        .all()
    )


def record_supplier_payment_svc(
    db: Session, ctx: TenantContext, sync_id: str, payment: SupplierPaymentRequest
) -> Supplier:
    check_feature_access(db, ctx.boutique.id, "module_suppliers")
    supplier = db.query(Supplier).filter(
        Supplier.sync_id == sync_id, Supplier.boutique_id == ctx.boutique.id, Supplier.deleted_at.is_(None)
    ).first()
    if not supplier:
        raise HTTPException(status_code=404, detail="Fournisseur introuvable")

    previous_balance = float(supplier.balance or 0.0)
    if not payment.allow_overpayment and payment.amount > previous_balance + 1e-6:
        raise HTTPException(
            status_code=400,
            detail=f"Montant versé ({payment.amount}) supérieur à la dette fournisseur ({previous_balance}).",
        )
    new_balance = round(max(0.0, previous_balance - payment.amount), 2)
    supplier.balance = new_balance
    now = datetime.now(timezone.utc)
    supplier.updated_at = now
    uname = ctx.user.full_name or ctx.user.username

    db.add(SupplierPayment(
        boutique_id=ctx.boutique.id,
        magasin_id=payment.magasin_id or ctx.requested_magasin_id,
        supplier_sync_id=supplier.sync_id,
        amount=round(payment.amount, 2),
        payment_method=payment.payment_method,
        previous_balance=previous_balance,
        new_balance=new_balance,
        notes=payment.notes,
        user_id=ctx.user.id,
        user_name=uname,
        created_at=now,
    ))
    db.add(AuditLog(
        boutique_id=ctx.boutique.id, user_id=ctx.user.id, user_name=uname,
        action="SUPPLIER_PAYMENT", entity_type="supplier", entity_id=supplier.sync_id,
        details={
            "supplier_name": supplier.name, "amount_paid": payment.amount, "payment_method": payment.payment_method,
            "previous_balance": previous_balance, "new_balance": new_balance, "notes": payment.notes,
        },
        created_at=now,
    ))
    db.commit()
    db.refresh(supplier)
    return supplier
