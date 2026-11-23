from datetime import datetime, timedelta, timezone
import json
import uuid
import httpx
from fastapi.testclient import TestClient

from app.core.database import SessionLocal
from app.main import app
from app.models import PlatformAuditLog, SaasInvoice, SaasSubscription
from app.services.payments.feexpay_gateway import FeexPayGateway
from app.services.subscription_lifecycle import sync_subscriptions_lifecycle


def _provision(tc: TestClient, plan_code: str, tag: str):
    email = f"toc007_{tag}_{uuid.uuid4().hex[:5]}@example.com".lower()
    r1 = tc.post(
        "/api/v1/saas/auth/register-credentials",
        json={"full_name": f"Owner {tag}", "username_or_email": email, "password": "Password123!"},
    )
    assert r1.status_code == 200
    r2 = tc.post(
        "/api/v1/saas/tenant/provision",
        headers={"Authorization": f"Bearer {r1.json()['access_token']}"},
        json={"boutique_name": f"Btq {tag}", "magasin_name": "Mag 1", "plan_code": plan_code},
    )
    assert r2.status_code == 200
    d = r2.json()
    return {"boutique_id": d["boutique_id"], "headers": {"Authorization": f"Bearer {d['access_token']}", "X-Boutique-Id": d["boutique_id"]}}


def test_feexpay_payload_normalization_redirect_and_otp_networks():
    captured = []

    def handler(request: httpx.Request) -> httpx.Response:
        body = json.loads(request.content.decode("utf-8"))
        captured.append((str(request.url), body))
        if request.url.path.endswith("/wave_ci"):
            return httpx.Response(200, json={"status": "PENDING", "reference": "EXT-WAVE-1", "payment_url": "https://pay.feexpay.me/wave"})
        return httpx.Response(200, json={"status": "PENDING", "reference": "EXT-OTP-1"})

    gw = FeexPayGateway("https://api-v2.feexpay.me", "test-key", "shop-1", http_client=httpx.Client(transport=httpx.MockTransport(handler)))

    r_wave = gw.initiate("TOC-1", 15000, "+22990000000", "WAVE CI", "Owner", "o@t.com", "Pro")
    assert r_wave.flow_type == "redirect"
    assert r_wave.payment_url == "https://pay.feexpay.me/wave"
    assert captured[0][1]["phoneNumber"] == "22990000000"
    assert "otp" not in captured[0][1]

    r_coris = gw.initiate("TOC-2", 15000, "+22670000000", "CORIS", "Owner", "o@t.com", "Pro")
    assert r_coris.flow_type == "ussd_push"
    assert captured[1][1]["otp"] == ""


def test_webhook_forged_unconfirmed_does_not_activate(monkeypatch):
    with TestClient(app) as tc:
        btq = _provision(tc, "free", "forge")

        def handler(request: httpx.Request) -> httpx.Response:
            if "requesttopay" in request.url.path:
                return httpx.Response(200, json={"status": "PENDING", "reference": "FP-PENDING-1"})
            return httpx.Response(200, json={"status": "PENDING", "reference": "FP-PENDING-1"})

        gw = FeexPayGateway("https://api-v2.feexpay.me", "k", "s", http_client=httpx.Client(transport=httpx.MockTransport(handler)))
        monkeypatch.setattr("app.services.payments.billing_service.get_feexpay_gateway", lambda db: gw)

        co = tc.post("/api/v1/billing/checkout", headers=btq["headers"], json={"plan_code": "pro", "billing_cycle": "monthly", "network": "MTN", "phone": "+22990000001"})
        assert co.status_code == 200
        ref = co.json()["reference"]

        wh = tc.post("/api/v1/webhooks/feexpay", json={"callback_info": ref, "reference": "FP-PENDING-1", "status": "SUCCESSFUL"})
        assert wh.status_code == 200
        assert wh.json()["status"] == "unconfirmed"

        plan = tc.get("/api/v1/tenant/current-plan", headers=btq["headers"]).json()
        assert plan["plan_code"] == "free"

        db = SessionLocal()
        try:
            assert db.query(PlatformAuditLog).filter(PlatformAuditLog.action == "FEEXPAY_UNCONFIRMED_CALLBACK").count() >= 1
        finally:
            db.close()


def test_confirmed_webhook_idempotency_and_pdf_invoice_isolation(monkeypatch):
    with TestClient(app) as tc:
        btq_a = _provision(tc, "free", "inv_a")
        btq_b = _provision(tc, "free", "inv_b")

        def handler(request: httpx.Request) -> httpx.Response:
            if "requesttopay" in request.url.path:
                return httpx.Response(200, json={"status": "PENDING", "reference": "FP-OK-99"})
            return httpx.Response(200, json={"status": "SUCCESSFUL", "reference": "FP-OK-99", "amount": 15000})

        gw = FeexPayGateway("https://api-v2.feexpay.me", "k", "s", http_client=httpx.Client(transport=httpx.MockTransport(handler)))
        monkeypatch.setattr("app.services.payments.billing_service.get_feexpay_gateway", lambda db: gw)

        co = tc.post("/api/v1/billing/checkout", headers=btq_a["headers"], json={"plan_code": "pro", "billing_cycle": "monthly", "network": "MTN", "phone": "22990000002"})
        assert co.status_code == 200
        ref = co.json()["reference"]

        for _ in range(2):
            wh = tc.post("/api/v1/webhooks/feexpay", json={"callback_info": ref, "reference": "FP-OK-99", "status": "SUCCESSFUL", "amount": 15000})
            assert wh.status_code == 200
        st = tc.get(f"/api/v1/billing/status/{ref}", headers=btq_a["headers"])
        assert st.status_code == 200
        assert st.json()["status"] == "successful"

        invs = tc.get("/api/v1/billing/invoices", headers=btq_a["headers"]).json()
        assert len(invs) == 1
        inv_id = invs[0]["id"]

        pdf_a = tc.get(f"/api/v1/billing/invoices/{inv_id}/pdf", headers=btq_a["headers"])
        assert pdf_a.status_code == 200
        assert pdf_a.content.startswith(b"%PDF")

        pdf_b = tc.get(f"/api/v1/billing/invoices/{inv_id}/pdf", headers=btq_b["headers"])
        assert pdf_b.status_code == 404

        db = SessionLocal()
        try:
            assert db.query(SaasInvoice).filter(SaasInvoice.boutique_id == btq_a["boutique_id"]).count() == 1
        finally:
            db.close()


def test_sandbox_synchronous_activation_and_lifecycle_transitions(monkeypatch):
    with TestClient(app) as tc:
        btq = _provision(tc, "free", "syncsbx")

        def handler(request: httpx.Request) -> httpx.Response:
            return httpx.Response(200, json={"status": "SUCCESSFUL", "reference": "SBX-1"})

        gw = FeexPayGateway("https://api-v2.feexpay.me", "k", "s", http_client=httpx.Client(transport=httpx.MockTransport(handler)))
        monkeypatch.setattr("app.services.payments.billing_service.get_feexpay_gateway", lambda db: gw)

        co = tc.post("/api/v1/billing/checkout", headers=btq["headers"], json={"plan_code": "enterprise", "billing_cycle": "yearly", "network": "MTN", "phone": "22990000003"})
        assert co.status_code == 200
        assert co.json()["status"] == "successful"
        assert co.json()["amount"] == 400000.0

        assert tc.get("/api/v1/tenant/current-plan", headers=btq["headers"]).json()["plan_code"] == "enterprise"

        db = SessionLocal()
        try:
            sub = db.query(SaasSubscription).filter(SaasSubscription.boutique_id == btq["boutique_id"]).first()
            sub.current_period_end = datetime.now(timezone.utc) - timedelta(days=1)
            db.commit()
            res1 = sync_subscriptions_lifecycle(db)
            assert res1["marked_past_due"] >= 1

            db.refresh(sub)
            assert sub.status == "past_due"
            sub.current_period_end = datetime.now(timezone.utc) - timedelta(days=5)
            db.commit()
            res2 = sync_subscriptions_lifecycle(db)
            assert res2["canceled_after_grace"] >= 1
        finally:
            db.close()

        assert tc.get("/api/v1/tenant/current-plan", headers=btq["headers"]).json()["plan_code"] == "free"
