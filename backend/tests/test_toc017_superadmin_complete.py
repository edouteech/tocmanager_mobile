import uuid
from datetime import datetime, timezone
from fastapi.testclient import TestClient
from app.main import app
from app.core.database import SessionLocal
from app.models import Boutique, Magasin, SaasPlan, SaasSubscription, User


def _login(tc: TestClient, username: str, password: str) -> str:
    res = tc.post(
        "/api/v1/auth/login",
        json={"username_or_email": username, "password": password},
    )
    assert res.status_code == 200, res.text
    return res.json()["access_token"]


def test_toc017_mrr_excludes_trialing_prorates_yearly_and_handles_multicurrency():
    db = SessionLocal()
    try:
        # Preserve clean subscription set while computing delta or isolate by snapshot
        admin_user = db.query(User).filter(User.role == "superadmin").first()
        pro_xof = db.query(SaasPlan).filter(SaasPlan.code == "pro").first()
        assert admin_user is not None and pro_xof is not None

        eur_plan = db.query(SaasPlan).filter(SaasPlan.code == "pro_eur_test").first()
        if not eur_plan:
            eur_plan = SaasPlan(
                name="Pro EUR",
                code="pro_eur_test",
                price_monthly=20.0,
                price_yearly=200.0,
                currency="EUR",
                trial_period_days=0,
                is_active=True,
            )
            db.add(eur_plan)
            db.flush()

        # Clear existing subscriptions temporarily to verify exact formula
        saved_subs = [
            (s.boutique_id, s.plan_id, s.status, s.billing_cycle, s.trial_ends_at)
            for s in db.query(SaasSubscription).all()
        ]
        db.query(SaasSubscription).delete()

        # Re-create 3 test subscriptions cleanly across boutiques
        owner = db.query(User).filter(User.role != "superadmin").first()
        boutiques = db.query(Boutique).all()
        while len(boutiques) < 4:
            uid = uuid.uuid4().hex[:6]
            b = Boutique(
                slug=f"test-kpi-{uid}",
                name=f"KPI Boutique {uid}",
                owner_user_id=owner.id,
                currency="XOF",
                is_active=True,
            )
            db.add(b)
            db.flush()
            db.add(Magasin(boutique_id=b.id, name="Mag", code="M1", is_active=True))
            boutiques.append(b)

        # 1) Trialing Pro (15 000) -> contributes 0 to MRR
        db.add(
            SaasSubscription(
                boutique_id=boutiques[0].id,
                plan_id=pro_xof.id,
                status="trialing",
                billing_cycle="monthly",
                trial_ends_at=datetime(2099, 1, 1),  # naive datetime intentionally for SQLite check
            )
        )
        # 2) Active Pro monthly (15 000) -> 15 000 XOF
        db.add(
            SaasSubscription(
                boutique_id=boutiques[1].id,
                plan_id=pro_xof.id,
                status="active",
                billing_cycle="monthly",
            )
        )
        # 3) Active Pro yearly (150 000 / 12 = 12 500) -> 12 500 XOF
        db.add(
            SaasSubscription(
                boutique_id=boutiques[2].id,
                plan_id=pro_xof.id,
                status="active",
                billing_cycle="yearly",
            )
        )
        # 4) Active EUR monthly (20 EUR) -> mrr_by_currency["EUR"] == 20.0
        db.add(
            SaasSubscription(
                boutique_id=boutiques[3].id,
                plan_id=eur_plan.id,
                status="active",
                billing_cycle="monthly",
            )
        )
        db.commit()
    finally:
        db.close()

    try:
        with TestClient(app) as tc:
            token = _login(tc, "admin", "admin1234")
            res = tc.get("/api/v1/admin/kpis", headers={"Authorization": f"Bearer {token}"})
            assert res.status_code == 200, res.text
            data = res.json()
            assert data["trialing_subscriptions"] == 1
            assert data["active_subscriptions"] == 3
            assert data["mrr_by_currency"]["XOF"] == 27500.0
            assert data["mrr_by_currency"]["EUR"] == 20.0
            assert data["mrr"] > 27500.0
            assert "gmv_by_currency" in data
            assert "conversion_rate" in data
            assert "churn_rate" in data
    finally:
        # Restore subscriptions
        db = SessionLocal()
        try:
            db.query(SaasSubscription).delete()
            for btq_id, plan_id, st, cyc, te in saved_subs:
                db.add(
                    SaasSubscription(
                        boutique_id=btq_id,
                        plan_id=plan_id,
                        status=st,
                        billing_cycle=cyc,
                        trial_ends_at=te,
                    )
                )
            db.query(SaasPlan).filter(SaasPlan.code == "pro_eur_test").delete()
            db.commit()
        finally:
            db.close()


def test_toc017_extend_trial_utc_validation_impersonation_and_provider_secrets():
    uid = uuid.uuid4().hex[:6]
    with TestClient(app) as tc:
        admin_token = _login(tc, "admin", "admin1234")
        admin_headers = {"Authorization": f"Bearer {admin_token}"}

        boutiques = tc.get("/api/v1/admin/boutiques", headers=admin_headers).json()
        assert len(boutiques) >= 1
        target_btq_id = boutiques[0]["id"]

        # 1) extend-trial validation (days=0 or non-int -> 422; valid -> 200 without naive TZ TypeError)
        assert (
            tc.post(
                f"/api/v1/admin/boutiques/{target_btq_id}/extend-trial",
                json={"days": 0},
                headers=admin_headers,
            ).status_code
            == 422
        )
        assert (
            tc.post(
                f"/api/v1/admin/boutiques/{target_btq_id}/extend-trial",
                json={"days": "abc"},
                headers=admin_headers,
            ).status_code
            == 422
        )
        ok_ext = tc.post(
            f"/api/v1/admin/boutiques/{target_btq_id}/extend-trial",
            json={"days": 14},
            headers=admin_headers,
        )
        assert ok_ext.status_code == 200, ok_ext.text

        # 2) Boutique detail + manual plan assignment + audit log
        detail = tc.get(f"/api/v1/admin/boutiques/{target_btq_id}", headers=admin_headers)
        assert detail.status_code == 200
        assert detail.json()["owner"]["email"] is not None

        assign = tc.put(
            f"/api/v1/admin/boutiques/{target_btq_id}/plan",
            json={"plan_code": "pro", "status": "active", "billing_cycle": "monthly", "period_days": 30, "reason": "VIP"},
            headers=admin_headers,
        )
        assert assign.status_code == 200, assign.text

        # 3) Impersonation read-only enforcement
        imp = tc.post(
            f"/api/v1/admin/boutiques/{target_btq_id}/impersonate",
            headers=admin_headers,
        )
        assert imp.status_code == 200, imp.text
        imp_token = imp.json()["access_token"]
        assert imp.json()["read_only"] is True
        imp_headers = {"Authorization": f"Bearer {imp_token}", "X-Boutique-Id": target_btq_id}

        assert tc.get("/api/v1/products", headers=imp_headers).status_code == 200
        blocked_write = tc.post(
            "/api/v1/products",
            json={"name": "Blocked Write", "price": 100},
            headers=imp_headers,
        )
        assert blocked_write.status_code == 403

        # 4) FeexPay provider credentials encryption & masking
        secret_key = f"fp_secret_{uid}_99887766"
        put_prov = tc.put(
            "/api/v1/admin/payment-providers/feexpay",
            json={
                "mode": "sandbox",
                "is_active": True,
                "sandbox": {"api_key": secret_key, "api_id": "shop_123"},
            },
            headers=admin_headers,
        )
        assert put_prov.status_code == 200, put_prov.text
        assert secret_key not in str(put_prov.json())
        assert "****" in put_prov.json()["sandbox"]["api_key_masked"]

        get_prov = tc.get("/api/v1/admin/payment-providers/feexpay", headers=admin_headers)
        assert get_prov.status_code == 200
        assert secret_key not in str(get_prov.json())
        assert get_prov.json()["sandbox"]["has_api_key"] is True

        # Saving again with masked key preserves stored key
        put_prov2 = tc.put(
            "/api/v1/admin/payment-providers/feexpay",
            json={
                "sandbox": {
                    "api_key": get_prov.json()["sandbox"]["api_key_masked"],
                    "api_id": "shop_456",
                }
            },
            headers=admin_headers,
        )
        assert put_prov2.status_code == 200
        assert put_prov2.json()["sandbox"]["has_api_key"] is True
        assert put_prov2.json()["sandbox"]["api_id"] == "shop_456"

        # 5) Subscriptions & Audit endpoints
        subs_res = tc.get("/api/v1/admin/subscriptions", headers=admin_headers)
        assert subs_res.status_code == 200
        assert "items" in subs_res.json() and "transactions" in subs_res.json()

        audit_res = tc.get("/api/v1/admin/audit", headers=admin_headers)
        assert audit_res.status_code == 200
        actions = [item["action"] for item in audit_res.json()["items"]]
        assert "SUPPORT_IMPERSONATE_START" in actions
        assert "PAYMENT_PROVIDER_UPDATE" in actions
