from datetime import datetime, timezone
import uuid
from fastapi.testclient import TestClient

from app.core.database import SessionLocal
from app.core.rate_limit import reset_rate_limits
from app.main import app
from app.models import Product


def _provision(tc: TestClient, tag: str):
    reset_rate_limits()
    uid = uuid.uuid4().hex[:6]
    ident = f"toc046_{tag}_{uid}@example.com".lower()
    reg = tc.post(
        "/api/v1/saas/auth/register-credentials",
        json={"full_name": f"Owner {tag}", "username_or_email": ident, "password": "Password123!"},
    )
    assert reg.status_code == 200
    prov = tc.post(
        "/api/v1/saas/tenant/provision",
        headers={"Authorization": f"Bearer {reg.json()['access_token']}"},
        json={"boutique_name": f"Btq {tag} {uid}", "magasin_name": "Mag 1", "plan_code": "pro"},
    )
    assert prov.status_code == 200
    data = prov.json()
    login = tc.post(
        "/api/v1/auth/login",
        json={"username_or_email": ident, "password": "Password123!"},
    )
    assert login.status_code == 200
    lj = login.json()
    return {
        "boutique_id": data["boutique_id"],
        "magasin_id": data["magasin_id"],
        "access_token": lj["access_token"],
        "refresh_token": lj["refresh_token"],
        "headers": {
            "Authorization": f"Bearer {lj['access_token']}",
            "X-Boutique-Id": data["boutique_id"],
            "X-Magasin-Id": data["magasin_id"],
        },
    }


def test_logout_with_bearer_revokes_refresh_token_and_push_persists_image_path():
    with TestClient(app) as tc:
        env = _provision(tc, "logoutimg")

        # Without Bearer token, /auth/logout fails 401
        unauth = tc.post("/api/v1/auth/logout", json={"refresh_token": env["refresh_token"]})
        assert unauth.status_code == 401

        # Pushing product with image_path persists URL on create & update
        prod_id = str(uuid.uuid4())
        now = datetime.now(timezone.utc).isoformat()
        push_res = tc.post(
            "/api/v1/sync/push",
            headers=env["headers"],
            json={
                "products": [{
                    "sync_id": prod_id,
                    "name": "Sac Cuir",
                    "price": 15000,
                    "cost_price": 9000,
                    "stock": 4,
                    "min_stock": 1,
                    "image_path": "/uploads/images/sac_cuir.png",
                    "updated_at": now,
                }]
            },
        )
        assert push_res.status_code == 200, push_res.text

        with SessionLocal() as db:
            row = db.query(Product).filter(Product.sync_id == prod_id).first()
            assert row is not None
            assert row.image_path == "/uploads/images/sac_cuir.png"

        # With Bearer token, /auth/logout revokes the refresh token
        logout_res = tc.post(
            "/api/v1/auth/logout",
            headers={"Authorization": f"Bearer {env['access_token']}"},
            json={"refresh_token": env["refresh_token"]},
        )
        assert logout_res.status_code == 200, logout_res.text
        assert logout_res.json()["revoked_count"] >= 1

        # Refresh token is now rejected
        refresh_res = tc.post("/api/v1/auth/refresh", json={"refresh_token": env["refresh_token"]})
        assert refresh_res.status_code == 401
