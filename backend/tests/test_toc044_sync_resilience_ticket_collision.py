from datetime import datetime, timezone
import uuid
from fastapi.testclient import TestClient

from app.core.database import SessionLocal
from app.core.rate_limit import reset_rate_limits
from app.main import app
from app.models import Product, Vente


def _provision_boutique(tc: TestClient, plan_code: str, tag: str):
    reset_rate_limits()
    uid = uuid.uuid4().hex[:6]
    ident = f"toc044_{tag}_{uid}@example.com".lower()
    reg = tc.post(
        "/api/v1/saas/auth/register-credentials",
        json={"full_name": f"User {tag}", "username_or_email": ident, "password": "Password123!"},
    )
    assert reg.status_code == 200, reg.text
    prov = tc.post(
        "/api/v1/saas/tenant/provision",
        headers={"Authorization": f"Bearer {reg.json()['access_token']}"},
        json={"boutique_name": f"Btq {tag} {uid}", "magasin_name": "Mag 1", "plan_code": plan_code},
    )
    assert prov.status_code == 200, prov.text
    data = prov.json()
    return {
        "boutique_id": data["boutique_id"],
        "magasin_id": data["magasin_id"],
        "headers": {
            "Authorization": f"Bearer {data['access_token']}",
            "X-Boutique-Id": data["boutique_id"],
            "X-Magasin-Id": data["magasin_id"],
        },
    }


def test_over_quota_product_is_isolated_when_batch_contains_valid_vente():
    with TestClient(app) as tc:
        btq = _provision_boutique(tc, "free", "quota")
        with SessionLocal() as db:
            for idx in range(100):
                db.add(Product(boutique_id=btq["boutique_id"], name=f"P{idx}", price=100))
            db.commit()

        over_prod_id = str(uuid.uuid4())
        valid_vente_id = str(uuid.uuid4())
        now = datetime.now(timezone.utc).isoformat()

        res = tc.post(
            "/api/v1/sync/push",
            headers=btq["headers"],
            json={
                "products": [
                    {
                        "sync_id": over_prod_id,
                        "name": "OverQuota 101",
                        "price": 500,
                        "cost_price": 200,
                        "stock": 5,
                        "min_stock": 1,
                        "updated_at": now,
                    }
                ],
                "ventes": [
                    {
                        "sync_id": valid_vente_id,
                        "magasin_id": btq["magasin_id"],
                        "ticket_number": f"T-{uuid.uuid4().hex[:6]}",
                        "total_amount": 1000,
                        "paid_amount": 1000,
                        "payment_method": "Espèces",
                        "created_at": now,
                        "updated_at": now,
                        "items": [
                            {"product_name": "P0", "quantity": 1, "unit_price": 1000, "cost_price": 0, "total": 1000}
                        ],
                    }
                ],
            },
        )
        assert res.status_code == 200, res.text
        body = res.json()
        assert body["synced_count"] == 1
        assert body["synced_uuids"] == [valid_vente_id]
        assert body["rejected_count"] == 1
        assert any(over_prod_id in err for err in body["errors"])

        with SessionLocal() as db:
            assert db.query(Vente).filter(Vente.sync_id == valid_vente_id).first() is not None
            assert db.query(Product).filter(Product.sync_id == over_prod_id).first() is None

        # Only quota failure (nothing synced) still returns 403 PLAN_QUOTA_EXCEEDED
        only_quota = tc.post(
            "/api/v1/sync/push",
            headers=btq["headers"],
            json={
                "products": [
                    {
                        "sync_id": str(uuid.uuid4()),
                        "name": "OverQuota Alone",
                        "price": 500,
                        "cost_price": 200,
                        "stock": 1,
                        "min_stock": 1,
                        "updated_at": now,
                    }
                ]
            },
        )
        assert only_quota.status_code == 403
        assert only_quota.json()["detail"]["error"] == "PLAN_QUOTA_EXCEEDED"


def test_duplicate_ticket_number_is_disambiguated_on_sync_push():
    with TestClient(app) as tc:
        btq = _provision_boutique(tc, "pro", "ticket")
        now = datetime.now(timezone.utc).isoformat()
        v1_id = "11111111-1111-4111-8111-111111111111"
        v2_id = "deadbeef-2222-4222-8222-222222222222"
        shared_ticket = "VNT-20261125-0001"

        res = tc.post(
            "/api/v1/sync/push",
            headers=btq["headers"],
            json={
                "ventes": [
                    {
                        "sync_id": v1_id,
                        "magasin_id": btq["magasin_id"],
                        "ticket_number": shared_ticket,
                        "total_amount": 500,
                        "paid_amount": 500,
                        "payment_method": "Espèces",
                        "created_at": now,
                        "updated_at": now,
                        "items": [{"product_name": "A", "quantity": 1, "unit_price": 500, "cost_price": 0, "total": 500}],
                    },
                    {
                        "sync_id": v2_id,
                        "magasin_id": btq["magasin_id"],
                        "ticket_number": shared_ticket,
                        "total_amount": 800,
                        "paid_amount": 800,
                        "payment_method": "Espèces",
                        "created_at": now,
                        "updated_at": now,
                        "items": [{"product_name": "B", "quantity": 1, "unit_price": 800, "cost_price": 0, "total": 800}],
                    },
                ]
            },
        )
        assert res.status_code == 200, res.text
        body = res.json()
        assert body["rejected_count"] == 0
        assert set(body["synced_uuids"]) == {v1_id, v2_id}

        with SessionLocal() as db:
            row1 = db.query(Vente).filter(Vente.sync_id == v1_id).first()
            row2 = db.query(Vente).filter(Vente.sync_id == v2_id).first()
            assert row1.ticket_number == shared_ticket
            assert row2.ticket_number != shared_ticket
            assert row2.ticket_number.startswith(f"{shared_ticket}-")
