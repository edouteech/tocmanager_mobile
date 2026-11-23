import uuid
import pytest
from sqlalchemy import create_engine
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import sessionmaker

from app.core.database import Base
from app.core.rls import TENANT_RLS_TABLES, apply_postgresql_rls, build_rls_ddl
from app.models import (
    Approvisionnement,
    Boutique,
    BoutiqueUserMembership,
    Category,
    Client,
    Decaissement,
    Magasin,
    Product,
    ProductMagasinAvailability,
    SaasPlan,
    SaasPlanFeature,
    SaasSubscription,
    StockMagasin,
    Supplier,
    User,
    Vente,
)
from app.services.seed_demo import seed_demo_data
from app.services.seed_plans import seed_saas_plans
from scripts.backfill_boutique_id import run_backfill


def _isolated_session(tmp_path, name: str = "toc004.db"):
    eng = create_engine(f"sqlite:///{tmp_path / name}", connect_args={"check_same_thread": False})
    Base.metadata.create_all(bind=eng)
    Session = sessionmaker(bind=eng)
    return eng, Session()


def _create_base_tenant(db, suffix: str):
    owner = User(
        username=f"owner_{suffix}",
        email=f"owner_{suffix}@test.local",
        hashed_password="hash",
        role="merchant",
    )
    db.add(owner)
    db.flush()
    btq = Boutique(
        slug=f"btq-{suffix}",
        name=f"Boutique {suffix}",
        owner_user_id=owner.id,
    )
    db.add(btq)
    db.flush()
    mag = Magasin(boutique_id=btq.id, name=f"Magasin {suffix}", code=f"M-{suffix}")
    db.add(mag)
    db.flush()
    prod = Product(boutique_id=btq.id, name=f"Prod {suffix}", price=100.0)
    db.add(prod)
    db.flush()
    return owner, btq, mag, prod


def test_seed_demo_fresh_db_and_idempotent(tmp_path):
    _, db = _isolated_session(tmp_path, "seed.db")
    try:
        seed_saas_plans(db)
        seed_demo_data(db)

        assert db.query(Boutique).count() == 1
        assert db.query(Magasin).count() == 1
        assert db.query(Category).count() == 2
        assert db.query(Product).count() == 3
        assert db.query(StockMagasin).count() == 3
        assert db.query(Client).count() == 2
        assert db.query(Supplier).count() == 1
        sub = db.query(SaasSubscription).first()
        assert sub is not None
        assert sub.trial_ends_at is not None

        btq = db.query(Boutique).first()
        stocks = db.query(StockMagasin).all()
        assert all(s.boutique_id == btq.id for s in stocks)
        assert sorted(s.quantity for s in stocks) == [15.0, 24.0, 48.0]

        seed_demo_data(db)
        assert db.query(Boutique).count() == 1
        assert db.query(Category).count() == 2
        assert db.query(Product).count() == 3
        assert db.query(StockMagasin).count() == 3
        assert db.query(Client).count() == 2
        assert db.query(Supplier).count() == 1
    finally:
        db.close()


def test_boutique_id_not_null_enforced(tmp_path):
    factories = [
        lambda: Category(name="Cat", boutique_id=None),
        lambda: Product(name="Prod", boutique_id=None),
        lambda: Client(name="Cli", boutique_id=None),
        lambda: Supplier(name="Sup", boutique_id=None),
        lambda: Vente(ticket_number="T-1", boutique_id=None),
        lambda: Approvisionnement(product_name="P", boutique_id=None),
        lambda: Decaissement(title="Exp", boutique_id=None),
        lambda: Magasin(name="Mag", boutique_id=None),
        lambda: StockMagasin(magasin_id="m1", product_sync_id="p1", boutique_id=None),
        lambda: ProductMagasinAvailability(magasin_id="m1", product_sync_id="p1", boutique_id=None),
    ]
    _, db = _isolated_session(tmp_path, "notnull.db")
    try:
        for build_row in factories:
            db.add(build_row())
            with pytest.raises(IntegrityError):
                db.flush()
            db.rollback()
    finally:
        db.close()


def test_unique_constraints_enforced(tmp_path):
    _, db = _isolated_session(tmp_path, "unique.db")
    try:
        u1, b1, m1, p1 = _create_base_tenant(db, uuid.uuid4().hex[:6])
        _, b2, _, _ = _create_base_tenant(db, uuid.uuid4().hex[:6])

        db.add(StockMagasin(boutique_id=b1.id, magasin_id=m1.id, product_sync_id=p1.sync_id, quantity=5))
        db.flush()
        db.add(StockMagasin(boutique_id=b1.id, magasin_id=m1.id, product_sync_id=p1.sync_id, quantity=9))
        with pytest.raises(IntegrityError):
            db.flush()
        db.rollback()

        db.add(ProductMagasinAvailability(boutique_id=b1.id, magasin_id=m1.id, product_sync_id=p1.sync_id))
        db.flush()
        db.add(ProductMagasinAvailability(boutique_id=b1.id, magasin_id=m1.id, product_sync_id=p1.sync_id))
        with pytest.raises(IntegrityError):
            db.flush()
        db.rollback()

        db.add(BoutiqueUserMembership(boutique_id=b1.id, user_id=u1.id, role="owner"))
        db.flush()
        db.add(BoutiqueUserMembership(boutique_id=b1.id, user_id=u1.id, role="manager"))
        with pytest.raises(IntegrityError):
            db.flush()
        db.rollback()

        plan = SaasPlan(name="Test", code="test-uniq")
        db.add(plan)
        db.flush()
        db.add(SaasPlanFeature(plan_id=plan.id, feature_code="max_users", feature_name="Users"))
        db.flush()
        db.add(SaasPlanFeature(plan_id=plan.id, feature_code="max_users", feature_name="Users Dup"))
        with pytest.raises(IntegrityError):
            db.flush()
        db.rollback()

        db.add(Vente(boutique_id=b1.id, ticket_number="VNT-UNIQ-1", total_amount=100, paid_amount=100))
        db.add(Vente(boutique_id=b2.id, ticket_number="VNT-UNIQ-1", total_amount=200, paid_amount=200))
        db.commit()

        db.add(Vente(boutique_id=b1.id, ticket_number="VNT-UNIQ-1", total_amount=300, paid_amount=300))
        with pytest.raises(IntegrityError):
            db.flush()
        db.rollback()
    finally:
        db.close()


def test_rls_ddl_and_sqlite_noop(tmp_path):
    eng, db = _isolated_session(tmp_path, "rls.db")
    try:
        ddl = "\n".join(build_rls_ddl())
        for table in TENANT_RLS_TABLES:
            assert f"ALTER TABLE {table} ENABLE ROW LEVEL SECURITY;" in ddl
            assert f"ALTER TABLE {table} FORCE ROW LEVEL SECURITY;" in ddl
            assert f"CREATE POLICY tenant_isolation_{table} ON {table}" in ddl
        assert apply_postgresql_rls(eng) is False
    finally:
        db.close()


def test_backfill_script_idempotent(tmp_path):
    _, db = _isolated_session(tmp_path, "backfill.db")
    try:
        seed_saas_plans(db)
        seed_demo_data(db)
        dry = run_backfill(db, dry_run=True)
        applied = run_backfill(db, dry_run=False)
        assert all(v == 0 for v in dry.values())
        assert all(v == 0 for v in applied.values())
    finally:
        db.close()
