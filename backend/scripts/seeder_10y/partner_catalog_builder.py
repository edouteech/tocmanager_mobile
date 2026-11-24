from datetime import datetime, timedelta
import random
from typing import Any, Dict, List, Tuple
import uuid

from app.core.database import Base
from scripts.seeder_10y.catalog_data import (
    CLIENT_FIRST_NAMES,
    CLIENT_LAST_NAMES,
    NETWORKS,
    SECTOR_CATALOGS,
    SUPPLIER_NAMES,
    BoutiqueBlueprint,
)
from scripts.seeder_10y.db_ops import bulk_insert
from scripts.seeder_10y.state_types import BoutiqueSeedState, ProductSeedRef, StaffSeedRef


def seed_saas_billing_history(
    conn,
    dialect: str,
    btq_id: str,
    bp: BoutiqueBlueprint,
    plan_info: Dict[str, Any],
    owner: StaffSeedRef,
    start_at: datetime,
    end_at: datetime,
    rng: random.Random,
    counts: Dict[str, int],
) -> None:
    """Seed SaasSubscription, FeexPay transactions and invoices across the boutique lifetime."""
    sub_id = str(uuid.uuid4())
    trial_start = start_at if bp.plan_code != "free" else None
    trial_end = (start_at + timedelta(days=14)) if bp.plan_code != "free" else None
    period_end = end_at + timedelta(days=20 if bp.sub_status != "past_due" else -7)
    sub_row = {
        "id": sub_id, "boutique_id": btq_id, "plan_id": plan_info["id"], "status": bp.sub_status,
        "billing_cycle": "yearly" if bp.plan_code == "enterprise" else "monthly",
        "trial_starts_at": trial_start, "trial_ends_at": trial_end, "has_used_trial": bp.plan_code != "free",
        "current_period_start": end_at - timedelta(days=30), "current_period_end": period_end,
        "canceled_at": None, "created_at": start_at, "updated_at": end_at,
    }
    counts["saas_subscriptions"] = counts.get("saas_subscriptions", 0) + bulk_insert(
        conn, dialect, Base.metadata.tables["saas_subscriptions"], [sub_row]
    )
    if bp.plan_code == "free":
        return

    tx_rows, inv_rows = [], []
    step_days = 365 if sub_row["billing_cycle"] == "yearly" else 30
    amount = float(plan_info["price_yearly"] if step_days == 365 else plan_info["price_monthly"])
    cursor = start_at + timedelta(days=14)
    idx = 0
    while cursor < end_at:
        idx += 1
        tx_id = str(uuid.uuid4())
        is_failed = idx % 17 == 0
        tx_rows.append({
            "id": tx_id, "reference": f"FP-{bp.code}-{idx:04d}-{tx_id[:6]}",
            "external_reference": f"FX2-{tx_id[:10]}", "provider_code": "feexpay",
            "boutique_id": btq_id, "user_id": owner.id, "plan_id": plan_info["id"],
            "billing_cycle": sub_row["billing_cycle"], "amount": amount, "currency": bp.currency,
            "phone": "+221770001122", "network": rng.choice(NETWORKS), "flow_type": "ussd_push",
            "payment_url": None, "status": "failed" if is_failed else "confirmed",
            "raw_payload": {"source": "demo10y"}, "paid_at": None if is_failed else cursor,
            "created_at": cursor, "updated_at": cursor,
        })
        if not is_failed:
            inv_rows.append({
                "id": str(uuid.uuid4()), "invoice_number": f"FAC-D10Y-{bp.code}-{cursor.year}-{idx:04d}",
                "transaction_id": tx_id, "boutique_id": btq_id, "plan_name": plan_info["name"],
                "billing_cycle": sub_row["billing_cycle"], "amount": amount, "currency": bp.currency,
                "period_start": cursor, "period_end": cursor + timedelta(days=step_days), "issued_at": cursor,
            })
        cursor += timedelta(days=step_days)

    counts["saas_payment_transactions"] = counts.get("saas_payment_transactions", 0) + bulk_insert(
        conn, dialect, Base.metadata.tables["saas_payment_transactions"], tx_rows, boutique_id=btq_id
    )
    counts["saas_invoices"] = counts.get("saas_invoices", 0) + bulk_insert(
        conn, dialect, Base.metadata.tables["saas_invoices"], inv_rows, boutique_id=btq_id
    )


def populate_catalog_and_partners(
    conn, dialect: str, bp: BoutiqueBlueprint, btq_id: str, start_at: datetime, now: datetime,
    mag_ids: List[str], pos_ids: List[str], wh_ids: List[str], staff: List[StaffSeedRef],
    scale_cfg: Dict[str, float], rng: random.Random, counts: Dict[str, int],
) -> BoutiqueSeedState:
    """Seed categories, products, per-magasin stock/availability, clients and suppliers."""
    cat_rows, prod_rows, stock_rows, avail_rows, prod_refs = [], [], [], [], []
    stock_qty: Dict[Tuple[str, str], float] = {}
    product_names: Dict[str, str] = {}
    sector_defs = SECTOR_CATALOGS[bp.sector]
    target_per_cat = int(scale_cfg["products_per_cat"])

    for cat_name, cat_color, base_items in sector_defs:
        cid = str(uuid.uuid4())
        cat_rows.append({"sync_id": cid, "boutique_id": btq_id, "name": cat_name, "color": cat_color, "created_at": start_at, "updated_at": now})
        for idx in range(target_per_cat):
            base_name, price, cost, unit = base_items[idx % len(base_items)]
            pname = base_name if idx < len(base_items) else f"{base_name} Format {idx + 1}"
            pid = str(uuid.uuid4())
            product_names[pid] = pname
            is_deleted = (idx == target_per_cat - 1) and len(prod_rows) > 3
            prod_rows.append({
                "sync_id": pid, "boutique_id": btq_id, "name": pname, "category_sync_id": cid,
                "price": float(price), "cost_price": float(cost), "average_cost_price": float(cost),
                "stock": 0.0, "min_stock": 8.0, "barcode": f"600{bp.code}{len(prod_rows):05d}",
                "unit": unit, "is_active": not is_deleted, "created_at": start_at, "updated_at": now,
                "deleted_at": (now - timedelta(days=90)) if is_deleted else None,
            })
            custom_prices: Dict[str, float] = {}
            avail_mags: set[str] = set()
            for m_idx, mid in enumerate(mag_ids):
                init_qty = float(rng.randint(35, 140))
                stock_qty[(mid, pid)] = init_qty
                stock_rows.append({"id": str(uuid.uuid4()), "boutique_id": btq_id, "magasin_id": mid, "product_sync_id": pid, "quantity": init_qty, "min_stock": 8.0, "cost_price": float(cost), "average_cost_price": float(cost), "last_updated_at": now})
                is_avail = not (m_idx > 0 and idx % 9 == 0)
                c_price = round(price * 1.08, 2) if (m_idx == 1 and idx % 4 == 0) else float(price)
                if is_avail:
                    avail_mags.add(mid)
                if c_price != float(price):
                    custom_prices[mid] = c_price
                avail_rows.append({"id": str(uuid.uuid4()), "boutique_id": btq_id, "magasin_id": mid, "product_sync_id": pid, "is_available": is_avail, "custom_price": c_price if c_price != float(price) else None, "created_at": start_at})
            if not is_deleted:
                prod_refs.append(ProductSeedRef(pid, pname, float(price), float(cost), custom_prices, avail_mags))

    cli_count = max(6, len(mag_ids) * 6 * int(scale_cfg["clients_mult"]))
    sup_count = max(3, 3 * int(scale_cfg["suppliers_mult"]))
    cli_rows, cli_ids, cli_bals = [], [], {}
    for i in range(cli_count):
        cid = str(uuid.uuid4())
        cname = f"{CLIENT_FIRST_NAMES[i % len(CLIENT_FIRST_NAMES)]} {CLIENT_LAST_NAMES[(i * 3) % len(CLIENT_LAST_NAMES)]} #{i + 1}"
        cli_ids.append((cid, cname))
        cli_bals[cid] = 0.0
        cli_rows.append({"sync_id": cid, "boutique_id": btq_id, "name": cname, "phone": f"+22177100{i:04d}", "balance": 0.0, "user_id": staff[0].id, "user_name": staff[0].full_name, "created_at": start_at, "updated_at": now})

    sup_rows, sup_ids, sup_bals = [], [], {}
    for i in range(sup_count):
        sid = str(uuid.uuid4())
        sname = f"{SUPPLIER_NAMES[i % len(SUPPLIER_NAMES)]} #{i + 1}"
        sup_ids.append((sid, sname))
        sup_bals[sid] = 0.0
        sup_rows.append({"sync_id": sid, "boutique_id": btq_id, "name": sname, "contact_person": staff[0].full_name, "balance": 0.0, "user_id": staff[0].id, "user_name": staff[0].full_name, "created_at": start_at, "updated_at": now})

    for tbl_name, rows in (("categories", cat_rows), ("products", prod_rows), ("stocks_magasin", stock_rows), ("product_magasin_availability", avail_rows), ("clients", cli_rows), ("suppliers", sup_rows)):
        counts[tbl_name] = counts.get(tbl_name, 0) + bulk_insert(conn, dialect, Base.metadata.tables[tbl_name], rows, boutique_id=btq_id)

    return BoutiqueSeedState(bp, btq_id, start_at, now, mag_ids, pos_ids or mag_ids, wh_ids, staff, prod_refs, cli_ids, sup_ids, cli_bals, sup_bals, stock_qty, product_names)
