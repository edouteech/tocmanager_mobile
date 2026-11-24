from datetime import datetime, timedelta, timezone
import random
from typing import Any, Dict, List, Tuple
import uuid

from sqlalchemy import text
from sqlalchemy.orm import sessionmaker

from app.core.database import Base
from app.core.security import get_password_hash, hash_pin
from app.services.payments.feexpay_catalog import seed_default_payment_providers
from app.services.seed_plans import seed_saas_plans
from scripts.seeder_10y.catalog_data import BOUTIQUE_PROFILES, DEMO_DEFAULT_PASSWORD, DEMO_USER_PREFIX
from scripts.seeder_10y.db_ops import bulk_insert
from scripts.seeder_10y.partner_catalog_builder import populate_catalog_and_partners, seed_saas_billing_history
from scripts.seeder_10y.state_types import BoutiqueSeedState, StaffSeedRef

ROLE_PERMISSIONS = {
    "superadmin": ["*"],
    "merchant": ["*"],
    "store_admin": ["*"],
    "manager": ["sales.*", "products.*", "clients.*", "suppliers.*", "stocks.*", "reports.view"],
    "cashier": ["sales.create", "sales.view_own", "products.view_price", "clients.create"],
}


def _ensure_plans_and_providers(engine) -> Dict[str, Dict[str, Any]]:
    Session = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    with Session() as db:
        seed_saas_plans(db)
        seed_default_payment_providers(db)
        rows = db.execute(text('SELECT id, code, name, price_monthly, price_yearly FROM "saas_plans"')).mappings().all()
        return {r["code"]: dict(r) for r in rows}


def build_tenants_and_catalogs(
    engine, years: int, scale_cfg: Dict[str, float], rng: random.Random, counts: Dict[str, int]
) -> Tuple[datetime, List[BoutiqueSeedState]]:
    """Create demo superadmin, 6 boutiques, ~24 users, magasins, plans history, catalogs & partners."""
    plans_by_code = _ensure_plans_and_providers(engine)
    now = datetime.now(timezone.utc)
    pw_hash = get_password_hash(DEMO_DEFAULT_PASSWORD)
    pin_hashes = {p: hash_pin(p) for p in ("1234", "4321", "567890")}

    sa_id = str(uuid.uuid4())
    sa_username = f"{DEMO_USER_PREFIX}superadmin"
    users_rows: List[Dict[str, Any]] = [{
        "id": sa_id, "username": sa_username, "email": f"{sa_username}@demo10y.tocmanager.local",
        "full_name": "SuperAdmin Démo 10 Ans", "hashed_password": pw_hash, "pin_hash": pin_hashes["1234"],
        "pin_failed_attempts": 0, "email_verified_at": now - timedelta(days=365 * years), "totp_enabled": False,
        "role": "superadmin", "permissions": ["*"], "is_active": True,
        "created_at": now - timedelta(days=365 * years), "updated_at": now,
    }]
    pending = []
    dialect = engine.dialect.name

    with engine.begin() as conn:
        for bp in BOUTIQUE_PROFILES:
            btq_years = min(years, bp.active_years)
            start_at = now - timedelta(days=365 * btq_years)
            btq_id = str(uuid.uuid4())
            staff_refs: List[StaffSeedRef] = []
            for s_idx, sp in enumerate(bp.staff):
                uid = str(uuid.uuid4())
                uname = f"{DEMO_USER_PREFIX}{bp.code.lower()}_{sp.role_key}"
                created = start_at + timedelta(days=s_idx * 45)
                users_rows.append({
                    "id": uid, "username": uname, "email": f"{uname}@demo10y.tocmanager.local",
                    "full_name": sp.label, "hashed_password": pw_hash, "pin_hash": pin_hashes[sp.pin],
                    "pin_failed_attempts": 0, "email_verified_at": created, "totp_enabled": False,
                    "role": sp.role, "permissions": ROLE_PERMISSIONS[sp.role], "is_active": sp.is_active,
                    "created_at": created, "updated_at": now,
                })
                staff_refs.append(StaffSeedRef(uid, uname, sp.label, sp.role, sp.magasin_index, sp.is_active))
            pending.append((bp, btq_id, start_at, staff_refs))

        counts["users"] = counts.get("users", 0) + bulk_insert(conn, dialect, Base.metadata.tables["users"], users_rows)

        built_states: List[BoutiqueSeedState] = []
        platform_logs: List[Dict[str, Any]] = []
        for bp, btq_id, start_at, staff_refs in pending:
            owner = staff_refs[0]
            counts["boutiques"] = counts.get("boutiques", 0) + bulk_insert(conn, dialect, Base.metadata.tables["boutiques"], [{
                "id": btq_id, "slug": bp.slug, "name": bp.name, "company_name": bp.company_name,
                "currency": bp.currency, "country": bp.country, "phone": "+221770000000",
                "email": f"contact+{bp.code.lower()}@demo10y.tocmanager.local",
                "owner_user_id": owner.id, "has_used_trial": bp.plan_code != "free",
                "is_active": bp.is_active, "created_at": start_at, "updated_at": now,
            }])
            mag_rows, mag_ids, pos_ids, wh_ids = [], [], [], []
            for m in bp.magasins:
                mid = str(uuid.uuid4())
                mag_ids.append(mid)
                (wh_ids if m.is_warehouse else pos_ids).append(mid)
                mag_rows.append({"id": mid, "boutique_id": btq_id, "name": m.name, "code": m.code, "is_warehouse": m.is_warehouse, "is_active": True, "created_at": start_at, "updated_at": now})
            counts["magasins"] = counts.get("magasins", 0) + bulk_insert(conn, dialect, Base.metadata.tables["magasins"], mag_rows, boutique_id=btq_id)

            mem_rows = [{
                "id": str(uuid.uuid4()), "boutique_id": btq_id, "user_id": s.id,
                "role": bp.staff[idx].membership_role,
                "assigned_magasin_ids": [] if bp.staff[idx].membership_role in ("owner", "store_admin") else [mag_ids[min(s.magasin_index, len(mag_ids) - 1)]],
                "is_active": s.is_active, "created_at": start_at, "updated_at": now,
            } for idx, s in enumerate(staff_refs)]
            counts["boutique_user_memberships"] = counts.get("boutique_user_memberships", 0) + bulk_insert(conn, dialect, Base.metadata.tables["boutique_user_memberships"], mem_rows)
            counts["store_settings"] = counts.get("store_settings", 0) + bulk_insert(conn, dialect, Base.metadata.tables["store_settings"], [
                {"id": str(uuid.uuid4()), "boutique_id": btq_id, "key": "receipt_footer", "value": f"Merci de votre fidélité chez {bp.name}", "updated_at": now},
                {"id": str(uuid.uuid4()), "boutique_id": btq_id, "key": "default_currency", "value": bp.currency, "updated_at": now},
            ], boutique_id=btq_id)

            seed_saas_billing_history(conn, dialect, btq_id, bp, plans_by_code[bp.plan_code], owner, start_at, now, rng, counts)
            platform_logs.append({"id": str(uuid.uuid4()), "admin_user_id": sa_id, "admin_username": sa_username, "action": "BOUTIQUE_ONBOARD", "target_entity": "boutique", "target_id": btq_id, "details": {"slug": bp.slug, "plan": bp.plan_code}, "created_at": start_at})

            built_states.append(populate_catalog_and_partners(conn, dialect, bp, btq_id, start_at, now, mag_ids, pos_ids, wh_ids, staff_refs, scale_cfg, rng, counts))

        counts["platform_audit_logs"] = counts.get("platform_audit_logs", 0) + bulk_insert(conn, dialect, Base.metadata.tables["platform_audit_logs"], platform_logs)
    return now, built_states
