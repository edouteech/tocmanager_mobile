import uuid
from fastapi.testclient import TestClient
from app.main import app
from app.core.database import SessionLocal
from app.models import PlatformAuditLog, SaasSubscription


def test_onboarding_provision_returns_full_session_and_refresh_works():
    uid = uuid.uuid4().hex[:6]
    email = f"founder_{uid}@example.com"
    with TestClient(app) as tc:
        step1 = tc.post(
            "/api/v1/saas/auth/register-credentials",
            json={
                "full_name": "Kofi Mensah",
                "username_or_email": email,
                "password": "StrongPass123!",
                "phone": "+221770001122",
            },
        )
        assert step1.status_code == 200
        onboarding_token = step1.json()["access_token"]

        step2 = tc.post(
            "/api/v1/saas/tenant/provision",
            headers={"Authorization": f"Bearer {onboarding_token}"},
            json={
                "boutique_name": f"Boutique {uid}",
                "company_name": f"Groupe {uid} SARL",
                "currency": "XOF",
                "country": "Côte d'Ivoire",
                "magasin_name": "Plateau",
                "plan_code": "enterprise",
                "billing_cycle": "yearly",
            },
        )
        assert step2.status_code == 200
        body = step2.json()
        assert body["access_token"]
        assert body["refresh_token"]
        assert body["user"]["username"] == email
        assert body["user"]["role"] == "merchant"
        assert body["boutique_id"]
        assert body["magasin_id"]

        # Access token must immediately work on protected routes
        prod_res = tc.get(
            "/api/v1/products",
            headers={
                "Authorization": f"Bearer {body['access_token']}",
                "X-Boutique-Id": body["boutique_id"],
                "X-Magasin-Id": body["magasin_id"],
            },
        )
        assert prod_res.status_code == 200

        # Refresh token returned by provision must rotate cleanly
        ref_res = tc.post("/api/v1/auth/refresh", json={"refresh_token": body["refresh_token"]})
        assert ref_res.status_code == 200
        assert ref_res.json()["refresh_token"] != body["refresh_token"]

    db = SessionLocal()
    try:
        sub = (
            db.query(SaasSubscription)
            .filter(SaasSubscription.boutique_id == body["boutique_id"])
            .first()
        )
        assert sub is not None
        assert sub.billing_cycle == "yearly"
    finally:
        db.close()


def test_public_contact_persists_message_and_validates_payload():
    uid = uuid.uuid4().hex[:6]
    with TestClient(app) as tc:
        bad = tc.post(
            "/api/v1/saas/contact",
            json={
                "full_name": "A",
                "email": "invalid-email",
                "message": "court",
            },
        )
        assert bad.status_code == 422

        res = tc.post(
            "/api/v1/saas/contact",
            json={
                "full_name": "Mariam Traore",
                "email": f"mariam_{uid}@example.com",
                "company": "Traore Distribution",
                "phone": "+22507000000",
                "message": "Bonjour, nous souhaitons déployer TocManager sur 8 magasins.",
            },
        )
        assert res.status_code == 200
        assert res.json()["success"] is True

    db = SessionLocal()
    try:
        entry = (
            db.query(PlatformAuditLog)
            .filter(
                PlatformAuditLog.action == "PUBLIC_CONTACT_MESSAGE",
                PlatformAuditLog.admin_username == f"mariam_{uid}@example.com",
            )
            .first()
        )
        assert entry is not None
        assert entry.details["company"] == "Traore Distribution"
    finally:
        db.close()
