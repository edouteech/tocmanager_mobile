from pathlib import Path
import sqlite3
import subprocess
import sys
import uuid

import pytest
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

from app.models import (
    AuditLog,
    Boutique,
    Category,
    Client,
    Magasin,
    Product,
    ProductMagasinAvailability,
    SaasPlan,
    SaasPlanFeature,
    SaasSubscription,
    StockMagasin,
    StoreSetting,
    Supplier,
    User,
    Vente,
    VenteItem,
)
from app.services.payments.feexpay_catalog import seed_default_payment_providers
from app.services.seed_plans import seed_saas_plans
from scripts.migrate_sqlite_to_pg import migrate_database_with_report


def _create_legacy_43e7954_sqlite(db_path: Path) -> None:
    """Create and populate an authentic pre-TOC-001 (43e7954) production SQLite database."""
    conn = sqlite3.connect(str(db_path))
    try:
        conn.executescript(
            """
            CREATE TABLE users (
                id VARCHAR(36) PRIMARY KEY,
                username VARCHAR(100) NOT NULL UNIQUE,
                email VARCHAR(255) UNIQUE,
                full_name VARCHAR(255),
                hashed_password VARCHAR(255) NOT NULL,
                pin_hash VARCHAR(255),
                role VARCHAR(50) NOT NULL,
                permissions TEXT,
                is_active INTEGER,
                created_at TEXT,
                updated_at TEXT
            );
            CREATE TABLE saas_plans (
                id VARCHAR(36) PRIMARY KEY,
                name VARCHAR(100) NOT NULL,
                code VARCHAR(50) NOT NULL UNIQUE,
                description TEXT,
                price_monthly FLOAT NOT NULL,
                price_yearly FLOAT NOT NULL,
                currency VARCHAR(10),
                trial_period_days INTEGER,
                is_active INTEGER,
                badge VARCHAR(50),
                created_at TEXT,
                updated_at TEXT
            );
            CREATE TABLE saas_plan_features (
                id VARCHAR(36) PRIMARY KEY,
                plan_id VARCHAR(36) NOT NULL,
                feature_code VARCHAR(100) NOT NULL,
                feature_name VARCHAR(200) NOT NULL,
                value_type VARCHAR(20),
                boolean_value INTEGER,
                int_limit INTEGER,
                created_at TEXT
            );
            CREATE TABLE boutiques (
                id VARCHAR(36) PRIMARY KEY,
                slug VARCHAR(100) NOT NULL UNIQUE,
                name VARCHAR(255) NOT NULL,
                company_name VARCHAR(255),
                currency VARCHAR(10),
                country VARCHAR(100),
                phone VARCHAR(50),
                email VARCHAR(255),
                address TEXT,
                logo_url TEXT,
                schema_name VARCHAR(63) UNIQUE,
                owner_user_id VARCHAR(36) NOT NULL,
                is_active INTEGER,
                created_at TEXT,
                updated_at TEXT
            );
            CREATE TABLE boutique_user_memberships (
                id VARCHAR(36) PRIMARY KEY,
                boutique_id VARCHAR(36) NOT NULL,
                user_id VARCHAR(36) NOT NULL,
                role VARCHAR(50),
                assigned_magasin_ids TEXT,
                is_active INTEGER,
                created_at TEXT,
                updated_at TEXT
            );
            CREATE TABLE saas_subscriptions (
                id VARCHAR(36) PRIMARY KEY,
                boutique_id VARCHAR(36) NOT NULL,
                plan_id VARCHAR(36) NOT NULL,
                status VARCHAR(50),
                billing_cycle VARCHAR(20),
                trial_starts_at TEXT,
                trial_ends_at TEXT,
                current_period_start TEXT,
                current_period_end TEXT,
                canceled_at TEXT,
                created_at TEXT,
                updated_at TEXT
            );
            CREATE TABLE magasins (
                id VARCHAR(36) PRIMARY KEY,
                boutique_id VARCHAR(36),
                name VARCHAR(255) NOT NULL,
                code VARCHAR(50),
                address TEXT,
                phone VARCHAR(50),
                is_warehouse INTEGER,
                is_active INTEGER,
                created_at TEXT,
                updated_at TEXT
            );
            CREATE TABLE categories (
                sync_id VARCHAR(36) PRIMARY KEY,
                boutique_id VARCHAR(36),
                name VARCHAR(150) NOT NULL,
                description TEXT,
                color VARCHAR(30),
                icon VARCHAR(50),
                created_at TEXT,
                updated_at TEXT,
                deleted_at TEXT
            );
            CREATE TABLE products (
                sync_id VARCHAR(36) PRIMARY KEY,
                boutique_id VARCHAR(36),
                name VARCHAR(255) NOT NULL,
                category_sync_id VARCHAR(36),
                price FLOAT NOT NULL,
                cost_price FLOAT NOT NULL,
                average_cost_price FLOAT,
                stock FLOAT NOT NULL,
                min_stock FLOAT NOT NULL,
                barcode VARCHAR(100),
                unit VARCHAR(50),
                image_path TEXT,
                is_active INTEGER,
                created_at TEXT,
                updated_at TEXT,
                deleted_at TEXT
            );
            CREATE TABLE stocks_magasin (
                id VARCHAR(36) PRIMARY KEY,
                magasin_id VARCHAR(36) NOT NULL,
                product_sync_id VARCHAR(36) NOT NULL,
                quantity FLOAT NOT NULL,
                min_stock FLOAT NOT NULL,
                cost_price FLOAT NOT NULL,
                average_cost_price FLOAT,
                last_updated_at TEXT
            );
            CREATE TABLE product_magasin_availability (
                id VARCHAR(36) PRIMARY KEY,
                magasin_id VARCHAR(36) NOT NULL,
                product_sync_id VARCHAR(36) NOT NULL,
                is_available INTEGER,
                custom_price FLOAT,
                created_at TEXT
            );
            CREATE TABLE clients (
                sync_id VARCHAR(36) PRIMARY KEY,
                boutique_id VARCHAR(36),
                name VARCHAR(255) NOT NULL,
                phone VARCHAR(50),
                email VARCHAR(255),
                address TEXT,
                balance FLOAT NOT NULL,
                notes TEXT,
                user_id VARCHAR(36),
                user_name VARCHAR(255),
                created_at TEXT,
                updated_at TEXT,
                deleted_at TEXT
            );
            CREATE TABLE suppliers (
                sync_id VARCHAR(36) PRIMARY KEY,
                boutique_id VARCHAR(36),
                name VARCHAR(255) NOT NULL,
                contact_person VARCHAR(255),
                phone VARCHAR(50),
                email VARCHAR(255),
                address TEXT,
                balance FLOAT NOT NULL,
                notes TEXT,
                user_id VARCHAR(36),
                user_name VARCHAR(255),
                created_at TEXT,
                updated_at TEXT,
                deleted_at TEXT
            );
            CREATE TABLE ventes (
                sync_id VARCHAR(36) PRIMARY KEY,
                boutique_id VARCHAR(36),
                magasin_id VARCHAR(36),
                ticket_number VARCHAR(100) NOT NULL,
                client_sync_id VARCHAR(36),
                client_name VARCHAR(255),
                user_id VARCHAR(36),
                user_name VARCHAR(255),
                total_amount FLOAT NOT NULL,
                paid_amount FLOAT NOT NULL,
                discount_amount FLOAT NOT NULL,
                payment_method VARCHAR(50) NOT NULL,
                notes TEXT,
                created_at TEXT,
                updated_at TEXT,
                deleted_at TEXT
            );
            CREATE TABLE vente_items (
                sync_id VARCHAR(36) PRIMARY KEY,
                vente_sync_id VARCHAR(36) NOT NULL,
                product_sync_id VARCHAR(36),
                product_name VARCHAR(255) NOT NULL,
                quantity FLOAT NOT NULL,
                unit_price FLOAT NOT NULL,
                cost_price FLOAT NOT NULL,
                total FLOAT NOT NULL
            );
            CREATE TABLE audit_logs (
                id VARCHAR(36) PRIMARY KEY,
                boutique_id VARCHAR(36),
                user_id VARCHAR(36),
                user_name VARCHAR(255),
                action VARCHAR(100) NOT NULL,
                entity_type VARCHAR(50),
                entity_id VARCHAR(100),
                details TEXT,
                created_at TEXT
            );
            CREATE TABLE sync_events (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                action VARCHAR(50) NOT NULL,
                entity_type VARCHAR(50) NOT NULL,
                entity_uuid VARCHAR(36) NOT NULL
            );
            CREATE TABLE store_settings (
                key VARCHAR(100) PRIMARY KEY,
                value TEXT,
                description VARCHAR(255),
                updated_at TEXT
            );
            """
        )

        ts = "2026-11-10T10:15:00"
        conn.execute(
            "INSERT INTO users VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            ("usr-owner", "mamadou", "mamadou@shop.sn", "Mamadou Diop", "$2b$12$hash", None, "merchant", '["*"]', 1, ts, ts),
        )
        conn.execute(
            "INSERT INTO saas_plans VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            ("plan-pro", "Plan Pro", "pro", "Pro", 15000.0, 150000.0, "XOF", 14, 1, "POPULAIRE", ts, ts),
        )
        conn.execute(
            "INSERT INTO saas_plan_features VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            ("feat-1", "plan-pro", "stock_transfers", "Transferts de stock inter-magasins", "boolean", 1, 0, ts),
        )
        conn.execute(
            "INSERT INTO boutiques VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            ("btq-1", "chezmamadou", "Chez Mamadou", "Mamadou SARL", "XOF", "Senegal", None, None, None, None, "tenant_btq_1", "usr-owner", 1, ts, ts),
        )
        conn.execute(
            "INSERT INTO boutique_user_memberships VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            ("mem-1", "btq-1", "usr-owner", "owner", '["mag-1"]', 1, ts, ts),
        )
        conn.execute(
            "INSERT INTO saas_subscriptions VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            ("sub-1", "btq-1", "plan-pro", "trialing", "monthly", ts, "2026-11-24T10:15:00Z", ts, None, None, ts, ts),
        )
        conn.execute(
            "INSERT INTO magasins VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            ("mag-1", "btq-1", "Dakar Plateau", "DKR1", None, None, 0, 1, ts, ts),
        )
        conn.execute(
            "INSERT INTO categories VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
            ("cat-1", "btq-1", "Boissons", None, "#29ABE2", None, ts, ts, None),
        )
        # Valid product + legacy product with NULL boutique_id and dangling category FK
        conn.execute(
            "INSERT INTO products VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            ("prod-1", "btq-1", "Jus Bissap", "cat-1", 1000.0, 600.0, 600.0, 20.0, 5.0, "123", "bouteille", None, 1, ts, ts, None),
        )
        conn.execute(
            "INSERT INTO products VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            ("prod-legacy-null", None, "Sucre Vrac", "cat-deleted", 500.0, 350.0, 350.0, 5.0, 2.0, None, "kg", None, 1, ts, ts, None),
        )
        conn.execute(
            "INSERT INTO stocks_magasin VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            ("stk-1", "mag-1", "prod-1", 20.0, 5.0, 600.0, 600.0, ts),
        )
        conn.execute(
            "INSERT INTO product_magasin_availability VALUES (?, ?, ?, ?, ?, ?)",
            ("avl-1", "mag-1", "prod-1", 1, 1200.0, ts),
        )
        conn.execute(
            "INSERT INTO clients VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            ("cli-1", "btq-1", "Fatou Ndiaye", "771234567", None, None, 2500.0, None, "usr-owner", "Mamadou Diop", ts, ts, None),
        )
        conn.execute(
            "INSERT INTO suppliers VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            ("sup-1", "btq-1", "Grossiste Dakar", None, None, None, None, 0.0, None, "usr-owner", "Mamadou Diop", ts, ts, None),
        )
        conn.execute(
            "INSERT INTO ventes VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            ("vnt-1", "btq-1", "mag-1", "VNT-0001", "cli-1", "Fatou Ndiaye", "usr-owner", "Mamadou Diop", 2000.0, 2000.0, 0.0, "Especes", None, ts, ts, None),
        )
        conn.execute(
            "INSERT INTO vente_items VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            ("vi-1", "vnt-1", "prod-1", "Jus Bissap", 2.0, 1000.0, 600.0, 2000.0),
        )
        # Orphan vente_item referencing missing vente
        conn.execute(
            "INSERT INTO vente_items VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
            ("vi-orphan", "vnt-missing", "prod-1", "Jus Bissap", 1.0, 1000.0, 600.0, 1000.0),
        )
        # Audit log with NULL boutique_id (would fail RLS if not backfilled)
        conn.execute(
            "INSERT INTO audit_logs VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
            ("aud-1", None, "usr-owner", "Mamadou Diop", "CREATE", "product", "prod-1", '{"price": 1000}', ts),
        )
        conn.execute(
            "INSERT INTO sync_events (action, entity_type, entity_uuid) VALUES (?, ?, ?)",
            ("create", "product", "prod-1"),
        )
        conn.execute(
            "INSERT INTO store_settings VALUES (?, ?, ?, ?)",
            ("receipt_footer", "Merci de votre visite", "Pied de ticket", ts),
        )
        conn.commit()
    finally:
        conn.close()


def _prepare_alembic_target(db_path: Path) -> str:
    backend_dir = Path(__file__).resolve().parents[1]
    alembic_bin = Path(sys.executable).parent / "alembic"
    target_url = f"sqlite:///{db_path}"
    proc = subprocess.run(
        [str(alembic_bin), "upgrade", "head"],
        cwd=str(backend_dir),
        env={"PATH": str(Path(sys.executable).parent), "DATABASE_URL": target_url},
        capture_output=True,
        text=True,
    )
    assert proc.returncode == 0, proc.stderr + proc.stdout
    return target_url


def test_legacy_43e7954_sqlite_dry_run_and_live_migration_into_alembic_target(tmp_path):
    legacy_db = tmp_path / "legacy_43e7954.db"
    target_db = tmp_path / "alembic_target.db"
    _create_legacy_43e7954_sqlite(legacy_db)

    src_url = f"sqlite:///{legacy_db}"
    dst_url = _prepare_alembic_target(target_db)

    dry = migrate_database_with_report(src_url, dst_url, ensure_schema=False, dry_run=True)
    assert dry.dry_run is True
    assert dry.copied["users"] == 1
    assert dry.copied["products"] == 2
    assert dry.nulled_fks["products"] == 1
    assert dry.skipped_orphans["vente_items"] == 1

    # Dry-run must leave target completely untouched
    dst_engine = create_engine(dst_url, connect_args={"check_same_thread": False})
    Session = sessionmaker(bind=dst_engine)
    db = Session()
    try:
        assert db.query(User).count() == 0
        assert db.query(Product).count() == 0
    finally:
        db.close()

    # Live migration into Alembic target
    live = migrate_database_with_report(src_url, dst_url, ensure_schema=False, truncate_target=True)
    assert live.copied["users"] == 1
    assert live.copied["boutiques"] == 1
    assert live.copied["magasins"] == 1
    assert live.copied["products"] == 2
    assert live.copied["stocks_magasin"] == 1
    assert live.copied["product_magasin_availability"] == 1
    assert live.copied["clients"] == 1
    assert live.copied["suppliers"] == 1
    assert live.copied["ventes"] == 1
    assert live.copied["vente_items"] == 1
    assert live.copied["store_settings"] == 1
    assert live.copied["audit_logs"] == 1
    assert live.nulled_fks["products"] == 1
    assert live.skipped_orphans["vente_items"] == 1

    db = Session()
    try:
        user = db.query(User).one()
        assert user.permissions == ["*"]
        assert user.pin_failed_attempts == 0
        assert user.totp_enabled is False

        btq = db.query(Boutique).one()
        assert btq.id == "btq-1"
        assert btq.has_used_trial is False

        sub = db.query(SaasSubscription).one()
        assert sub.has_used_trial is True

        backfilled_prod = db.query(Product).filter_by(sync_id="prod-legacy-null").one()
        assert backfilled_prod.boutique_id == "btq-1"
        assert backfilled_prod.category_sync_id is None

        assert db.query(StockMagasin).one().boutique_id == "btq-1"
        assert db.query(ProductMagasinAvailability).one().boutique_id == "btq-1"
        assert db.query(Client).one().sync_id == "cli-1"
        assert db.query(Supplier).one().sync_id == "sup-1"
        assert db.query(Vente).one().status == "completed"
        assert db.query(VenteItem).one().refunded_quantity == 0.0

        setting = db.query(StoreSetting).one()
        assert setting.id
        assert setting.boutique_id == "btq-1"
        assert setting.key == "receipt_footer"

        audit = db.query(AuditLog).one()
        assert audit.boutique_id == "btq-1"
        assert audit.details == {"price": 1000}

        # alembic_version remains intact and app seeders execute cleanly afterwards
        ver = db.execute(text("SELECT version_num FROM alembic_version")).scalar()
        assert ver == "0003_auth_tokens_and_2fa"

        seed_saas_plans(db)
        seed_default_payment_providers(db)
        assert db.query(SaasPlan).count() == 3
        assert db.query(SaasPlanFeature).count() == 3 * 28
    finally:
        db.close()


def test_migrate_refuses_non_empty_target_without_truncate_and_succeeds_with_truncate(tmp_path):
    legacy_db = tmp_path / "legacy.db"
    target_db = tmp_path / "target.db"
    _create_legacy_43e7954_sqlite(legacy_db)

    src_url = f"sqlite:///{legacy_db}"
    dst_url = _prepare_alembic_target(target_db)

    migrate_database_with_report(src_url, dst_url, ensure_schema=False)

    with pytest.raises(RuntimeError, match="--truncate"):
        migrate_database_with_report(src_url, dst_url, ensure_schema=False, truncate_target=False)

    rerun = migrate_database_with_report(src_url, dst_url, ensure_schema=False, truncate_target=True)
    assert rerun.copied["products"] == 2


def test_migrate_remaps_overlong_legacy_ids_and_truncates_strings(tmp_path):
    legacy_db = tmp_path / "legacy_long_ids.db"
    target_db = tmp_path / "target_long_ids.db"
    _create_legacy_43e7954_sqlite(legacy_db)

    raw_audit_id = f"audit-{uuid.uuid4()}"
    raw_client_id = f"client-{uuid.uuid4()}"
    assert len(raw_audit_id) == 42
    assert len(raw_client_id) == 43

    conn = sqlite3.connect(str(legacy_db))
    try:
        ts = "2026-11-10T10:15:00"
        conn.execute(
            "INSERT INTO clients VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            (raw_client_id, "btq-1", "Awa Kane", "770001122", None, None, 0.0, None, "usr-owner", "Mamadou Diop", ts, ts, None),
        )
        conn.execute(
            "INSERT INTO ventes VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
            ("vnt-long", "btq-1", "mag-1", "VNT-LONG", raw_client_id, "Awa Kane", "usr-owner", "Mamadou Diop", 1000.0, 1000.0, 0.0, "x" * 80, None, ts, ts, None),
        )
        conn.execute(
            "INSERT INTO audit_logs VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
            (raw_audit_id, "btq-1", "usr-owner", "Mamadou Diop", "CLIENT_CREATE", "client", raw_client_id, "{}", ts),
        )
        conn.commit()
    finally:
        conn.close()

    dst_url = _prepare_alembic_target(target_db)
    report = migrate_database_with_report(f"sqlite:///{legacy_db}", dst_url, ensure_schema=False)
    assert report.skipped_orphans == {"vente_items": 1}
    assert report.nulled_fks == {"products": 1}

    dst_engine = create_engine(dst_url, connect_args={"check_same_thread": False})
    Session = sessionmaker(bind=dst_engine)
    db = Session()
    try:
        expected_audit_id = str(uuid.uuid5(uuid.NAMESPACE_URL, f"tocmanager-legacy-id:{raw_audit_id}"))
        expected_client_id = str(uuid.uuid5(uuid.NAMESPACE_URL, f"tocmanager-legacy-id:{raw_client_id}"))
        assert len(expected_audit_id) == 36
        assert len(expected_client_id) == 36

        migrated_audit = db.query(AuditLog).filter_by(id=expected_audit_id).one()
        assert len(migrated_audit.id) == 36

        migrated_client = db.query(Client).filter_by(sync_id=expected_client_id).one()
        migrated_vente = db.query(Vente).filter_by(sync_id="vnt-long").one()
        assert migrated_client.sync_id == migrated_vente.client_sync_id
        assert len(migrated_client.sync_id) == 36
        assert len(migrated_vente.payment_method) == 50
    finally:
        db.close()
