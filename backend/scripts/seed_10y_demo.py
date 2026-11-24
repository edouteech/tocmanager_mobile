import argparse
from pathlib import Path
import sys

ROOT_DIR = Path(__file__).resolve().parents[1]
if str(ROOT_DIR) not in sys.path:
    sys.path.insert(0, str(ROOT_DIR))

from scripts.seeder_10y.catalog_data import DEMO_DEFAULT_PASSWORD, SCALE_PRESETS  # noqa: E402
from scripts.seeder_10y.runner import seed_10y_dataset  # noqa: E402


def main() -> int:
    parser = argparse.ArgumentParser(description="Seed a 10-year multi-tenant TocManager operational dataset.")
    parser.add_argument("--database-url", default=None, help="Target SQLAlchemy URL (defaults to settings.DATABASE_URL)")
    parser.add_argument("--scale", choices=tuple(SCALE_PRESETS.keys()), default="stress", help="Dataset volume preset")
    parser.add_argument("--years", type=int, default=10, help="Historical exploitation window in years (1-25)")
    parser.add_argument("--seed", type=int, default=42, help="Deterministic RNG seed")
    parser.add_argument("--clean-demo", action="store_true", help="Remove existing demo10y-* data first")
    parser.add_argument("--allow-production", action="store_true", help="Allow running when ENVIRONMENT=production")
    args = parser.parse_args()

    summary = seed_10y_dataset(
        database_url=args.database_url,
        scale=args.scale,
        years=args.years,
        seed=args.seed,
        clean_demo=args.clean_demo,
        allow_production=args.allow_production,
    )
    print(
        f"10Y seed complete in {summary.elapsed_seconds}s "
        f"[scale={summary.scale}, years={summary.years}, boutiques={summary.boutiques}, users={summary.users}]:"
    )
    for tname, count in sorted(summary.counts.items()):
        print(f"  - {tname}: {count} rows")
    print(f"Demo accounts prefix: demo10y_* (superadmin: demo10y_superadmin) | password: {DEMO_DEFAULT_PASSWORD}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
