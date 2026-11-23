import uuid
from fastapi.testclient import TestClient
from app.main import app


def _provision_merchant(tc: TestClient, plan_code: str):
    uid = uuid.uuid4().hex[:6]
    ident = f"trf_{plan_code}_{uid}@example.com"
    reg = tc.post(
        "/api/v1/saas/auth/register-credentials",
        json={"full_name": f"User {uid}", "username_or_email": ident, "password": "Password123!"},
    )
    assert reg.status_code == 200
    onb_h = {"Authorization": f"Bearer {reg.json()['access_token']}"}
    prov = tc.post(
        "/api/v1/saas/tenant/provision",
        headers=onb_h,
        json={"boutique_name": f"Boutique {uid}", "magasin_name": "Magasin A", "plan_code": plan_code},
    )
    assert prov.status_code == 200
    data = prov.json()
    tok = tc.post("/api/v1/auth/login", json={"username_or_email": ident, "password": "Password123!"}).json()["access_token"]
    return {
        "boutique_id": data["boutique_id"],
        "mag_a": data["magasin_id"],
        "headers": {"Authorization": f"Bearer {tok}", "X-Boutique-Id": data["boutique_id"]},
    }


def test_toc011_free_plan_blocks_transfers():
    with TestClient(app) as tc:
        free = _provision_merchant(tc, "free")
        res_get = tc.get("/api/v1/transfers", headers=free["headers"])
        assert res_get.status_code == 403
        assert res_get.json()["detail"]["error"] == "PLAN_FEATURE_LOCKED"

        res_post = tc.post(
            "/api/v1/transfers",
            headers=free["headers"],
            json={"from_magasin_id": free["mag_a"], "to_magasin_id": free["mag_a"], "items": [{"product_sync_id": "x", "quantity_sent": 1}]},
        )
        assert res_post.status_code == 403
        assert res_post.json()["detail"]["error"] == "PLAN_FEATURE_LOCKED"


def test_toc011_transfers_lifecycle_atomicity_and_stock_movements():
    with TestClient(app) as tc:
        owner = _provision_merchant(tc, "pro")
        h_a = {**owner["headers"], "X-Magasin-Id": owner["mag_a"]}

        mag_b = tc.post("/api/v1/tenant/magasins", headers=owner["headers"], json={"name": "Magasin B"}).json()["id"]
        h_b = {**owner["headers"], "X-Magasin-Id": mag_b}

        prod_res = tc.post(
            "/api/v1/products",
            headers=h_a,
            json={"name": "Huile 5L", "price": 5000.0, "cost_price": 4000.0, "stock": 0.0},
        )
        assert prod_res.status_code == 200
        prod_id = prod_res.json()["sync_id"]

        # Step 1: Supply +10 into Magasin A
        assert tc.post(
            "/api/v1/approvisionnements",
            headers=h_a,
            json={"product_sync_id": prod_id, "quantity": 10.0, "unit_cost": 4000.0},
        ).status_code == 201

        # Step 2: Sale -3 in Magasin A -> stock remaining 7
        assert tc.post(
            "/api/v1/ventes",
            headers=h_a,
            json={"items": [{"product_sync_id": prod_id, "quantity": 3.0}], "paid_amount": 15000.0},
        ).status_code == 201

        # Case 2: Same source and destination magasin -> 400
        same_mag = tc.post(
            "/api/v1/transfers",
            headers=owner["headers"],
            json={"from_magasin_id": owner["mag_a"], "to_magasin_id": owner["mag_a"], "items": [{"product_sync_id": prod_id, "quantity_sent": 1.0}]},
        )
        assert same_mag.status_code == 400

        # Case 3: Quantity exceeds Magasin A stock (7 available, requesting 9) -> 400 and untouched stock
        over_trf = tc.post(
            "/api/v1/transfers",
            headers=owner["headers"],
            json={"from_magasin_id": owner["mag_a"], "to_magasin_id": mag_b, "items": [{"product_sync_id": prod_id, "quantity_sent": 9.0}]},
        )
        assert over_trf.status_code == 400
        p_a_after_fail = [p for p in tc.get("/api/v1/products", headers=h_a).json() if p["sync_id"] == prod_id][0]
        assert p_a_after_fail["stock"] == 7.0

        # Step 3: Valid transfer -4 from Magasin A -> Magasin B -> Magasin A has 3, status is in_transit
        trf_res = tc.post(
            "/api/v1/transfers",
            headers=owner["headers"],
            json={"from_magasin_id": owner["mag_a"], "to_magasin_id": mag_b, "items": [{"product_sync_id": prod_id, "quantity_sent": 4.0}], "notes": "Réassort B"},
        )
        assert trf_res.status_code == 201
        trf = trf_res.json()
        assert trf["status"] == "in_transit"

        # Case 4: Receive + double receive blocked
        recv1 = tc.post(f"/api/v1/transfers/{trf['id']}/receive", headers=owner["headers"], json={})
        assert recv1.status_code == 200
        assert recv1.json()["status"] == "received"
        recv2 = tc.post(f"/api/v1/transfers/{trf['id']}/receive", headers=owner["headers"], json={})
        assert recv2.status_code == 400

        # Case 5: Cancel received transfer blocked 400
        assert tc.post(f"/api/v1/transfers/{trf['id']}/cancel", headers=owner["headers"]).status_code == 400

        # Verify Case 6 balances (+10 -3 -4 == 3 at A, 4 at B) and StockMovement ledger
        p_a = [p for p in tc.get("/api/v1/products", headers=h_a).json() if p["sync_id"] == prod_id][0]
        p_b = [p for p in tc.get("/api/v1/products", headers=h_b).json() if p["sync_id"] == prod_id][0]
        assert p_a["stock"] == 3.0
        assert p_b["stock"] == 4.0

        movs_a = tc.get(f"/api/v1/stock-movements?magasin_id={owner['mag_a']}&product_sync_id={prod_id}", headers=owner["headers"]).json()
        types_a = [m["movement_type"] for m in movs_a]
        assert types_a.count("supply") == 1
        assert types_a.count("sale") == 1
        assert types_a.count("transfer_out") == 1
        assert movs_a[0]["balance_after"] == 3.0

        # Test transfer cancelation restores stock to source
        trf_cancel_res = tc.post(
            "/api/v1/transfers",
            headers=owner["headers"],
            json={"from_magasin_id": mag_b, "to_magasin_id": owner["mag_a"], "items": [{"product_sync_id": prod_id, "quantity_sent": 2.0}]},
        )
        assert trf_cancel_res.status_code == 201
        trf2_id = trf_cancel_res.json()["id"]
        assert tc.post(f"/api/v1/transfers/{trf2_id}/cancel", headers=owner["headers"]).json()["status"] == "canceled"
        p_b_restored = [p for p in tc.get("/api/v1/products", headers=h_b).json() if p["sync_id"] == prod_id][0]
        assert p_b_restored["stock"] == 4.0

        # Inventory physical adjustment endpoint
        adj = tc.post(
            "/api/v1/stock-movements/adjust",
            headers=owner["headers"],
            json={"magasin_id": owner["mag_a"], "product_sync_id": prod_id, "counted_quantity": 2.0, "movement_type": "loss", "reason": "Bouteille percée"},
        )
        assert adj.status_code == 201
        assert adj.json()["quantity_delta"] == -1.0
        assert adj.json()["balance_after"] == 2.0
