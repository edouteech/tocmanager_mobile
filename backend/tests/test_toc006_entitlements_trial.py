from datetime import datetime, timedelta, timezone
import uuid
from fastapi.testclient import TestClient

from app.core.database import SessionLocal
from app.core.rate_limit import reset_rate_limits
from app.main import app
from app.models import AuditLog, Product, SaasSubscription
from app.services.feature_catalog import FEATURE_CATALOG


def _login(tc: TestClient, username: str, password: str) -> str:
    reset_rate_limits()
    resp = tc.post(
        "/api/v1/auth/login",
        json={"username_or_email": username, "password": password},
    )
    assert resp.status_code == 200, resp.text
    return resp.json()["access_token"]


def _provision(tc: TestClient, plan_code: str, tag: str):
    email = f"toc006_{tag}_{uuid.uuid4().hex[:5]}@example.com".lower()
    r1 = tc.post(
        "/api/v1/saas/auth/register-credentials",
        json={"full_name": f"Owner {tag}", "username_or_email": email, "password": "Password123!"},
    )
    assert r1.status_code == 200, r1.text
    r2 = tc.post(
        "/api/v1/saas/tenant/provision",
        headers={"Authorization": f"Bearer {r1.json()['access_token']}"},
        json={"boutique_name": f"Btq {tag}", "magasin_name": "Mag 1", "plan_code": plan_code},
    )
    assert r2.status_code == 200, r2.text
    data = r2.json()
    return {
        "boutique_id": data["boutique_id"],
        "magasin_id": data["magasin_id"],
        "headers": {"Authorization": f"Bearer {data['access_token']}", "X-Boutique-Id": data["boutique_id"]},
    }


def test_catalog_28_features_and_custom_plan_safe_defaults():
    with TestClient(app) as tc:
        pub = tc.get("/api/v1/saas/features-catalog")
        assert pub.status_code == 200
        assert len(pub.json()) == 28 == len(FEATURE_CATALOG)

        super_tok = _login(tc, "admin", "admin1234")
        super_h = {"Authorization": f"Bearer {super_tok}"}
        adm = tc.get("/api/v1/admin/features-catalog", headers=super_h)
        assert adm.status_code == 200
        assert len(adm.json()) == 28

        code = f"custom_{uuid.uuid4().hex[:5]}"
        created = tc.post(
            "/api/v1/admin/plans",
            headers=super_h,
            json={
                "name": "Custom Mini",
                "code": code,
                "price_monthly": 5000,
                "price_yearly": 50000,
                "features": [{"feature_code": "max_magasins", "int_limit": 2}],
            },
        )
        assert created.status_code == 200, created.text
        feat_map = {f["feature_code"]: f for f in created.json()["features"]}
        assert len(feat_map) == 28
        assert feat_map["max_magasins"]["int_limit"] == 2
        assert feat_map["module_credit_sales"]["boolean_value"] is False
        assert feat_map["max_clients"]["int_limit"] == 0


def test_dynamic_admin_edit_locks_credit_sale_and_client_quota():
    with TestClient(app) as tc:
        super_tok = _login(tc, "admin", "admin1234")
        super_h = {"Authorization": f"Bearer {super_tok}"}
        plans = tc.get("/api/v1/admin/plans", headers=super_h).json()
        pro_plan = next(p for p in plans if p["code"] == "pro")
        orig_features = pro_plan["features"]

        btq = _provision(tc, "pro", "dyn")
        prod_r = tc.post(
            "/api/v1/products",
            headers=btq["headers"],
            json={"name": "Savon", "price": 500, "cost_price": 200, "stock": 10},
        )
        assert prod_r.status_code == 200
        prod_id = prod_r.json()["sync_id"]

        updated_features = []
        for f in orig_features:
            item = dict(f)
            if item["feature_code"] == "module_credit_sales":
                item["boolean_value"] = False
            elif item["feature_code"] == "max_clients":
                item["int_limit"] = 1
            updated_features.append(item)

        try:
            up = tc.put(
                f"/api/v1/admin/plans/{pro_plan['id']}",
                headers=super_h,
                json={"features": updated_features},
            )
            assert up.status_code == 200

            cur = tc.get("/api/v1/tenant/current-plan", headers=btq["headers"]).json()
            assert cur["features"]["module_credit_sales"] is False
            assert cur["clients_limit"] == 1

            c1 = tc.post("/api/v1/clients", headers=btq["headers"], json={"name": "Client 1"})
            assert c1.status_code == 201
            c2 = tc.post("/api/v1/clients", headers=btq["headers"], json={"name": "Client 2"})
            assert c2.status_code == 403
            assert c2.json()["detail"]["error"] == "PLAN_QUOTA_EXCEEDED"

            sale = tc.post(
                "/api/v1/ventes",
                headers=btq["headers"],
                json={
                    "client_sync_id": c1.json()["sync_id"],
                    "items": [{"product_sync_id": prod_id, "quantity": 1, "unit_price": 500}],
                    "paid_amount": 0,
                    "payment_method": "Crédit",
                },
            )
            assert sale.status_code == 403
            assert sale.json()["detail"]["error"] == "PLAN_FEATURE_LOCKED"
        finally:
            tc.put(
                f"/api/v1/admin/plans/{pro_plan['id']}",
                headers=super_h,
                json={"features": orig_features},
            )


def test_expired_trial_downgrades_to_free_and_upgrade_requires_payment():
    with TestClient(app) as tc:
        btq = _provision(tc, "pro", "exp")
        db = SessionLocal()
        try:
            sub = db.query(SaasSubscription).filter(SaasSubscription.boutique_id == btq["boutique_id"]).first()
            sub.trial_ends_at = datetime.now(timezone.utc) - timedelta(minutes=1)
            db.commit()
        finally:
            db.close()

        status_resp = tc.get("/api/v1/tenant/current-plan", headers=btq["headers"]).json()
        assert status_resp["plan_code"] == "free"
        assert status_resp["trial_active"] is False
        assert status_resp["has_used_trial"] is True
        assert status_resp["features"]["pnl_reports"] is False

        assert tc.get("/api/v1/reports/financial", headers=btq["headers"]).status_code == 403
        up = tc.post("/api/v1/tenant/upgrade-plan", headers=btq["headers"], json={"plan_code": "pro"})
        assert up.status_code == 402
        assert up.json()["detail"]["error"] == "PAYMENT_REQUIRED"


def test_free_product_quota_via_api_and_sync_allows_offline_sale_and_blocks_cashier_upgrade():
    with TestClient(app) as tc:
        btq = _provision(tc, "free", "quota")
        c_uname = f"cash_q_{uuid.uuid4().hex[:5]}"
        assert tc.post(
            "/api/v1/users",
            headers=btq["headers"],
            json={"username": c_uname, "password": "Password123!", "role": "cashier", "pin": "1234"},
        ).status_code == 200
        c_tok = _login(tc, c_uname, "Password123!")
        assert tc.post(
            "/api/v1/tenant/upgrade-plan",
            headers={"Authorization": f"Bearer {c_tok}"},
            json={"plan_code": "pro"},
        ).status_code == 403

        db = SessionLocal()
        try:
            for idx in range(99):
                db.add(Product(boutique_id=btq["boutique_id"], name=f"SeedP {idx}", price=100))
            db.commit()
        finally:
            db.close()

        p100 = tc.post(
            "/api/v1/products",
            headers=btq["headers"],
            json={"name": "Prod 100", "price": 500},
        )
        assert p100.status_code == 200
        p101 = tc.post(
            "/api/v1/products",
            headers=btq["headers"],
            json={"name": "Prod 101", "price": 500},
        )
        assert p101.status_code == 403
        assert p101.json()["detail"]["error"] == "PLAN_QUOTA_EXCEEDED"

        sync_new = tc.post(
            "/api/v1/sync/push",
            headers=btq["headers"],
            json={
                "products": [{
                    "sync_id": str(uuid.uuid4()),
                    "name": "Sync 101",
                    "price": 100,
                    "cost_price": 50,
                    "stock": 5,
                    "min_stock": 1,
                }]
            },
        )
        assert sync_new.status_code == 403
        assert sync_new.json()["detail"]["error"] == "PLAN_QUOTA_EXCEEDED"

        sync_sale = tc.post(
            "/api/v1/sync/push",
            headers=btq["headers"],
            json={
                "ventes": [{
                    "sync_id": str(uuid.uuid4()),
                    "ticket_number": f"T-{uuid.uuid4().hex[:6]}",
                    "total_amount": 500,
                    "paid_amount": 500,
                    "payment_method": "Espèces",
                    "created_at": datetime.now(timezone.utc).isoformat(),
                    "items": [{"product_name": "Prod 100", "quantity": 1, "unit_price": 500, "cost_price": 0, "total": 500}],
                }]
            },
        )
        assert sync_sale.status_code == 200


def test_audit_retention_days_filtering():
    with TestClient(app) as tc:
        btq = _provision(tc, "pro", "auditret")
        db = SessionLocal()
        try:
            db.add(AuditLog(
                boutique_id=btq["boutique_id"],
                action="OLD_LOG",
                created_at=datetime.now(timezone.utc) - timedelta(days=120),
            ))
            db.add(AuditLog(
                boutique_id=btq["boutique_id"],
                action="RECENT_LOG",
                created_at=datetime.now(timezone.utc),
            ))
            db.commit()
        finally:
            db.close()

        res = tc.get("/api/v1/audit/logs", headers=btq["headers"])
        assert res.status_code == 200
        body = res.json()
        assert body["retention_days_applied"] == 90
        actions = {item["action"] for item in body["items"]}
        assert "RECENT_LOG" in actions
        assert "OLD_LOG" not in actions
