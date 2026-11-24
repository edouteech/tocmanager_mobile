import os
from pathlib import Path
import subprocess
import sys

from sqlalchemy import create_engine, inspect
from sqlalchemy.orm import sessionmaker

from app import models
from app.core.database import Base
from app.models import Boutique, Product, SaasPlan
from app.services import init_db as init_db_mod
from app.services.seed_plans import seed_saas_plans


def test_no_backend_module_exceeds_250_lines():
    app_dir = Path(__file__).resolve().parents[1] / "app"
    oversized = []
    for folder in ("models", "schemas", "services", "api"):
        for py_file in (app_dir / folder).rglob("*.py"):
            line_count = len(py_file.read_text(encoding="utf-8").splitlines())
            if line_count > 250:
                oversized.append((str(py_file.relative_to(app_dir)), line_count))
    assert oversized == [], f"Files > 250 lines: {oversized}"


def test_dead_code_removed():
    backend_dir = Path(__file__).resolve().parents[1]
    assert not (backend_dir / "seed.py").exists()
    req_text = (backend_dir / "requirements.txt").read_text(encoding="utf-8")
    assert "passlib" not in req_text.lower()
    assert not hasattr(Boutique, "schema_name")
    assert not hasattr(models, "SyncEvent")


def test_init_db_and_seed_plans_are_idempotent_on_empty_db(tmp_path, monkeypatch):
    db_file = tmp_path / "clean_init.db"
    eng = create_engine(f"sqlite:///{db_file}", connect_args={"check_same_thread": False})
    Session = sessionmaker(autocommit=False, autoflush=False, bind=eng)

    monkeypatch.setattr(init_db_mod, "engine", eng)
    monkeypatch.setattr(init_db_mod.settings, "ENVIRONMENT", "development")
    monkeypatch.setattr(init_db_mod.settings, "ENABLE_DEMO_SEED", True)

    db = Session()
    try:
        init_db_mod.init_db(db)
        init_db_mod.init_db(db)
        seed_saas_plans(db)

        assert db.query(SaasPlan).count() == 3
        assert db.query(Boutique).count() == 1
        assert db.query(Product).count() == 3
    finally:
        db.close()
        eng.dispose()


def test_pytest_uses_temp_db_and_multi_tenant_fixture_isolation(multi_tenant_env):
    assert "tocmanager_pytest_" in os.environ.get("DATABASE_URL", "")

    client = multi_tenant_env["client"]
    btq_a = multi_tenant_env["boutique_a"]
    btq_b = multi_tenant_env["boutique_b"]
    mag_a1 = multi_tenant_env["magasin_a1"]
    merchant = multi_tenant_env["merchant"]
    cashier = multi_tenant_env["cashier"]
    make_headers = multi_tenant_env["make_headers"]

    created = client.post(
        "/api/v1/products",
        headers=make_headers(merchant, btq_a, mag_a1),
        json={"name": "Produit Alpha Uniq", "price": 1200, "cost_price": 800, "stock": 10},
    )
    assert created.status_code == 200, created.text

    # Boutique B cannot see Boutique A's product
    res_b = client.get("/api/v1/products", headers=make_headers(merchant, btq_b))
    assert res_b.status_code == 200
    assert all(p["name"] != "Produit Alpha Uniq" for p in res_b.json())

    # Cashier assigned to A1 cannot access A2
    mag_a2 = multi_tenant_env["magasin_a2"]
    res_forbidden = client.get("/api/v1/products", headers=make_headers(cashier, btq_a, mag_a2))
    assert res_forbidden.status_code == 403


def test_alembic_head_drops_legacy_sync_events_and_schema_name(tmp_path):
    backend_dir = Path(__file__).resolve().parents[1]
    db_file = tmp_path / "alembic_0002.db"
    alembic_bin = Path(sys.executable).parent / "alembic"
    env = {"PATH": str(Path(sys.executable).parent), "DATABASE_URL": f"sqlite:///{db_file}"}

    proc = subprocess.run([str(alembic_bin), "upgrade", "head"], cwd=str(backend_dir), env=env, capture_output=True, text=True)
    assert proc.returncode == 0, proc.stderr + proc.stdout

    eng = create_engine(f"sqlite:///{db_file}", connect_args={"check_same_thread": False})
    inspector = inspect(eng)
    assert "sync_events" not in inspector.get_table_names()
    boutique_cols = {c["name"] for c in inspector.get_columns("boutiques")}
    assert "schema_name" not in boutique_cols
