from typing import Any, List, Optional
from datetime import datetime, date
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.api import deps
from app.core.database import get_db
from app.models import Vente, VenteItem, User
from app.schemas.sync import VenteSync, VenteItemSync
from pydantic import BaseModel

router = APIRouter()

@router.get("", response_model=List[VenteSync])
def list_ventes(
    skip: int = 0,
    limit: int = 100,
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(deps.get_current_user),
) -> Any:
    query = db.query(Vente).filter(Vente.deleted_at.is_(None))
    if start_date:
        query = query.filter(func.date(Vente.created_at) >= start_date)
    if end_date:
        query = query.filter(func.date(Vente.created_at) <= end_date)
    
    ventes = query.order_by(Vente.created_at.desc()).offset(skip).limit(limit).all()
    return [
        VenteSync(
            sync_id=v.sync_id,
            ticket_number=v.ticket_number,
            client_sync_id=v.client_sync_id,
            client_name=v.client_name,
            total_amount=v.total_amount,
            paid_amount=v.paid_amount,
            discount_amount=v.discount_amount,
            payment_method=v.payment_method,
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
        for v in ventes
    ]

@router.get("/{sync_id}", response_model=VenteSync)
def get_vente(
    sync_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(deps.get_current_user),
) -> Any:
    v = db.query(Vente).filter(Vente.sync_id == sync_id).first()
    if not v:
        raise HTTPException(status_code=404, detail="Vente non trouvée")
    return VenteSync(
        sync_id=v.sync_id,
        ticket_number=v.ticket_number,
        client_sync_id=v.client_sync_id,
        client_name=v.client_name,
        total_amount=v.total_amount,
        paid_amount=v.paid_amount,
        discount_amount=v.discount_amount,
        payment_method=v.payment_method,
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
