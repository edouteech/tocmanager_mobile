from datetime import datetime, timezone
from typing import Optional
from sqlalchemy.orm import Session
from app.models import (
    Category, Product, Client, Supplier, Vente, Approvisionnement, Decaissement
)
from app.schemas.sync import (
    SyncPullResponse,
    CategorySync, ProductSync, ClientSync, SupplierSync,
    VenteSync, VenteItemSync, DecaissementSync, ApprovisionnementSync,
)


def pull_boutique_changes(
    db: Session,
    boutique_id: str,
    since: Optional[datetime] = None,
) -> SyncPullResponse:
    """Télécharge les données cloisonnées d'une boutique modifiées depuis 'since'."""
    now = datetime.now(timezone.utc)

    def _scoped(model):
        query = db.query(model).filter(model.boutique_id == boutique_id)
        if since is not None:
            query = query.filter(model.updated_at >= since)
        return query

    cat_rows = _scoped(Category).all()
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

    prod_rows = _scoped(Product).all()
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

    client_rows = _scoped(Client).all()
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

    sup_rows = _scoped(Supplier).all()
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

    vente_rows = _scoped(Vente).all()
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

    dec_rows = _scoped(Decaissement).all()
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

    app_rows = _scoped(Approvisionnement).all()
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
