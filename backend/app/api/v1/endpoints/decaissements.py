from typing import List, Optional
from datetime import datetime, timezone
import uuid
from fastapi import APIRouter, Depends, HTTPException, Query, status, Response
from sqlalchemy.orm import Session

from app.api import deps
from app.core.database import get_db
from app.models import Decaissement, AuditLog
from app.schemas.entities import DecaissementCreate, DecaissementResponse
from app.services.entitlements import check_feature_access
from app.services.tenant_context_service import TenantContext

router = APIRouter()


@router.get("", response_model=List[DecaissementResponse])
def list_decaissements(
    category: Optional[str] = Query(None, description="Filtrer par catégorie"),
    start_date: Optional[datetime] = Query(None),
    end_date: Optional[datetime] = Query(None),
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
    ctx: TenantContext = Depends(deps.get_tenant_context),
    db: Session = Depends(get_db),
):
    check_feature_access(db, ctx.boutique.id, "module_expenses")
    query = db.query(Decaissement).filter(
        Decaissement.boutique_id == ctx.boutique.id,
        Decaissement.deleted_at.is_(None),
    )
    if category:
        query = query.filter(Decaissement.category == category)
    if start_date:
        query = query.filter(Decaissement.date >= start_date)
    if end_date:
        query = query.filter(Decaissement.date <= end_date)
    return query.order_by(Decaissement.date.desc()).offset(offset).limit(limit).all()


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
    current_user = ctx.user
    now = datetime.now(timezone.utc)
    dec_date = dec_in.date or now

    dec = Decaissement(
        sync_id=str(uuid.uuid4()),
        boutique_id=ctx.boutique.id,
        magasin_id=ctx.requested_magasin_id,
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
