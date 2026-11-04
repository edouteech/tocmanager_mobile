import uuid
from typing import Any, List, Optional
from datetime import datetime, date, timezone
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
from sqlalchemy import func
from app.api import deps
from app.core.database import get_db
from app.models import Vente, VenteItem, Product, Client, AuditLog, User
from app.schemas.sync import VenteSync, VenteItemSync
from app.schemas.entities import VenteCreate
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

@router.post("", response_model=VenteSync, status_code=status.HTTP_201_CREATED)
def create_vente(
    vente_in: VenteCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(deps.get_current_user),
) -> Any:
    """
    Enregistre une nouvelle vente directe depuis le Back-office :
    - Décrémente automatiquement le stock des produits vendus.
    - Met à jour le solde / la dette du client si paiement partiel ou à crédit.
    - Génère le numéro de ticket de vente et un sync_id UUID.
    - Émet un log d'audit.
    """
    if not vente_in.items:
        raise HTTPException(status_code=400, detail="La vente doit contenir au moins un article.")

    now = datetime.now(timezone.utc)
    today_str = now.strftime("%Y%m%d")

    # Calcul du numéro de ticket
    total_sales_count = db.query(func.count(Vente.sync_id)).scalar() or 0
    ticket_num = f"VNT-{today_str}-{(total_sales_count + 1):04d}"

    # Validation et préparation des articles
    db_items = []
    calculated_subtotal = 0.0

    for item_in in vente_in.items:
        prod = db.query(Product).filter(
            Product.sync_id == item_in.product_sync_id,
            Product.deleted_at.is_(None)
        ).first()

        if not prod:
            raise HTTPException(
                status_code=404,
                detail=f"Produit ID {item_in.product_sync_id} introuvable"
            )

        if prod.stock < item_in.quantity:
            raise HTTPException(
                status_code=400,
                detail=f"Stock insuffisant pour '{prod.name}' (Disponible: {prod.stock}, Demandé: {item_in.quantity})"
            )

        line_total = round(item_in.quantity * item_in.unit_price, 2)
        calculated_subtotal += line_total
        cost_price = item_in.cost_price if item_in.cost_price is not None else (prod.average_cost_price or prod.cost_price or 0.0)

        # Décrémenter le stock
        prod.stock -= item_in.quantity
        prod.updated_at = now

        db_item = VenteItem(
            sync_id=str(uuid.uuid4()),
            product_sync_id=prod.sync_id,
            product_name=prod.name,
            quantity=item_in.quantity,
            unit_price=item_in.unit_price,
            cost_price=cost_price,
            total=line_total,
        )
        db_items.append(db_item)

    net_total = max(0.0, round(calculated_subtotal - vente_in.discount_amount, 2))

    # Gestion du client & créance
    target_client = None
    client_name = vente_in.client_name
    if vente_in.client_sync_id:
        target_client = db.query(Client).filter(
            Client.sync_id == vente_in.client_sync_id,
            Client.deleted_at.is_(None)
        ).first()
        if target_client:
            client_name = target_client.name
            if vente_in.paid_amount < net_total:
                reliquat = round(net_total - vente_in.paid_amount, 2)
                target_client.balance += reliquat
                target_client.updated_at = now

    v_uid = current_user.id
    v_uname = current_user.full_name or current_user.username
    vente_sync_id = str(uuid.uuid4())

    new_vente = Vente(
        sync_id=vente_sync_id,
        ticket_number=ticket_num,
        client_sync_id=target_client.sync_id if target_client else None,
        client_name=client_name or "Client Occasionnel",
        user_id=v_uid,
        user_name=v_uname,
        total_amount=net_total,
        paid_amount=vente_in.paid_amount,
        discount_amount=vente_in.discount_amount,
        payment_method=vente_in.payment_method,
        notes=vente_in.notes,
        created_at=now,
        updated_at=now,
    )

    for item in db_items:
        item.vente_sync_id = vente_sync_id
        new_vente.items.append(item)

    db.add(new_vente)

    # Audit log
    db.add(AuditLog(
        id=f"audit-{vente_sync_id}",
        user_id=v_uid,
        user_name=v_uname,
        action="SALE_CREATE",
        entity_type="vente",
        entity_id=vente_sync_id,
        details={
            "ticket_number": ticket_num,
            "total_amount": net_total,
            "paid_amount": vente_in.paid_amount,
            "client_name": client_name or "Client Occasionnel",
            "payment_method": vente_in.payment_method,
            "item_count": len(db_items),
            "source": "backoffice",
        },
        created_at=now,
    ))

    db.commit()
    db.refresh(new_vente)

    return VenteSync(
        sync_id=new_vente.sync_id,
        ticket_number=new_vente.ticket_number,
        client_sync_id=new_vente.client_sync_id,
        client_name=new_vente.client_name,
        total_amount=new_vente.total_amount,
        paid_amount=new_vente.paid_amount,
        discount_amount=new_vente.discount_amount,
        payment_method=new_vente.payment_method,
        notes=new_vente.notes,
        created_at=new_vente.created_at,
        updated_at=new_vente.updated_at,
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
            for it in new_vente.items
        ],
    )

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


