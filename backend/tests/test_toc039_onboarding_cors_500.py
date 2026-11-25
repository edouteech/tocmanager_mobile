import uuid
from fastapi.testclient import TestClient

from app.api.v1.endpoints import saas_public
from app.core.config import settings
from app.core.security import get_password_hash
from app.main import app
from app.models import SaasPlan, SaasSubscription, User
from app.schemas.saas import BoutiqueCreate
from app.services import onboarding_service
from app.services.tenant_service import create_boutique_for_owner


def test_provision_self_heals_when_saas_plans_table_is_empty(isolated_db_session):
    db, _, _ = isolated_db_session
    assert db.query(SaasPlan).count() == 0

    uid = uuid.uuid4().hex[:6]
    with TestClient(app) as tc:
        step1 = tc.post(
            "/api/v1/saas/auth/register-credentials",
            json={
                "full_name": "Self Heal Founder",
                "username_or_email": f"selfheal_{uid}@example.com",
                "password": "Password123!",
            },
        )
        assert step1.status_code == 200
        onboarding_token = step1.json()["access_token"]

        step2 = tc.post(
            "/api/v1/saas/tenant/provision",
            headers={"Authorization": f"Bearer {onboarding_token}"},
            json={
                "boutique_name": f"Boutique {uid}",
                "company_name": f"Entreprise {uid}",
                "currency": "XOF",
                "country": "Sénégal",
                "magasin_name": "Magasin Principal",
                "plan_code": "pro",
                "billing_cycle": "monthly",
            },
        )
        assert step2.status_code == 200, step2.text
        data = step2.json()
        assert data["success"] is True

    seeded_plans = db.query(SaasPlan).all()
    assert len(seeded_plans) >= 3
    sub = db.query(SaasSubscription).filter(SaasSubscription.boutique_id == data["boutique_id"]).first()
    assert sub is not None
    assert sub.plan_id != "free"
    assert sub.plan_id in {p.id for p in seeded_plans}


def test_provision_returns_503_when_plans_remain_unavailable(isolated_db_session, monkeypatch):
    db, _, _ = isolated_db_session
    assert db.query(SaasPlan).count() == 0
    monkeypatch.setattr(onboarding_service, "seed_saas_plans", lambda _db: None)

    uid = uuid.uuid4().hex[:6]
    with TestClient(app) as tc:
        step1 = tc.post(
            "/api/v1/saas/auth/register-credentials",
            json={
                "full_name": "Unavailable Plan Founder",
                "username_or_email": f"noplan_{uid}@example.com",
                "password": "Password123!",
            },
        )
        assert step1.status_code == 200
        onboarding_token = step1.json()["access_token"]

        step2 = tc.post(
            "/api/v1/saas/tenant/provision",
            headers={"Authorization": f"Bearer {onboarding_token}"},
            json={
                "boutique_name": f"Boutique {uid}",
                "magasin_name": "Principal",
                "plan_code": "pro",
            },
        )
        assert step2.status_code == 503
        assert "forfait SaaS" in step2.json()["detail"]


def test_create_boutique_for_owner_self_heals_empty_plans(isolated_db_session):
    db, _, _ = isolated_db_session
    assert db.query(SaasPlan).count() == 0

    owner = User(
        username="owner_heal",
        email="owner_heal@example.com",
        full_name="Owner Heal",
        hashed_password=get_password_hash("Secret123!"),
        role="merchant",
        is_active=True,
    )
    db.add(owner)
    db.commit()
    db.refresh(owner)

    created = create_boutique_for_owner(
        db,
        owner,
        BoutiqueCreate(name="Shop Self Heal", plan_code="pro"),
    )

    seeded_ids = {p.id for p in db.query(SaasPlan).all()}
    assert len(seeded_ids) >= 3
    sub = db.query(SaasSubscription).filter(SaasSubscription.boutique_id == created["id"]).first()
    assert sub is not None
    assert sub.plan_id != "free"
    assert sub.plan_id in seeded_ids


def test_register_credentials_resumes_orphan_user_only_with_matching_password(isolated_db_session):
    db, _, _ = isolated_db_session
    onboarding_service.seed_saas_plans(db)

    uid = uuid.uuid4().hex[:6]
    email = f"resume_{uid}@example.com"
    with TestClient(app) as tc:
        first = tc.post(
            "/api/v1/saas/auth/register-credentials",
            json={
                "full_name": "Amadou Diallo",
                "username_or_email": email,
                "password": "Password123!",
            },
        )
        assert first.status_code == 200
        assert first.json()["resumed"] is False

        wrong_pwd = tc.post(
            "/api/v1/saas/auth/register-credentials",
            json={
                "full_name": "Amadou Diallo",
                "username_or_email": email,
                "password": "WrongPassword999!",
            },
        )
        assert wrong_pwd.status_code == 400

        resumed = tc.post(
            "/api/v1/saas/auth/register-credentials",
            json={
                "full_name": "Amadou Diallo Updated",
                "username_or_email": email,
                "password": "Password123!",
            },
        )
        assert resumed.status_code == 200, resumed.text
        resumed_data = resumed.json()
        assert resumed_data["resumed"] is True
        assert resumed_data["full_name"] == "Amadou Diallo Updated"

        provision = tc.post(
            "/api/v1/saas/tenant/provision",
            headers={"Authorization": f"Bearer {resumed_data['access_token']}"},
            json={
                "boutique_name": f"Leo Sarl {uid}",
                "company_name": f"Leo Sarl Enterprise {uid}",
                "magasin_name": "Magasin Principal",
                "plan_code": "pro",
            },
        )
        assert provision.status_code == 200, provision.text

        after_boutique = tc.post(
            "/api/v1/saas/auth/register-credentials",
            json={
                "full_name": "Amadou Diallo Updated",
                "username_or_email": email,
                "password": "Password123!",
            },
        )
        assert after_boutique.status_code == 400


def test_unhandled_500_returns_json_with_cors_only_for_allowed_origins(isolated_db_session, monkeypatch):
    def _boom():
        raise RuntimeError("simulated unexpected crash")

    monkeypatch.setattr(saas_public, "serialize_feature_catalog", _boom)
    allowed_origin = settings.BACKEND_CORS_ORIGINS[0]

    with TestClient(app, raise_server_exceptions=False) as tc:
        allowed_res = tc.get(
            "/api/v1/saas/features-catalog",
            headers={"Origin": allowed_origin},
        )
        assert allowed_res.status_code == 500
        body = allowed_res.json()
        assert body["detail"] == "Erreur interne du serveur."
        assert body["request_id"]
        assert allowed_res.headers.get("x-request-id") == body["request_id"]
        assert allowed_res.headers.get("access-control-allow-origin") == allowed_origin

        blocked_res = tc.get(
            "/api/v1/saas/features-catalog",
            headers={"Origin": "https://untrusted.example.com"},
        )
        assert blocked_res.status_code == 500
        assert "access-control-allow-origin" not in blocked_res.headers
