from sqlalchemy import text
from sqlalchemy.orm import Session
from app.core.database import engine, Base
from app.core.security import get_password_hash, hash_pin
from app.models import User, Category, Product, Client, Supplier, AuditLog

def _migrate_columns() -> None:
    """Ajoute de façon non destructive les nouvelles colonnes si la table existe déjà."""
    with engine.connect() as conn:
        def add_col_if_missing(table: str, col: str, col_type: str):
            try:
                res = conn.execute(text(f"PRAGMA table_info({table})")).fetchall()
                existing = [r[1] for r in res]
                if existing and col not in existing:
                    conn.execute(text(f"ALTER TABLE {table} ADD COLUMN {col} {col_type}"))
                    conn.commit()
            except Exception:
                pass

        add_col_if_missing("clients", "user_id", "VARCHAR(36)")
        add_col_if_missing("clients", "user_name", "VARCHAR(255)")
        add_col_if_missing("suppliers", "user_id", "VARCHAR(36)")
        add_col_if_missing("suppliers", "user_name", "VARCHAR(255)")
        add_col_if_missing("ventes", "user_name", "VARCHAR(255)")
        add_col_if_missing("approvisionnements", "user_id", "VARCHAR(36)")
        add_col_if_missing("approvisionnements", "user_name", "VARCHAR(255)")
        add_col_if_missing("decaissements", "user_id", "VARCHAR(36)")
        add_col_if_missing("decaissements", "user_name", "VARCHAR(255)")

def init_db(db: Session) -> None:
    # Create all tables
    Base.metadata.create_all(bind=engine)
    _migrate_columns()

    # Check if admin user exists
    admin = db.query(User).filter(User.username == "admin").first()
    if not admin:
        admin_user = User(
            username="admin",
            email="admin@tocmanager.local",
            full_name="Administrateur TocManager",
            hashed_password=get_password_hash("admin1234"),
            pin_hash=hash_pin("1234"),
            role="admin",
            permissions=["*"],
            is_active=True,
        )
        db.add(admin_user)

        # Create a sample cashier
        cashier_user = User(
            username="caissier1",
            email="caissier1@tocmanager.local",
            full_name="Jean Caissier",
            hashed_password=get_password_hash("caisse1234"),
            pin_hash=hash_pin("0000"),
            role="cashier",
            permissions=["sales.create", "sales.view_own", "products.view_price", "clients.create"],
            is_active=True,
        )
        db.add(cashier_user)

        # Create sample categories
        cat_boisson = Category(name="Boissons", description="Jus, eaux et sodas", color="#2196F3", icon="local_drink")
        cat_epicerie = Category(name="Épicerie", description="Produits alimentaires secs", color="#4CAF50", icon="shopping_basket")
        db.add(cat_boisson)
        db.add(cat_epicerie)
        db.flush()

        # Create sample products
        p1 = Product(
            name="Coca-Cola 33cl",
            category_sync_id=cat_boisson.sync_id,
            price=500.0,
            cost_price=350.0,
            average_cost_price=350.0,
            stock=48.0,
            min_stock=10.0,
            unit="bouteille",
        )
        p2 = Product(
            name="Eau Minérale 1.5L",
            category_sync_id=cat_boisson.sync_id,
            price=400.0,
            cost_price=250.0,
            average_cost_price=250.0,
            stock=24.0,
            min_stock=6.0,
            unit="bouteille",
        )
        p3 = Product(
            name="Riz Parfumé 5kg",
            category_sync_id=cat_epicerie.sync_id,
            price=4500.0,
            cost_price=3800.0,
            average_cost_price=3800.0,
            stock=15.0,
            min_stock=3.0,
            unit="sac",
        )
        db.add_all([p1, p2, p3])

        # Create sample client
        cl1 = Client(name="Marcelle Konan", phone="+229 97 00 00 01", balance=0.0)
        cl_def = Client(name="Occasionnel", balance=0.0)
        db.add_all([cl1, cl_def])

        # Create sample supplier
        sup = Supplier(name="SOBEBRA", phone="+229 21 00 00 00", contact_person="Service Commercial")
        db.add(sup)

        db.commit()
