import pytest
from fastapi.testclient import TestClient
from app.main import app

@pytest.fixture(scope="module")
def client():
    with TestClient(app) as test_client:
        yield test_client

def test_health(client):
    res = client.get("/health")
    assert res.status_code == 200
    assert res.json()["status"] == "ok"

def test_login_success(client):
    res = client.post("/api/v1/auth/login", json={
        "username_or_email": "admin",
        "password": "admin1234"
    })
    assert res.status_code == 200
    data = res.json()
    assert "access_token" in data
    assert data["user"]["role"] == "admin"
    assert data["user"]["has_pin"] is True

def test_verify_pin(client):
    # Login first
    login_res = client.post("/api/v1/auth/login", json={
        "username_or_email": "admin",
        "password": "admin1234"
    })
    token = login_res.json()["access_token"]

    # Verify correct PIN
    pin_res = client.post(
        "/api/v1/auth/verify-pin",
        json={"pin": "1234"},
        headers={"Authorization": f"Bearer {token}"}
    )
    assert pin_res.status_code == 200
    assert pin_res.json()["username"] == "admin"

    # Verify wrong PIN
    pin_bad = client.post(
        "/api/v1/auth/verify-pin",
        json={"pin": "9999"},
        headers={"Authorization": f"Bearer {token}"}
    )
    assert pin_bad.status_code == 400

def test_sync_pull(client):
    login_res = client.post("/api/v1/auth/login", json={
        "username_or_email": "admin",
        "password": "admin1234"
    })
    token = login_res.json()["access_token"]

    pull_res = client.get(
        "/api/v1/sync/pull",
        headers={"Authorization": f"Bearer {token}"}
    )
    assert pull_res.status_code == 200
    data = pull_res.json()
    assert "products" in data
    assert len(data["products"]) >= 3
    assert "categories" in data
    assert "clients" in data

def test_sync_push_idempotent_vente(client):
    login_res = client.post("/api/v1/auth/login", json={
        "username_or_email": "caissier1",
        "password": "caisse1234"
    })
    token = login_res.json()["access_token"]

    test_uuid = "99999999-0000-0000-0000-000000000001"
    vente_payload = {
        "sync_id": test_uuid,
        "ticket_number": "VNT-TEST-001",
        "client_name": "Occasionnel",
        "total_amount": 1000.0,
        "paid_amount": 1000.0,
        "payment_method": "Espèces",
        "created_at": "2026-11-01T20:00:00Z",
        "items": [
            {
                "product_name": "Produit Test",
                "quantity": 2.0,
                "unit_price": 500.0,
                "cost_price": 300.0,
                "total": 1000.0
            }
        ]
    }

    # First push
    push_res1 = client.post(
        "/api/v1/sync/push",
        json={"ventes": [vente_payload]},
        headers={"Authorization": f"Bearer {token}"}
    )
    assert push_res1.status_code == 200
    assert test_uuid in push_res1.json()["synced_uuids"]

    # Second push (idempotent, must not duplicate or crash)
    push_res2 = client.post(
        "/api/v1/sync/push",
        json={"ventes": [vente_payload]},
        headers={"Authorization": f"Bearer {token}"}
    )
    assert push_res2.status_code == 200
    assert test_uuid in push_res2.json()["synced_uuids"]

def test_audit_logs(client):
    login_res = client.post("/api/v1/auth/login", json={
        "username_or_email": "admin",
        "password": "admin1234"
    })
    token = login_res.json()["access_token"]

    res = client.get("/api/v1/audit/logs", headers={"Authorization": f"Bearer {token}"})
    assert res.status_code == 200
    data = res.json()
    assert "items" in data
    assert "total" in data
    assert data["total"] >= 1
    # Check that LOGIN action was recorded for admin
    actions = [item["action"] for item in data["items"]]
    assert "LOGIN" in actions
