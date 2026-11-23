from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from fastapi import HTTPException, status
from sqlalchemy.orm import Session

from app.core.permissions import normalize_tenant_role
from app.models import (
    AuditLog,
    CashRegisterSession,
    ClientPayment,
    Decaissement,
    Magasin,
    Vente,
)
from app.schemas.cash import CashSessionCloseRequest, CashSessionOpenRequest
from app.services.tenant_context_service import (
    TenantContext,
    resolve_operational_magasin,
    resolve_read_magasin_id,
)

CASH_METHODS = {"espèces", "especes", "cash"}
MOBILE_METHODS = {"mobile money", "wave", "orange money", "moov money", "mtn", "celtiis", "flooz", "t-money"}
CARD_METHODS = {"carte bancaire", "carte", "card"}


def _serialize_session(db: Session, s: CashRegisterSession) -> Dict[str, Any]:
    mag = db.query(Magasin.name).filter(Magasin.id == s.magasin_id).first()
    return {
        "id": s.id,
        "magasin_id": s.magasin_id,
        "magasin_name": mag[0] if mag else None,
        "opened_by_user_id": s.opened_by_user_id,
        "opened_by_name": s.opened_by_name,
        "opened_at": s.opened_at,
        "opening_balance": float(s.opening_balance or 0.0),
        "status": s.status,
        "expected_cash": s.expected_cash,
        "expected_mobile_money": s.expected_mobile_money,
        "expected_card": s.expected_card,
        "declared_cash": s.declared_cash,
        "discrepancy": s.discrepancy,
        "closed_by_name": s.closed_by_name,
        "closed_at": s.closed_at,
        "notes": s.notes,
    }


def open_cash_session(
    db: Session, ctx: TenantContext, payload: CashSessionOpenRequest
) -> Dict[str, Any]:
    magasin = resolve_operational_magasin(
        db, ctx, body_magasin_id=payload.magasin_id, allow_warehouse=False
    )
    existing = (
        db.query(CashRegisterSession)
        .filter(
            CashRegisterSession.boutique_id == ctx.boutique.id,
            CashRegisterSession.magasin_id == magasin.id,
            CashRegisterSession.opened_by_user_id == ctx.user.id,
            CashRegisterSession.status == "open",
        )
        .first()
    )
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Une session de caisse est déjà ouverte pour ce poste dans ce magasin.",
        )

    now = datetime.now(timezone.utc)
    uname = ctx.user.full_name or ctx.user.username
    session = CashRegisterSession(
        boutique_id=ctx.boutique.id,
        magasin_id=magasin.id,
        opened_by_user_id=ctx.user.id,
        opened_by_name=uname,
        opened_at=now,
        opening_balance=round(float(payload.opening_balance), 2),
        status="open",
        notes=payload.notes,
        created_at=now,
        updated_at=now,
    )
    db.add(session)
    db.flush()
    db.add(AuditLog(
        boutique_id=ctx.boutique.id,
        user_id=ctx.user.id,
        user_name=uname,
        action="CASH_SESSION_OPEN",
        entity_type="cash_register_session",
        entity_id=session.id,
        details={"magasin": magasin.name, "opening_balance": session.opening_balance},
        created_at=now,
    ))
    db.commit()
    db.refresh(session)
    return _serialize_session(db, session)


def get_current_cash_session(
    db: Session, ctx: TenantContext, magasin_id: Optional[str] = None
) -> Optional[Dict[str, Any]]:
    eff_mag = magasin_id or ctx.requested_magasin_id
    q = db.query(CashRegisterSession).filter(
        CashRegisterSession.boutique_id == ctx.boutique.id,
        CashRegisterSession.opened_by_user_id == ctx.user.id,
        CashRegisterSession.status == "open",
    )
    if eff_mag:
        q = q.filter(CashRegisterSession.magasin_id == eff_mag)
    row = q.order_by(CashRegisterSession.opened_at.desc()).first()
    return _serialize_session(db, row) if row else None


def list_cash_sessions(
    db: Session, ctx: TenantContext, limit: int = 100
) -> List[Dict[str, Any]]:
    mag_id = resolve_read_magasin_id(ctx)
    q = db.query(CashRegisterSession).filter(CashRegisterSession.boutique_id == ctx.boutique.id)
    if mag_id:
        q = q.filter(CashRegisterSession.magasin_id == mag_id)
    rows = q.order_by(CashRegisterSession.opened_at.desc()).limit(limit).all()
    return [_serialize_session(db, r) for r in rows]


def close_cash_session(
    db: Session, ctx: TenantContext, session_id: str, payload: CashSessionCloseRequest
) -> Dict[str, Any]:
    session = (
        db.query(CashRegisterSession)
        .filter(
            CashRegisterSession.id == session_id,
            CashRegisterSession.boutique_id == ctx.boutique.id,
        )
        .first()
    )
    if not session:
        raise HTTPException(status_code=404, detail="Session de caisse introuvable.")
    if session.status != "open":
        raise HTTPException(status_code=400, detail="Cette session de caisse est déjà clôturée.")

    eff_role = normalize_tenant_role(ctx.role)
    if session.opened_by_user_id != ctx.user.id and eff_role not in ("owner", "store_admin", "manager"):
        raise HTTPException(status_code=403, detail="Vous ne pouvez pas clôturer la caisse d'un autre opérateur.")

    now = datetime.now(timezone.utc)
    ventes = (
        db.query(Vente)
        .filter(
            Vente.boutique_id == ctx.boutique.id,
            Vente.magasin_id == session.magasin_id,
            Vente.deleted_at.is_(None),
            Vente.status != "refunded",
            Vente.created_at >= session.opened_at,
            Vente.created_at <= now,
        )
        .all()
    )

    cash_sales = 0.0
    momo_sales = 0.0
    card_sales = 0.0
    for v in ventes:
        collected = min(float(v.paid_amount or 0.0), float(v.total_amount or 0.0))
        method = (v.payment_method or "").strip().lower()
        if method in CASH_METHODS:
            cash_sales += collected
        elif method in MOBILE_METHODS:
            momo_sales += collected
        elif method in CARD_METHODS:
            card_sales += collected

    debt_payments = (
        db.query(ClientPayment)
        .filter(
            ClientPayment.boutique_id == ctx.boutique.id,
            ClientPayment.created_at >= session.opened_at,
            ClientPayment.created_at <= now,
            (ClientPayment.magasin_id == session.magasin_id) | (ClientPayment.magasin_id.is_(None)),
        )
        .all()
    )
    for cp in debt_payments:
        m = (cp.payment_method or "").strip().lower()
        if m in CASH_METHODS:
            cash_sales += float(cp.amount or 0.0)
        elif m in MOBILE_METHODS:
            momo_sales += float(cp.amount or 0.0)
        elif m in CARD_METHODS:
            card_sales += float(cp.amount or 0.0)

    cash_expenses = 0.0
    expenses = (
        db.query(Decaissement)
        .filter(
            Decaissement.boutique_id == ctx.boutique.id,
            Decaissement.magasin_id == session.magasin_id,
            Decaissement.deleted_at.is_(None),
            Decaissement.date >= session.opened_at,
            Decaissement.date <= now,
        )
        .all()
    )
    for d in expenses:
        if (d.payment_method or "").strip().lower() in CASH_METHODS:
            cash_expenses += float(d.amount or 0.0)

    expected_cash = round(float(session.opening_balance or 0.0) + cash_sales - cash_expenses, 2)
    declared_cash = round(float(payload.declared_cash), 2)
    discrepancy = round(declared_cash - expected_cash, 2)
    uname = ctx.user.full_name or ctx.user.username

    session.expected_cash = expected_cash
    session.expected_mobile_money = round(momo_sales, 2)
    session.expected_card = round(card_sales, 2)
    session.declared_cash = declared_cash
    session.discrepancy = discrepancy
    session.status = "closed"
    session.closed_by_user_id = ctx.user.id
    session.closed_by_name = uname
    session.closed_at = now
    if payload.notes:
        session.notes = f"{session.notes or ''}\n{payload.notes}".strip()

    db.add(AuditLog(
        boutique_id=ctx.boutique.id,
        user_id=ctx.user.id,
        user_name=uname,
        action="CASH_SESSION_CLOSE",
        entity_type="cash_register_session",
        entity_id=session.id,
        details={
            "expected_cash": expected_cash,
            "declared_cash": declared_cash,
            "discrepancy": discrepancy,
            "expected_mobile_money": session.expected_mobile_money,
            "expected_card": session.expected_card,
        },
        created_at=now,
    ))
    db.commit()
    db.refresh(session)
    return _serialize_session(db, session)
