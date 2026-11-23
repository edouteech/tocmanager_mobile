import uuid
from datetime import datetime, timezone
from fastapi.testclient import TestClient

from app.core.database import SessionLocal
from app.main import app
from app.models import AuditLog, Vente, VenteItem


def _provision_merchant(tc: TestClient):
    uid = uuid.uuid4().hex[:6]
    ident = f"rep_{uid}@example.com"
    assert tc.post(
        "/api/v1/saas/auth/register-credentials",
        json={"full_name": f"Owner {uid}", "username_or_email": ident, "password": "Password123!"},
    ).status_code == 200
    reg = tc.post("/api/v1/auth/login", json={"username_or_email": ident, "password": "Password123!"}).json()
    tok = reg["access_token"]
    onb_res = tc.post(
        "/api/v1/saas/tenant/provision",
        headers={"Authorization": f"Bearer {tok}"},
        json={"boutique_name": f"RepShop {uid}", "magasin_name": "Mag 1", "plan_code": "pro"},
    )
    assert onb_res.status_code == 200
    data = onb_res.json()
    return {
        "boutique_id": data["boutique_id"],
        "mag_id": data["magasin_id"],
        "headers": {
            "Authorization": f"Bearer {tok}",
            "X-Boutique-Id": data["boutique_id"],
            "X-Magasin-Id": data["magasin_id"],
        },
    }


def test_toc013_gross_sales_pricing_integrity_and_audit():
    with TestClient(app) as tc:
        m = _provision_merchant(tc)
        h = m["headers"]

        prod = tc.post(
            "/api/v1/products",
            headers=h,
            json={"name": "Café", "price": 500.0, "cost_price": 300.0, "stock": 50.0},
        ).json()
        prod_id = prod["sync_id"]

        # Create cashier in Mag 1
        c_name = f"cashier_{uuid.uuid4().hex[:4]}"
        assert tc.post(
            "/api/v1/users",
            headers=h,
            json={"username": c_name, "password": "Password123!", "role": "cashier", "pin": "1234", "assigned_magasin_ids": [m["mag_id"]]},
        ).status_code == 200
        c_tok = tc.post("/api/v1/auth/login", json={"username_or_email": c_name, "password": "Password123!"}).json()["access_token"]
        c_h = {"Authorization": f"Bearer {c_tok}", "X-Boutique-Id": m["boutique_id"], "X-Magasin-Id": m["mag_id"]}

        # Case 2: Negative discount -> 422
        assert tc.post(
            "/api/v1/ventes",
            headers=h,
            json={"items": [{"product_sync_id": prod_id, "quantity": 1.0}], "discount_amount": -500.0, "paid_amount": 500.0},
        ).status_code == 422

        # Discount exceeding subtotal -> 400
        assert tc.post(
            "/api/v1/ventes",
            headers=h,
            json={"items": [{"product_sync_id": prod_id, "quantity": 1.0}], "discount_amount": 1000.0, "paid_amount": 0.0},
        ).status_code == 400

        # Case 3: Cashier overriding price 500 -> 10 => 403
        bad_price = tc.post(
            "/api/v1/ventes",
            headers=c_h,
            json={"items": [{"product_sync_id": prod_id, "quantity": 1.0, "unit_price": 10.0}], "paid_amount": 10.0},
        )
        assert bad_price.status_code == 403

        # Owner overriding price succeeds and logs PRICE_OVERRIDE, while client-supplied cost_price=0 is ignored
        ov_sale = tc.post(
            "/api/v1/ventes",
            headers=h,
            json={"items": [{"product_sync_id": prod_id, "quantity": 1.0, "unit_price": 450.0, "cost_price": 0.0}], "paid_amount": 450.0},
        )
        assert ov_sale.status_code == 201
        assert ov_sale.json()["items"][0]["cost_price"] == 300.0
        assert ov_sale.json()["user_id"] is not None and ov_sale.json()["user_name"] is not None

        with SessionLocal() as db:
            ov_log = db.query(AuditLog).filter(
                AuditLog.boutique_id == m["boutique_id"],
                AuditLog.action == "PRICE_OVERRIDE",
                AuditLog.entity_id == ov_sale.json()["sync_id"],
            ).first()
            assert ov_log is not None

        # Case 1: Sale 2000 (4x500) with discount 200 -> net=1800, discount=200, gross=2000 on clean boutique
        m2 = _provision_merchant(tc)
        h2 = m2["headers"]
        p2 = tc.post(
            "/api/v1/products",
            headers=h2,
            json={"name": "Thé", "price": 500.0, "cost_price": 250.0, "stock": 20.0},
        ).json()
        s2 = tc.post(
            "/api/v1/ventes",
            headers=h2,
            json={"items": [{"product_sync_id": p2["sync_id"], "quantity": 4.0}], "discount_amount": 200.0, "paid_amount": 1800.0},
        )
        assert s2.status_code == 201
        rep = tc.get("/api/v1/reports/financial?preset=thisMonth", headers=h2)
        assert rep.status_code == 200
        kpis = rep.json()["kpis"]
        assert kpis["gross_sales"] == 2000.0
        assert kpis["discount_amount"] == 200.0
        assert kpis["net_sales"] == 1800.0
        assert kpis["cogs"] == 1000.0
        assert kpis["gross_margin"] == 800.0


def test_toc013_financial_report_1200_sales_exceeding_sqlite_param_limit():
    with TestClient(app) as tc:
        m = _provision_merchant(tc)
        h = m["headers"]
        now = datetime.now(timezone.utc)

        with SessionLocal() as db:
            for i in range(1200):
                vid = str(uuid.uuid4())
                db.add(Vente(
                    sync_id=vid,
                    boutique_id=m["boutique_id"],
                    magasin_id=m["mag_id"],
                    ticket_number=f"BULK-{i:04d}",
                    total_amount=100.0,
                    paid_amount=100.0,
                    discount_amount=10.0,
                    payment_method="Espèces",
                    status="completed",
                    created_at=now,
                    updated_at=now,
                ))
                db.add(VenteItem(
                    sync_id=str(uuid.uuid4()),
                    vente_sync_id=vid,
                    product_name="Article Masse",
                    quantity=1.0,
                    unit_price=110.0,
                    cost_price=60.0,
                    total=110.0,
                ))
            db.commit()

        rep = tc.get("/api/v1/reports/financial?preset=all", headers=h)
        assert rep.status_code == 200
        body = rep.json()
        assert body["kpis"]["net_sales"] == 120000.0
        assert body["kpis"]["discount_amount"] == 12000.0
        assert body["kpis"]["gross_sales"] == 132000.0
        assert body["kpis"]["cogs"] == 72000.0
        periods = [pt["period"] for pt in body["monthly_trend"]]
        assert len(periods) == 6
        assert len(set(periods)) == 6
        last_month = body["monthly_trend"][-1]
        assert last_month["profit"] == round(last_month["sales"] - last_month["cogs"] - last_month["expenses"], 2)
