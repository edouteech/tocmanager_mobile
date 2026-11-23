from typing import Any, Optional
from datetime import date, datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session, selectinload
from sqlalchemy import case, func, or_

from app.api import deps
from app.core.database import get_db
from app.models import Vente
from app.schemas.cash import SaleRefundRequest
from app.schemas.sync import VenteSync, VenteItemSync
from app.schemas.entities import VenteCreate
from app.services.pagination_service import paginate_sqlalchemy
from app.services.sale_refund_service import refund_vente
from app.services.tenant_context_service import TenantContext, resolve_read_magasin_id
from app.services.vente_service import create_vente_transaction

router = APIRouter()


def _to_vente_sync(v: Vente) -> VenteSync:
    return VenteSync(
        sync_id=v.sync_id,
        magasin_id=v.magasin_id,
        ticket_number=v.ticket_number,
        client_sync_id=v.client_sync_id,
        client_name=v.client_name,
        user_id=v.user_id,
        user_name=v.user_name,
        total_amount=v.total_amount,
        paid_amount=v.paid_amount,
        discount_amount=v.discount_amount,
        payment_method=v.payment_method,
        status=getattr(v, "status", "completed") or "completed",
        notes=v.notes,
        created_at=v.created_at,
        updated_at=v.updated_at,
        items=[
            VenteItemSync(
                sync_id=it.sync_id,
                product_sync_id=it.product_sync_id,
                product_name=it.product_name,
                quantity=it.quantity,
                unit_price=it.unit_price,
                cost_price=it.cost_price,
                total=it.total,
            )
            for it in v.items
        ],
    )


@router.get("", response_model=Any)
def list_ventes(
    skip: int = 0,
    limit: int = Query(100, ge=1, le=500),
    page: int = Query(1, ge=1),
    paginated: bool = False,
    q: Optional[str] = None,
    only_credit: bool = False,
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    ctx: TenantContext = Depends(deps.get_tenant_context),
    db: Session = Depends(get_db),
) -> Any:
    magasin_id = resolve_read_magasin_id(ctx)
    base_query = db.query(Vente).filter(
        Vente.boutique_id == ctx.boutique.id,
        Vente.deleted_at.is_(None),
    )
    if magasin_id:
        base_query = base_query.filter(Vente.magasin_id == magasin_id)

    filtered = base_query
    if q and q.strip():
        term = f"%{q.strip()}%"
        filtered = filtered.filter(
            or_(Vente.ticket_number.ilike(term), Vente.client_name.ilike(term))
        )
    if only_credit:
        filtered = filtered.filter(
            (Vente.total_amount > Vente.paid_amount) & (Vente.status != "refunded")
        )
    if start_date:
        filtered = filtered.filter(func.date(Vente.created_at) >= start_date)
    if end_date:
        filtered = filtered.filter(func.date(Vente.created_at) <= end_date)

    ordered = filtered.options(selectinload(Vente.items)).order_by(Vente.created_at.desc())
    if not paginated:
        ventes = ordered.offset(skip).limit(limit).all()
        return [_to_vente_sync(v) for v in ventes]

    today = datetime.now(timezone.utc).date()
    credit_expr = case(
        ((Vente.total_amount > Vente.paid_amount) & (Vente.status != "refunded"), Vente.total_amount - Vente.paid_amount),
        else_=0.0,
    )
    non_refunded_amount = case((Vente.status != "refunded", Vente.total_amount), else_=0.0)
    today_expr = case(
        ((func.date(Vente.created_at) == today) & (Vente.status != "refunded"), Vente.total_amount),
        else_=0.0,
    )
    total_count, total_amount, today_amount, total_credit = base_query.with_entities(
        func.count(Vente.sync_id),
        func.coalesce(func.sum(non_refunded_amount), 0.0),
        func.coalesce(func.sum(today_expr), 0.0),
        func.coalesce(func.sum(credit_expr), 0.0),
    ).one()
    filtered_amount = filtered.with_entities(func.coalesce(func.sum(non_refunded_amount), 0.0)).scalar() or 0.0

    summary = {
        "total_count": int(total_count or 0),
        "total_amount": float(total_amount or 0.0),
        "filtered_amount": float(filtered_amount or 0.0),
        "today_amount": float(today_amount or 0.0),
        "total_credit": float(total_credit or 0.0),
    }
    return paginate_sqlalchemy(
        ordered,
        page=page,
        limit=limit,
        summary=summary,
        serializer=lambda v: _to_vente_sync(v).model_dump(),
    )


@router.post("", response_model=VenteSync, status_code=status.HTTP_201_CREATED)
def create_vente(
    vente_in: VenteCreate,
    ctx: TenantContext = Depends(deps.get_tenant_context),
    db: Session = Depends(get_db),
) -> Any:
    return _to_vente_sync(create_vente_transaction(db, ctx, vente_in))


@router.get("/{sync_id}", response_model=VenteSync)
def get_vente(
    sync_id: str,
    ctx: TenantContext = Depends(deps.get_tenant_context),
    db: Session = Depends(get_db),
) -> Any:
    v = db.query(Vente).filter(Vente.sync_id == sync_id, Vente.boutique_id == ctx.boutique.id).first()
    if not v:
        raise HTTPException(status_code=404, detail="Vente non trouvée")
    return _to_vente_sync(v)


@router.post("/{sync_id}/refund", response_model=VenteSync)
def post_refund_vente(
    sync_id: str,
    payload: SaleRefundRequest,
    ctx: TenantContext = Depends(deps.require_tenant_role(["owner", "store_admin", "manager"])),
    db: Session = Depends(get_db),
) -> Any:
    return _to_vente_sync(refund_vente(db, ctx, sync_id, payload))
