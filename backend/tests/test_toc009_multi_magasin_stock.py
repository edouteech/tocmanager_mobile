import uuid
from fastapi.testclient import TestClient
from app.main import app


def _provision_pro_owner(tc: TestClient):
    uid = uuid.uuid4().hex[:6]
    ident = f"mag_owner_{uid}@example.com"
    reg = tc.post(
        "/api/v1/saas/auth/register-credentials",
        json={"full_name": f"Owner {uid}", "username_or_email": ident, "password": "Password123!"},
    )
    assert reg.status_code == 200
    onb_h = {"Authorization": f"Bearer {reg.json()['access_token']}"}
    prov = tc.post(
        "/api/v1/saas/tenant/provision",
        headers=onb_h,
        json={"boutique_name": f"MultiShop {uid}", "magasin_name": "Magasin A", "plan_code": "pro"},
    )
    assert prov.status_code == 200
    data = prov.json()
    login = tc.post("/api/v1/auth/login", json={"username_or_email": ident, "password": "Password123!"})
    assert login.status_code == 200
    token = login.json()["access_token"]
    return {
        "boutique_id": data["boutique_id"],
        "mag_a_id": data["magasin_id"],
        "headers": {"Authorization": f"Bearer {token}", "X-Boutique-Id": data["boutique_id"]},
        "token": token,
    }


def test_toc009_multi_magasin_stocks_warehouse_pricing_and_cashier_isolation():
    with TestClient(app) as tc:
        owner = _provision_pro_owner(tc)
        h_a = {**owner["headers"], "X-Magasin-Id": owner["mag_a_id"]}

        # Create Magasin B (retail) and Entrepôt Depot C (is_warehouse=True)
        mag_b_res = tc.post(
            "/api/v1/tenant/magasins",
            headers=owner["headers"],
            json={"name": "Magasin B", "code": "MAG-B", "is_warehouse": False},
        )
        assert mag_b_res.status_code == 200
        mag_b_id = mag_b_res.json()["id"]
        h_b = {**owner["headers"], "X-Magasin-Id": mag_b_id}

        depot_res = tc.post(
            "/api/v1/tenant/magasins",
            headers=owner["headers"],
            json={"name": "Entrepot Central", "code": "DEP-01", "is_warehouse": True},
        )
        assert depot_res.status_code == 200
        depot_id = depot_res.json()["id"]
        h_depot = {**owner["headers"], "X-Magasin-Id": depot_id}

        # Create product at catalogue price 1000 with initial stock 10 in Magasin A
        prod_res = tc.post(
            "/api/v1/products",
            headers=h_a,
            json={"name": "Sac de Riz", "price": 1000.0, "cost_price": 700.0, "stock": 10.0, "min_stock": 2.0},
        )
        assert prod_res.status_code == 200
        prod_id = prod_res.json()["sync_id"]

        # Supply +5 in Magasin B and +20 in Entrepot C
        assert tc.post(
            "/api/v1/approvisionnements",
            headers=h_b,
            json={"product_sync_id": prod_id, "quantity": 5.0, "unit_cost": 750.0},
        ).status_code == 201
        assert tc.post(
            "/api/v1/approvisionnements",
            headers=h_depot,
            json={"product_sync_id": prod_id, "quantity": 20.0, "unit_cost": 680.0},
        ).status_code == 201

        # Verify distinct stocks per magasin and consolidated sum (10 + 5 + 20 = 35)
        p_a = [p for p in tc.get("/api/v1/products", headers=h_a).json() if p["sync_id"] == prod_id][0]
        p_b = [p for p in tc.get("/api/v1/products", headers=h_b).json() if p["sync_id"] == prod_id][0]
        p_all = [p for p in tc.get("/api/v1/products", headers=owner["headers"]).json() if p["sync_id"] == prod_id][0]
        assert p_a["stock"] == 10.0
        assert p_b["stock"] == 5.0
        assert p_all["stock"] == 35.0

        # Case 1: Sale from warehouse (Entrepot Central) -> 400
        wh_sale = tc.post(
            "/api/v1/ventes",
            headers=h_depot,
            json={"items": [{"product_sync_id": prod_id, "quantity": 1.0}], "paid_amount": 1000.0},
        )
        assert wh_sale.status_code == 400
        assert "entrepôt" in wh_sale.json()["detail"].lower()

        # Set custom price 1200 in Magasin B and verify custom pricing works on sale
        cfg_b = tc.put(
            f"/api/v1/products/{prod_id}/magasins/{mag_b_id}",
            headers=owner["headers"],
            json={"is_available": True, "custom_price": 1200.0, "min_stock": 1.0},
        )
        assert cfg_b.status_code == 200
        assert cfg_b.json()["effective_price"] == 1200.0

        # Case 3: Sale in Magasin B without explicit unit_price uses custom_price 1200
        sale_b = tc.post(
            "/api/v1/ventes",
            headers=h_b,
            json={"items": [{"product_sync_id": prod_id, "quantity": 2.0}], "paid_amount": 2400.0},
        )
        assert sale_b.status_code == 201
        assert sale_b.json()["total_amount"] == 2400.0
        assert sale_b.json()["magasin_id"] == mag_b_id

        # Case 2: Disable product in Magasin B -> hidden with only_available=true and sale 400 in Magasin B, still sellable in Magasin A
        assert tc.put(
            f"/api/v1/products/{prod_id}/magasins/{mag_b_id}",
            headers=owner["headers"],
            json={"is_available": False},
        ).status_code == 200
        avail_b = tc.get("/api/v1/products?only_available=true", headers=h_b).json()
        assert all(p["sync_id"] != prod_id for p in avail_b)
        disabled_sale = tc.post(
            "/api/v1/ventes",
            headers=h_b,
            json={"items": [{"product_sync_id": prod_id, "quantity": 1.0}], "paid_amount": 1200.0},
        )
        assert disabled_sale.status_code == 400

        sale_a = tc.post(
            "/api/v1/ventes",
            headers=h_a,
            json={"items": [{"product_sync_id": prod_id, "quantity": 3.0}], "paid_amount": 3000.0},
        )
        assert sale_a.status_code == 201
        assert sale_a.json()["total_amount"] == 3000.0

        # Owner in consolidated view MUST supply explicit magasin_id for operational POST /ventes when >1 magasin
        cons_no_mag = tc.post(
            "/api/v1/ventes",
            headers=owner["headers"],
            json={"items": [{"product_sync_id": prod_id, "quantity": 1.0}], "paid_amount": 1000.0},
        )
        assert cons_no_mag.status_code == 400

        # Scoped KPIs & expenses per magasin
        assert tc.post(
            "/api/v1/decaissements",
            headers=h_a,
            json={"title": "Loyer A", "amount": 500.0},
        ).status_code == 201
        dash_a = tc.get("/api/v1/reports/dashboard", headers=h_a).json()
        dash_b = tc.get("/api/v1/reports/dashboard", headers=h_b).json()
        assert dash_a["total_sales_amount"] == 3000.0
        assert dash_a["total_expenses"] == 500.0
        assert dash_b["total_sales_amount"] == 2400.0
        assert dash_b["total_expenses"] == 0.0

        # Case 4: Cashier restricted to Magasin A -> consolidated omitted/explicit -> 403, Magasin B -> 403, Magasin A -> OK
        c_user = f"cashier_a_{uuid.uuid4().hex[:4]}"
        assert tc.post(
            "/api/v1/users",
            headers=owner["headers"],
            json={
                "username": c_user,
                "password": "Password123!",
                "role": "cashier",
                "pin": "1111",
                "assigned_magasin_ids": [owner["mag_a_id"]],
            },
        ).status_code == 200
        c_tok = tc.post("/api/v1/auth/login", json={"username_or_email": c_user, "password": "Password123!"}).json()["access_token"]
        c_h_base = {"Authorization": f"Bearer {c_tok}", "X-Boutique-Id": owner["boutique_id"]}
        assert tc.get("/api/v1/products", headers=c_h_base).status_code == 403
        assert tc.get("/api/v1/products", headers={**c_h_base, "X-Magasin-Id": "consolidated"}).status_code == 403
        assert tc.get("/api/v1/products", headers={**c_h_base, "X-Magasin-Id": mag_b_id}).status_code == 403
        assert tc.get("/api/v1/ventes", headers=c_h_base).status_code == 403
        assert tc.get("/api/v1/products", headers={**c_h_base, "X-Magasin-Id": owner["mag_a_id"]}).status_code == 200
        assert tc.post(
            "/api/v1/ventes",
            headers={**c_h_base, "X-Magasin-Id": owner["mag_a_id"]},
            json={"items": [{"product_sync_id": prod_id, "quantity": 1.0}], "paid_amount": 1000.0},
        ).status_code == 201
