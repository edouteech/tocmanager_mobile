from datetime import datetime, timedelta, timezone
import uuid
from fastapi.testclient import TestClient

from app.core.database import SessionLocal
from app.core.rate_limit import reset_rate_limits
from app.main import app
from app.models import Client, Product, StockMagasin, Supplier, Vente, VenteItem


def _provision(tc: TestClient, tag: str):
    reset_rate_limits()
    uid = uuid.uuid4().hex[:6]
    ident = f"toc045_{tag}_{uid}@example.com".lower()
    reg = tc.post(
        "/api/v1/saas/auth/register-credentials",
        json={"full_name": f"Owner {tag}", "username_or_email": ident, "password": "Password123!"},
    )
    assert reg.status_code == 200
    prov = tc.post(
        "/api/v1/saas/tenant/provision",
        headers={"Authorization": f"Bearer {reg.json()['access_token']}"},
        json={"boutique_name": f"Btq {tag} {uid}", "magasin_name": "Mag 1", "plan_code": "pro"},
    )
    assert prov.status_code == 200
    data = prov.json()
    return {
        "boutique_id": data["boutique_id"],
        "magasin_id": data["magasin_id"],
        "headers": {
            "Authorization": f"Bearer {data['access_token']}",
            "X-Boutique-Id": data["boutique_id"],
            "X-Magasin-Id": data["magasin_id"],
        },
    }


def test_vente_edit_and_cancel_reconcile_stock_items_and_client_balance():
    with TestClient(app) as tc:
        env = _provision(tc, "venterev")
        h = env["headers"]
        cat = tc.post("/api/v1/categories", headers=h, json={"name": "Boissons"}).json()
        prod = tc.post(
            "/api/v1/products",
            headers=h,
            json={"name": "Jus", "category_sync_id": cat["sync_id"], "price": 1000, "cost_price": 500, "stock": 10},
        ).json()
        cl = tc.post("/api/v1/clients", headers=h, json={"name": "Moussa"}).json()

        t1 = datetime.now(timezone.utc)
        vente_id = str(uuid.uuid4())
        r1 = tc.post(
            "/api/v1/sync/push",
            headers=h,
            json={
                "ventes": [{
                    "sync_id": vente_id,
                    "magasin_id": env["magasin_id"],
                    "ticket_number": "VNT-REV-1",
                    "client_sync_id": cl["sync_id"],
                    "client_name": "Moussa",
                    "total_amount": 3000,
                    "paid_amount": 1000,
                    "payment_method": "Crédit",
                    "created_at": t1.isoformat(),
                    "updated_at": t1.isoformat(),
                    "items": [{
                        "sync_id": str(uuid.uuid4()),
                        "product_sync_id": prod["sync_id"],
                        "product_name": "Jus",
                        "quantity": 3,
                        "unit_price": 1000,
                        "cost_price": 500,
                        "total": 3000,
                    }],
                }]
            },
        )
        assert r1.status_code == 200, r1.text

        # Edit vente: quantity 3 -> 5 (total 5000, paid 1000 => credit 2000 -> 4000, stock 7 -> 5)
        t2 = t1 + timedelta(seconds=10)
        r2 = tc.post(
            "/api/v1/sync/push",
            headers=h,
            json={
                "ventes": [{
                    "sync_id": vente_id,
                    "magasin_id": env["magasin_id"],
                    "ticket_number": "VNT-REV-1",
                    "client_sync_id": cl["sync_id"],
                    "client_name": "Moussa",
                    "total_amount": 5000,
                    "paid_amount": 1000,
                    "payment_method": "Crédit",
                    "created_at": t1.isoformat(),
                    "updated_at": t2.isoformat(),
                    "items": [{
                        "sync_id": str(uuid.uuid4()),
                        "product_sync_id": prod["sync_id"],
                        "product_name": "Jus",
                        "quantity": 5,
                        "unit_price": 1000,
                        "cost_price": 500,
                        "total": 5000,
                    }],
                }]
            },
        )
        assert r2.status_code == 200, r2.text

        with SessionLocal() as db:
            sm = db.query(StockMagasin).filter(
                StockMagasin.product_sync_id == prod["sync_id"],
                StockMagasin.magasin_id == env["magasin_id"],
            ).first()
            c = db.query(Client).filter(Client.sync_id == cl["sync_id"]).first()
            items = db.query(VenteItem).filter(VenteItem.vente_sync_id == vente_id).all()
            assert sm.quantity == 5.0
            assert c.balance == 4000.0
            assert len(items) == 1 and items[0].quantity == 5.0

        # Cancel vente: restores stock 5 -> 10 and reduces client debt 4000 -> 0
        t3 = t2 + timedelta(seconds=10)
        r3 = tc.post(
            "/api/v1/sync/push",
            headers=h,
            json={
                "ventes": [{
                    "sync_id": vente_id,
                    "magasin_id": env["magasin_id"],
                    "ticket_number": "VNT-REV-1",
                    "client_sync_id": cl["sync_id"],
                    "client_name": "Moussa",
                    "total_amount": 5000,
                    "paid_amount": 1000,
                    "payment_method": "Crédit",
                    "status": "cancelled",
                    "created_at": t1.isoformat(),
                    "updated_at": t3.isoformat(),
                    "deleted_at": t3.isoformat(),
                    "items": [],
                }]
            },
        )
        assert r3.status_code == 200, r3.text

        with SessionLocal() as db:
            sm = db.query(StockMagasin).filter(
                StockMagasin.product_sync_id == prod["sync_id"],
                StockMagasin.magasin_id == env["magasin_id"],
            ).first()
            c = db.query(Client).filter(Client.sync_id == cl["sync_id"]).first()
            v_row = db.query(Vente).filter(Vente.sync_id == vente_id).first()
            assert sm.quantity == 10.0
            assert c.balance == 0.0
            assert v_row.status == "cancelled" and v_row.deleted_at is not None


def test_appro_edit_cancel_reconciles_stock_pamp_supplier_and_lww_blocks_stale():
    with TestClient(app) as tc:
        env = _provision(tc, "approlww")
        h = env["headers"]
        cat = tc.post("/api/v1/categories", headers=h, json={"name": "Stock"}).json()
        prod = tc.post(
            "/api/v1/products",
            headers=h,
            json={"name": "Riz", "category_sync_id": cat["sync_id"], "price": 1500, "cost_price": 800, "stock": 0},
        ).json()
        sup = tc.post("/api/v1/suppliers", headers=h, json={"name": "Fournisseur A"}).json()

        t1 = datetime.now(timezone.utc) + timedelta(seconds=2)
        a1_id, a2_id = str(uuid.uuid4()), str(uuid.uuid4())
        r1 = tc.post(
            "/api/v1/sync/push",
            headers=h,
            json={
                "approvisionnements": [
                    {
                        "sync_id": a1_id,
                        "magasin_id": env["magasin_id"],
                        "supplier_sync_id": sup["sync_id"],
                        "supplier_name": "Fournisseur A",
                        "product_sync_id": prod["sync_id"],
                        "product_name": "Riz",
                        "quantity": 10,
                        "unit_cost": 600,
                        "total_cost": 6000,
                        "paid_amount": 0,
                        "payment_status": "Crédit",
                        "date": t1.isoformat(),
                        "updated_at": t1.isoformat(),
                    },
                    {
                        "sync_id": a2_id,
                        "magasin_id": env["magasin_id"],
                        "supplier_sync_id": sup["sync_id"],
                        "supplier_name": "Fournisseur A",
                        "product_sync_id": prod["sync_id"],
                        "product_name": "Riz",
                        "quantity": 10,
                        "unit_cost": 800,
                        "total_cost": 8000,
                        "paid_amount": 0,
                        "payment_status": "Crédit",
                        "date": t1.isoformat(),
                        "updated_at": t1.isoformat(),
                    },
                ]
            },
        )
        assert r1.status_code == 200, r1.text

        # Cancel a2 -> stock 20 -> 10, PAMP -> 600.0, supplier balance 14000 -> 6000
        t2 = t1 + timedelta(seconds=10)
        r2 = tc.post(
            "/api/v1/sync/push",
            headers=h,
            json={
                "approvisionnements": [{
                    "sync_id": a2_id,
                    "magasin_id": env["magasin_id"],
                    "supplier_sync_id": sup["sync_id"],
                    "supplier_name": "Fournisseur A",
                    "product_sync_id": prod["sync_id"],
                    "product_name": "Riz",
                    "quantity": 10,
                    "unit_cost": 800,
                    "total_cost": 8000,
                    "paid_amount": 0,
                    "payment_status": "Crédit",
                    "date": t1.isoformat(),
                    "updated_at": t2.isoformat(),
                    "deleted_at": t2.isoformat(),
                }]
            },
        )
        assert r2.status_code == 200, r2.text

        with SessionLocal() as db:
            sm = db.query(StockMagasin).filter(
                StockMagasin.product_sync_id == prod["sync_id"],
                StockMagasin.magasin_id == env["magasin_id"],
            ).first()
            p_row = db.query(Product).filter(Product.sync_id == prod["sync_id"]).first()
            s_row = db.query(Supplier).filter(Supplier.sync_id == sup["sync_id"]).first()
            assert sm.quantity == 10.0
            assert sm.average_cost_price == 600.0
            assert p_row.average_cost_price == 600.0
            assert s_row.balance == 6000.0

        # LWW: newer product price = 1800, then stale push with price = 1200 must NOT overwrite
        t_new = datetime.now(timezone.utc) + timedelta(minutes=2)
        t_old = t_new - timedelta(minutes=1)
        assert tc.post(
            "/api/v1/sync/push",
            headers=h,
            json={
                "products": [{
                    "sync_id": prod["sync_id"],
                    "name": "Riz",
                    "category_sync_id": cat["sync_id"],
                    "price": 1800,
                    "cost_price": 800,
                    "stock": 10,
                    "min_stock": 2,
                    "updated_at": t_new.isoformat(),
                }]
            },
        ).status_code == 200

        stale_res = tc.post(
            "/api/v1/sync/push",
            headers=h,
            json={
                "products": [{
                    "sync_id": prod["sync_id"],
                    "name": "Riz Ancien",
                    "category_sync_id": cat["sync_id"],
                    "price": 1200,
                    "cost_price": 800,
                    "stock": 10,
                    "min_stock": 2,
                    "updated_at": t_old.isoformat(),
                }]
            },
        )
        assert stale_res.status_code == 200
        assert prod["sync_id"] in stale_res.json()["synced_uuids"]
        with SessionLocal() as db:
            p_row = db.query(Product).filter(Product.sync_id == prod["sync_id"]).first()
            assert p_row.price == 1800.0
            assert p_row.name == "Riz"
