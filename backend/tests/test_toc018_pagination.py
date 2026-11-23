import uuid
from fastapi.testclient import TestClient
from app.main import app
from app.core.database import SessionLocal
from app.models import (
    Approvisionnement,
    AuditLog,
    Boutique,
    BoutiqueUserMembership,
    Client,
    Decaissement,
    Magasin,
    Product,
    SaasPlan,
    SaasSubscription,
    Supplier,
    User,
    Vente,
)
from app.core.security import get_password_hash


def _setup_pagination_tenant():
    db = SessionLocal()
    uid = uuid.uuid4().hex[:6]
    username = f"pag_owner_{uid}"
    password = "Password123!"
    try:
        user = User(
            id=f"u-pag-{uid}",
            username=username,
            hashed_password=get_password_hash(password),
            role="owner",
            is_active=True,
        )
        db.add(user)
        db.flush()

        boutique = Boutique(
            slug=f"pag-shop-{uid}",
            name=f"Pagination Shop {uid}",
            owner_user_id=user.id,
            currency="XOF",
            is_active=True,
        )
        db.add(boutique)
        db.flush()
        user.boutique_id = boutique.id

        db.add(
            BoutiqueUserMembership(
                boutique_id=boutique.id,
                user_id=user.id,
                role="owner",
                is_active=True,
            )
        )

        pro_plan = db.query(SaasPlan).filter(SaasPlan.code == "pro").first()
        if not pro_plan:
            pro_plan = db.query(SaasPlan).first()
        assert pro_plan is not None
        db.add(
            SaasSubscription(
                boutique_id=boutique.id,
                plan_id=pro_plan.id,
                status="active",
                billing_cycle="monthly",
            )
        )

        mag = Magasin(boutique_id=boutique.id, name="Magasin Test", code="MT", is_active=True)
        db.add(mag)
        db.flush()

        for i in range(7):
            db.add(
                Product(
                    sync_id=f"p-pag-{uid}-{i}",
                    boutique_id=boutique.id,
                    name=f"Produit {i:02d}",
                    price=1000.0 + i * 100,
                    cost_price=500.0,
                    stock=0.0 if i < 2 else (3.0 if i < 4 else 20.0),
                    min_stock=5.0,
                )
            )
            db.add(
                Client(
                    sync_id=f"c-pag-{uid}-{i}",
                    boutique_id=boutique.id,
                    name=f"Client {i:02d}",
                    balance=1500.0 if i < 3 else 0.0,
                )
            )
            db.add(
                Supplier(
                    sync_id=f"s-pag-{uid}-{i}",
                    boutique_id=boutique.id,
                    name=f"Fournisseur {i:02d}",
                    balance=2500.0 if i < 2 else 0.0,
                )
            )
            db.add(
                Decaissement(
                    sync_id=f"d-pag-{uid}-{i}",
                    boutique_id=boutique.id,
                    magasin_id=mag.id,
                    title=f"Charge {i}",
                    amount=500.0,
                    category="Divers",
                )
            )
            db.add(
                Approvisionnement(
                    sync_id=f"a-pag-{uid}-{i}",
                    boutique_id=boutique.id,
                    magasin_id=mag.id,
                    product_sync_id=f"p-pag-{uid}-{i}",
                    product_name=f"Produit {i:02d}",
                    quantity=2.0,
                    unit_cost=500.0,
                    total_cost=1000.0,
                )
            )
            db.add(
                Vente(
                    sync_id=f"v-pag-{uid}-{i}",
                    boutique_id=boutique.id,
                    magasin_id=mag.id,
                    ticket_number=f"T-{uid}-{i}",
                    total_amount=2000.0,
                    paid_amount=1000.0 if i == 0 else 2000.0,
                    payment_method="Crédit" if i == 0 else "Espèces",
                )
            )
            db.add(
                AuditLog(
                    boutique_id=boutique.id,
                    user_id=user.id,
                    user_name=username,
                    action="SALE_CREATE",
                    entity_type="vente",
                    entity_id=f"v-pag-{uid}-{i}",
                )
            )
        db.commit()
    finally:
        db.close()
    return username, password


def test_toc018_paginated_endpoints_and_legacy_compatibility():
    username, password = _setup_pagination_tenant()
    with TestClient(app) as tc:
        login = tc.post("/api/v1/auth/login", json={"username_or_email": username, "password": password})
        assert login.status_code == 200
        headers = {"Authorization": f"Bearer {login.json()['access_token']}"}

        # Legacy format preserved by default (paginated=False) across endpoints
        for endpoint in (
            "/api/v1/products",
            "/api/v1/clients",
            "/api/v1/suppliers",
            "/api/v1/approvisionnements",
            "/api/v1/decaissements",
            "/api/v1/ventes",
        ):
            res = tc.get(endpoint, headers=headers)
            assert res.status_code == 200, f"{endpoint}: {res.text}"
            payload = res.json()
            assert isinstance(payload, list) and len(payload) == 7

        # Paginated products page 1 & page 3 + SQL summary
        p1 = tc.get("/api/v1/products?paginated=true&page=1&limit=3", headers=headers)
        assert p1.status_code == 200
        body = p1.json()
        assert body["total"] == 7
        assert body["page"] == 1
        assert body["pages"] == 3
        assert len(body["items"]) == 3
        assert body["summary"]["total"] == 7
        assert body["summary"]["out_of_stock"] == 2
        assert body["summary"]["low_stock"] == 2
        assert body["summary"]["in_stock"] == 3

        p3 = tc.get("/api/v1/products?paginated=true&page=3&limit=3", headers=headers)
        assert len(p3.json()["items"]) == 1

        # Clients pagination + global debt summary even when filtered
        cl = tc.get("/api/v1/clients?paginated=true&page=1&limit=2&only_debtors=true", headers=headers)
        assert cl.status_code == 200
        cl_data = cl.json()
        assert cl_data["total"] == 3
        assert cl_data["pages"] == 2
        assert len(cl_data["items"]) == 2
        assert cl_data["summary"]["total_clients"] == 7
        assert cl_data["summary"]["debtors_count"] == 3
        assert cl_data["summary"]["total_debt"] == 4500.0

        # Suppliers pagination
        sup = tc.get("/api/v1/suppliers?paginated=true&page=2&limit=4", headers=headers)
        assert sup.status_code == 200
        assert len(sup.json()["items"]) == 3
        assert sup.json()["summary"]["total_debt"] == 5000.0

        # Ventes pagination + credit summary
        ven = tc.get("/api/v1/ventes?paginated=true&page=1&limit=3&only_credit=true", headers=headers)
        assert ven.status_code == 200
        vdata = ven.json()
        assert vdata["total"] == 1
        assert vdata["summary"]["total_count"] == 7
        assert vdata["summary"]["total_amount"] == 14000.0
        assert vdata["summary"]["total_credit"] == 1000.0

        # Approvisionnements & decaissements pagination
        app_res = tc.get("/api/v1/approvisionnements?paginated=true&page=1&limit=5", headers=headers)
        assert app_res.status_code == 200
        assert len(app_res.json()["items"]) == 5
        assert app_res.json()["summary"]["total_cost"] == 7000.0

        dec_res = tc.get("/api/v1/decaissements?paginated=true&page=2&limit=5", headers=headers)
        assert dec_res.status_code == 200
        assert len(dec_res.json()["items"]) == 2
        assert dec_res.json()["summary"]["total_amount"] == 3500.0

        # Audit pagination with page param (7 SALE_CREATE seeded + 1 LOGIN from auth)
        aud = tc.get("/api/v1/audit/logs?action=SALE_CREATE&page=2&limit=4", headers=headers)
        assert aud.status_code == 200
        adata = aud.json()
        assert adata["total"] == 7
        assert adata["page"] == 2
        assert adata["pages"] == 2
        assert len(adata["items"]) == 3
