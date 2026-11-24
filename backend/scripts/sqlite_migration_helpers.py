from dataclasses import dataclass, field
from datetime import datetime, timezone
import json
from typing import Any, Callable, Dict, List, Optional, Tuple
import uuid

import sqlalchemy as sa

from app.core.rls import TENANT_RLS_TABLES

TENANT_RLS_TABLE_SET = set(TENANT_RLS_TABLES)

_LEGACY_DEFAULTS: Dict[Tuple[str, str], Callable[[Dict[str, Any]], Any]] = {
    ("boutiques", "has_used_trial"): lambda _row: False,
    ("saas_subscriptions", "has_used_trial"): lambda row: bool(row.get("trial_starts_at")),
    ("saas_plan_features", "category"): lambda _row: "modules",
    ("saas_plan_features", "display_order"): lambda _row: 0,
    ("saas_plan_features", "show_on_pricing"): lambda _row: True,
    ("users", "pin_failed_attempts"): lambda _row: 0,
    ("users", "totp_enabled"): lambda _row: False,
    ("ventes", "status"): lambda _row: "completed",
    ("vente_items", "refunded_quantity"): lambda _row: 0.0,
    ("store_settings", "id"): lambda _row: str(uuid.uuid4()),
}


@dataclass
class MigrationReport:
    copied: Dict[str, int] = field(default_factory=dict)
    skipped_orphans: Dict[str, int] = field(default_factory=dict)
    nulled_fks: Dict[str, int] = field(default_factory=dict)
    deduplicated: Dict[str, int] = field(default_factory=dict)
    dry_run: bool = False


def _fit_legacy_id(value: str) -> str:
    """Deterministically fit legacy string IDs longer than 36 chars into UUID-length IDs."""
    return value if len(value) <= 36 else str(uuid.uuid5(uuid.NAMESPACE_URL, f"tocmanager-legacy-id:{value}"))


def _fit_string(col: sa.Column, value: str) -> str:
    """Enforce PostgreSQL String(N) limits, remapping overlong ID/FK columns cleanly."""
    max_len = getattr(col.type, "length", None)
    if not max_len or len(value) <= max_len:
        return value
    if max_len == 36 and (
        col.primary_key or col.foreign_keys or col.name in ("id", "sync_id") or col.name.endswith("_id")
    ):
        return _fit_legacy_id(value)
    return value[:max_len]


def coerce_value(col: sa.Column, value: Any) -> Any:
    """Coerce raw SQLite column value to match target SQLAlchemy/PostgreSQL column type."""
    if value is None:
        return None
    if isinstance(col.type, sa.Boolean):
        if isinstance(value, bool):
            return value
        if isinstance(value, (int, float)):
            return bool(value)
        if isinstance(value, str):
            return value.strip().lower() in ("1", "true", "t", "yes", "y", "on")
        return bool(value)
    if isinstance(col.type, sa.DateTime):
        if isinstance(value, str):
            raw = value.strip()
            if not raw:
                return None
            if raw.endswith("Z"):
                raw = raw[:-1] + "+00:00"
            dt = datetime.fromisoformat(raw)
            return dt.replace(tzinfo=timezone.utc) if dt.tzinfo is None else dt
        if isinstance(value, datetime) and value.tzinfo is None:
            return value.replace(tzinfo=timezone.utc)
        return value
    if isinstance(col.type, sa.JSON):
        return (json.loads(value.strip()) if value.strip() else None) if isinstance(value, str) else value
    if isinstance(col.type, sa.String):
        return _fit_string(col, str(value))
    if isinstance(col.type, sa.Integer) and not isinstance(value, bool):
        return int(value)
    if isinstance(col.type, sa.Float) and not isinstance(value, bool):
        return float(value)
    return value


def resolve_boutique_id(raw_row: Dict[str, Any], ctx: Dict[str, Any]) -> Optional[str]:
    """Infer tenant boutique_id from magasin_id, user_id, or default boutique."""
    magasin_id = raw_row.get("magasin_id")
    if magasin_id and magasin_id in ctx["magasin_to_boutique"]:
        return ctx["magasin_to_boutique"][magasin_id]
    user_id = raw_row.get("user_id")
    if user_id and user_id in ctx["user_to_boutique"]:
        return ctx["user_to_boutique"][user_id]
    return ctx.get("default_boutique_id")


def default_for_column(
    table_name: str,
    col: sa.Column,
    raw_row: Dict[str, Any],
    ctx: Dict[str, Any],
) -> Any:
    """Resolve fallback value for missing or NULL legacy columns."""
    legacy_fn = _LEGACY_DEFAULTS.get((table_name, col.name))
    if legacy_fn is not None:
        return legacy_fn(raw_row)

    if col.name == "boutique_id" and (not col.nullable or table_name in TENANT_RLS_TABLE_SET):
        resolved = resolve_boutique_id(raw_row, ctx)
        if resolved is not None:
            return resolved

    if col.default is not None:
        if col.default.is_callable:
            try:
                return col.default.arg()
            except TypeError:
                return col.default.arg(None)
        if col.default.is_scalar:
            return col.default.arg

    return None


def normalize_row(
    table: sa.Table,
    raw_row: Dict[str, Any],
    ctx: Dict[str, Any],
) -> Dict[str, Any]:
    """Project legacy SQLite row onto target table schema and coerce values."""
    normalized: Dict[str, Any] = {}
    for col in table.columns:
        val = raw_row.get(col.name)
        need_backfill = val is None or (isinstance(val, str) and not val.strip() and not col.nullable)
        if need_backfill:
            val = default_for_column(table.name, col, raw_row, ctx)
        elif isinstance(val, str) and not val.strip() and (col.foreign_keys or col.unique):
            val = None
        if val is not None:
            val = coerce_value(col, val)
        normalized[col.name] = val
    return normalized


def validate_fks(
    table: sa.Table,
    row: Dict[str, Any],
    seen_pks: Dict[Tuple[str, str], set],
) -> Tuple[bool, int]:
    """Nullify dangling nullable FKs or flag rows with broken required FKs."""
    nulled_count = 0
    for col in table.columns:
        val = row.get(col.name)
        if val is None or not col.foreign_keys:
            continue
        for fk in col.foreign_keys:
            parent_table = fk.column.table.name
            parent_col = fk.column.name
            if parent_table == table.name:
                continue
            parent_keys = seen_pks.get((parent_table, parent_col))
            if parent_keys is not None and val not in parent_keys:
                if col.nullable:
                    row[col.name] = None
                    nulled_count += 1
                    break
                return False, nulled_count
    return True, nulled_count


def unique_constraint_keys(table: sa.Table, row: Dict[str, Any]) -> List[Tuple[str, Tuple[Any, ...]]]:
    """Build deterministic unique-key tuples for PK, single-column unique, and composite constraints."""
    keys: List[Tuple[str, Tuple[Any, ...]]] = []
    pk_cols = [c.name for c in table.primary_key.columns]
    if pk_cols:
        pk_vals = tuple(row.get(c) for c in pk_cols)
        if any(v is not None for v in pk_vals):
            keys.append(("__pk__", pk_vals))

    for col in table.columns:
        if col.unique and col.name not in pk_cols:
            val = row.get(col.name)
            if val is not None:
                keys.append((f"__col_{col.name}", (val,)))

    for constraint in table.constraints:
        if isinstance(constraint, sa.UniqueConstraint):
            col_names = [c.name for c in constraint.columns]
            vals = tuple(row.get(c) for c in col_names)
            if any(v is not None for v in vals):
                cname = constraint.name or ("__uq_" + "_".join(col_names))
                keys.append((cname, vals))
    return keys


def build_tenant_context(src_conn, src_tables: set[str]) -> Dict[str, Any]:
    """Pre-scan legacy users, boutiques, magasins and memberships to resolve tenant mappings."""
    ctx: Dict[str, Any] = {
        "default_boutique_id": None, "first_user_id": None, "synthesize_boutique": None,
        "magasin_to_boutique": {}, "user_to_boutique": {},
    }
    if "users" in src_tables:
        first_user = src_conn.execute(sa.text('SELECT id FROM "users" LIMIT 1')).mappings().first()
        if first_user and first_user.get("id"):
            ctx["first_user_id"] = _fit_legacy_id(str(first_user["id"]))

    if "boutiques" in src_tables:
        boutiques = src_conn.execute(sa.text('SELECT id, owner_user_id FROM "boutiques"')).mappings().all()
        if boutiques:
            ctx["default_boutique_id"] = _fit_legacy_id(str(boutiques[0]["id"]))
            for row in boutiques:
                if row.get("owner_user_id"):
                    ctx["user_to_boutique"].setdefault(_fit_legacy_id(str(row["owner_user_id"])), _fit_legacy_id(str(row["id"])))

    if ctx["default_boutique_id"] is None and ctx["first_user_id"]:
        tenant_tables = ("products", "categories", "clients", "suppliers", "ventes", "magasins", "store_settings")
        if any(src_conn.execute(sa.text(f'SELECT 1 FROM "{t}" LIMIT 1')).first() is not None for t in tenant_tables if t in src_tables):
            synth_id = str(uuid.uuid4())
            ctx["default_boutique_id"] = synth_id
            ctx["synthesize_boutique"] = {
                "id": synth_id, "slug": "boutique-principale", "name": "Boutique Principale",
                "owner_user_id": ctx["first_user_id"], "has_used_trial": False, "is_active": True,
                "created_at": datetime.now(timezone.utc), "updated_at": datetime.now(timezone.utc),
            }

    if "magasins" in src_tables:
        for row in src_conn.execute(sa.text('SELECT id, boutique_id FROM "magasins"')).mappings().all():
            bid = _fit_legacy_id(str(row["boutique_id"])) if row.get("boutique_id") else ctx["default_boutique_id"]
            if row.get("id") and bid:
                ctx["magasin_to_boutique"][_fit_legacy_id(str(row["id"]))] = bid

    if "boutique_user_memberships" in src_tables:
        for row in src_conn.execute(sa.text('SELECT user_id, boutique_id FROM "boutique_user_memberships"')).mappings().all():
            if row.get("user_id") and row.get("boutique_id"):
                ctx["user_to_boutique"].setdefault(_fit_legacy_id(str(row["user_id"])), _fit_legacy_id(str(row["boutique_id"])))

    return ctx
