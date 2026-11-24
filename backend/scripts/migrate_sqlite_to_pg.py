import argparse
from pathlib import Path
import sys
from typing import Dict

from sqlalchemy import create_engine, text

ROOT_DIR = Path(__file__).resolve().parents[1]
if str(ROOT_DIR) not in sys.path:
    sys.path.insert(0, str(ROOT_DIR))

from app.core.database import Base  # noqa: E402
from app.core.rls import apply_postgresql_rls  # noqa: E402
import app.models  # noqa: F401, E402


def _sync_pg_sequences(target_engine) -> None:
    if target_engine.dialect.name != "postgresql":
        return
    with target_engine.begin() as conn:
        for table in Base.metadata.sorted_tables:
            for col in table.columns:
                if col.primary_key and getattr(col.type, "python_type", None) is int and col.autoincrement:
                    conn.execute(
                        text(
                            f"SELECT setval(pg_get_serial_sequence('{table.name}', '{col.name}'), "
                            f"COALESCE((SELECT MAX({col.name}) FROM {table.name}), 1), true);"
                        )
                    )


def migrate_database(
    source_url: str,
    target_url: str,
    *,
    ensure_schema: bool = True,
    truncate_target: bool = False,
    chunk_size: int = 500,
) -> Dict[str, int]:
    """Copy all TocManager rows from source SQLite/DB to target PostgreSQL preserving PKs and sync_id."""
    src_args = {"check_same_thread": False} if source_url.startswith("sqlite") else {}
    dst_args = {"check_same_thread": False} if target_url.startswith("sqlite") else {}
    src_engine = create_engine(source_url, connect_args=src_args)
    dst_engine = create_engine(target_url, connect_args=dst_args)

    if ensure_schema:
        Base.metadata.create_all(bind=dst_engine)
        apply_postgresql_rls(dst_engine)

    copied: Dict[str, int] = {}
    with src_engine.connect() as src_conn, dst_engine.begin() as dst_conn:
        if truncate_target:
            for table in reversed(Base.metadata.sorted_tables):
                dst_conn.execute(table.delete())

        for table in Base.metadata.sorted_tables:
            rows = src_conn.execute(table.select()).mappings().all()
            if not rows:
                copied[table.name] = 0
                continue
            payload = [dict(r) for r in rows]
            for start in range(0, len(payload), chunk_size):
                dst_conn.execute(table.insert(), payload[start : start + chunk_size])
            copied[table.name] = len(payload)

    _sync_pg_sequences(dst_engine)
    return copied


def main() -> int:
    parser = argparse.ArgumentParser(description="Migrate TocManager SQLite data to PostgreSQL.")
    parser.add_argument("--source", required=True, help="Source SQLAlchemy URL (e.g. sqlite:///./tocmanager.db)")
    parser.add_argument("--target", required=True, help="Target SQLAlchemy URL (e.g. postgresql://...)")
    parser.add_argument("--truncate", action="store_true", help="Clear target tables before copying")
    args = parser.parse_args()

    counts = migrate_database(args.source, args.target, truncate_target=args.truncate)
    total = sum(counts.values())
    print(f"Migration complete: {total} rows copied across {len(counts)} tables.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
