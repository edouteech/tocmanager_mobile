from datetime import datetime, timedelta
import random
from typing import Any, Dict, List
import uuid

from scripts.seeder_10y.catalog_data import EXPENSE_CATEGORIES
from scripts.seeder_10y.state_types import BoutiqueSeedState


def append_month_support_ops(
    state: BoutiqueSeedState,
    month_dt: datetime,
    m_idx: int,
    rng: random.Random,
    seq_counters: Dict[str, int],
    buf: Dict[str, List[Dict[str, Any]]],
    is_last_month: bool,
) -> None:
    """Append monthly restocks, supplier payments, expenses, cash Z sessions & transfers."""
    btq_id = state.boutique_id
    op_dt = min(month_dt + timedelta(days=2), state.end_at - timedelta(hours=2))

    for mid in state.magasin_ids:
        prod = rng.choice(state.products)
        sup_id, sup_name = rng.choice(state.supplier_ids)
        actor = rng.choice(state.staff)
        qty = float(rng.randint(25, 80))
        total_cost = round(qty * prod.cost_price, 2)
        is_credit = rng.random() < 0.25
        before = state.stock_qty[(mid, prod.sync_id)]
        after = before + qty
        state.stock_qty[(mid, prod.sync_id)] = after
        ap_id = str(uuid.uuid4())
        buf["approvisionnements"].append({
            "sync_id": ap_id, "boutique_id": btq_id, "magasin_id": mid, "supplier_sync_id": sup_id,
            "supplier_name": sup_name, "product_sync_id": prod.sync_id, "product_name": prod.name,
            "quantity": qty, "unit_cost": prod.cost_price, "total_cost": total_cost,
            "payment_status": "Crédit" if is_credit else "Payé", "date": op_dt,
            "user_id": actor.id, "user_name": actor.full_name, "created_at": op_dt, "updated_at": op_dt,
        })
        buf["stock_movements"].append({
            "id": str(uuid.uuid4()), "boutique_id": btq_id, "magasin_id": mid, "product_sync_id": prod.sync_id,
            "movement_type": "restock", "quantity_delta": qty, "balance_before": before, "balance_after": after,
            "reference_type": "approvisionnement", "reference_id": ap_id, "user_id": actor.id, "user_name": actor.full_name, "created_at": op_dt,
        })
        if is_credit:
            prev_b = state.supplier_balances[sup_id]
            new_b = round(prev_b + total_cost, 2)
            state.supplier_balances[sup_id] = new_b
            if m_idx % 2 == 1 and new_b > 0:
                pay_amt = round(new_b * 0.7, 2)
                state.supplier_balances[sup_id] = round(new_b - pay_amt, 2)
                buf["supplier_payments"].append({
                    "id": str(uuid.uuid4()), "boutique_id": btq_id, "magasin_id": mid, "supplier_sync_id": sup_id,
                    "amount": pay_amt, "payment_method": "Virement", "previous_balance": new_b,
                    "new_balance": state.supplier_balances[sup_id], "notes": "Règlement fournisseur démo",
                    "user_id": actor.id, "user_name": actor.full_name, "created_at": op_dt + timedelta(hours=3),
                })

    exp_cat, exp_title, exp_amt = EXPENSE_CATEGORIES[m_idx % len(EXPENSE_CATEGORIES)]
    pos_mid = state.pos_magasin_ids[m_idx % len(state.pos_magasin_ids)]
    mgr = state.staff[0]
    buf["decaissements"].append({
        "sync_id": str(uuid.uuid4()), "boutique_id": btq_id, "magasin_id": pos_mid,
        "title": f"{exp_title} ({op_dt.strftime('%Y-%m')})", "amount": exp_amt, "category": exp_cat,
        "beneficiary": exp_cat, "payment_method": "Espèces", "date": op_dt + timedelta(hours=1),
        "user_id": mgr.id, "user_name": mgr.full_name, "created_at": op_dt + timedelta(hours=1), "updated_at": op_dt,
    })

    for mid in state.pos_magasin_ids:
        opened = op_dt.replace(hour=8, minute=0)
        is_open = is_last_month
        expected_cash = float(rng.randint(120000, 480000))
        disc = float(rng.choice((-1500, -500, 0, 0, 0, 500, 1000)))
        buf["cash_register_sessions"].append({
            "id": str(uuid.uuid4()), "boutique_id": btq_id, "magasin_id": mid,
            "opened_by_user_id": state.staff[-1].id, "opened_by_name": state.staff[-1].full_name,
            "opened_at": opened, "opening_balance": 50000.0, "status": "open" if is_open else "closed",
            "expected_cash": None if is_open else expected_cash,
            "expected_mobile_money": None if is_open else float(rng.randint(45000, 190000)),
            "expected_card": None if is_open else float(rng.randint(15000, 80000)),
            "declared_cash": None if is_open else expected_cash + disc,
            "discrepancy": None if is_open else disc,
            "closed_by_user_id": None if is_open else mgr.id,
            "closed_by_name": None if is_open else mgr.full_name,
            "closed_at": None if is_open else opened + timedelta(hours=11),
            "created_at": opened, "updated_at": opened,
        })

    if len(state.magasin_ids) >= 2 and m_idx % 3 == 0:
        seq_counters["trf"] += 1
        src_m = state.warehouse_magasin_ids[0] if state.warehouse_magasin_ids else state.magasin_ids[0]
        dst_m = [m for m in state.magasin_ids if m != src_m][0]
        prod = rng.choice(state.products)
        qty_s = float(rng.randint(5, 18))
        trf_id = str(uuid.uuid4())
        trf_status = "in_transit" if is_last_month else ("canceled" if seq_counters["trf"] % 11 == 0 else "received")
        buf["stock_transfers"].append({
            "id": trf_id, "boutique_id": btq_id, "reference": f"TRF-{state.blueprint.code}-{seq_counters['trf']:05d}",
            "from_magasin_id": src_m, "to_magasin_id": dst_m, "status": trf_status,
            "created_by_user_id": mgr.id, "created_by_name": mgr.full_name, "shipped_at": op_dt,
            "received_at": (op_dt + timedelta(hours=6)) if trf_status == "received" else None,
            "received_by_user_id": mgr.id if trf_status == "received" else None,
            "received_by_name": mgr.full_name if trf_status == "received" else None,
            "canceled_at": (op_dt + timedelta(hours=2)) if trf_status == "canceled" else None,
            "created_at": op_dt, "updated_at": op_dt,
        })
        buf["stock_transfer_items"].append({
            "id": str(uuid.uuid4()), "transfer_id": trf_id, "product_sync_id": prod.sync_id,
            "product_name": prod.name, "quantity_sent": qty_s,
            "quantity_received": qty_s if trf_status == "received" else None, "unit_cost": prod.cost_price,
        })
        if trf_status == "received":
            b_src = max(qty_s, state.stock_qty[(src_m, prod.sync_id)])
            state.stock_qty[(src_m, prod.sync_id)] = b_src - qty_s
            b_dst = state.stock_qty[(dst_m, prod.sync_id)]
            state.stock_qty[(dst_m, prod.sync_id)] = b_dst + qty_s
