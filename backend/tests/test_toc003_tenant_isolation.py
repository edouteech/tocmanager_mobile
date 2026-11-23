import uuid
from fastapi.testclient import TestClient
from app.main import app
from app.core.database import SessionLocal
from app.models import Boutique


def _provision_merchant(tc: TestClient, tag: str):
    uid = uuid.uuid4().hex[:6]
    ident = f"owner_{tag.lower()}_{uid}@example.com"
    reg = tc.post(
        "/api/v1/saas/auth/register-credentials",
        json={
            "full_name": f"Owner {tag}",
            "username_or_email": ident,
            "password": "Password123!",
        },
    )
    assert reg.status_code == 200
    onb_headers = {"Authorization": f"Bearer {reg.json()['access_token']}"}
    prov = tc.post(
        "/api/v1/saas/tenant/provision",
        headers=onb_headers,
        json={"boutique_name": f"Boutique {tag} {uid}", "magasin_name": f"Magasin {tag}"},
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
        },
        "auth_only": {"Authorization": f"Bearer {token}"},
    }


def test_cross_boutique_isolation_all_resources():
    with TestClient(app) as tc:
        a = _provision_merchant(tc, "A")
        b = _provision_merchant(tc, "B")

        # B creates category, product, client, supplier, expense, sale
        cat_b = tc.post("/api/v1/categories", headers=b["headers"], json={"name": "Cat Secret B"})
        assert cat_b.status_code == 201
        cat_b_id = cat_b.json()["sync_id"]

        prod_b = tc.post(
            "/api/v1/products",
            headers=b["headers"],
            json={"name": "Produit B", "category_sync_id": cat_b_id, "price": 1500, "stock": 10},
        )
        assert prod_b.status_code == 200
        prod_b_id = prod_b.json()["sync_id"]

        cl_b = tc.post("/api/v1/clients", headers=b["headers"], json={"name": "Client B"})
        assert cl_b.status_code == 201
        cl_b_id = cl_b.json()["sync_id"]

        sup_b = tc.post("/api/v1/suppliers", headers=b["headers"], json={"name": "Fournisseur B"})
        assert sup_b.status_code == 201
        sup_b_id = sup_b.json()["sync_id"]

        # A tries to forge X-Boutique-Id: B across all routes -> 403
        forged = {"Authorization": a["headers"]["Authorization"], "X-Boutique-Id": b["boutique_id"]}
        for path in (
            "/api/v1/products",
            "/api/v1/categories",
            "/api/v1/clients",
            "/api/v1/suppliers",
            "/api/v1/approvisionnements",
            "/api/v1/decaissements",
            "/api/v1/ventes",
            "/api/v1/reports/dashboard",
            "/api/v1/sync/pull",
            "/api/v1/audit/logs",
            "/api/v1/settings",
            "/api/v1/tenant/magasins",
            "/api/v1/tenant/current-plan",
        ):
            assert tc.get(path, headers=forged).status_code == 403, f"Expected 403 on {path}"

        # A uses own header to access/mutate B's IDs -> 404 or empty list
        assert [p for p in tc.get("/api/v1/products", headers=a["headers"]).json() if p["sync_id"] == prod_b_id] == []
        assert tc.put(f"/api/v1/products/{prod_b_id}", headers=a["headers"], json={"price": 1}).status_code == 404
        assert tc.delete(f"/api/v1/products/{prod_b_id}", headers=a["headers"]).status_code == 404
        assert tc.get(f"/api/v1/clients/{cl_b_id}", headers=a["headers"]).status_code == 404
        assert tc.put(f"/api/v1/clients/{cl_b_id}", headers=a["headers"], json={"name": "Hack"}).status_code == 404
        assert tc.delete(f"/api/v1/clients/{cl_b_id}", headers=a["headers"]).status_code == 404
        assert tc.get(f"/api/v1/suppliers/{sup_b_id}", headers=a["headers"]).status_code == 404

        # A cannot reference B's product/client/supplier in sale or supply
        bad_sale = tc.post(
            "/api/v1/ventes",
            headers=a["headers"],
            json={"items": [{"product_sync_id": prod_b_id, "quantity": 1, "unit_price": 100}], "paid_amount": 100},
        )
        assert bad_sale.status_code == 404

        prod_a = tc.post("/api/v1/products", headers=a["headers"], json={"name": "Produit A", "price": 500, "stock": 5})
        assert prod_a.status_code == 200
        bad_sale_client = tc.post(
            "/api/v1/ventes",
            headers=a["headers"],
            json={
                "client_sync_id": cl_b_id,
                "items": [{"product_sync_id": prod_a.json()["sync_id"], "quantity": 1, "unit_price": 500}],
                "paid_amount": 500,
            },
        )
        assert bad_sale_client.status_code == 404
        bad_supply = tc.post(
            "/api/v1/approvisionnements",
            headers=a["headers"],
            json={
                "product_sync_id": prod_a.json()["sync_id"],
                "supplier_sync_id": sup_b_id,
                "quantity": 1,
                "unit_cost": 100,
            },
        )
        assert bad_supply.status_code == 404

        # Cross-boutique sync/push overwrite attempt must be rejected cleanly
        push_hijack = tc.post(
            "/api/v1/sync/push",
            headers=a["headers"],
            json={
                "products": [{
                    "sync_id": prod_b_id,
                    "name": "Hijacked",
                    "price": 1.0,
                    "stock": 999.0,
                }]
            },
        )
        assert push_hijack.status_code == 200
        assert push_hijack.json()["rejected_count"] == 1
        assert prod_b_id not in push_hijack.json()["synced_uuids"]
        still_b = tc.get("/api/v1/products", headers=b["headers"]).json()
        assert next(p for p in still_b if p["sync_id"] == prod_b_id)["name"] == "Produit B"


def test_store_settings_isolated_per_boutique():
    with TestClient(app) as tc:
        a = _provision_merchant(tc, "SetA")
        b = _provision_merchant(tc, "SetB")

        res_put = tc.put(
            "/api/v1/settings",
            headers=a["headers"],
            json={"store_name": "Alpha Market", "currency": "EUR", "tax_rate": 18.0, "low_stock_threshold": 4.0},
        )
        assert res_put.status_code == 200

        got_a = tc.get("/api/v1/settings", headers=a["headers"]).json()
        got_b = tc.get("/api/v1/settings", headers=b["headers"]).json()
        assert got_a["store_name"] == "Alpha Market"
        assert got_a["currency"] == "EUR"
        assert got_b["store_name"] != "Alpha Market"
        assert got_b["currency"] == "XOF"


def test_superadmin_blocked_suspended_boutique_and_ambiguous_multi_boutique():
    with TestClient(app) as tc:
        # 1. Superadmin must receive 403 on all tenant routes
        sa_login = tc.post("/api/v1/auth/login", json={"username_or_email": "admin", "password": "admin1234"})
        sa_headers = {"Authorization": f"Bearer {sa_login.json()['access_token']}"}
        assert tc.get("/api/v1/products", headers=sa_headers).status_code == 403
        assert tc.get("/api/v1/settings", headers=sa_headers).status_code == 403
        assert tc.get("/api/v1/tenant/magasins", headers=sa_headers).status_code == 403

        # 2. Multi-boutique owner without X-Boutique-Id receives 400 (never .first())
        owner = _provision_merchant(tc, "Multi")
        second = tc.post("/api/v1/tenant/boutiques", headers=owner["auth_only"], json={"name": "Second Store"})
        assert second.status_code == 200
        ambiguous = tc.get("/api/v1/products", headers=owner["auth_only"])
        assert ambiguous.status_code == 400

        # 3. Suspended boutique rejects requests with 403
        db = SessionLocal()
        try:
            btq = db.query(Boutique).filter(Boutique.id == owner["boutique_id"]).first()
            btq.is_active = False
            db.commit()
        finally:
            db.close()

        assert tc.get("/api/v1/products", headers=owner["headers"]).status_code == 403
