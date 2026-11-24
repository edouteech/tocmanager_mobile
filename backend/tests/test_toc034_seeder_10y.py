from pathlib import Path
import subprocess
import sys

import pytest
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

from app.core.security import verify_password, verify_pin
from app.models import (
    Approvisionnement,
    AuditLog,
    Boutique,
    CashRegisterSession,
    Client,
    ClientPayment,
    Decaissement,
    Magasin,
    PlatformAuditLog,
    Product,
    SaasInvoice,
    SaasPaymentTransaction,
    SaasSubscription,
    StockMovement,
    StockTransfer,
    StockTransferItem,
    StoreSetting,
    Supplier,
    SupplierPayment,
    User,
    Vente,
    VenteItem,
)
from scripts.seed_10y_demo import seed_10y_dataset
from scripts.seeder_10y.catalog_data import DEMO_DEFAULT_PASSWORD, SCALE_PRESETS


def _prepare_fresh_db(db_path: Path) -> str:
    backend_dir = Path(__file__).resolve().parents[1]
    alembic_bin = Path(sys.executable).parent / "alembic"
    db_url = f"sqlite:///{db_path}"
    proc = subprocess.run(
        [str(alembic_bin), "upgrade", "head"],
        cwd=str(backend_dir),
        env={"PATH": str(Path(sys.executable).parent), "DATABASE_URL": db_url},
        capture_output=True,
        text=True,
    )
    assert proc.returncode == 0, proc.stderr + proc.stdout
    return db_url


def test_seeder_10y_small_populates_full_multitenant_10y_dataset(tmp_path):
    db_url = _prepare_fresh_db(tmp_path / "seed_10y_small.db")
    summary = seed_10y_dataset(db_url, scale="small", years=10, seed=42)

    assert summary.boutiques == 6
    assert summary.users >= 20
    assert summary.counts["ventes"] >= 2500

    eng = create_engine(db_url, connect_args={"check_same_thread": False})
    Session = sessionmaker(bind=eng)
    db = Session()
    try:
        boutiques = db.query(Boutique).filter(Boutique.slug.like("demo10y-%")).all()
        assert len(boutiques) == 6
        assert any(not b.is_active for b in boutiques)

        magasins = db.query(Magasin).all()
        assert len(magasins) >= 10
        assert any(m.is_warehouse for m in magasins)

        users = db.query(User).filter(User.username.like("demo10y_%")).all()
        assert len(users) >= 20
        roles = {u.role for u in users}
        assert {"superadmin", "merchant", "store_admin", "manager", "cashier"}.issubset(roles)
        assert any(not u.is_active for u in users)
        assert verify_password(DEMO_DEFAULT_PASSWORD, users[0].hashed_password)
        assert verify_pin("1234", users[0].pin_hash)

        ventes_count = db.query(Vente).count()
        assert ventes_count >= 2500
        assert db.query(VenteItem).count() > ventes_count

        min_dt, max_dt = db.execute(text("SELECT MIN(created_at), MAX(created_at) FROM ventes")).one()
        assert min_dt is not None and max_dt is not None
        span_days = (
            db.query(Vente).order_by(Vente.created_at.desc()).first().created_at
            - db.query(Vente).order_by(Vente.created_at.asc()).first().created_at
        ).days
        assert span_days >= 3200

        statuses = {row[0] for row in db.execute(text("SELECT DISTINCT status FROM ventes")).fetchall()}
        assert {"completed", "partial_refund", "refunded", "canceled"}.issubset(statuses)

        assert db.query(Approvisionnement).count() > 0
        assert db.query(Decaissement).count() > 0
        assert db.query(CashRegisterSession).filter_by(status="closed").count() > 0
        assert db.query(CashRegisterSession).filter_by(status="open").count() >= 5
        assert db.query(ClientPayment).count() > 0
        assert db.query(SupplierPayment).count() > 0
        assert db.query(StockTransfer).count() > 0
        assert db.query(StockTransferItem).count() > 0
        assert db.query(StockMovement).count() > 0
        assert db.query(SaasSubscription).count() == 6
        assert db.query(SaasPaymentTransaction).count() > 0
        assert db.query(SaasInvoice).count() > 0
        assert db.query(StoreSetting).count() >= 6
        assert db.query(AuditLog).count() > 0
        assert db.query(PlatformAuditLog).count() == 6
    finally:
        db.close()


def test_seeder_10y_clean_demo_preserves_real_production_tenants_and_is_idempotent(tmp_path):
    db_url = _prepare_fresh_db(tmp_path / "seed_10y_clean.db")
    eng = create_engine(db_url, connect_args={"check_same_thread": False})
    Session = sessionmaker(bind=eng)

    # Create pre-existing non-demo production tenant & records
    db = Session()
    try:
        real_user = User(username="real_owner", email="real@client.sn", hashed_password="h", role="merchant")
        db.add(real_user)
        db.flush()
        real_btq = Boutique(slug="real-client-shop", name="Vraie Boutique Client", owner_user_id=real_user.id)
        db.add(real_btq)
        db.flush()
        db.add(Product(boutique_id=real_btq.id, sync_id="real-prod-1", name="Article Réel", price=1000.0, stock=5.0))
        db.commit()
    finally:
        db.close()

    first = seed_10y_dataset(db_url, scale="small", years=2, seed=7, clean_demo=True)
    with pytest.raises(RuntimeError, match="--clean-demo"):
        seed_10y_dataset(db_url, scale="small", years=2, seed=7, clean_demo=False)

    second = seed_10y_dataset(db_url, scale="small", years=2, seed=7, clean_demo=True)
    assert second.counts["ventes"] == first.counts["ventes"]
    assert second.counts["boutiques"] == 6

    db = Session()
    try:
        assert db.query(User).filter_by(username="real_owner").count() == 1
        assert db.query(Boutique).filter_by(slug="real-client-shop").count() == 1
        assert db.query(Product).filter_by(sync_id="real-prod-1").count() == 1
        assert db.query(Boutique).filter(Boutique.slug.like("demo10y-%")).count() == 6
    finally:
        db.close()


def test_seeder_10y_blocks_production_without_explicit_flag(tmp_path):
    db_url = _prepare_fresh_db(tmp_path / "seed_10y_prod_guard.db")
    with pytest.raises(RuntimeError, match="allow_production"):
        seed_10y_dataset(db_url, scale="small", years=1, environment="production", allow_production=False)

    eng = create_engine(db_url, connect_args={"check_same_thread": False})
    with eng.connect() as conn:
        assert conn.execute(text("SELECT COUNT(*) FROM boutiques")).scalar() == 0


def test_seeder_10y_stress_preset_targets_over_100k_sales():
    assert SCALE_PRESETS["stress"]["total_sales_target"] >= 100_000
