from typing import List, Optional
from datetime import datetime, timezone
import uuid
from fastapi import APIRouter, Depends, HTTPException, Query, status, Response
from sqlalchemy.orm import Session
from sqlalchemy import or_

from app.api import deps
from app.core.database import get_db
from app.models import Client, AuditLog, User, Vente
from app.schemas.entities import ClientCreate, ClientUpdate, ClientResponse, DebtPaymentRequest

router = APIRouter()

@router.get("", response_model=List[ClientResponse])
def list_clients(
    q: Optional[str] = Query(None, description="Recherche par nom, téléphone ou email"),
    only_debtors: bool = Query(False, description="Filtrer uniquement les clients ayant une dette"),
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
    current_user: User = Depends(deps.get_current_user),
    db: Session = Depends(get_db),
):
    """Liste tous les clients avec recherche et filtre d'impayés."""
    query = db.query(Client).filter(Client.deleted_at.is_(None))

    if q:
        search = f"%{q.strip()}%"
        query = query.filter(
            or_(
                Client.name.ilike(search),
                Client.phone.ilike(search),
                Client.email.ilike(search),
            )
        )

    if only_debtors:
        query = query.filter(Client.balance > 0)

    return query.order_by(Client.name.asc()).offset(offset).limit(limit).all()

@router.post("", response_model=ClientResponse, status_code=status.HTTP_201_CREATED)
def create_client(
    client_in: ClientCreate,
    current_user: User = Depends(deps.get_current_user),
    db: Session = Depends(get_db),
):
    """Crée un nouveau client et enregistre l'action dans le journal d'audit."""
    now = datetime.now(timezone.utc)
    client = Client(
        sync_id=str(uuid.uuid4()),
        name=client_in.name.strip(),
        phone=client_in.phone.strip() if client_in.phone else None,
        email=client_in.email.strip() if client_in.email else None,
        address=client_in.address,
        balance=client_in.balance,
        notes=client_in.notes,
        user_id=current_user.id,
        user_name=current_user.full_name or current_user.username,
        created_at=now,
        updated_at=now,
    )
    db.add(client)
    db.flush()

    db.add(AuditLog(
        user_id=current_user.id,
        user_name=current_user.full_name or current_user.username,
        action="CLIENT_CREATE",
        entity_type="client",
        entity_id=client.sync_id,
        details={"name": client.name, "phone": client.phone, "initial_balance": client.balance},
        created_at=now,
    ))
    db.commit()
    db.refresh(client)
    return client

@router.get("/{sync_id}", response_model=ClientResponse)
def get_client(
    sync_id: str,
    current_user: User = Depends(deps.get_current_user),
    db: Session = Depends(get_db),
):
    """Récupère la fiche détaillée d'un client."""
    client = db.query(Client).filter(Client.sync_id == sync_id, Client.deleted_at.is_(None)).first()
    if not client:
        raise HTTPException(status_code=404, detail="Client introuvable")
    return client

@router.put("/{sync_id}", response_model=ClientResponse)
def update_client(
    sync_id: str,
    client_in: ClientUpdate,
    current_user: User = Depends(deps.require_role(["admin", "manager"])),
    db: Session = Depends(get_db),
):
    """Met à jour un client existant."""
    client = db.query(Client).filter(Client.sync_id == sync_id, Client.deleted_at.is_(None)).first()
    if not client:
        raise HTTPException(status_code=404, detail="Client introuvable")

    update_data = client_in.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(client, field, value)

    now = datetime.now(timezone.utc)
    client.updated_at = now

    db.add(AuditLog(
        user_id=current_user.id,
        user_name=current_user.full_name or current_user.username,
        action="CLIENT_UPDATE",
        entity_type="client",
        entity_id=client.sync_id,
        details=update_data,
        created_at=now,
    ))
    db.commit()
    db.refresh(client)
    return client

@router.delete("/{sync_id}", status_code=status.HTTP_204_NO_CONTENT, response_class=Response)
def delete_client(
    sync_id: str,
    current_user: User = Depends(deps.require_role(["admin", "manager"])),
    db: Session = Depends(get_db),
):
    """Suppression logique d'un client."""
    client = db.query(Client).filter(Client.sync_id == sync_id, Client.deleted_at.is_(None)).first()
    if not client:
        raise HTTPException(status_code=404, detail="Client introuvable")

    now = datetime.now(timezone.utc)
    client.deleted_at = now
    client.updated_at = now

    db.add(AuditLog(
        user_id=current_user.id,
        user_name=current_user.full_name or current_user.username,
        action="CLIENT_DELETE",
        entity_type="client",
        entity_id=client.sync_id,
        details={"name": client.name},
        created_at=now,
    ))
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)

@router.post("/{sync_id}/payments", response_model=ClientResponse)
def record_client_payment(
    sync_id: str,
    payment: DebtPaymentRequest,
    current_user: User = Depends(deps.get_current_user),
    db: Session = Depends(get_db),
):
    """Enregistre un règlement de dette client et réduit son solde débiteur."""
    client = db.query(Client).filter(Client.sync_id == sync_id, Client.deleted_at.is_(None)).first()
    if not client:
        raise HTTPException(status_code=404, detail="Client introuvable")

    previous_balance = client.balance
    new_balance = max(0.0, client.balance - payment.amount)
    client.balance = new_balance

    now = datetime.now(timezone.utc)
    client.updated_at = now

    db.add(AuditLog(
        user_id=current_user.id,
        user_name=current_user.full_name or current_user.username,
        action="DEBT_PAYMENT",
        entity_type="client",
        entity_id=client.sync_id,
        details={
            "client_name": client.name,
            "amount_paid": payment.amount,
            "payment_method": payment.payment_method,
            "previous_balance": previous_balance,
            "new_balance": new_balance,
            "notes": payment.notes,
        },
        created_at=now,
    ))
    db.commit()
    db.refresh(client)
    return client
