import uuid
from fastapi.testclient import TestClient
from app.main import app


def _provision_merchant(tc: TestClient):
    uid = uuid.uuid4().hex[:6]
    ident = f"caisse_{uid}@example.com"
    reg = tc.post(
        "/api/v1/saas/auth/register-credentials",
        json={"full_name": f"Owner {uid}", "username_or_email": ident, "password": "Password123!"},
    )
    assert reg.status_code == 200
    onb_h = {"Authorization": f"Bearer {reg.json()['access_token']}"}
    prov = tc.post(
        "/api/v1/saas/tenant/provision",
        headers=onb_h,
        json={"boutique_name": f"CaisseShop {uid}", "magasin_name": "Caisse 1", "plan_code": "pro"},
    )
    assert prov.status_code == 200
    data = prov.json()
    tok = tc.post("/api/v1/auth/login", json={"username_or_email": ident, "password": "Password123!"}).json()["access_token"]
    return {
        "boutique_id": data["boutique_id"],
        "mag_id": data["magasin_id"],
        "headers": {
            "Authorization": f"Bearer {tok}",
            "X-Boutique-Id": data["boutique_id"],
            "X-Magasin-Id": data["magasin_id"],
        },
    }


def test_toc012_cash_z_refund_and_payment_ledgers():
    with TestClient(app) as tc:
        m = _provision_merchant(tc)
        h = m["headers"]

        prod = tc.post(
            "/api/v1/products",
            headers=h,
            json={"name": "Sucre 1kg", "price": 1500.0, "cost_price": 1100.0, "stock": 10.0},
        ).json()
        prod_id = prod["sync_id"]

        client = tc.post("/api/v1/clients", headers=h, json={"name": "Awa", "balance": 0.0}).json()
        client_id = client["sync_id"]

        sup = tc.post("/api/v1/suppliers", headers=h, json={"name": "Distro", "balance": 5000.0}).json()
        sup_id = sup["sync_id"]

        # Open Cash Z session with 10000
        open_res = tc.post(
            "/api/v1/cash-sessions/open",
            headers=h,
            json={"magasin_id": m["mag_id"], "opening_balance": 10000.0},
        )
        assert open_res.status_code == 201
        sess_id = open_res.json()["id"]

        # Double open in same magasin by same user -> 400
        assert tc.post(
            "/api/v1/cash-sessions/open",
            headers=h,
            json={"magasin_id": m["mag_id"], "opening_balance": 500.0},
        ).status_code == 400

        # 2 cash sales totaling 3000 F
        v1 = tc.post(
            "/api/v1/ventes",
            headers=h,
            json={"items": [{"product_sync_id": prod_id, "quantity": 1.0}], "paid_amount": 1500.0, "payment_method": "Espèces"},
        )
        assert v1.status_code == 201
        v2 = tc.post(
            "/api/v1/ventes",
            headers=h,
            json={"items": [{"product_sync_id": prod_id, "quantity": 1.0}], "paid_amount": 1500.0, "payment_method": "Espèces"},
        )
        assert v2.status_code == 201

        # 1 cash expense of 1000 F
        assert tc.post(
            "/api/v1/decaissements",
            headers=h,
            json={"title": "Achat sachets", "amount": 1000.0, "payment_method": "Espèces"},
        ).status_code == 201

        # Close Z with declared 11500 -> expected = 10000 + 3000 - 1000 = 12000, discrepancy = -500
        close_res = tc.post(
            f"/api/v1/cash-sessions/{sess_id}/close",
            headers=h,
            json={"declared_cash": 11500.0},
        )
        assert close_res.status_code == 200
        z = close_res.json()
        assert z["expected_cash"] == 12000.0
        assert z["declared_cash"] == 11500.0
        assert z["discrepancy"] == -500.0
        assert z["status"] == "closed"

        # Refund v1 (credit balance check too via a third credit sale)
        stock_before_refund = [p for p in tc.get("/api/v1/products", headers=h).json() if p["sync_id"] == prod_id][0]["stock"]
        assert stock_before_refund == 8.0

        rf1 = tc.post(
            f"/api/v1/ventes/{v1.json()['sync_id']}/refund",
            headers=h,
            json={"reason": "Retour client"},
        )
        assert rf1.status_code == 200
        assert rf1.json()["status"] == "refunded"
        stock_after_refund = [p for p in tc.get("/api/v1/products", headers=h).json() if p["sync_id"] == prod_id][0]["stock"]
        assert stock_after_refund == 9.0

        # Double refund -> 400
        assert tc.post(
            f"/api/v1/ventes/{v1.json()['sync_id']}/refund",
            headers=h,
            json={"reason": "Double"},
        ).status_code == 400

        # StockMovement(movement_type="return") logged
        movs = tc.get(f"/api/v1/stock-movements?product_sync_id={prod_id}", headers=h).json()
        assert any(mv["movement_type"] == "return" and mv["quantity_delta"] == 1.0 for mv in movs)

        # Partial refund + Client credit balance reduction
        v_credit = tc.post(
            "/api/v1/ventes",
            headers=h,
            json={
                "client_sync_id": client_id,
                "items": [{"product_sync_id": prod_id, "quantity": 2.0}],
                "paid_amount": 0.0,
                "payment_method": "Crédit",
            },
        )
        assert v_credit.status_code == 201
        credit_item_id = v_credit.json()["items"][0]["sync_id"]
        rf_part = tc.post(
            f"/api/v1/ventes/{v_credit.json()['sync_id']}/refund",
            headers=h,
            json={"items": [{"vente_item_sync_id": credit_item_id, "quantity": 1.0}], "reason": "Retour partiel"},
        )
        assert rf_part.status_code == 200
        assert rf_part.json()["status"] == "partially_refunded"

        # ClientPayment ledger + overpayment check (client owes 1500 after 1500 refund)
        assert tc.post(
            f"/api/v1/clients/{client_id}/payments",
            headers=h,
            json={"amount": 5000.0, "payment_method": "Espèces"},
        ).status_code == 400
        assert tc.post(
            f"/api/v1/clients/{client_id}/payments",
            headers=h,
            json={"amount": 1000.0, "payment_method": "Espèces"},
        ).status_code == 200
        cl_hist = tc.get(f"/api/v1/clients/{client_id}/payments", headers=h).json()
        assert len(cl_hist) == 1
        assert cl_hist[0]["amount"] == 1000.0
        assert cl_hist[0]["new_balance"] == 500.0

        # SupplierPayment ledger + overpayment check
        assert tc.post(
            f"/api/v1/suppliers/{sup_id}/payments",
            headers=h,
            json={"amount": 9000.0, "payment_method": "Espèces"},
        ).status_code == 400
        assert tc.post(
            f"/api/v1/suppliers/{sup_id}/payments",
            headers=h,
            json={"amount": 2000.0, "payment_method": "Virement"},
        ).status_code == 200
        sup_hist = tc.get(f"/api/v1/suppliers/{sup_id}/payments", headers=h).json()
        assert len(sup_hist) == 1
        assert sup_hist[0]["previous_balance"] == 5000.0
        assert sup_hist[0]["new_balance"] == 3000.0
