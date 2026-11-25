from datetime import datetime, timedelta, timezone
from pathlib import Path
import subprocess
import sys
import uuid

from sqlalchemy import create_engine, event, inspect

from app.models import (
    Approvisionnement,
    Category,
    Client,
    Decaissement,
    Product,
    Supplier,
    Vente,
    VenteItem,
)


def _seed_boutique_dataset(db, boutique_id: str, magasin_id: str, user_id: str):
    now = datetime.now(timezone.utc)
    cat = Category(sync_id=str(uuid.uuid4()), boutique_id=boutique_id, name="Boissons", color="#29ABE2")
    db.add(cat)
    db.flush()

    prods = []
    for i in range(5):
        p = Product(
            sync_id=str(uuid.uuid4()),
            boutique_id=boutique_id,
            category_sync_id=cat.sync_id,
            name=f"Produit {i}",
            price=1000.0 + i * 100,
            cost_price=500.0,
            stock=20.0,
        )
        db.add(p)
        prods.append(p)

    clients = []
    for i in range(4):
        c = Client(sync_id=str(uuid.uuid4()), boutique_id=boutique_id, name=f"Client {i}")
        db.add(c)
        clients.append(c)

    suppliers = []
    for i in range(3):
        s = Supplier(sync_id=str(uuid.uuid4()), boutique_id=boutique_id, name=f"Fournisseur {i}")
        db.add(s)
        suppliers.append(s)

    db.flush()

    for i in range(6):
        v = Vente(
            sync_id=str(uuid.uuid4()),
            boutique_id=boutique_id,
            magasin_id=magasin_id,
            ticket_number=f"VNT-PAG-{i:04d}",
            client_sync_id=clients[i % len(clients)].sync_id,
            client_name=clients[i % len(clients)].name,
            user_id=user_id,
            user_name="Owner",
            total_amount=2000.0,
            paid_amount=2000.0,
            created_at=now - timedelta(minutes=i),
        )
        db.add(v)
        db.flush()
        for j in range(2):
            prod = prods[(i + j) % len(prods)]
            db.add(
                VenteItem(
                    sync_id=str(uuid.uuid4()),
                    vente_sync_id=v.sync_id,
                    product_sync_id=prod.sync_id,
                    product_name=prod.name,
                    quantity=1.0,
                    unit_price=prod.price,
                    cost_price=prod.cost_price,
                    total=prod.price,
                )
            )

    for i in range(3):
        db.add(
            Decaissement(
                sync_id=str(uuid.uuid4()),
                boutique_id=boutique_id,
                magasin_id=magasin_id,
                title=f"Depense {i}",
                amount=500.0 * (i + 1),
                date=now - timedelta(minutes=i),
            )
        )
        db.add(
            Approvisionnement(
                sync_id=str(uuid.uuid4()),
                boutique_id=boutique_id,
                magasin_id=magasin_id,
                supplier_sync_id=suppliers[i % len(suppliers)].sync_id,
                supplier_name=suppliers[i % len(suppliers)].name,
                product_sync_id=prods[i % len(prods)].sync_id,
                product_name=prods[i % len(prods)].name,
                quantity=5.0,
                unit_cost=500.0,
                total_cost=2500.0,
                date=now - timedelta(minutes=i),
            )
        )
    db.commit()


def test_sync_pull_uses_eager_loading_without_n_plus_1(multi_tenant_env, isolated_db_session):
    db, test_engine, _ = isolated_db_session
    client = multi_tenant_env["client"]
    btq = multi_tenant_env["boutique_a"]
    mag = multi_tenant_env["magasin_a1"]
    merchant = multi_tenant_env["merchant"]
    headers = multi_tenant_env["make_headers"](merchant, btq, mag)

    prod = Product(
        sync_id=str(uuid.uuid4()),
        boutique_id=btq.id,
        name="Eau 1L",
        price=500.0,
        cost_price=300.0,
        stock=100.0,
    )
    db.add(prod)
    db.flush()

    now = datetime.now(timezone.utc)
    for i in range(25):
        v = Vente(
            sync_id=str(uuid.uuid4()),
            boutique_id=btq.id,
            magasin_id=mag.id,
            ticket_number=f"VNT-EAGER-{i:04d}",
            client_name="Occasionnel",
            user_id=merchant.id,
            user_name="Merchant",
            total_amount=1000.0,
            paid_amount=1000.0,
            created_at=now - timedelta(minutes=i),
        )
        db.add(v)
        db.flush()
        for _ in range(2):
            db.add(
                VenteItem(
                    sync_id=str(uuid.uuid4()),
                    vente_sync_id=v.sync_id,
                    product_sync_id=prod.sync_id,
                    product_name=prod.name,
                    quantity=1.0,
                    unit_price=500.0,
                    cost_price=300.0,
                    total=500.0,
                )
            )
    db.commit()

    executed_sql = []

    def _count_queries(conn, cursor, statement, parameters, context, executemany):
        executed_sql.append(statement)

    event.listen(test_engine, "before_cursor_execute", _count_queries)
    try:
        res = client.get("/api/v1/sync/pull", headers=headers)
    finally:
        event.remove(test_engine, "before_cursor_execute", _count_queries)

    assert res.status_code == 200, res.text
    body = res.json()
    assert len(body["ventes"]) == 25
    assert all(len(v["items"]) == 2 for v in body["ventes"])
    item_queries = [sql for sql in executed_sql if "vente_items" in sql.lower()]
    assert len(item_queries) == 1, f"Expected single selectinload query, got {len(item_queries)}"
    assert len(executed_sql) <= 22, f"Too many SQL queries ({len(executed_sql)}), possible N+1"


def test_sync_pull_cursor_pagination_master_then_ops_and_backwards_compat(multi_tenant_env):
    db = multi_tenant_env["db"]
    client = multi_tenant_env["client"]
    btq = multi_tenant_env["boutique_a"]
    mag = multi_tenant_env["magasin_a1"]
    merchant = multi_tenant_env["merchant"]
    headers = multi_tenant_env["make_headers"](merchant, btq, mag)

    _seed_boutique_dataset(db, btq.id, mag.id, merchant.id)

    full_res = client.get("/api/v1/sync/pull", headers=headers)
    assert full_res.status_code == 200, full_res.text
    full = full_res.json()
    assert full["has_more"] is False
    assert full["next_cursor"] is None

    collected = {
        k: []
        for k in ("categories", "products", "clients", "suppliers", "ventes", "decaissements", "approvisionnements")
    }
    cursors_seen = []
    cursor = None
    for _ in range(10):
        params = {"limit": 2}
        if cursor:
            params["cursor"] = cursor
        page_res = client.get("/api/v1/sync/pull", headers=headers, params=params)
        assert page_res.status_code == 200, page_res.text
        page = page_res.json()
        for k in collected:
            collected[k].extend(page[k])
        if not page["has_more"]:
            assert page["next_cursor"] is None
            break
        cursor = page["next_cursor"]
        assert cursor
        cursors_seen.append(cursor)
    else:
        raise AssertionError("Pagination loop exceeded 10 iterations")

    assert "master:2" in cursors_seen
    assert any(c.startswith("ops:") for c in cursors_seen)

    for k in collected:
        got_ids = [row["sync_id"] for row in collected[k]]
        expected_ids = [row["sync_id"] for row in full[k]]
        assert len(got_ids) == len(set(got_ids)), f"Duplicate sync_ids in {k}"
        assert set(got_ids) == set(expected_ids), f"Mismatch in {k}"

    for bad_cursor in ("invalid", "master:0", "ops:-1", "unknown:1", "ops:abc"):
        bad_res = client.get(
            "/api/v1/sync/pull", headers=headers, params={"limit": 2, "cursor": bad_cursor}
        )
        assert bad_res.status_code == 400


def test_vente_items_vente_sync_id_index_and_migration_0004(tmp_path):
    col_indexed = any(
        list(idx.columns.keys()) == ["vente_sync_id"] for idx in VenteItem.__table__.indexes
    )
    assert col_indexed

    backend_dir = Path(__file__).resolve().parents[1]
    db_file = tmp_path / "alembic_0004.db"
    alembic_bin = Path(sys.executable).parent / "alembic"
    env = {"PATH": str(Path(sys.executable).parent), "DATABASE_URL": f"sqlite:///{db_file}"}

    up1 = subprocess.run(
        [str(alembic_bin), "upgrade", "head"], cwd=str(backend_dir), env=env, capture_output=True, text=True
    )
    assert up1.returncode == 0, up1.stderr + up1.stdout

    eng = create_engine(f"sqlite:///{db_file}", connect_args={"check_same_thread": False})
    idx_cols = [idx["column_names"] for idx in inspect(eng).get_indexes("vente_items")]
    assert ["vente_sync_id"] in idx_cols

    down = subprocess.run(
        [str(alembic_bin), "downgrade", "0003_auth_tokens_and_2fa"],
        cwd=str(backend_dir),
        env=env,
        capture_output=True,
        text=True,
    )
    assert down.returncode == 0, down.stderr + down.stdout

    idx_after_down = [idx["name"] for idx in inspect(eng).get_indexes("vente_items")]
    assert "ix_vente_items_vente_sync_id" not in idx_after_down

    up2 = subprocess.run(
        [str(alembic_bin), "upgrade", "head"], cwd=str(backend_dir), env=env, capture_output=True, text=True
    )
    assert up2.returncode == 0, up2.stderr + up2.stdout

    idx_after_up = [idx["name"] for idx in inspect(eng).get_indexes("vente_items")]
    assert "ix_vente_items_vente_sync_id" in idx_after_up
