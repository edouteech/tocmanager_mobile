from sqlalchemy import text
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


def _migrate_columns() -> None:
    """Ajoute de façon non destructive les nouvelles colonnes sous SQLite."""
    if not settings.DATABASE_URL.startswith("sqlite"):
        return

    with engine.connect() as conn:
        def add_col_if_missing(table: str, col: str, col_type: str):
            try:
                res = conn.execute(text(f"PRAGMA table_info({table})")).fetchall()
                existing = [r[1] for r in res]
                if existing and col not in existing:
                    conn.execute(text(f"ALTER TABLE {table} ADD COLUMN {col} {col_type}"))
                    conn.commit()
            except Exception:
                pass

        for table in ("clients", "suppliers", "approvisionnements", "decaissements"):
            add_col_if_missing(table, "user_id", "VARCHAR(36)")
            add_col_if_missing(table, "user_name", "VARCHAR(255)")
        add_col_if_missing("ventes", "user_name", "VARCHAR(255)")
        add_col_if_missing("ventes", "status", "VARCHAR(30) DEFAULT 'completed'")
        add_col_if_missing("vente_items", "refunded_quantity", "FLOAT DEFAULT 0.0")
        add_col_if_missing("users", "pin_failed_attempts", "INTEGER DEFAULT 0")
        add_col_if_missing("users", "pin_locked_until", "DATETIME")

        for table in (
            "categories", "products", "clients", "suppliers",
            "ventes", "approvisionnements", "decaissements",
            "audit_logs", "sync_events",
        ):
            add_col_if_missing(table, "boutique_id", "VARCHAR(36)")

        for table in ("ventes", "approvisionnements", "decaissements", "sync_events"):
            add_col_if_missing(table, "magasin_id", "VARCHAR(36)")

        for table in ("stocks_magasin", "product_magasin_availability"):
            add_col_if_missing(table, "boutique_id", "VARCHAR(36)")

        add_col_if_missing("saas_plan_features", "category", "VARCHAR(50) DEFAULT 'modules'")
        add_col_if_missing("saas_plan_features", "description", "TEXT")
        add_col_if_missing("saas_plan_features", "display_order", "INTEGER DEFAULT 0")
        add_col_if_missing("saas_plan_features", "show_on_pricing", "BOOLEAN DEFAULT 1")
        add_col_if_missing("boutiques", "has_used_trial", "BOOLEAN DEFAULT 0")
        add_col_if_missing("saas_subscriptions", "has_used_trial", "BOOLEAN DEFAULT 0")

        # Rebuild legacy store_settings table under SQLite if it lacks id/boutique_id
        try:
            cols = [r[1] for r in conn.execute(text("PRAGMA table_info(store_settings)")).fetchall()]
            if cols and "boutique_id" not in cols:
                conn.execute(text("DROP TABLE IF EXISTS store_settings"))
                conn.commit()
        except Exception:
            pass


def bootstrap_production_superadmin(db: Session) -> None:
    """Crée un unique superadmin initial en prod si des identifiants explicites sont fournis."""
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
    _migrate_columns()
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
