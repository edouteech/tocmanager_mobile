import uuid
from fastapi.testclient import TestClient

from app.core.rate_limit import reset_rate_limits
from app.main import app


def _provision_boutique(tc: TestClient, tag: str):
    email = f"owner_{tag}_{uuid.uuid4().hex[:5]}@example.com".lower()
    r1 = tc.post(
        "/api/v1/saas/auth/register-credentials",
        json={
            "full_name": f"Owner {tag}",
            "username_or_email": email,
            "password": "Password123!",
            "phone": "+221770000000",
        },
    )
    assert r1.status_code == 200, r1.text
    token1 = r1.json()["access_token"]

    r2 = tc.post(
        "/api/v1/saas/tenant/provision",
        json={
            "boutique_name": f"Boutique {tag}",
            "company_name": f"Corp {tag}",
            "currency": "XOF",
            "country": "Sénégal",
            "magasin_name": f"Magasin {tag}",
            "plan_code": "pro",
        },
        headers={"Authorization": f"Bearer {token1}"},
    )
    assert r2.status_code == 200, r2.text
    prov = r2.json()
    return prov["access_token"], prov["boutique_id"], prov["magasin_id"]


def _login(tc: TestClient, username: str, password: str) -> dict:
    reset_rate_limits()
    resp = tc.post(
        "/api/v1/auth/login",
        json={"username_or_email": username, "password": password},
    )
    assert resp.status_code == 200, resp.text
    return resp.json()


def test_superadmin_vs_store_admin_strict_separation():
    with TestClient(app) as tc:
        owner_tok, _, _ = _provision_boutique(tc, "sep")
        owner_h = {"Authorization": f"Bearer {owner_tok}"}

        suffix = uuid.uuid4().hex[:5]
        s_admin_uname = f"sadmin_{suffix}"
        mgr_uname = f"mgr_{suffix}"

        r_sa = tc.post(
            "/api/v1/users",
            headers=owner_h,
            json={
                "username": s_admin_uname,
                "password": "Password123!",
                "full_name": "Store Admin",
                "role": "store_admin",
                "pin": "1234",
            },
        )
        assert r_sa.status_code == 200, r_sa.text
        assert r_sa.json()["role"] == "store_admin"

        r_mgr = tc.post(
            "/api/v1/users",
            headers=owner_h,
            json={
                "username": mgr_uname,
                "password": "Password123!",
                "full_name": "Manager User",
                "role": "manager",
                "pin": "2345",
            },
        )
        assert r_mgr.status_code == 200, r_mgr.text

        sa_tok = _login(tc, s_admin_uname, "Password123!")["access_token"]
        mgr_tok = _login(tc, mgr_uname, "Password123!")["access_token"]
        super_tok = _login(tc, "admin", "admin1234")["access_token"]

        for tok in (owner_tok, sa_tok, mgr_tok):
            hdr = {"Authorization": f"Bearer {tok}"}
            assert tc.get("/api/v1/admin/kpis", headers=hdr).status_code == 403
            assert tc.get("/api/v1/admin/plans", headers=hdr).status_code == 403
            assert tc.get("/api/v1/admin/boutiques", headers=hdr).status_code == 403

        super_h = {"Authorization": f"Bearer {super_tok}"}
        assert tc.get("/api/v1/admin/kpis", headers=super_h).status_code == 200
        assert tc.get("/api/v1/users", headers=super_h).status_code == 403
        assert tc.get("/api/v1/products", headers=super_h).status_code == 403
        assert tc.get("/api/v1/audit/logs", headers=super_h).status_code == 403


def test_users_isolated_per_boutique_no_escalation_and_revocation():
    with TestClient(app) as tc:
        tok_a, _, _ = _provision_boutique(tc, "iso_a")
        tok_b, _, mag_b = _provision_boutique(tc, "iso_b")
        h_a = {"Authorization": f"Bearer {tok_a}"}
        h_b = {"Authorization": f"Bearer {tok_b}"}

        tag = uuid.uuid4().hex[:5]
        s_a1 = f"sa1_{tag}"
        c_a2 = f"ca2_{tag}"
        c_b1 = f"cb1_{tag}"

        res_sa1 = tc.post(
            "/api/v1/users",
            headers=h_a,
            json={"username": s_a1, "password": "Password123!", "role": "store_admin", "pin": "1111"},
        )
        assert res_sa1.status_code == 200
        sa1_id = res_sa1.json()["id"]

        res_ca2 = tc.post(
            "/api/v1/users",
            headers=h_a,
            json={"username": c_a2, "password": "Password123!", "role": "cashier", "pin": "2222"},
        )
        assert res_ca2.status_code == 200
        ca2_id = res_ca2.json()["id"]

        res_cb1 = tc.post(
            "/api/v1/users",
            headers=h_b,
            json={"username": c_b1, "password": "Password123!", "role": "cashier", "pin": "3333"},
        )
        assert res_cb1.status_code == 200
        cb1_id = res_cb1.json()["id"]

        users_a = tc.get("/api/v1/users", headers=h_a).json()
        usernames_a = {u["username"] for u in users_a}
        assert s_a1 in usernames_a and c_a2 in usernames_a
        assert c_b1 not in usernames_a
        assert "admin" not in usernames_a

        assert tc.put(f"/api/v1/users/{cb1_id}", headers=h_a, json={"full_name": "Hack"}).status_code == 404
        assert tc.delete(f"/api/v1/users/{cb1_id}", headers=h_a).status_code == 404

        for forbidden_role in ("superadmin", "admin", "owner"):
            bad = tc.post(
                "/api/v1/users",
                headers=h_a,
                json={"username": f"bad_{forbidden_role}_{tag}", "password": "Password123!", "role": forbidden_role},
            )
            assert bad.status_code == 422

        assert tc.post(
            "/api/v1/users",
            headers=h_a,
            json={"username": f"badpin_{tag}", "password": "Password123!", "role": "cashier", "pin": "12"},
        ).status_code == 422

        assert tc.post(
            "/api/v1/users",
            headers=h_a,
            json={"username": f"badmag_{tag}", "password": "Password123!", "role": "cashier", "assigned_magasin_ids": [mag_b]},
        ).status_code == 400

        owner_row = next(u for u in users_a if u["role"] == "owner")
        sa1_tok = _login(tc, s_a1, "Password123!")["access_token"]
        sa1_h = {"Authorization": f"Bearer {sa1_tok}"}
        assert tc.put(f"/api/v1/users/{owner_row['id']}", headers=sa1_h, json={"full_name": "Hack"}).status_code == 403
        assert tc.delete(f"/api/v1/users/{owner_row['id']}", headers=sa1_h).status_code == 403
        assert tc.put(f"/api/v1/users/{sa1_id}", headers=sa1_h, json={"is_active": False}).status_code == 400
        assert tc.delete(f"/api/v1/users/{sa1_id}", headers=sa1_h).status_code == 400

        ca2_login = _login(tc, c_a2, "Password123!")
        ca2_refresh = ca2_login["refresh_token"]
        assert tc.put(f"/api/v1/users/{ca2_id}", headers=h_a, json={"is_active": False}).status_code == 200
        assert tc.post("/api/v1/auth/refresh", json={"refresh_token": ca2_refresh}).status_code == 401
        assert tc.delete(f"/api/v1/users/{ca2_id}", headers=h_a).status_code == 200

        logs = tc.get("/api/v1/audit/logs", headers=h_a).json()["items"]
        actions = {item["action"] for item in logs}
        assert {"USER_CREATE", "USER_UPDATE", "USER_DELETE"}.issubset(actions)


def test_tenant_role_matrix_cashier_and_manager():
    with TestClient(app) as tc:
        owner_tok, _, _ = _provision_boutique(tc, "matrix")
        owner_h = {"Authorization": f"Bearer {owner_tok}"}
        tag = uuid.uuid4().hex[:5]
        c_name = f"cashier_{tag}"
        m_name = f"manager_{tag}"

        assert tc.post(
            "/api/v1/users",
            headers=owner_h,
            json={"username": c_name, "password": "Password123!", "role": "cashier", "pin": "1234"},
        ).status_code == 200
        assert tc.post(
            "/api/v1/users",
            headers=owner_h,
            json={"username": m_name, "password": "Password123!", "role": "manager", "pin": "2345"},
        ).status_code == 200

        c_h = {"Authorization": f"Bearer {_login(tc, c_name, 'Password123!')['access_token']}"}
        m_h = {"Authorization": f"Bearer {_login(tc, m_name, 'Password123!')['access_token']}"}

        assert tc.post("/api/v1/products", headers=c_h, json={"name": "Item", "price": 100}).status_code == 403
        assert tc.put("/api/v1/settings", headers=c_h, json={"store_name": "Hack", "currency": "XOF"}).status_code == 403
        assert tc.get("/api/v1/audit/logs", headers=c_h).status_code == 403
        assert tc.get("/api/v1/reports/dashboard", headers=c_h).status_code == 403
        assert tc.post(
            "/api/v1/users",
            headers=c_h,
            json={"username": f"c2_{tag}", "password": "Password123!", "role": "cashier"},
        ).status_code == 403

        assert tc.get("/api/v1/reports/dashboard", headers=m_h).status_code == 200
        assert tc.get("/api/v1/users", headers=m_h).status_code == 200
        assert tc.post(
            "/api/v1/users",
            headers=m_h,
            json={"username": f"m2_{tag}", "password": "Password123!", "role": "cashier"},
        ).status_code == 403
        assert tc.put("/api/v1/settings", headers=m_h, json={"store_name": "Hack", "currency": "XOF"}).status_code == 403
        assert tc.get("/api/v1/audit/logs", headers=m_h).status_code == 403
