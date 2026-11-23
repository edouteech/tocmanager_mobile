from datetime import datetime, timedelta, timezone
import uuid
from fastapi.testclient import TestClient

from app.core.database import SessionLocal
from app.main import app
from app.models import Client, Product, StockMagasin, Supplier, Vente


def _provision(tc: TestClient, tag: str):
    uid = uuid.uuid4().hex[:6]
    ident = f"sync_{tag}_{uid}@example.com"
    reg = tc.post(
        "/api/v1/saas/auth/register-credentials",
        json={
            "full_name": f"Sync {tag}",
            "username_or_email": ident,
            "password": "Password123!",
        },
    )
    assert reg.status_code == 200
    onb_h = {"Authorization": f"Bearer {reg.json()['access_token']}"}
    prov = tc.post(
        "/api/v1/saas/tenant/provision",
        headers=onb_h,
        json={
            "boutique_name": f"Boutique Sync {uid}",
            "magasin_name": "Magasin Principal",
            "plan_code": "pro",
        },
    )
    assert prov.status_code == 200
    data = prov.json()
    login = tc.post(
        "/api/v1/auth/login",
        json={"username_or_email": ident, "password": "Password123!"},
    )
    assert login.status_code == 200
    token = login.json()["access_token"]
    return {
        "boutique_id": data["boutique_id"],
        "magasin_id": data["magasin_id"],
        "headers": {
            "Authorization": f"Bearer {token}",
            "X-Boutique-Id": data["boutique_id"],
            "X-Magasin-Id": data["magasin_id"],
        },
    }


def test_offline_batch_no_double_decrement_and_client_debt_once():
    with TestClient(app) as tc:
        env = _provision(tc, "nodup")
        headers = env["headers"]
        cat = tc.post("/api/v1/categories", headers=headers, json={"name": "Boissons"})
        assert cat.status_code == 201
        prod = tc.post(
            "/api/v1/products",
            headers=headers,
            json={"name": "Eau 1.5L", "category_sync_id": cat.json()["sync_id"], "price": 500, "cost_price": 300, "stock": 10},
        )
        assert prod.status_code == 200
        prod_id = prod.json()["sync_id"]
        cl = tc.post("/api/v1/clients", headers=headers, json={"name": "Client Credit"})
        assert cl.status_code == 201
        cl_id = cl.json()["sync_id"]

        now = datetime.now(timezone.utc)
        vente_id = str(uuid.uuid4())
        # Simulate offline mobile batch pushing updated product stock (10->7) + client balance (0->1500) AND the credit vente
        res = tc.post(
            "/api/v1/sync/push",
            headers=headers,
            json={
                "is_initial_sync": False,
                "products": [
                    {
                        "sync_id": prod_id,
                        "name": "Eau 1.5L",
                        "category_sync_id": cat.json()["sync_id"],
                        "price": 500,
                        "cost_price": 300,
                        "stock": 7,
                        "min_stock": 2,
                        "updated_at": now.isoformat(),
                    }
                ],
                "clients": [
                    {
                        "sync_id": cl_id,
                        "name": "Client Credit",
                        "balance": 1500,
                        "updated_at": (now - timedelta(seconds=2)).isoformat(),
                    }
                ],
                "ventes": [
                    {
                        "sync_id": vente_id,
                        "magasin_id": env["magasin_id"],
                        "ticket_number": "VNT-OFF-001",
                        "client_sync_id": cl_id,
                        "client_name": "Client Credit",
                        "total_amount": 1500,
                        "paid_amount": 0,
                        "payment_method": "Crédit",
                        "created_at": now.isoformat(),
                        "updated_at": now.isoformat(),
                        "items": [
                            {
                                "sync_id": str(uuid.uuid4()),
                                "product_sync_id": prod_id,
                                "product_name": "Eau 1.5L",
                                "quantity": 3,
                                "unit_price": 500,
                                "cost_price": 300,
                                "total": 1500,
                            }
                        ],
                    }
                ],
            },
        )
        assert res.status_code == 200, res.text
        assert res.json()["rejected_count"] == 0

        with SessionLocal() as db:
            p = db.query(Product).filter(Product.sync_id == prod_id).first()
            sm = db.query(StockMagasin).filter(
                StockMagasin.product_sync_id == prod_id, StockMagasin.magasin_id == env["magasin_id"]
            ).first()
            c = db.query(Client).filter(Client.sync_id == cl_id).first()
            assert p.stock == 7.0
            assert sm.quantity == 7.0
            assert c.balance == 1500.0


def test_sync_push_savepoint_isolates_invalid_item():
    with TestClient(app) as tc:
        env = _provision(tc, "savept")
        headers = env["headers"]
        now = datetime.now(timezone.utc)
        valid_cat_id = str(uuid.uuid4())
        bad_prod_id = str(uuid.uuid4())
        valid_client_id = str(uuid.uuid4())

        res = tc.post(
            "/api/v1/sync/push",
            headers=headers,
            json={
                "categories": [
                    {"sync_id": valid_cat_id, "name": "Ok Cat", "updated_at": now.isoformat()}
                ],
                "products": [
                    {
                        "sync_id": bad_prod_id,
                        "name": "Bad Prod",
                        "category_sync_id": "nonexistent-cat",
                        "price": 1000,
                        "stock": 5,
                        "updated_at": now.isoformat(),
                    }
                ],
                "clients": [
                    {"sync_id": valid_client_id, "name": "Valid Client", "updated_at": now.isoformat()}
                ],
            },
        )
        assert res.status_code == 200
        body = res.json()
        assert valid_cat_id in body["synced_uuids"]
        assert valid_client_id in body["synced_uuids"]
        assert body["rejected_count"] == 1
        assert any(bad_prod_id in err for err in body["errors"])


def test_appro_sync_updates_pamp_and_supplier_balance_and_pull_soft_deletes():
    with TestClient(app) as tc:
        env = _provision(tc, "approdel")
        headers = env["headers"]
        sup = tc.post("/api/v1/suppliers", headers=headers, json={"name": "Grossiste Test"})
        assert sup.status_code == 201
        sup_id = sup.json()["sync_id"]
        prod = tc.post(
            "/api/v1/products",
            headers=headers,
            json={"name": "Riz 25kg", "price": 18000, "cost_price": 12000, "stock": 10},
        )
        assert prod.status_code == 200
        prod_id = prod.json()["sync_id"]

        now = datetime.now(timezone.utc)
        appro_id = str(uuid.uuid4())
        push = tc.post(
            "/api/v1/sync/push",
            headers=headers,
            json={
                "approvisionnements": [
                    {
                        "sync_id": appro_id,
                        "magasin_id": env["magasin_id"],
                        "supplier_sync_id": sup_id,
                        "supplier_name": "Grossiste Test",
                        "product_sync_id": prod_id,
                        "product_name": "Riz 25kg",
                        "quantity": 10,
                        "unit_cost": 14000,
                        "total_cost": 140000,
                        "paid_amount": 40000,
                        "payment_status": "Partiel",
                        "date": now.isoformat(),
                        "updated_at": now.isoformat(),
                    }
                ]
            },
        )
        assert push.status_code == 200
        assert appro_id in push.json()["synced_uuids"]

        with SessionLocal() as db:
            p = db.query(Product).filter(Product.sync_id == prod_id).first()
            s = db.query(Supplier).filter(Supplier.sync_id == sup_id).first()
            assert p.stock == 20.0
            # Weighted average cost: (10*12000 + 10*14000) / 20 = 13000
            assert p.average_cost_price == 13000.0
            assert s.balance == 100000.0

        # Soft-delete product from backoffice and ensure pull returns deleted_at even with X-Magasin-Id
        del_res = tc.delete(f"/api/v1/products/{prod_id}", headers=headers)
        assert del_res.status_code in (200, 204)

        pull = tc.get("/api/v1/sync/pull", headers=headers)
        assert pull.status_code == 200
        pulled_prods = [p for p in pull.json()["products"] if p["sync_id"] == prod_id]
        assert len(pulled_prods) == 1
        assert pulled_prods[0]["deleted_at"] is not None

        # Cancelled / deleted vente pushed later updates existing server status
        v_id = str(uuid.uuid4())
        tc.post(
            "/api/v1/sync/push",
            headers=headers,
            json={
                "ventes": [
                    {
                        "sync_id": v_id,
                        "magasin_id": env["magasin_id"],
                        "ticket_number": "VNT-CAN-1",
                        "total_amount": 1000,
                        "paid_amount": 1000,
                        "created_at": now.isoformat(),
                        "items": [],
                    }
                ]
            },
        )
        cancel_push = tc.post(
            "/api/v1/sync/push",
            headers=headers,
            json={
                "ventes": [
                    {
                        "sync_id": v_id,
                        "ticket_number": "VNT-CAN-1",
                        "total_amount": 1000,
                        "paid_amount": 1000,
                        "status": "cancelled",
                        "created_at": now.isoformat(),
                        "updated_at": (now + timedelta(seconds=5)).isoformat(),
                        "deleted_at": (now + timedelta(seconds=5)).isoformat(),
                        "items": [],
                    }
                ]
            },
        )
        assert cancel_push.status_code == 200
        with SessionLocal() as db:
            v = db.query(Vente).filter(Vente.sync_id == v_id).first()
            assert v.status == "cancelled"
            assert v.deleted_at is not None
