import uuid
import pytest
from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def get_admin_token():
    resp = client.post("/api/v1/auth/login", json={
        "username_or_email": "admin",
        "password": "admin1234"
    })
    assert resp.status_code == 200, resp.text
    return resp.json()["access_token"]

def get_merchant_token():
    resp = client.post("/api/v1/auth/login", json={
        "username_or_email": "commercant",
        "password": "commercant1234"
    })
    assert resp.status_code == 200, resp.text
    return resp.json()["access_token"]

def test_public_plans():
    """Vérifie la disponibilité publique des forfaits pour la page de pricing."""
    response = client.get("/api/v1/saas/plans")
    assert response.status_code == 200
    plans = response.json()
    assert len(plans) >= 3
    plan_codes = [p["code"] for p in plans]
    assert "free" in plan_codes
    assert "pro" in plan_codes
    assert "enterprise" in plan_codes

def test_registration_and_onboarding_flow():
    """Vérifie le parcours d'inscription en 2 étapes (identifiants -> provision boutique)."""
    uid = uuid.uuid4().hex[:6]
    reg_payload = {
        "full_name": "Fatou Ndiaye",
        "username_or_email": f"fatou_{uid}@example.com",
        "password": "Password123!",
        "phone": "+221 77 123 45 67"
    }
    r1 = client.post("/api/v1/saas/auth/register-credentials", json=reg_payload)
    assert r1.status_code == 200, r1.text
    data1 = r1.json()
    assert "access_token" in data1
    token1 = data1["access_token"]

    # Étape 2 : Configuration de l'entreprise et première boutique
    onboarding_payload = {
        "boutique_name": f"Élégance Ndiaye {uid}",
        "company_name": "Ndiaye Fashion SARL",
        "currency": "XOF",
        "country": "Sénégal",
        "phone": "+221 77 123 45 67",
        "magasin_name": "Boutique Médina",
        "plan_code": "pro"
    }
    r2 = client.post(
        "/api/v1/saas/tenant/provision",
        json=onboarding_payload,
        headers={"Authorization": f"Bearer {token1}"}
    )
    assert r2.status_code == 200, r2.text
    data2 = r2.json()
    assert data2["success"] is True
    assert data2["boutique_name"] == f"Élégance Ndiaye {uid}"
    assert data2["magasin_name"] == "Boutique Médina"
    assert data2["trial_active"] is True # 14 jours pour pro

def test_admin_kpis_and_plans():
    """Vérifie l'accès du superadmin aux KPIs et aux forfaits."""
    admin_token = get_admin_token()
    headers = {"Authorization": f"Bearer {admin_token}"}

    # KPIs
    kpi_resp = client.get("/api/v1/admin/kpis", headers=headers)
    assert kpi_resp.status_code == 200
    kpis = kpi_resp.json()
    assert "mrr" in kpis
    assert "total_boutiques" in kpis
    assert kpis["total_boutiques"] >= 1

    # Boutiques list
    btq_resp = client.get("/api/v1/admin/boutiques", headers=headers)
    assert btq_resp.status_code == 200
    btqs = btq_resp.json()
    assert len(btqs) >= 1

def test_tenant_multi_magasins():
    """Vérifie la gestion des magasins et le statut du plan pour le tenant."""
    # L'administrateur de plateforme n'a pas de boutique client (renvoie [])
    admin_token = get_admin_token()
    assert client.get("/api/v1/tenant/boutiques", headers={"Authorization": f"Bearer {admin_token}"}).json() == []

    # Le commerçant a sa boutique
    merchant_token = get_merchant_token()
    headers = {"Authorization": f"Bearer {merchant_token}"}

    # Liste des boutiques
    btqs = client.get("/api/v1/tenant/boutiques", headers=headers).json()
    assert len(btqs) >= 1
    active_btq_id = btqs[0]["id"]
    headers["X-Boutique-Id"] = active_btq_id

    # Statut du plan
    plan_status = client.get("/api/v1/tenant/current-plan", headers=headers).json()
    assert "plan_name" in plan_status
    assert "features" in plan_status

    # Nettoyage préventif des magasins de test pour respecter le quota Pro (max 5)
    from app.core.database import SessionLocal
    from app.models import Magasin
    _db = SessionLocal()
    _db.query(Magasin).filter(Magasin.name == "Point de Vente 2").delete()
    _db.commit()
    _db.close()

    # Création d'un magasin supplémentaire
    mag_payload = {
        "name": "Point de Vente 2",
        "code": "MAG-02",
        "address": "Dakar Ville",
        "is_warehouse": False,
        "is_active": True
    }
    mag_resp = client.post("/api/v1/tenant/magasins", json=mag_payload, headers=headers)
    assert mag_resp.status_code == 200
    mag_data = mag_resp.json()
    assert mag_data["name"] == "Point de Vente 2"
