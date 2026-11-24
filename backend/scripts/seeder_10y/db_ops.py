from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional

from sqlalchemy import text

from app.core.rls import TENANT_RLS_TABLES
from scripts.seeder_10y.catalog_data import DEMO_SLUG_PREFIX, DEMO_USER_PREFIX

DEFAULT_CHUNK_SIZE = 500
TENANT_RLS_TABLE_SET = set(TENANT_RLS_TABLES)

_TENANT_DELETE_ORDER = (
    "saas_invoices",
    "saas_payment_transactions",
    "saas_subscriptions",
    "audit_logs",
    "stock_movements",
    "stock_transfers",
    "cash_register_sessions",
    "client_payments",
    "supplier_payments",
    "ventes",
    "approvisionnements",
    "decaissements",
    "stocks_magasin",
    "product_magasin_availability",
    "products",
    "categories",
    "clients",
    "suppliers",
    "store_settings",
    "boutique_user_memberships",
    "magasins",
)


@dataclass
class SeedSummary:
    counts: Dict[str, int] = field(default_factory=dict)
    elapsed_seconds: float = 0.0
    scale: str = "stress"
    years: int = 10
    boutiques: int = 0
    users: int = 0


def set_pg_tenant_context(conn, dialect_name: str, boutique_id: str) -> None:
    """Bind transaction-local PostgreSQL RLS boutique_id before tenant writes or deletes."""
    if dialect_name == "postgresql":
        conn.execute(text("SELECT set_config('app.current_boutique_id', :bid, true)"), {"bid": str(boutique_id)})


def bulk_insert(
    conn,
    dialect_name: str,
    table,
    rows: List[Dict[str, Any]],
    *,
    boutique_id: Optional[str] = None,
    chunk_size: int = DEFAULT_CHUNK_SIZE,
) -> int:
    """Insert rows in bounded chunks with PostgreSQL RLS context when applicable."""
    if not rows:
        return 0
    if boutique_id and table.name in TENANT_RLS_TABLE_SET:
        set_pg_tenant_context(conn, dialect_name, boutique_id)
    for start in range(0, len(rows), chunk_size):
        conn.execute(table.insert(), rows[start : start + chunk_size])
    return len(rows)


def _delete_user_chunked(conn, table_name: str, user_col: str, user_ids: List[str]) -> None:
    if not user_ids:
        return
    for start in range(0, len(user_ids), 200):
        batch = user_ids[start : start + 200]
        placeholders = ", ".join(f":u{i}" for i in range(len(batch)))
        params = {f"u{i}": uid for i, uid in enumerate(batch)}
        conn.execute(text(f'DELETE FROM "{table_name}" WHERE {user_col} IN ({placeholders})'), params)


def count_existing_demo_boutiques(engine) -> int:
    with engine.connect() as conn:
        return int(
            conn.execute(
                text('SELECT COUNT(*) FROM "boutiques" WHERE slug LIKE :pref'),
                {"pref": f"{DEMO_SLUG_PREFIX}%"},
            ).scalar()
            or 0
        )


def clean_demo_data(engine) -> Dict[str, int]:
    """Delete ONLY demo10y-* boutiques and demo10y_* users without touching real tenants."""
    deleted: Dict[str, int] = {}
    dialect = engine.dialect.name
    with engine.begin() as conn:
        btq_rows = conn.execute(
            text('SELECT id FROM "boutiques" WHERE slug LIKE :pref'),
            {"pref": f"{DEMO_SLUG_PREFIX}%"},
        ).fetchall()
        demo_btq_ids = [r[0] for r in btq_rows]

        usr_rows = conn.execute(
            text('SELECT id FROM "users" WHERE username LIKE :pref'),
            {"pref": f"{DEMO_USER_PREFIX}%"},
        ).fetchall()
        demo_user_ids = [r[0] for r in usr_rows]

        for bid in demo_btq_ids:
            set_pg_tenant_context(conn, dialect, bid)
            vi = conn.execute(
                text('DELETE FROM "vente_items" WHERE vente_sync_id IN (SELECT sync_id FROM "ventes" WHERE boutique_id = :bid)'),
                {"bid": bid},
            )
            deleted["vente_items"] = deleted.get("vente_items", 0) + (vi.rowcount or 0)
            sti = conn.execute(
                text(
                    'DELETE FROM "stock_transfer_items" WHERE transfer_id IN '
                    '(SELECT id FROM "stock_transfers" WHERE boutique_id = :bid)'
                ),
                {"bid": bid},
            )
            deleted["stock_transfer_items"] = deleted.get("stock_transfer_items", 0) + (sti.rowcount or 0)

            for tname in _TENANT_DELETE_ORDER:
                res = conn.execute(text(f'DELETE FROM "{tname}" WHERE boutique_id = :bid'), {"bid": bid})
                if res.rowcount:
                    deleted[tname] = deleted.get(tname, 0) + res.rowcount

            btq_res = conn.execute(text('DELETE FROM "boutiques" WHERE id = :bid'), {"bid": bid})
            deleted["boutiques"] = deleted.get("boutiques", 0) + (btq_res.rowcount or 0)

        _delete_user_chunked(conn, "refresh_tokens", "user_id", demo_user_ids)
        _delete_user_chunked(conn, "auth_action_tokens", "user_id", demo_user_ids)
        conn.execute(
            text('DELETE FROM "platform_audit_logs" WHERE admin_username LIKE :pref'),
            {"pref": f"{DEMO_USER_PREFIX}%"},
        )
        _delete_user_chunked(conn, "users", "id", demo_user_ids)
        if demo_user_ids:
            deleted["users"] = len(demo_user_ids)

    return deleted
