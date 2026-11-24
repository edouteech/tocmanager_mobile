import random
import time
from typing import Dict, Optional

from sqlalchemy import create_engine

from app.core.config import settings
from app.core.database import Base, normalize_database_url
from app.core.rls import apply_postgresql_rls
import app.models  # noqa: F401
from scripts.seeder_10y.catalog_data import BOUTIQUE_PROFILES, DEMO_SLUG_PREFIX, SCALE_PRESETS
from scripts.seeder_10y.db_ops import SeedSummary, clean_demo_data, count_existing_demo_boutiques
from scripts.seeder_10y.operations_builder import build_10y_operations
from scripts.seeder_10y.tenants_builder import build_tenants_and_catalogs


def seed_10y_dataset(
    database_url: Optional[str] = None,
    *,
    scale: str = "stress",
    years: int = 10,
    seed: int = 42,
    clean_demo: bool = False,
    allow_production: bool = False,
    environment: Optional[str] = None,
) -> SeedSummary:
    """Seed a deterministic 10-year multi-tenant TocManager dataset isolated under demo10y-*."""
    effective_env = (environment or settings.ENVIRONMENT or "development").strip().lower()
    if effective_env == "production" and not allow_production:
        raise RuntimeError(
            "Refusing to run 10-year demo seeder in production without allow_production/--allow-production."
        )
    if scale not in SCALE_PRESETS:
        raise ValueError(f"Unknown scale '{scale}'. Expected one of: {', '.join(SCALE_PRESETS)}")
    if years < 1 or years > 25:
        raise ValueError("years must be between 1 and 25.")

    target_url = normalize_database_url(database_url or settings.DATABASE_URL)
    connect_args = {"check_same_thread": False} if target_url.startswith("sqlite") else {}
    engine = create_engine(target_url, connect_args=connect_args, pool_pre_ping=True)

    Base.metadata.create_all(bind=engine)
    apply_postgresql_rls(engine)

    existing_demo = count_existing_demo_boutiques(engine)
    if existing_demo > 0 and not clean_demo:
        raise RuntimeError(
            f"Found {existing_demo} existing '{DEMO_SLUG_PREFIX}*' demo boutiques. Pass --clean-demo to replace them."
        )

    started = time.perf_counter()
    if clean_demo:
        clean_demo_data(engine)

    counts: Dict[str, int] = {}
    rng = random.Random(seed)
    scale_cfg = SCALE_PRESETS[scale]

    now, states = build_tenants_and_catalogs(engine, years, scale_cfg, rng, counts)
    build_10y_operations(engine, now, years, states, scale_cfg, rng, counts)

    elapsed = round(time.perf_counter() - started, 2)
    return SeedSummary(
        counts=counts,
        elapsed_seconds=elapsed,
        scale=scale,
        years=years,
        boutiques=len(BOUTIQUE_PROFILES),
        users=counts.get("users", 0),
    )
