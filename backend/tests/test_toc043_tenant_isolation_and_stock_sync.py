from datetime import datetime, timezone
import uuid
from fastapi.testclient import TestClient

from app.core.database import SessionLocal
from app.main import app
from app.models import Product, StockMagasin


def _provision_pro(tc: TestClient, tag: str):
    uid = uuid.uuid4().hex[:6]
    ident = f"toc043_{tag}_{uid}@example.com"
    reg = tc.post(
        "/api/v1/saas/auth/register-credentials",
        json={
            "full_name": f"User {tag}",
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
            "boutique_name": f"Boutique {tag} {uid}",
            "magasin_name": "Magasin 1",
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
        "mag1_id": data["magasin_id"],
        "headers": {
            "Authorization": f"Bearer {token}",
            "X-Boutique-Id": data["boutique_id"],
            "X-Magasin-Id": data["magasin_id"],
        },
        "consolidated_headers": {
            "Authorization": f"Bearer {token}",
            "X-Boutique-Id": data["boutique_id"],
        },
    }


def test_push_product_updates_only_target_magasin_stock_and_recomputes_total():
    with TestClient(app) as tc:
        env = _provision_pro(tc, "multimag")
        mag2_res = tc.post(
            "/api/v1/tenant/magasins",
            headers=env["headers"],
            json={"name": "Magasin 2"},
        )
        assert mag2_res.status_code == 200, mag2_res.text
        mag2_id = mag2_res.json()["id"]

        cat = tc.post("/api/v1/categories", headers=env["headers"], json={"name": "Epicerie"})
        assert cat.status_code == 201
        cat_sync_id = cat.json()["sync_id"]

        prod = tc.post(
            "/api/v1/products",
            headers=env["headers"],
            json={"name": "Sucre 1kg", "category_sync_id": cat_sync_id, "price": 750, "cost_price": 500, "stock": 10},
        )
        assert prod.status_code == 200
        prod_sync_id = prod.json()["sync_id"]
        now = datetime.now(timezone.utc)

        # Set mag2 stock to 5 via sync push targeting mag2
        r2 = tc.post(
            "/api/v1/sync/push",
            headers={**env["consolidated_headers"], "X-Magasin-Id": mag2_id},
            json={
                "is_initial_sync": False,
                "products": [
                    {
                        "sync_id": prod_sync_id,
                        "name": "Sucre 1kg",
                        "category_sync_id": cat_sync_id,
                        "price": 750,
                        "cost_price": 500,
                        "stock": 5,
                        "min_stock": 2,
                        "magasin_id": mag2_id,
                        "updated_at": now.isoformat(),
                    }
                ],
            },
        )
        assert r2.status_code == 200, r2.text

        # Update mag1 stock to 8 via sync push targeting mag1
        r1 = tc.post(
            "/api/v1/sync/push",
            headers=env["headers"],
            json={
                "is_initial_sync": False,
                "products": [
                    {
                        "sync_id": prod_sync_id,
                        "name": "Sucre 1kg",
                        "category_sync_id": cat_sync_id,
                        "price": 800,
                        "cost_price": 500,
                        "stock": 8,
                        "min_stock": 3,
                        "magasin_id": env["mag1_id"],
                        "updated_at": now.isoformat(),
                    }
                ],
            },
        )
        assert r1.status_code == 200, r1.text

        with SessionLocal() as db:
            sm1 = db.query(StockMagasin).filter(
                StockMagasin.product_sync_id == prod_sync_id,
                StockMagasin.magasin_id == env["mag1_id"],
            ).first()
            sm2 = db.query(StockMagasin).filter(
                StockMagasin.product_sync_id == prod_sync_id,
                StockMagasin.magasin_id == mag2_id,
            ).first()
            p = db.query(Product).filter(Product.sync_id == prod_sync_id).first()
            assert sm1.quantity == 8.0
            assert sm2.quantity == 5.0
            assert p.stock == 13.0
            assert p.price == 800.0

        # Consolidated push without magasin_id updates metadata without corrupting stock
        r_cons = tc.post(
            "/api/v1/sync/push",
            headers=env["consolidated_headers"],
            json={
                "is_initial_sync": False,
                "products": [
                    {
                        "sync_id": prod_sync_id,
                        "name": "Sucre Blanc 1kg",
                        "category_sync_id": cat_sync_id,
                        "price": 820,
                        "cost_price": 500,
                        "stock": 999,
                        "min_stock": 3,
                        "updated_at": now.isoformat(),
                    }
                ],
            },
        )
        assert r_cons.status_code == 200, r_cons.text

        with SessionLocal() as db:
            sm1 = db.query(StockMagasin).filter(
                StockMagasin.product_sync_id == prod_sync_id,
                StockMagasin.magasin_id == env["mag1_id"],
            ).first()
            sm2 = db.query(StockMagasin).filter(
                StockMagasin.product_sync_id == prod_sync_id,
                StockMagasin.magasin_id == mag2_id,
            ).first()
            p = db.query(Product).filter(Product.sync_id == prod_sync_id).first()
            assert p.name == "Sucre Blanc 1kg"
            assert sm1.quantity == 8.0
            assert sm2.quantity == 5.0
            assert p.stock == 13.0


def test_push_new_product_uses_payload_magasin_id_for_initial_stock():
    with TestClient(app) as tc:
        env = _provision_pro(tc, "newprodmag")
        mag2_res = tc.post(
            "/api/v1/tenant/magasins",
            headers=env["headers"],
            json={"name": "Magasin 2"},
        )
        assert mag2_res.status_code == 200
        mag2_id = mag2_res.json()["id"]

        cat = tc.post("/api/v1/categories", headers=env["headers"], json={"name": "Divers"})
        assert cat.status_code == 201
        prod_sync_id = str(uuid.uuid4())
        now = datetime.now(timezone.utc)

        res = tc.post(
            "/api/v1/sync/push",
            headers=env["headers"],
            json={
                "is_initial_sync": False,
                "products": [
                    {
                        "sync_id": prod_sync_id,
                        "name": "Savon",
                        "category_sync_id": cat.json()["sync_id"],
                        "price": 400,
                        "cost_price": 250,
                        "stock": 6,
                        "min_stock": 2,
                        "magasin_id": mag2_id,
                        "updated_at": now.isoformat(),
                    }
                ],
            },
        )
        assert res.status_code == 200, res.text
        assert res.json()["rejected_count"] == 0

        with SessionLocal() as db:
            sm1 = db.query(StockMagasin).filter(
                StockMagasin.product_sync_id == prod_sync_id,
                StockMagasin.magasin_id == env["mag1_id"],
            ).first()
            sm2 = db.query(StockMagasin).filter(
                StockMagasin.product_sync_id == prod_sync_id,
                StockMagasin.magasin_id == mag2_id,
            ).first()
            p = db.query(Product).filter(Product.sync_id == prod_sync_id).first()
            assert sm1.quantity == 0.0
            assert sm2.quantity == 6.0
            assert p.stock == 6.0
