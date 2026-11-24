from io import StringIO
import logging
from pathlib import Path
import subprocess

from fastapi.testclient import TestClient
import pyotp

from app.core.logging import JsonLogFormatter
from app.core.security import create_access_token
from app.main import app
from app.services import account_security_service
from app.services.storage_service import settings as storage_settings


def test_observability_json_logs_request_id_and_health_endpoints(multi_tenant_env, monkeypatch):
    client = multi_tenant_env["client"]
    monkeypatch.setattr(storage_settings, "S3_BUCKET", None)

    stream = StringIO()
    handler = logging.StreamHandler(stream)
    handler.setFormatter(JsonLogFormatter())
    logger = logging.getLogger("tocmanager")
    old_handlers = logger.handlers
    logger.handlers = [handler]

    try:
        live = client.get("/health/live")
        assert live.status_code == 200
        assert live.json()["status"] == "alive"
        assert "X-Request-Id" in live.headers

        ready = client.get("/health/ready", headers={"X-Request-Id": "req-custom-42"})
        assert ready.status_code == 200
        assert ready.json() == {"status": "ready", "database": "ok", "storage": "local"}
        assert ready.headers["X-Request-Id"] == "req-custom-42"

        raw_logs = stream.getvalue()
        assert "req-custom-42" in raw_logs
        assert "Secret123!" not in raw_logs
    finally:
        logger.handlers = old_handlers


def test_health_ready_returns_503_when_db_unreachable(tmp_path):
    from app.core.database import get_db

    class BrokenSession:
        def execute(self, *_args, **_kwargs):
            raise RuntimeError("DB offline")

        def close(self):
            pass

    def broken_db():
        yield BrokenSession()

    app.dependency_overrides[get_db] = broken_db
    try:
        client = TestClient(app)
        res = client.get("/health/ready")
        assert res.status_code == 503
        assert res.json()["status"] == "not_ready"
        assert res.json()["database"] == "error"
    finally:
        app.dependency_overrides.clear()


def test_forgot_reset_password_anti_enumeration_single_use_and_revokes_tokens(multi_tenant_env, monkeypatch):
    client = multi_tenant_env["client"]
    merchant = multi_tenant_env["merchant"]

    sent_reset_tokens = []

    def fake_send_reset(to_email, full_name, raw_token):
        sent_reset_tokens.append((to_email, raw_token))
        return "console"

    monkeypatch.setattr(account_security_service, "send_password_reset", fake_send_reset)

    login_res = client.post("/api/v1/auth/login", json={"username_or_email": merchant.username, "password": "Secret123!"})
    assert login_res.status_code == 200
    refresh_token = login_res.json()["refresh_token"]

    # Non-existent email returns exact same 200 payload as valid email (anti-enumeration)
    missing_res = client.post("/api/v1/auth/forgot-password", json={"email": "nobody@tocmanager.local"})
    valid_res = client.post("/api/v1/auth/forgot-password", json={"email": merchant.email})
    assert missing_res.status_code == 200
    assert valid_res.status_code == 200
    assert missing_res.json() == valid_res.json()
    assert len(sent_reset_tokens) == 1

    reset_tok = sent_reset_tokens[0][1]
    ok_reset = client.post("/api/v1/auth/reset-password", json={"token": reset_tok, "new_password": "NewStrongPassword!1"})
    assert ok_reset.status_code == 200

    # Reusing the same reset token must fail with 400
    reused_reset = client.post("/api/v1/auth/reset-password", json={"token": reset_tok, "new_password": "AnotherPassword!2"})
    assert reused_reset.status_code == 400

    # Old refresh tokens must be revoked immediately after password reset
    ref_res = client.post("/api/v1/auth/refresh", json={"refresh_token": refresh_token})
    assert ref_res.status_code == 401

    # Can login with the new password
    relogin = client.post("/api/v1/auth/login", json={"username_or_email": merchant.username, "password": "NewStrongPassword!1"})
    assert relogin.status_code == 200


def test_email_verification_flow_single_use(multi_tenant_env, monkeypatch):
    client = multi_tenant_env["client"]
    merchant = multi_tenant_env["merchant"]
    sent_verify = []

    monkeypatch.setattr(
        account_security_service,
        "send_email_verification",
        lambda to_email, full_name, raw_token: sent_verify.append(raw_token) or "console",
    )

    headers = {"Authorization": f"Bearer {create_access_token(merchant.id)}"}
    req = client.post("/api/v1/auth/request-email-verification", headers=headers)
    assert req.status_code == 200
    assert len(sent_verify) == 1

    ver = client.post("/api/v1/auth/verify-email", json={"token": sent_verify[0]})
    assert ver.status_code == 200
    assert ver.json()["email_verified"] is True

    # Reusing verification token fails 400
    reused = client.post("/api/v1/auth/verify-email", json={"token": sent_verify[0]})
    assert reused.status_code == 400


def test_superadmin_2fa_challenge_blocks_admin_routes_until_verified(multi_tenant_env):
    client = multi_tenant_env["client"]
    superadmin = multi_tenant_env["superadmin"]
    admin_hdrs = {"Authorization": f"Bearer {create_access_token(superadmin.id)}"}

    setup_res = client.post("/api/v1/auth/2fa/setup", headers=admin_hdrs)
    assert setup_res.status_code == 200
    secret = setup_res.json()["secret"]
    totp = pyotp.TOTP(secret)

    confirm_res = client.post("/api/v1/auth/2fa/confirm", headers=admin_hdrs, json={"code": totp.now()})
    assert confirm_res.status_code == 200
    assert confirm_res.json()["totp_enabled"] is True

    # Login returns requires_2fa + challenge_token with no usable access_token
    login_res = client.post("/api/v1/auth/login", json={"username_or_email": superadmin.username, "password": "Secret123!"})
    assert login_res.status_code == 200
    body = login_res.json()
    assert body["requires_2fa"] is True
    challenge_tok = body["challenge_token"]
    assert challenge_tok

    # Challenge token must be rejected on /api/v1/admin/*
    blocked = client.get("/api/v1/admin/kpis", headers={"Authorization": f"Bearer {challenge_tok}"})
    assert blocked.status_code == 401

    # Completing 2FA returns real access token granting /api/v1/admin/kpis access
    verify_res = client.post("/api/v1/auth/verify-2fa", json={"challenge_token": challenge_tok, "code": totp.now()})
    assert verify_res.status_code == 200
    real_token = verify_res.json()["access_token"]
    allowed = client.get("/api/v1/admin/kpis", headers={"Authorization": f"Bearer {real_token}"})
    assert allowed.status_code == 200


def test_backup_script_passes_bash_syntax_check():
    script = Path(__file__).resolve().parents[1] / "scripts" / "backup_pg_to_s3.sh"
    assert script.is_file()
    proc = subprocess.run(["bash", "-n", str(script)], capture_output=True, text=True)
    assert proc.returncode == 0, proc.stderr
