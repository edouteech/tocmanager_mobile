import argparse
from typing import Dict, Optional
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.core.database import SessionLocal
from app.models import Boutique

TENANT_DIRECT_TABLES = (
    "categories",
    "products",
    "clients",
    "suppliers",
    "ventes",
    "approvisionnements",
    "decaissements",
    "magasins",
)


def _resolve_target_boutique_id(db: Session, default_boutique_id: Optional[str]) -> Optional[str]:
    if default_boutique_id:
        row = db.query(Boutique).filter(Boutique.id == default_boutique_id).first()
        if not row:
            raise ValueError(f"Boutique {default_boutique_id} introuvable")
        return row.id
    first = db.query(Boutique).first()
    return first.id if first else None


def run_backfill(
    db: Session,
    default_boutique_id: Optional[str] = None,
    dry_run: bool = False,
) -> Dict[str, int]:
    """Populate NULL boutique_id rows from magasin relations or a default boutique."""
    target_id = _resolve_target_boutique_id(db, default_boutique_id)
    results: Dict[str, int] = {}

    for table in ("stocks_magasin", "product_magasin_availability"):
        count = db.execute(
            text(f"SELECT COUNT(*) FROM {table} WHERE boutique_id IS NULL")
        ).scalar() or 0
        results[table] = int(count)
        if count > 0 and not dry_run:
            db.execute(
                text(
                    f"UPDATE {table} SET boutique_id = ("
                    f"SELECT magasins.boutique_id FROM magasins "
                    f"WHERE magasins.id = {table}.magasin_id) "
                    f"WHERE boutique_id IS NULL"
                )
            )

    for table in TENANT_DIRECT_TABLES:
        count = db.execute(
            text(f"SELECT COUNT(*) FROM {table} WHERE boutique_id IS NULL")
        ).scalar() or 0
        results[table] = int(count)
        if count > 0 and not dry_run:
            if not target_id:
                raise ValueError(f"Cannot backfill {table}: no default boutique exists")
            db.execute(
                text(f"UPDATE {table} SET boutique_id = :bid WHERE boutique_id IS NULL"),
                {"bid": target_id},
            )

    if not dry_run:
        db.commit()
    return results


def main() -> None:
    parser = argparse.ArgumentParser(description="Backfill NULL boutique_id tenant columns")
    parser.add_argument("--dry-run", action="store_true", help="Count rows without mutating data")
    parser.add_argument("--default-boutique-id", default=None, help="Fallback boutique ID")
    args = parser.parse_args()

    db = SessionLocal()
    try:
        report = run_backfill(db, default_boutique_id=args.default_boutique_id, dry_run=args.dry_run)
        print(report)
    finally:
        db.close()


if __name__ == "__main__":
    main()
