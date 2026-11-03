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
