from typing import Iterable, List
from sqlalchemy import text
from sqlalchemy.engine import Engine

TENANT_RLS_TABLES = (
    "categories",
    "products",
    "clients",
    "suppliers",
    "ventes",
    "approvisionnements",
    "decaissements",
    "store_settings",
    "magasins",
    "stocks_magasin",
    "product_magasin_availability",
    "audit_logs",
)


def build_rls_ddl(tables: Iterable[str] = TENANT_RLS_TABLES) -> List[str]:
    """Build idempotent PostgreSQL Row-Level Security statements for tenant tables."""
    statements: List[str] = []
    predicate = (
        "current_setting('app.current_boutique_id', true) IS NOT NULL "
        "AND current_setting('app.current_boutique_id', true) <> '' "
        "AND boutique_id = current_setting('app.current_boutique_id', true)"
    )
    for table in tables:
        statements.extend([
            f"ALTER TABLE {table} ENABLE ROW LEVEL SECURITY;",
            f"ALTER TABLE {table} FORCE ROW LEVEL SECURITY;",
            f"DROP POLICY IF EXISTS tenant_isolation_{table} ON {table};",
            (
                f"CREATE POLICY tenant_isolation_{table} ON {table} "
                f"USING ({predicate}) WITH CHECK ({predicate});"
            ),
        ])
    return statements


def apply_postgresql_rls(db_engine: Engine) -> bool:
    """Apply tenant RLS policies when connected to PostgreSQL; no-op on SQLite."""
    if db_engine.dialect.name != "postgresql":
        return False

    with db_engine.begin() as conn:
        for stmt in build_rls_ddl():
            conn.execute(text(stmt))
    return True
