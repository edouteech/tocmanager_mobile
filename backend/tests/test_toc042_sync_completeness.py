from datetime import datetime, timedelta, timezone
import time
import uuid
from fastapi.testclient import TestClient

from app.core.database import SessionLocal
from app.core.rate_limit import reset_rate_limits
from app.main import app


def _provision(tc: TestClient, tag: str):
    reset_rate_limits()
    uid = uuid.uuid4().hex[:6]
    ident = f"toc042_{tag}_{uid}@example.com".lower()
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


def test_magasin_config_change_bumps_product_updated_at_for_delta_pull():
    with TestClient(app) as tc:
        env = _provision(tc, "magcfg")
        h = env["headers"]
        mag2 = tc.post("/api/v1/tenant/magasins", headers=h, json={"name": "Mag 2"}).json()["id"]
        prod = tc.post(
            "/api/v1/products",
            headers=h,
            json={"name": "Cafe 250g", "price": 2000, "cost_price": 1200, "stock": 5},
        ).json()
        time.sleep(0.02)
        since_ts = datetime.now(timezone.utc).isoformat()
        time.sleep(0.02)

        before_pull = tc.get(
            "/api/v1/sync/pull",
            headers={**h, "X-Magasin-Id": mag2},
            params={"since": since_ts},
        )
        assert before_pull.status_code == 200
        assert before_pull.json()["products"] == []

        # Modify custom_price, is_available, min_stock on mag2 via magasin-config endpoint
        cfg_res = tc.put(
            f"/api/v1/products/{prod['sync_id']}/magasins/{mag2}",
            headers=h,
            json={"is_available": False, "custom_price": 2300, "min_stock": 9},
        )
        assert cfg_res.status_code == 200, cfg_res.text

        pull_res = tc.get(
            "/api/v1/sync/pull",
            headers={**h, "X-Magasin-Id": mag2},
            params={"since": since_ts},
        )
        assert pull_res.status_code == 200, pull_res.text
        pulled_prods = pull_res.json()["products"]
        assert len(pulled_prods) == 1
        assert pulled_prods[0]["sync_id"] == prod["sync_id"]
        assert pulled_prods[0]["custom_price"] == 2300.0
        assert pulled_prods[0]["is_available"] is False
        assert pulled_prods[0]["min_stock"] == 9.0
        assert pulled_prods[0]["magasin_id"] == mag2


def test_pull_includes_deleted_at_on_ventes_and_user_traceability_on_entities():
    with TestClient(app) as tc:
        env = _provision(tc, "pullfields")
        h = env["headers"]
        now = datetime.now(timezone.utc)
        del_ts = (now + timedelta(seconds=5)).isoformat()
        v_id, cl_id, sup_id, dec_id, app_id = [str(uuid.uuid4()) for _ in range(5)]

        push_res = tc.post(
            "/api/v1/sync/push",
            headers=h,
            json={
                "clients": [{"sync_id": cl_id, "name": "Cl Trace", "balance": 0, "updated_at": now.isoformat()}],
                "suppliers": [{"sync_id": sup_id, "name": "Sup Trace", "balance": 0, "updated_at": now.isoformat()}],
                "decaissements": [{
                    "sync_id": dec_id,
                    "magasin_id": env["magasin_id"],
                    "title": "Frais",
                    "amount": 500,
                    "date": now.isoformat(),
                    "updated_at": now.isoformat(),
                }],
                "approvisionnements": [{
                    "sync_id": app_id,
                    "magasin_id": env["magasin_id"],
                    "supplier_sync_id": sup_id,
                    "product_name": "Riz",
                    "quantity": 2,
                    "unit_cost": 400,
                    "total_cost": 800,
                    "payment_status": "Payé",
                    "date": now.isoformat(),
                    "updated_at": now.isoformat(),
                }],
                "ventes": [{
                    "sync_id": v_id,
                    "magasin_id": env["magasin_id"],
                    "ticket_number": "VNT-DEL-1",
                    "total_amount": 1000,
                    "paid_amount": 1000,
                    "payment_method": "Espèces",
                    "status": "cancelled",
                    "created_at": now.isoformat(),
                    "updated_at": del_ts,
                    "deleted_at": del_ts,
                    "items": [{"product_name": "Riz", "quantity": 1, "unit_price": 1000, "total": 1000}],
                }],
            },
        )
        assert push_res.status_code == 200, push_res.text

        pull_res = tc.get("/api/v1/sync/pull", headers=h)
        assert pull_res.status_code == 200, pull_res.text
        data = pull_res.json()

        assert data["ventes"][0]["deleted_at"] is not None
        assert data["clients"][0]["user_id"] is not None
        assert data["clients"][0]["user_name"] is not None
        assert data["suppliers"][0]["user_id"] is not None
        assert data["suppliers"][0]["user_name"] is not None
        assert data["decaissements"][0]["user_id"] is not None
        assert data["decaissements"][0]["user_name"] is not None
        assert data["approvisionnements"][0]["user_id"] is not None
        assert data["approvisionnements"][0]["user_name"] is not None
