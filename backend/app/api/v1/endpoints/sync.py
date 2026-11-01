from datetime import datetime, timezone
from typing import Any, Optional
from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session
from app.api import deps
from app.core.database import get_db
from app.models import (
    User, Category, Product, Client, Supplier, Vente, VenteItem,
    Approvisionnement, Decaissement, SyncEvent, AuditLog
)
from app.schemas.sync import (
    SyncPullResponse, SyncPushRequest, SyncPushResult,
    CategorySync, ProductSync, ClientSync, SupplierSync,
    VenteSync, VenteItemSync, DecaissementSync, ApprovisionnementSync
)

router = APIRouter()

@router.get("/pull", response_model=SyncPullResponse)
def pull_changes(
    since: Optional[datetime] = Query(None, description="Timestamp UTC du dernier pull"),
    current_user: User = Depends(deps.get_current_user),
    db: Session = Depends(get_db),
) -> Any:
    """Télécharge les données créées ou modifiées depuis le dernier 'since'."""
    now = datetime.now(timezone.utc)

    def _filter(query, model):
        if since is not None:
            return query.filter(model.updated_at >= since)
        return query

    # 1. Categories
    cat_rows = _filter(db.query(Category), Category).all()
    categories = [
        CategorySync(
            sync_id=c.sync_id,
            name=c.name,
            description=c.description,
            color=c.color,
            icon=c.icon,
            updated_at=c.updated_at,
            deleted_at=c.deleted_at,
        )
        for c in cat_rows
    ]

    # 2. Products
    prod_rows = _filter(db.query(Product), Product).all()
    products = [
        ProductSync(
            sync_id=p.sync_id,
            name=p.name,
            category_sync_id=p.category_sync_id,
            price=p.price,
            cost_price=p.cost_price,
            average_cost_price=p.average_cost_price,
            stock=p.stock,
            min_stock=p.min_stock,
            barcode=p.barcode,
            unit=p.unit,
            image_path=p.image_path,
            is_active=p.is_active,
            updated_at=p.updated_at,
            deleted_at=p.deleted_at,
        )
        for p in prod_rows
    ]

    # 3. Clients
    client_rows = _filter(db.query(Client), Client).all()
    clients = [
        ClientSync(
            sync_id=cl.sync_id,
            name=cl.name,
            phone=cl.phone,
            email=cl.email,
            address=cl.address,
            balance=cl.balance,
            notes=cl.notes,
            updated_at=cl.updated_at,
            deleted_at=cl.deleted_at,
        )
        for cl in client_rows
    ]

    # 4. Suppliers
    sup_rows = _filter(db.query(Supplier), Supplier).all()
    suppliers = [
        SupplierSync(
            sync_id=s.sync_id,
            name=s.name,
            contact_person=s.contact_person,
            phone=s.phone,
            email=s.email,
            address=s.address,
            balance=s.balance,
            notes=s.notes,
            updated_at=s.updated_at,
            deleted_at=s.deleted_at,
        )
        for s in sup_rows
    ]

    # 5. Ventes
    vente_rows = _filter(db.query(Vente), Vente).all()
    ventes = [
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
        for v in vente_rows
    ]

    # 6. Decaissements
    dec_rows = _filter(db.query(Decaissement), Decaissement).all()
    decaissements = [
        DecaissementSync(
            sync_id=d.sync_id,
            title=d.title,
            amount=d.amount,
            category=d.category,
            beneficiary=d.beneficiary,
            payment_method=d.payment_method,
            date=d.date,
            notes=d.notes,
            updated_at=d.updated_at,
            deleted_at=d.deleted_at,
        )
        for d in dec_rows
    ]

    # 7. Approvisionnements
    app_rows = _filter(db.query(Approvisionnement), Approvisionnement).all()
    approvisionnements = [
        ApprovisionnementSync(
            sync_id=a.sync_id,
            supplier_sync_id=a.supplier_sync_id,
            supplier_name=a.supplier_name,
            product_sync_id=a.product_sync_id,
            product_name=a.product_name,
            quantity=a.quantity,
            unit_cost=a.unit_cost,
            total_cost=a.total_cost,
            payment_status=a.payment_status,
            date=a.date,
            notes=a.notes,
            updated_at=a.updated_at,
            deleted_at=a.deleted_at,
        )
        for a in app_rows
    ]

    return SyncPullResponse(
        server_time=now,
        categories=categories,
        products=products,
        clients=clients,
        suppliers=suppliers,
        ventes=ventes,
        decaissements=decaissements,
        approvisionnements=approvisionnements,
    )

@router.post("/push", response_model=SyncPushResult)
def push_changes(
    payload: SyncPushRequest,
    current_user: User = Depends(deps.get_current_user),
    db: Session = Depends(get_db),
) -> Any:
    """Reçoit un lot d'entités créées ou modifiées hors-ligne (idempotent sur sync_id)."""
    synced_uuids = []
    errors = []

    # 1. Clients
    for cl in payload.clients:
        try:
            cl_uid = cl.user_id or current_user.id
            cl_uname = cl.user_name or (current_user.full_name or current_user.username)
            existing = db.query(Client).filter(Client.sync_id == cl.sync_id).first()
            if existing:
                existing.name = cl.name
                existing.phone = cl.phone
                existing.email = cl.email
                existing.address = cl.address
                existing.balance = cl.balance
                existing.notes = cl.notes
                existing.user_id = cl_uid
                existing.user_name = cl_uname
                existing.updated_at = cl.updated_at or datetime.now(timezone.utc)
            else:
                db.add(Client(
                    sync_id=cl.sync_id,
                    name=cl.name,
                    phone=cl.phone,
                    email=cl.email,
                    address=cl.address,
                    balance=cl.balance,
                    notes=cl.notes,
                    user_id=cl_uid,
                    user_name=cl_uname,
                    created_at=cl.updated_at or datetime.now(timezone.utc),
                    updated_at=cl.updated_at or datetime.now(timezone.utc),
                ))
                db.add(AuditLog(
                    id=f"audit-{cl.sync_id}",
                    user_id=cl_uid,
                    user_name=cl_uname,
                    action="CLIENT_CREATE",
                    entity_type="client",
                    entity_id=cl.sync_id,
                    details={"name": cl.name, "phone": cl.phone, "balance": cl.balance},
                    created_at=cl.updated_at or datetime.now(timezone.utc),
                ))
            synced_uuids.append(cl.sync_id)
        except Exception as e:
            errors.append(f"Client {cl.sync_id}: {str(e)}")

    # 2. Ventes (Idempotent: si la vente existe déjà, on la marque comme synchronisée sans double décrément de stock)
    for v in payload.ventes:
        try:
            existing = db.query(Vente).filter(Vente.sync_id == v.sync_id).first()
            if existing:
                synced_uuids.append(v.sync_id)
                continue

            v_uid = v.user_id or current_user.id
            v_uname = v.user_name or (current_user.full_name or current_user.username)

            # Création de la vente
            new_vente = Vente(
                sync_id=v.sync_id,
                ticket_number=v.ticket_number,
                client_sync_id=v.client_sync_id,
                client_name=v.client_name,
                user_id=v_uid,
                user_name=v_uname,
                total_amount=v.total_amount,
                paid_amount=v.paid_amount,
                discount_amount=v.discount_amount,
                payment_method=v.payment_method,
                notes=v.notes,
                created_at=v.created_at,
                updated_at=v.updated_at or v.created_at,
            )
            db.add(new_vente)

            # Traitement des articles et mise à jour des stocks
            for item in v.items:
                v_item = VenteItem(
                    sync_id=item.sync_id or None,
                    vente_sync_id=v.sync_id,
                    product_sync_id=item.product_sync_id,
                    product_name=item.product_name,
                    quantity=item.quantity,
                    unit_price=item.unit_price,
                    cost_price=item.cost_price,
                    total=item.total,
                )
                db.add(v_item)

                # Décrémenter le stock produit sur le serveur
                if item.product_sync_id:
                    prod = db.query(Product).filter(Product.sync_id == item.product_sync_id).first()
                    if prod:
                        prod.stock -= item.quantity
                        prod.updated_at = datetime.now(timezone.utc)

            # Mise à jour de la créance client si paiement partiel
            if v.client_sync_id and v.paid_amount < v.total_amount:
                reliquat = v.total_amount - v.paid_amount
                target_client = db.query(Client).filter(Client.sync_id == v.client_sync_id).first()
                if target_client:
                    target_client.balance += reliquat
                    target_client.updated_at = datetime.now(timezone.utc)

            # Audit log de la vente
            db.add(AuditLog(
                id=f"audit-{v.sync_id}",
                user_id=v_uid,
                user_name=v_uname,
                action="SALE_CREATE",
                entity_type="vente",
                entity_id=v.sync_id,
                details={
                    "ticket_number": v.ticket_number,
                    "total_amount": v.total_amount,
                    "paid_amount": v.paid_amount,
                    "client_name": v.client_name,
                    "payment_method": v.payment_method,
                    "item_count": len(v.items),
                },
                created_at=v.created_at,
            ))

            synced_uuids.append(v.sync_id)
        except Exception as e:
            errors.append(f"Vente {v.sync_id}: {str(e)}")

    # 3. Décaissements
    for d in payload.decaissements:
        try:
            existing = db.query(Decaissement).filter(Decaissement.sync_id == d.sync_id).first()
            d_uid = d.user_id or current_user.id
            d_uname = d.user_name or (current_user.full_name or current_user.username)
            if not existing:
                db.add(Decaissement(
                    sync_id=d.sync_id,
                    title=d.title,
                    amount=d.amount,
                    category=d.category,
                    beneficiary=d.beneficiary,
                    payment_method=d.payment_method,
                    date=d.date,
                    notes=d.notes,
                    user_id=d_uid,
                    user_name=d_uname,
                    created_at=d.date,
                    updated_at=d.updated_at or d.date,
                ))
                db.add(AuditLog(
                    id=f"audit-{d.sync_id}",
                    user_id=d_uid,
                    user_name=d_uname,
                    action="EXPENSE_CREATE",
                    entity_type="decaissement",
                    entity_id=d.sync_id,
                    details={
                        "title": d.title,
                        "amount": d.amount,
                        "category": d.category,
                        "beneficiary": d.beneficiary,
                    },
                    created_at=d.date,
                ))
            synced_uuids.append(d.sync_id)
        except Exception as e:
            errors.append(f"Decaissement {d.sync_id}: {str(e)}")

    # 4. Approvisionnements
    for a in payload.approvisionnements:
        try:
            existing = db.query(Approvisionnement).filter(Approvisionnement.sync_id == a.sync_id).first()
            a_uid = a.user_id or current_user.id
            a_uname = a.user_name or (current_user.full_name or current_user.username)
            if not existing:
                db.add(Approvisionnement(
                    sync_id=a.sync_id,
                    supplier_sync_id=a.supplier_sync_id,
                    supplier_name=a.supplier_name,
                    product_sync_id=a.product_sync_id,
                    product_name=a.product_name,
                    quantity=a.quantity,
                    unit_cost=a.unit_cost,
                    total_cost=a.total_cost,
                    payment_status=a.payment_status,
                    date=a.date,
                    notes=a.notes,
                    user_id=a_uid,
                    user_name=a_uname,
                    created_at=a.date,
                    updated_at=a.updated_at or a.date,
                ))
                db.add(AuditLog(
                    id=f"audit-{a.sync_id}",
                    user_id=a_uid,
                    user_name=a_uname,
                    action="STOCK_SUPPLY",
                    entity_type="approvisionnement",
                    entity_id=a.sync_id,
                    details={
                        "product_name": a.product_name,
                        "quantity": a.quantity,
                        "unit_cost": a.unit_cost,
                        "total_cost": a.total_cost,
                    },
                    created_at=a.date,
                ))
                # Incrémenter le stock produit
                if a.product_sync_id:
                    prod = db.query(Product).filter(Product.sync_id == a.product_sync_id).first()
                    if prod:
                        prod.stock += a.quantity
                        prod.updated_at = datetime.now(timezone.utc)

            synced_uuids.append(a.sync_id)
        except Exception as e:
            errors.append(f"Approvisionnement {a.sync_id}: {str(e)}")

    # 5. Audit logs poussés directement depuis le terminal mobile
    for al in payload.audit_logs:
        try:
            existing_al = db.query(AuditLog).filter(AuditLog.id == al.sync_id).first()
            if not existing_al:
                db.add(AuditLog(
                    id=al.sync_id,
                    user_id=al.user_id or current_user.id,
                    user_name=al.user_name or (current_user.full_name or current_user.username),
                    action=al.action,
                    entity_type=al.entity_type,
                    entity_id=al.entity_id,
                    details=al.details,
                    created_at=al.created_at,
                ))
            synced_uuids.append(al.sync_id)
        except Exception as e:
            errors.append(f"AuditLog {al.sync_id}: {str(e)}")

    db.commit()

    return SyncPushResult(
        synced_count=len(synced_uuids),
        rejected_count=len(errors),
        synced_uuids=synced_uuids,
        errors=errors,
    )
