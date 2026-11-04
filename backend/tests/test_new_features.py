import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def get_auth_token():
    res = client.post("/api/v1/auth/login", json={
        "username_or_email": "admin",
        "password": "admin1234",
    })
    assert res.status_code == 200
    return res.json()["access_token"]

def test_clients_crud():
    token = get_auth_token()
    headers = {"Authorization": f"Bearer {token}"}

    # 1. Create client
    res = client.post("/api/v1/clients", headers=headers, json={
        "name": "Société Test E2E",
        "phone": "+228 99 88 77 66",
        "balance": 50000.0,
    })
    assert res.status_code == 201
    c_data = res.json()
    client_id = c_data["sync_id"]
    assert c_data["name"] == "Société Test E2E"
    assert c_data["balance"] == 50000.0

    # 2. List clients
    res = client.get("/api/v1/clients?q=Société Test", headers=headers)
    assert res.status_code == 200
    assert len(res.json()) >= 1

    # 3. Record debt payment
    res = client.post(f"/api/v1/clients/{client_id}/payments", headers=headers, json={
        "amount": 20000.0,
        "payment_method": "Espèces",
    })
    assert res.status_code == 200
    assert res.json()["balance"] == 30000.0

    # 4. Delete client
    res = client.delete(f"/api/v1/clients/{client_id}", headers=headers)
    assert res.status_code == 204

def test_suppliers_crud():
    token = get_auth_token()
    headers = {"Authorization": f"Bearer {token}"}

    # 1. Create supplier
    res = client.post("/api/v1/suppliers", headers=headers, json={
        "name": "Fournisseur Agro Test",
        "contact_person": "M. Kodjo",
        "balance": 100000.0,
    })
    assert res.status_code == 201
    s_data = res.json()
    sup_id = s_data["sync_id"]

    # 2. Record payment
    res = client.post(f"/api/v1/suppliers/{sup_id}/payments", headers=headers, json={
        "amount": 40000.0,
        "payment_method": "Virement",
    })
    assert res.status_code == 200
    assert res.json()["balance"] == 60000.0

    # 3. Delete supplier
    res = client.delete(f"/api/v1/suppliers/{sup_id}", headers=headers)
    assert res.status_code == 204

def test_financial_report():
    token = get_auth_token()
    headers = {"Authorization": f"Bearer {token}"}

    res = client.get("/api/v1/reports/financial", headers=headers)
    assert res.status_code == 200
    data = res.json()
    assert "kpis" in data
    assert "gross_sales" in data["kpis"]
    assert "cogs" in data["kpis"]
    assert "gross_margin" in data["kpis"]
    assert "net_profit" in data["kpis"]
    assert "top_products" in data
    assert "expenses_by_category" in data
    assert "monthly_trend" in data

def test_store_settings():
    token = get_auth_token()
    headers = {"Authorization": f"Bearer {token}"}

    res = client.get("/api/v1/settings", headers=headers)
    assert res.status_code == 200
    settings_data = res.json()
    assert "store_name" in settings_data

    # Update settings
    res = client.put("/api/v1/settings", headers=headers, json={
        "store_name": "TocManager Superette",
        "currency": "FCFA",
        "phone": "+228 90 11 22 33",
        "low_stock_threshold": 8.0,
    })
    assert res.status_code == 200
    assert res.json()["store_name"] == "TocManager Superette"

def test_vente_creation_from_backoffice():
    token = get_auth_token()
    headers = {"Authorization": f"Bearer {token}"}

    # 1. Create product with stock
    prod_res = client.post("/api/v1/products", headers=headers, json={
        "name": "Biscottes Test Caisse",
        "price": 1000.0,
        "cost_price": 600.0,
        "stock": 25.0,
    })
    assert prod_res.status_code in [200, 201]
    prod_sync_id = prod_res.json()["sync_id"]

    # 2. Create client
    client_res = client.post("/api/v1/clients", headers=headers, json={
        "name": "Client Vente Test",
        "balance": 0.0,
    })
    assert client_res.status_code == 201
    c_sync_id = client_res.json()["sync_id"]

    # 3. Create sale: 2 items @ 1000 = 2000, discount 200 => net total 1800, paid 1000 => debt 800
    vente_payload = {
        "client_sync_id": c_sync_id,
        "items": [
            {
                "product_sync_id": prod_sync_id,
                "quantity": 2.0,
                "unit_price": 1000.0,
            }
        ],
        "discount_amount": 200.0,
        "paid_amount": 1000.0,
        "payment_method": "Espèces",
        "notes": "Vente test backoffice",
    }
    v_res = client.post("/api/v1/ventes", headers=headers, json=vente_payload)
    assert v_res.status_code == 201
    v_data = v_res.json()
    assert v_data["ticket_number"].startswith("VNT-")
    assert v_data["total_amount"] == 1800.0
    assert v_data["paid_amount"] == 1000.0
    assert len(v_data["items"]) == 1

    # 4. Verify product stock decremented (25 - 2 = 23)
    p_get = client.get(f"/api/v1/products?search=Biscottes Test Caisse", headers=headers)
    assert p_get.status_code == 200
    found_prods = [p for p in p_get.json() if p["sync_id"] == prod_sync_id]
    assert len(found_prods) == 1
    assert found_prods[0]["stock"] == 23.0

    # 5. Verify client balance updated (0 + 800 = 800)
    c_get = client.get(f"/api/v1/clients/{c_sync_id}", headers=headers)
    assert c_get.status_code == 200
    assert c_get.json()["balance"] == 800.0

def test_user_management_crud():
    token = get_auth_token()
    headers = {"Authorization": f"Bearer {token}"}

    # 1. Create cashier
    create_res = client.post("/api/v1/users", headers=headers, json={
        "username": "cashier_test_crud",
        "password": "password123",
        "full_name": "Caissier Test",
        "role": "cashier",
        "pin": "1234",
    })
    assert create_res.status_code == 200
    u_data = create_res.json()
    user_id = u_data["id"]
    assert u_data["username"] == "cashier_test_crud"
    assert u_data["has_pin"] is True
    assert u_data["is_active"] is True

    # 2. Update user
    update_res = client.put(f"/api/v1/users/{user_id}", headers=headers, json={
        "full_name": "Caissier Modifié",
        "role": "manager",
        "pin": "5678",
        "is_active": False,
    })
    assert update_res.status_code == 200
    up_data = update_res.json()
    assert up_data["full_name"] == "Caissier Modifié"
    assert up_data["role"] == "manager"
    assert up_data["is_active"] is False
    assert up_data["has_pin"] is True

    # 3. Delete user
    del_res = client.delete(f"/api/v1/users/{user_id}", headers=headers)
    assert del_res.status_code == 200
    assert del_res.json()["status"] == "success"

