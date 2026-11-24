from sqlalchemy.orm import Session
from app.core.config import settings
from app.core.database import engine, Base
from app.core.rls import apply_postgresql_rls
from app.core.security import get_password_hash
from app.models import BoutiqueUserMembership, User
from app.services.payments.feexpay_catalog import seed_default_payment_providers
from app.services.seed_plans import seed_saas_plans
from app.services.seed_demo import seed_demo_data
from app.services.stock_service import backfill_product_stocks_to_main_magasin


def bootstrap_production_superadmin(db: Session) -> None:
    """Create initial superadmin in production only when explicit credentials are configured."""
    existing_superadmin = db.query(User).filter(User.role == "superadmin").first()
    if existing_superadmin:
        return

    email = (settings.BOOTSTRAP_SUPERADMIN_EMAIL or "").strip().lower()
    password = settings.BOOTSTRAP_SUPERADMIN_PASSWORD or ""
    username = (settings.BOOTSTRAP_SUPERADMIN_USERNAME or "admin").strip()
    if not email or not password:
        return

    db.add(User(
        username=username,
        email=email,
        full_name="Super Administrateur Plateforme",
        hashed_password=get_password_hash(password),
        role="superadmin",
        permissions=["*"],
        is_active=True,
    ))
    db.commit()


def _migrate_legacy_admin_roles(db: Session) -> None:
    """Migrate ambiguous legacy 'admin' user/membership roles to 'store_admin'."""
    updated = False
    for user in db.query(User).filter(User.role == "admin").all():
        user.role = "store_admin"
        updated = True
    for membership in db.query(BoutiqueUserMembership).filter(BoutiqueUserMembership.role == "admin").all():
        membership.role = "store_admin"
        updated = True
    if updated:
        db.commit()


def init_db(db: Session) -> None:
    """Ensure schema creation, PostgreSQL RLS, base SaaS seed and environment bootstrap."""
    Base.metadata.create_all(bind=engine)
    apply_postgresql_rls(engine)
    _migrate_legacy_admin_roles(db)
    seed_saas_plans(db)
    seed_default_payment_providers(db)
    backfill_product_stocks_to_main_magasin(db)

    if settings.ENVIRONMENT.strip().lower() == "production":
        bootstrap_production_superadmin(db)
        return

    if settings.ENABLE_DEMO_SEED:
        seed_demo_data(db)
