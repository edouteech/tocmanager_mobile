from datetime import datetime, timedelta
import random
from typing import Any, Dict, List
import uuid

from sqlalchemy import text

from app.core.database import Base
from scripts.seeder_10y.catalog_data import MONTH_SEASONALITY, PAYMENT_METHODS, PAYMENT_WEIGHTS
from scripts.seeder_10y.db_ops import bulk_insert, set_pg_tenant_context
from scripts.seeder_10y.state_types import BoutiqueSeedState
from scripts.seeder_10y.support_ops_builder import append_month_support_ops

_OPERATION_TABLES = (
    "approvisionnements", "decaissements", "cash_register_sessions", "ventes", "vente_items",
    "client_payments", "supplier_payments", "stock_transfers", "stock_transfer_items", "stock_movements", "audit_logs",
)


def _compute_year_month_sales(total_target: int, years: int, start_yr_offset: int) -> Dict[int, List[int]]:
    raw_weights: Dict[int, List[float]] = {}
    weight_sum = 0.0
    for y_idx in range(start_yr_offset, years):
        growth = 1.0 + 0.10 * (y_idx - start_yr_offset)
        months = [growth * MONTH_SEASONALITY[m_idx] for m_idx in range(12)]
        weight_sum += sum(months)
        raw_weights[y_idx] = months

    factor = total_target / max(weight_sum, 1.0)
    return {y: [max(1, round(w * factor)) for w in ws] for y, ws in raw_weights.items()}


def _flush_year_buffers(conn, dialect: str, btq_id: str, buf: Dict[str, List[Dict[str, Any]]], counts: Dict[str, int]) -> None:
    for tname in _OPERATION_TABLES:
        rows = buf[tname]
        if rows:
            scoped_bid = None if tname in ("vente_items", "stock_transfer_items") else btq_id
            counts[tname] = counts.get(tname, 0) + bulk_insert(
                conn, dialect, Base.metadata.tables[tname], rows, boutique_id=scoped_bid
            )
            rows.clear()


def _finalize_balances(conn, dialect: str, state: BoutiqueSeedState) -> None:
    set_pg_tenant_context(conn, dialect, state.boutique_id)
    for cid, bal in state.client_balances.items():
        conn.execute(text('UPDATE "clients" SET balance = :b WHERE sync_id = :id'), {"b": round(bal, 2), "id": cid})
    for sid, bal in state.supplier_balances.items():
        conn.execute(text('UPDATE "suppliers" SET balance = :b WHERE sync_id = :id'), {"b": round(bal, 2), "id": sid})

    prod_totals: Dict[str, float] = {p.sync_id: 0.0 for p in state.products}
    for (mid, pid), qty in state.stock_qty.items():
        conn.execute(
            text('UPDATE "stocks_magasin" SET quantity = :q WHERE magasin_id = :m AND product_sync_id = :p'),
            {"q": round(qty, 4), "m": mid, "p": pid},
        )
        if pid in prod_totals:
            prod_totals[pid] += qty
    for pid, total in prod_totals.items():
        conn.execute(text('UPDATE "products" SET stock = :q WHERE sync_id = :p'), {"q": round(total, 4), "p": pid})


def _append_sale(
    state: BoutiqueSeedState, s_ts: datetime, sample_rate: float, rng: random.Random,
    seq_counters: Dict[str, int], buf: Dict[str, List[Dict[str, Any]]], log_audit: bool,
) -> None:
    btq_id = state.boutique_id
    seq_counters["sale"] += 1
    mid = rng.choice(state.pos_magasin_ids)
    cashier = rng.choice(state.staff)
    v_id = str(uuid.uuid4())
    roll = rng.random()
    v_status = "completed" if roll < 0.94 else ("partial_refund" if roll < 0.97 else ("refunded" if roll < 0.99 else "canceled"))
    method = rng.choices(PAYMENT_METHODS, weights=PAYMENT_WEIGHTS, k=1)[0]
    cli_id, cli_name = rng.choice(state.client_ids) if (rng.random() < 0.65 or method == "Crédit") else (None, None)

    n_items = 1 if rng.random() < 0.55 else 2
    raw_total = 0.0
    for _ in range(n_items):
        prod = rng.choice(state.products)
        qty = float(rng.randint(1, 3))
        unit_p = prod.custom_prices.get(mid, prod.price)
        line_total = round(qty * unit_p, 2)
        raw_total += line_total
        ref_q = qty if v_status == "refunded" else (1.0 if (v_status == "partial_refund" and qty > 1.0) else 0.0)
        buf["vente_items"].append({
            "sync_id": str(uuid.uuid4()), "vente_sync_id": v_id, "product_sync_id": prod.sync_id,
            "product_name": prod.name, "quantity": qty, "unit_price": unit_p,
            "cost_price": prod.cost_price, "total": line_total, "refunded_quantity": ref_q,
        })
        if v_status != "canceled":
            bef = state.stock_qty[(mid, prod.sync_id)]
            aft = max(2.0, bef - qty) if bef >= qty else 25.0
            state.stock_qty[(mid, prod.sync_id)] = aft
            if rng.random() < sample_rate:
                buf["stock_movements"].append({
                    "id": str(uuid.uuid4()), "boutique_id": btq_id, "magasin_id": mid,
                    "product_sync_id": prod.sync_id, "movement_type": "sale", "quantity_delta": -qty,
                    "balance_before": bef, "balance_after": aft, "reference_type": "vente",
                    "reference_id": v_id, "user_id": cashier.id, "user_name": cashier.full_name, "created_at": s_ts,
                })

    disc = round(raw_total * 0.05, 2) if rng.random() < 0.12 else 0.0
    final_total = round(max(0.0, raw_total - disc), 2)
    buf["ventes"].append({
        "sync_id": v_id, "boutique_id": btq_id, "magasin_id": mid,
        "ticket_number": f"VNT-{state.blueprint.code}-{s_ts.year}-{seq_counters['sale']:06d}",
        "client_sync_id": cli_id, "client_name": cli_name, "user_id": cashier.id, "user_name": cashier.full_name,
        "total_amount": final_total, "paid_amount": 0.0 if method == "Crédit" else final_total,
        "discount_amount": disc, "payment_method": method, "status": v_status, "created_at": s_ts, "updated_at": s_ts,
    })
    if method == "Crédit" and cli_id and v_status == "completed":
        prev_b = state.client_balances[cli_id]
        new_b = round(prev_b + final_total, 2)
        state.client_balances[cli_id] = new_b
        if seq_counters["sale"] % 12 == 0 and new_b > 0:
            settle = round(new_b * 0.6, 2)
            state.client_balances[cli_id] = round(new_b - settle, 2)
            buf["client_payments"].append({
                "id": str(uuid.uuid4()), "boutique_id": btq_id, "magasin_id": mid, "client_sync_id": cli_id,
                "amount": settle, "payment_method": "Mobile Money", "previous_balance": new_b,
                "new_balance": state.client_balances[cli_id], "notes": "Encaissement créance client",
                "user_id": cashier.id, "user_name": cashier.full_name, "created_at": s_ts + timedelta(hours=2),
            })
    if v_status != "completed" or log_audit:
        buf["audit_logs"].append({
            "id": str(uuid.uuid4()), "boutique_id": btq_id, "user_id": cashier.id, "user_name": cashier.full_name,
            "action": f"VENTE_{v_status.upper()}", "entity_type": "vente", "entity_id": v_id,
            "details": {"total": final_total}, "created_at": s_ts,
        })


def build_10y_operations(
    engine, now: datetime, years: int, states: List[BoutiqueSeedState], scale_cfg: Dict[str, float],
    rng: random.Random, counts: Dict[str, int],
) -> None:
    """Stream 10 years of sales, items, restocks, expenses, Z sessions, transfers, payments & audits."""
    dialect = engine.dialect.name
    total_target = int(scale_cfg["total_sales_target"])
    sample_rate = float(scale_cfg["movement_sample_rate"])

    for state in states:
        bp = state.blueprint
        start_offset = max(0, years - min(years, bp.active_years))
        btq_target = max(12, round(total_target * bp.sales_weight))
        month_plan = _compute_year_month_sales(btq_target, years, start_offset)
        seq_counters = {"sale": 0, "trf": 0}
        buf: Dict[str, List[Dict[str, Any]]] = {t: [] for t in _OPERATION_TABLES}

        with engine.begin() as conn:
            for y_idx, month_counts in month_plan.items():
                year_start = now - timedelta(days=365 * (years - y_idx))
                for m_idx, sales_n in enumerate(month_counts):
                    is_last_month = (y_idx == years - 1) and (m_idx == len(month_counts) - 1)
                    m_base = year_start + timedelta(days=int(365 * m_idx / 12))
                    append_month_support_ops(state, m_base, m_idx, rng, seq_counters, buf, is_last_month)

                    for s_i in range(sales_n):
                        s_ts = m_base + timedelta(days=rng.randint(0, 29), hours=rng.randint(8, 20), minutes=rng.randint(0, 59))
                        if s_ts >= state.end_at:
                            s_ts = state.end_at - timedelta(minutes=1)
                        _append_sale(state, s_ts, sample_rate, rng, seq_counters, buf, log_audit=(s_i == 0))
                _flush_year_buffers(conn, dialect, state.boutique_id, buf, counts)
            _finalize_balances(conn, dialect, state)
