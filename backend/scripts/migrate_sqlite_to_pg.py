import argparse
from pathlib import Path
import sys
from typing import Any, Dict, List, Tuple

from sqlalchemy import create_engine, inspect, text

ROOT_DIR = Path(__file__).resolve().parents[1]
if str(ROOT_DIR) not in sys.path:
    sys.path.insert(0, str(ROOT_DIR))

from app.core.database import Base, normalize_database_url  # noqa: E402
from app.core.rls import apply_postgresql_rls  # noqa: E402
import app.models  # noqa: F401, E402
from scripts.sqlite_migration_helpers import (  # noqa: E402
    TENANT_RLS_TABLE_SET,
    MigrationReport,
    build_tenant_context,
    normalize_row,
    unique_constraint_keys,
    validate_fks,
)


def _sync_pg_sequences(target_engine) -> None:
    if target_engine.dialect.name != "postgresql":
        return
    with target_engine.begin() as conn:
        for table in Base.metadata.sorted_tables:
            for col in table.columns:
                if col.primary_key and getattr(col.type, "python_type", None) is int and col.autoincrement:
                    seq = conn.execute(
                        text("SELECT pg_get_serial_sequence(:tbl, :col)"),
                        {"tbl": table.name, "col": col.name},
                    ).scalar()
                    if seq:
                        conn.execute(
                            text(
                                f"SELECT setval(:seq, COALESCE((SELECT MAX({col.name}) FROM {table.name}), 1), true);"
                            ),
                            {"seq": seq},
                        )


def _ensure_target_ready(dst_engine, truncate_target: bool) -> None:
    dst_tables = set(inspect(dst_engine).get_table_names())
    guard_tables = [t for t in ("users", "boutiques", "saas_plans", "products", "ventes") if t in dst_tables]
    with dst_engine.connect() as conn:
        non_empty = [t for t in guard_tables if conn.execute(text(f'SELECT 1 FROM "{t}" LIMIT 1')).first() is not None]

    if non_empty and not truncate_target:
        joined = ", ".join(non_empty)
        raise RuntimeError(f"Target database is not empty ({joined}). Pass --truncate to replace existing target data.")

    if truncate_target and dst_tables:
        with dst_engine.begin() as dst_conn:
            if dst_engine.dialect.name == "postgresql":
                existing = [f'"{t.name}"' for t in Base.metadata.sorted_tables if t.name in dst_tables]
                if existing:
                    dst_conn.execute(text(f"TRUNCATE TABLE {', '.join(existing)} RESTART IDENTITY CASCADE;"))
            else:
                for table in reversed(Base.metadata.sorted_tables):
                    if table.name in dst_tables:
                        dst_conn.execute(table.delete())


def _insert_table_rows(dst_conn, dialect_name: str, table, rows: List[Dict[str, Any]], chunk_size: int) -> None:
    if not rows:
        return
    if dialect_name == "postgresql" and table.name in TENANT_RLS_TABLE_SET:
        by_boutique: Dict[str, List[Dict[str, Any]]] = {}
        for row in rows:
            by_boutique.setdefault(str(row["boutique_id"]), []).append(row)
        for bid, tenant_rows in by_boutique.items():
            dst_conn.execute(text("SELECT set_config('app.current_boutique_id', :bid, true)"), {"bid": bid})
            for start in range(0, len(tenant_rows), chunk_size):
                dst_conn.execute(table.insert(), tenant_rows[start : start + chunk_size])
        return

    for start in range(0, len(rows), chunk_size):
        dst_conn.execute(table.insert(), rows[start : start + chunk_size])


def _record_unique_keys(
    table,
    row: Dict[str, Any],
    seen_pks: Dict[Tuple[str, str], set],
    seen_uniques: Dict[Tuple[str, str], set],
) -> None:
    for col in table.columns:
        if col.primary_key or col.unique:
            val = row.get(col.name)
            if val is not None:
                seen_pks[(table.name, col.name)].add(val)
    for cname, key_vals in unique_constraint_keys(table, row):
        seen_uniques[(table.name, cname)].add(key_vals)


def migrate_database_with_report(
    source_url: str,
    target_url: str,
    *,
    ensure_schema: bool = True,
    truncate_target: bool = False,
    chunk_size: int = 500,
    dry_run: bool = False,
) -> MigrationReport:
    """Copy TocManager data from legacy or current SQLite into PostgreSQL with schema/RLS normalization."""
    source_url = normalize_database_url(source_url)
    target_url = normalize_database_url(target_url)
    src_args = {"check_same_thread": False} if source_url.startswith("sqlite") else {}
    dst_args = {"check_same_thread": False} if target_url.startswith("sqlite") else {}
    src_engine = create_engine(source_url, connect_args=src_args)
    dst_engine = create_engine(target_url, connect_args=dst_args)

    if ensure_schema and not dry_run:
        Base.metadata.create_all(bind=dst_engine)
        apply_postgresql_rls(dst_engine)
    if not dry_run:
        _ensure_target_ready(dst_engine, truncate_target=truncate_target)

    src_tables = set(inspect(src_engine).get_table_names())
    report = MigrationReport(dry_run=dry_run)
    seen_pks: Dict[Tuple[str, str], set] = {
        (t.name, c.name): set() for t in Base.metadata.sorted_tables for c in t.columns if c.primary_key or c.unique
    }
    seen_uniques: Dict[Tuple[str, str], set] = {}
    for t in Base.metadata.sorted_tables:
        seen_uniques.setdefault((t.name, "__pk__"), set())
        for c in t.columns:
            if c.unique:
                seen_uniques.setdefault((t.name, f"__col_{c.name}"), set())
        for cons in t.constraints:
            if getattr(cons, "columns", None):
                cname = cons.name or ("__uq_" + "_".join(c.name for c in cons.columns))
                seen_uniques.setdefault((t.name, cname), set())

    with src_engine.connect() as src_conn:
        ctx = build_tenant_context(src_conn, src_tables)
        prepared: List[Tuple[Any, List[Dict[str, Any]]]] = []

        for table in Base.metadata.sorted_tables:
            raw_rows: List[Dict[str, Any]] = []
            if table.name in src_tables:
                raw_rows = [dict(r) for r in src_conn.execute(text(f'SELECT * FROM "{table.name}"')).mappings().all()]
            if table.name == "boutiques" and not raw_rows and ctx.get("synthesize_boutique"):
                raw_rows = [ctx["synthesize_boutique"]]

            accepted: List[Dict[str, Any]] = []
            for raw in raw_rows:
                row = normalize_row(table, raw, ctx)
                ok, nulled = validate_fks(table, row, seen_pks)
                if nulled:
                    report.nulled_fks[table.name] = report.nulled_fks.get(table.name, 0) + nulled
                if not ok:
                    report.skipped_orphans[table.name] = report.skipped_orphans.get(table.name, 0) + 1
                    continue
                ukeys = unique_constraint_keys(table, row)
                if any(kvals in seen_uniques[(table.name, cname)] for cname, kvals in ukeys):
                    report.deduplicated[table.name] = report.deduplicated.get(table.name, 0) + 1
                    continue
                _record_unique_keys(table, row, seen_pks, seen_uniques)
                accepted.append(row)

            report.copied[table.name] = len(accepted)
            if accepted:
                prepared.append((table, accepted))

    if not dry_run:
        with dst_engine.begin() as dst_conn:
            for table, rows in prepared:
                _insert_table_rows(dst_conn, dst_engine.dialect.name, table, rows, chunk_size)
        _sync_pg_sequences(dst_engine)

    return report


def migrate_database(
    source_url: str,
    target_url: str,
    *,
    ensure_schema: bool = True,
    truncate_target: bool = False,
    chunk_size: int = 500,
    dry_run: bool = False,
) -> Dict[str, int]:
    """Copy all TocManager rows from source SQLite/DB to target PostgreSQL preserving PKs and sync_id."""
    return migrate_database_with_report(
        source_url,
        target_url,
        ensure_schema=ensure_schema,
        truncate_target=truncate_target,
        chunk_size=chunk_size,
        dry_run=dry_run,
    ).copied


def main() -> int:
    parser = argparse.ArgumentParser(description="Migrate TocManager SQLite data to PostgreSQL.")
    parser.add_argument("--source", required=True, help="Source SQLAlchemy URL (e.g. sqlite:////app/data/tocmanager.db)")
    parser.add_argument("--target", required=True, help="Target SQLAlchemy URL (e.g. postgresql://...)")
    parser.add_argument("--truncate", action="store_true", help="Clear target tables before copying")
    parser.add_argument("--dry-run", action="store_true", help="Validate & count without writing to target")
    args = parser.parse_args()

    report = migrate_database_with_report(args.source, args.target, truncate_target=args.truncate, dry_run=args.dry_run)
    total = sum(report.copied.values())
    mode = "DRY-RUN" if report.dry_run else "LIVE"
    print(f"[{mode}] Migration complete: {total} rows across {len(report.copied)} tables.")
    for tname, count in report.copied.items():
        if count:
            print(f"  - {tname}: {count} rows")
    if report.nulled_fks:
        print(f"  Nulled dangling nullable FKs: {report.nulled_fks}")
    if report.skipped_orphans:
        print(f"  Skipped orphan rows (broken required FK): {report.skipped_orphans}")
    if report.deduplicated:
        print(f"  Deduplicated constraint collisions: {report.deduplicated}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
