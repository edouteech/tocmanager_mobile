import uuid
from fastapi.testclient import TestClient
from app.main import app
from app.core.database import SessionLocal
from app.core.security import legacy_pin_digest
from app.core.rate_limit import reset_rate_limits
from app.models import User


def test_onboarding_token_blocked_on_private_routes():
    uid = uuid.uuid4().hex[:6]
    with TestClient(app) as tc:
        res = tc.post(
            "/api/v1/saas/auth/register-credentials",
            json={
                "full_name": "Onboarding Guard",
                "username_or_email": f"onb_{uid}@example.com",
                "password": "Password123!",
            },
        )
        assert res.status_code == 200
        token = res.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}

        assert tc.get("/api/v1/products", headers=headers).status_code == 403
        assert tc.get("/api/v1/tenant/boutiques", headers=headers).status_code == 403
        assert tc.get("/api/v1/admin/kpis", headers=headers).status_code == 403
        assert tc.get("/api/v1/auth/me", headers=headers).status_code == 200

        prov = tc.post(
            "/api/v1/saas/tenant/provision",
            headers=headers,
            json={"boutique_name": f"Boutique Onb {uid}", "magasin_name": "Principal"},
        )
        assert prov.status_code == 200


def test_refresh_token_rotation_and_reuse_detection():
    with TestClient(app) as tc:
        login_res = tc.post(
            "/api/v1/auth/login",
            json={"username_or_email": "commercant", "password": "commercant1234"},
        )
        assert login_res.status_code == 200
        rt1 = login_res.json()["refresh_token"]

        ref1 = tc.post("/api/v1/auth/refresh", json={"refresh_token": rt1})
        assert ref1.status_code == 200
        rt2 = ref1.json()["refresh_token"]
        assert rt2 != rt1

        # Replay of rt1 must trigger family revocation and return 401
        replay = tc.post("/api/v1/auth/refresh", json={"refresh_token": rt1})
        assert replay.status_code == 401

        # Even rt2 (the newer token in the same family) must now be revoked
        after_compromise = tc.post("/api/v1/auth/refresh", json={"refresh_token": rt2})
        assert after_compromise.status_code == 401


def test_logout_revokes_refresh_token():
    with TestClient(app) as tc:
        login_res = tc.post(
            "/api/v1/auth/login",
            json={"username_or_email": "commercant", "password": "commercant1234"},
        )
        data = login_res.json()
        headers = {"Authorization": f"Bearer {data['access_token']}"}
        rt = data["refresh_token"]

        out = tc.post("/api/v1/auth/logout", json={"refresh_token": rt}, headers=headers)
        assert out.status_code == 200
        assert out.json()["revoked_count"] == 1

        ref = tc.post("/api/v1/auth/refresh", json={"refresh_token": rt})
        assert ref.status_code == 401


def test_pin_bcrypt_migration_and_lockout():
    with TestClient(app) as tc:
        db = SessionLocal()
        try:
            user = db.query(User).filter(User.username == "caissier1").first()
            assert user is not None
            user.pin_hash = legacy_pin_digest("4321")
            user.pin_failed_attempts = 0
            user.pin_locked_until = None
            db.commit()
        finally:
            db.close()

        login_res = tc.post(
            "/api/v1/auth/login",
            json={"username_or_email": "caissier1", "password": "caisse1234"},
        )
        headers = {"Authorization": f"Bearer {login_res.json()['access_token']}"}

        # Success on legacy SHA-256 PIN must transparently migrate to bcrypt
        ok_res = tc.post("/api/v1/auth/verify-pin", json={"pin": "4321"}, headers=headers)
        assert ok_res.status_code == 200

        db = SessionLocal()
        try:
            user = db.query(User).filter(User.username == "caissier1").first()
            assert user.pin_hash.startswith("$2")
        finally:
            db.close()

        # 4 wrong attempts -> 400, 5th -> 423 Locked
        for attempt in range(4):
            bad = tc.post("/api/v1/auth/verify-pin", json={"pin": "9999"}, headers=headers)
            assert bad.status_code == 400, f"Expected 400 on attempt {attempt + 1}"

        # Reset rate-limit window before verifying DB 5-failure lockout (423)
        reset_rate_limits()
        fifth = tc.post("/api/v1/auth/verify-pin", json={"pin": "9999"}, headers=headers)
        assert fifth.status_code == 423

        # Even valid PIN fails while locked
        reset_rate_limits()
        still_locked = tc.post("/api/v1/auth/verify-pin", json={"pin": "4321"}, headers=headers)
        assert still_locked.status_code == 423


def test_rate_limit_enforced_on_verify_pin_and_login():
    with TestClient(app) as tc:
        # Unlock caissier1 cleanly first
        db = SessionLocal()
        try:
            user = db.query(User).filter(User.username == "caissier1").first()
            user.pin_failed_attempts = 0
            user.pin_locked_until = None
            db.commit()
        finally:
            db.close()

        login_res = tc.post(
            "/api/v1/auth/login",
            json={"username_or_email": "caissier1", "password": "caisse1234"},
        )
        headers = {"Authorization": f"Bearer {login_res.json()['access_token']}"}

        # 5 allowed per minute on /verify-pin, 6th returns 429
        for _ in range(5):
            r = tc.post("/api/v1/auth/verify-pin", json={"pin": "4321"}, headers=headers)
            assert r.status_code == 200
        sixth = tc.post("/api/v1/auth/verify-pin", json={"pin": "4321"}, headers=headers)
        assert sixth.status_code == 429

        # 10 allowed per minute on /login (1 already done above -> 9 more succeed, 11th -> 429)
        from app.core.rate_limit import reset_rate_limits
        reset_rate_limits()
        for _ in range(10):
            r = tc.post(
                "/api/v1/auth/login",
                json={"username_or_email": "caissier1", "password": "wrong"},
            )
            assert r.status_code == 401
        eleventh = tc.post(
            "/api/v1/auth/login",
            json={"username_or_email": "caissier1", "password": "wrong"},
        )
        assert eleventh.status_code == 429
