from datetime import datetime, timezone
from typing import Any, List, Optional, Tuple
from fastapi import HTTPException
from sqlalchemy.orm import Session, selectinload

from app.models import (
    Category, Product, Client, Supplier, Vente, Approvisionnement, Decaissement
)
from app.schemas.sync import (
    SyncPullResponse,
    CategorySync, ProductSync, ClientSync, SupplierSync,
    VenteSync, VenteItemSync, DecaissementSync, ApprovisionnementSync,
)
from app.services.product_magasin_service import enrich_products_for_context


def _parse_pull_cursor(cursor: Optional[str]) -> Tuple[str, int]:
    """Parse '<phase>:<page>' cursor into validated (phase, page)."""
    if cursor is None or not cursor.strip():
        return ("master", 1)
    parts = cursor.strip().split(":", 1)
    if len(parts) != 2 or parts[0] not in ("master", "ops"):
        raise HTTPException(status_code=400, detail="Curseur de synchronisation invalide")
    try:
        page = int(parts[1])
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Curseur de synchronisation invalide") from exc
    if page < 1:
        raise HTTPException(status_code=400, detail="Curseur de synchronisation invalide")
    return (parts[0], page)


def _fetch_page(query, limit: Optional[int], page: int) -> Tuple[List[Any], bool]:
    """Fetch all rows when limit is None, or a lookahead page of size limit."""
    if limit is None:
        return query.all(), False
    offset = (page - 1) * limit
    rows = query.offset(offset).limit(limit + 1).all()
    return rows[:limit], len(rows) > limit


def _serialize_products(
    db: Session,
    boutique_id: str,
    magasin_id: Optional[str],
    prod_rows: List[Product],
) -> List[ProductSync]:
    if not prod_rows:
        return []
    if magasin_id:
        active_prods = [p for p in prod_rows if p.deleted_at is None]
        deleted_prods = [p for p in prod_rows if p.deleted_at is not None]
        enriched = enrich_products_for_context(db, boutique_id, magasin_id, active_prods)
        products = [ProductSync(**p) for p in enriched]
        for dp in deleted_prods:
            products.append(ProductSync(
                sync_id=dp.sync_id, name=dp.name, category_sync_id=dp.category_sync_id,
                price=dp.price, cost_price=dp.cost_price, average_cost_price=dp.average_cost_price,
                stock=dp.stock, min_stock=dp.min_stock, barcode=dp.barcode, unit=dp.unit,
                image_path=dp.image_path, is_active=False, updated_at=dp.updated_at,
                deleted_at=dp.deleted_at, is_available=False, magasin_id=magasin_id,
            ))
        return products
    return [
        ProductSync(
            sync_id=p.sync_id, name=p.name, category_sync_id=p.category_sync_id,
            price=p.price, cost_price=p.cost_price, average_cost_price=p.average_cost_price,
            stock=p.stock, min_stock=p.min_stock, barcode=p.barcode, unit=p.unit,
            image_path=p.image_path, is_active=p.is_active,
            updated_at=p.updated_at, deleted_at=p.deleted_at,
        )
        for p in prod_rows
    ]


def _serialize_ventes(vente_rows: List[Vente]) -> List[VenteSync]:
    return [
        VenteSync(
            sync_id=v.sync_id, magasin_id=v.magasin_id, ticket_number=v.ticket_number,
            client_sync_id=v.client_sync_id, client_name=v.client_name,
            user_id=v.user_id, user_name=v.user_name, total_amount=v.total_amount,
            paid_amount=v.paid_amount, discount_amount=v.discount_amount,
            payment_method=v.payment_method,
            status=getattr(v, "status", "completed") or "completed",
            notes=v.notes, created_at=v.created_at, updated_at=v.updated_at,
            items=[
                VenteItemSync(
                    sync_id=it.sync_id, product_sync_id=it.product_sync_id,
                    product_name=it.product_name, quantity=it.quantity,
                    unit_price=it.unit_price, cost_price=it.cost_price, total=it.total,
                )
                for it in v.items
            ],
        )
        for v in vente_rows
    ]


def pull_boutique_changes(
    db: Session,
    boutique_id: str,
    since: Optional[datetime] = None,
    magasin_id: Optional[str] = None,
    limit: Optional[int] = None,
    cursor: Optional[str] = None,
) -> SyncPullResponse:
    """Download boutique changes since 'since', with optional cursor pagination."""
    now = datetime.now(timezone.utc)
    phase, page = _parse_pull_cursor(cursor) if limit is not None else ("master", 1)

    def _scoped(model, by_magasin: bool = False):
        query = db.query(model).filter(model.boutique_id == boutique_id)
        if by_magasin and magasin_id:
            query = query.filter(model.magasin_id == magasin_id)
        if since is not None:
            query = query.filter(model.updated_at >= since)
        return query.order_by(model.sync_id.asc())

    categories: List[CategorySync] = []
    products: List[ProductSync] = []
    clients: List[ClientSync] = []
    suppliers: List[SupplierSync] = []

    if phase == "master":
        if limit is None or page == 1:
            categories = [
                CategorySync(
                    sync_id=c.sync_id, name=c.name, description=c.description,
                    color=c.color, icon=c.icon, updated_at=c.updated_at, deleted_at=c.deleted_at,
                )
                for c in _scoped(Category).all()
            ]
        prod_rows, prod_more = _fetch_page(_scoped(Product), limit, page)
        products = _serialize_products(db, boutique_id, magasin_id, prod_rows)

        client_rows, client_more = _fetch_page(_scoped(Client), limit, page)
        clients = [
            ClientSync(
                sync_id=cl.sync_id, name=cl.name, phone=cl.phone, email=cl.email,
                address=cl.address, balance=cl.balance, notes=cl.notes,
                updated_at=cl.updated_at, deleted_at=cl.deleted_at,
            )
            for cl in client_rows
        ]

        sup_rows, sup_more = _fetch_page(_scoped(Supplier), limit, page)
        suppliers = [
            SupplierSync(
                sync_id=s.sync_id, name=s.name, contact_person=s.contact_person,
                phone=s.phone, email=s.email, address=s.address, balance=s.balance,
                notes=s.notes, updated_at=s.updated_at, deleted_at=s.deleted_at,
            )
            for s in sup_rows
        ]

        if limit is not None and (prod_more or client_more or sup_more):
            return SyncPullResponse(
                server_time=now, categories=categories, products=products,
                clients=clients, suppliers=suppliers,
                has_more=True, next_cursor=f"master:{page + 1}",
            )
        ops_page = 1
    else:
        ops_page = page

    vente_q = _scoped(Vente, by_magasin=True).options(selectinload(Vente.items))
    vente_rows, vente_more = _fetch_page(vente_q, limit, ops_page)
    ventes = _serialize_ventes(vente_rows)

    dec_rows, dec_more = _fetch_page(_scoped(Decaissement, by_magasin=True), limit, ops_page)
    decaissements = [
        DecaissementSync(
            sync_id=d.sync_id, magasin_id=d.magasin_id, title=d.title, amount=d.amount,
            category=d.category, beneficiary=d.beneficiary, payment_method=d.payment_method,
            date=d.date, notes=d.notes, updated_at=d.updated_at, deleted_at=d.deleted_at,
        )
        for d in dec_rows
    ]

    app_rows, app_more = _fetch_page(_scoped(Approvisionnement, by_magasin=True), limit, ops_page)
    approvisionnements = [
        ApprovisionnementSync(
            sync_id=a.sync_id, magasin_id=a.magasin_id, supplier_sync_id=a.supplier_sync_id,
            supplier_name=a.supplier_name, product_sync_id=a.product_sync_id,
            product_name=a.product_name, quantity=a.quantity, unit_cost=a.unit_cost,
            total_cost=a.total_cost, payment_status=a.payment_status, date=a.date,
            notes=a.notes, updated_at=a.updated_at, deleted_at=a.deleted_at,
        )
        for a in app_rows
    ]

    has_more = limit is not None and (vente_more or dec_more or app_more)
    next_cursor = f"ops:{ops_page + 1}" if has_more else None

    return SyncPullResponse(
        server_time=now, categories=categories, products=products, clients=clients,
        suppliers=suppliers, ventes=ventes, decaissements=decaissements,
        approvisionnements=approvisionnements, has_more=has_more, next_cursor=next_cursor,
    )
