from typing import Any, List, Optional
from datetime import datetime, timezone
import uuid
from fastapi import APIRouter, Depends, HTTPException, Query, status, Response
from sqlalchemy import case, func, or_
from sqlalchemy.orm import Session

from app.api import deps
from app.core.database import get_db
from app.models import Decaissement, AuditLog
from app.schemas.entities import DecaissementCreate, DecaissementResponse
from app.services.entitlements import check_feature_access
from app.services.pagination_service import paginate_sqlalchemy
from app.services.tenant_context_service import (
    TenantContext,
    resolve_operational_magasin,
    resolve_read_magasin_id,
)

router = APIRouter()


@router.get("", response_model=Any)
def list_decaissements(
    category: Optional[str] = Query(None, description="Filtrer par catégorie"),
    q: Optional[str] = Query(None),
    start_date: Optional[datetime] = Query(None),
    end_date: Optional[datetime] = Query(None),
    paginated: bool = False,
    page: int = Query(1, ge=1),
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
    ctx: TenantContext = Depends(deps.get_tenant_context),
    db: Session = Depends(get_db),
):
    check_feature_access(db, ctx.boutique.id, "module_expenses")
    magasin_id = resolve_read_magasin_id(ctx)
    base_query = db.query(Decaissement).filter(
        Decaissement.boutique_id == ctx.boutique.id,
        Decaissement.deleted_at.is_(None),
    )
    if magasin_id:
        base_query = base_query.filter(Decaissement.magasin_id == magasin_id)
    query = base_query
    if category:
        query = query.filter(Decaissement.category == category)
    if q and q.strip():
        term = f"%{q.strip()}%"
        query = query.filter(
            or_(
                Decaissement.title.ilike(term),
                Decaissement.beneficiary.ilike(term),
                Decaissement.category.ilike(term),
            )
        )
    if start_date:
        query = query.filter(Decaissement.date >= start_date)
    if end_date:
        query = query.filter(Decaissement.date <= end_date)

    ordered = query.order_by(Decaissement.date.desc())
    if not paginated:
        return [
            DecaissementResponse.model_validate(d).model_dump()
            for d in ordered.offset(offset).limit(limit).all()
        ]

    today = datetime.now(timezone.utc).date()
    today_expr = case((func.date(Decaissement.date) == today, Decaissement.amount), else_=0.0)
    total_count, total_amount, today_amount = base_query.with_entities(
        func.count(Decaissement.sync_id),
        func.coalesce(func.sum(Decaissement.amount), 0.0),
        func.coalesce(func.sum(today_expr), 0.0),
    ).one()
    filtered_amount = query.with_entities(func.coalesce(func.sum(Decaissement.amount), 0.0)).scalar() or 0.0
    summary = {
        "total_count": int(total_count or 0),
        "total_amount": float(total_amount or 0.0),
        "today_amount": float(today_amount or 0.0),
        "filtered_amount": float(filtered_amount or 0.0),
    }
    return paginate_sqlalchemy(
        ordered,
        page=page,
        limit=limit,
        summary=summary,
        serializer=lambda d: DecaissementResponse.model_validate(d).model_dump(),
    )


@router.get("/categories", response_model=List[str])
def list_expense_categories(
    include_defaults: bool = False,
    ctx: TenantContext = Depends(deps.get_tenant_context),
    db: Session = Depends(get_db),
):
    check_feature_access(db, ctx.boutique.id, "module_expenses")
    rows = (
        db.query(Decaissement.category)
        .filter(
            Decaissement.boutique_id == ctx.boutique.id,
            Decaissement.deleted_at.is_(None),
        )
        .distinct()
        .all()
    )
    db_cats = {r[0].strip() for r in rows if r[0] and r[0].strip()}
    defaults = {
        "Transport", "Télécoms", "Entretien", "Consommables",
        "Énergie", "Loyer", "Salaires", "Fournisseur", "Divers",
    }
    if include_defaults or not db_cats:
        return sorted(list(db_cats.union(defaults)))
    return sorted(list(db_cats))


@router.post("", response_model=DecaissementResponse, status_code=status.HTTP_201_CREATED)
def create_decaissement(
    dec_in: DecaissementCreate,
    ctx: TenantContext = Depends(deps.get_tenant_context),
    db: Session = Depends(get_db),
):
    check_feature_access(db, ctx.boutique.id, "module_expenses")
    magasin = resolve_operational_magasin(
        db, ctx, body_magasin_id=dec_in.magasin_id, allow_warehouse=True
    )
    current_user = ctx.user
    now = datetime.now(timezone.utc)
    dec_date = dec_in.date or now

    dec = Decaissement(
        sync_id=str(uuid.uuid4()),
        boutique_id=ctx.boutique.id,
        magasin_id=magasin.id,
        title=dec_in.title.strip(),
        amount=round(dec_in.amount, 2),
        category=dec_in.category or "Général",
        beneficiary=dec_in.beneficiary,
        payment_method=dec_in.payment_method,
        date=dec_date,
        notes=dec_in.notes,
        user_id=current_user.id,
        user_name=current_user.full_name or current_user.username,
        created_at=now,
        updated_at=now,
    )
    db.add(dec)
    db.flush()

    db.add(AuditLog(
        boutique_id=ctx.boutique.id,
        user_id=current_user.id,
        user_name=current_user.full_name or current_user.username,
        action="EXPENSE_CREATE",
        entity_type="decaissement",
        entity_id=dec.sync_id,
        details={
            "title": dec.title,
            "amount": dec.amount,
            "category": dec.category,
            "beneficiary": dec.beneficiary,
            "payment_method": dec.payment_method,
        },
        created_at=now,
    ))
    db.commit()
    db.refresh(dec)
    return dec


@router.delete("/{sync_id}", status_code=status.HTTP_204_NO_CONTENT, response_class=Response)
def delete_decaissement(
    sync_id: str,
    ctx: TenantContext = Depends(deps.require_tenant_role(["owner", "store_admin", "manager"])),
    db: Session = Depends(get_db),
):
    check_feature_access(db, ctx.boutique.id, "module_expenses")
    current_user = ctx.user
    dec = (
        db.query(Decaissement)
        .filter(
            Decaissement.sync_id == sync_id,
            Decaissement.boutique_id == ctx.boutique.id,
            Decaissement.deleted_at.is_(None),
        )
        .first()
    )
    if not dec:
        raise HTTPException(status_code=404, detail="Dépense introuvable")

    now = datetime.now(timezone.utc)
    dec.deleted_at = now
    dec.updated_at = now

    db.add(AuditLog(
        boutique_id=ctx.boutique.id,
        user_id=current_user.id,
        user_name=current_user.full_name or current_user.username,
        action="EXPENSE_DELETE",
        entity_type="decaissement",
        entity_id=dec.sync_id,
        details={"title": dec.title, "amount": dec.amount},
        created_at=now,
    ))
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
