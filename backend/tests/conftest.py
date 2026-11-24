import atexit
import os
import tempfile
from fastapi.testclient import TestClient
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Isolate tests from the repository's ./tocmanager.db before importing app.*
if "DATABASE_URL" not in os.environ:
    _tmp_db_file = os.path.join(
        tempfile.gettempdir(), f"tocmanager_pytest_{os.getpid()}.db"
    )
    os.environ["DATABASE_URL"] = f"sqlite:///{_tmp_db_file}"

    def _cleanup_tmp_db() -> None:
        if os.path.exists(_tmp_db_file):
            try:
                os.remove(_tmp_db_file)
            except OSError:
                pass

    atexit.register(_cleanup_tmp_db)


@pytest.fixture(autouse=True)
def _reset_rate_limiter():
    from app.core.rate_limit import reset_rate_limits

    reset_rate_limits()
    yield
    reset_rate_limits()


@pytest.fixture
def isolated_db_session(tmp_path):
    """Per-test ephemeral SQLite DB with FastAPI get_db dependency override."""
    from app.core.database import Base, get_db
    from app.main import app

    db_path = tmp_path / "test_isolated.db"
    test_engine = create_engine(f"sqlite:///{db_path}", connect_args={"check_same_thread": False})
    TestingSession = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)
    Base.metadata.create_all(bind=test_engine)

    def override_get_db():
        db = TestingSession()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db
    session = TestingSession()
    try:
        yield session, test_engine, TestingSession
    finally:
        session.close()
        app.dependency_overrides.clear()
        test_engine.dispose()


@pytest.fixture
def multi_tenant_env(isolated_db_session):
    """Seed two boutiques, two magasins for A, and merchant/cashier/superadmin users."""
    from app.core.security import create_access_token, get_password_hash
    from app.main import app
    from app.models import Boutique, BoutiqueUserMembership, Magasin, SaasPlan, SaasSubscription, User
    from app.services.seed_plans import seed_saas_plans

    db, _, _ = isolated_db_session
    seed_saas_plans(db)
    pro_plan = db.query(SaasPlan).filter(SaasPlan.code == "pro").first()

    merchant = User(
        username="merchant_fx",
        email="merchant_fx@test.local",
        hashed_password=get_password_hash("Secret123!"),
        role="merchant",
        permissions=["*"],
        is_active=True,
    )
    cashier = User(
        username="cashier_fx",
        email="cashier_fx@test.local",
        hashed_password=get_password_hash("Secret123!"),
        role="cashier",
        permissions=["sales.create", "products.view_price"],
        is_active=True,
    )
    superadmin = User(
        username="superadmin_fx",
        email="superadmin_fx@test.local",
        hashed_password=get_password_hash("Secret123!"),
        role="superadmin",
        permissions=["*"],
        is_active=True,
    )
    db.add_all([merchant, cashier, superadmin])
    db.flush()

    boutique_a = Boutique(slug="btq-fx-a", name="Boutique Alpha", owner_user_id=merchant.id, is_active=True)
    boutique_b = Boutique(slug="btq-fx-b", name="Boutique Beta", owner_user_id=merchant.id, is_active=True)
    db.add_all([boutique_a, boutique_b])
    db.flush()

    magasin_a1 = Magasin(boutique_id=boutique_a.id, name="Magasin A1", code="A1", is_active=True)
    magasin_a2 = Magasin(boutique_id=boutique_a.id, name="Magasin A2", code="A2", is_active=True)
    db.add_all([magasin_a1, magasin_a2])
    db.flush()

    db.add_all([
        BoutiqueUserMembership(boutique_id=boutique_a.id, user_id=merchant.id, role="owner", assigned_magasin_ids=[]),
        BoutiqueUserMembership(boutique_id=boutique_b.id, user_id=merchant.id, role="owner", assigned_magasin_ids=[]),
        BoutiqueUserMembership(boutique_id=boutique_a.id, user_id=cashier.id, role="cashier", assigned_magasin_ids=[magasin_a1.id]),
    ])
    if pro_plan:
        db.add_all([
            SaasSubscription(boutique_id=boutique_a.id, plan_id=pro_plan.id, status="active"),
            SaasSubscription(boutique_id=boutique_b.id, plan_id=pro_plan.id, status="active"),
        ])
    db.commit()

    def make_headers(user: User, boutique: Boutique = boutique_a, magasin: Magasin | None = None):
        hdrs = {"Authorization": f"Bearer {create_access_token(user.id)}", "X-Boutique-Id": boutique.id}
        if magasin is not None:
            hdrs["X-Magasin-Id"] = magasin.id
        return hdrs

    return {
        "client": TestClient(app),
        "db": db,
        "boutique_a": boutique_a,
        "boutique_b": boutique_b,
        "magasin_a1": magasin_a1,
        "magasin_a2": magasin_a2,
        "merchant": merchant,
        "cashier": cashier,
        "superadmin": superadmin,
        "make_headers": make_headers,
    }
