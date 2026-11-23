from datetime import timedelta
from sqlalchemy.orm import Session
from app.core.security import get_password_hash, hash_pin
from app.models import (
    User,
    Category,
    Product,
    Client,
    Supplier,
    SaasPlan,
    SaasSubscription,
    Boutique,
    BoutiqueUserMembership,
    Magasin,
    StockMagasin,
    utc_now,
)


def seed_demo_data(db: Session) -> None:
    """Seed demo users, default boutique, initial magasin, and sample catalog once."""
    admin = db.query(User).filter(User.username == "admin").first()
    if not admin:
        admin = User(
            username="admin",
            email="admin@tocmanager.local",
            full_name="Super Administrateur Plateforme",
            hashed_password=get_password_hash("admin1234"),
            pin_hash=hash_pin("1234"),
            role="superadmin",
            permissions=["*"],
            is_active=True,
        )
        db.add(admin)
        db.flush()
    elif admin.role != "superadmin":
        admin.role = "superadmin"
        db.flush()

    commercant = db.query(User).filter(User.username == "commercant").first()
    if not commercant:
        commercant = User(
            username="commercant",
            email="commercant@tocmanager.local",
            full_name="Mamadou Diallo (Commerçant Démo)",
            hashed_password=get_password_hash("commercant1234"),
            pin_hash=hash_pin("1234"),
            role="merchant",
            permissions=["*"],
            is_active=True,
        )
        db.add(commercant)
        db.flush()

    cashier_user = db.query(User).filter(User.username == "caissier1").first()
    if not cashier_user:
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
        db.flush()

    default_btq = db.query(Boutique).first()
    if not default_btq:
        default_btq = Boutique(
            slug="boutique-principale",
            name="Boutique Principale",
            company_name="TocManager Démo SARL",
            currency="XOF",
            country="Sénégal",
            phone="+221 77 000 00 00",
            email="contact@tocmanager.local",
            owner_user_id=commercant.id,
            has_used_trial=True,
            is_active=True,
        )
        db.add(default_btq)
        db.flush()

        main_magasin = Magasin(
            boutique_id=default_btq.id,
            name="Magasin Principal",
            code="MAG-01",
            address="Plateau, Dakar",
            phone="+221 77 000 00 00",
            is_warehouse=False,
            is_active=True,
        )
        db.add(main_magasin)
        db.flush()

        db.add(BoutiqueUserMembership(
            boutique_id=default_btq.id,
            user_id=commercant.id,
            role="owner",
            assigned_magasin_ids=[main_magasin.id],
            is_active=True,
        ))
        db.add(BoutiqueUserMembership(
            boutique_id=default_btq.id,
            user_id=cashier_user.id,
            role="cashier",
            assigned_magasin_ids=[main_magasin.id],
            is_active=True,
        ))

        pro_plan = db.query(SaasPlan).filter(SaasPlan.code == "pro").first()
        if pro_plan:
            now = utc_now()
            db.add(SaasSubscription(
                boutique_id=default_btq.id,
                plan_id=pro_plan.id,
                status="trialing",
                billing_cycle="monthly",
                has_used_trial=True,
                trial_starts_at=now,
                trial_ends_at=now + timedelta(days=14),
            ))

        cat_boisson = Category(
            name="Boissons",
            boutique_id=default_btq.id,
            description="Jus, eaux et sodas",
            color="#2196F3",
            icon="local_drink",
        )
        cat_epicerie = Category(
            name="Épicerie",
            boutique_id=default_btq.id,
            description="Produits alimentaires secs",
            color="#4CAF50",
            icon="shopping_basket",
        )
        db.add_all([cat_boisson, cat_epicerie])
        db.flush()

        p1 = Product(
            name="Coca-Cola 33cl",
            boutique_id=default_btq.id,
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
            boutique_id=default_btq.id,
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
            boutique_id=default_btq.id,
            category_sync_id=cat_epicerie.sync_id,
            price=4500.0,
            cost_price=3800.0,
            average_cost_price=3800.0,
            stock=15.0,
            min_stock=3.0,
            unit="sac",
        )
        db.add_all([p1, p2, p3])
        db.flush()

        for prod in (p1, p2, p3):
            db.add(StockMagasin(
                boutique_id=default_btq.id,
                magasin_id=main_magasin.id,
                product_sync_id=prod.sync_id,
                quantity=prod.stock,
                min_stock=prod.min_stock,
                cost_price=prod.cost_price,
                average_cost_price=prod.average_cost_price,
            ))

        db.add_all([
            Client(name="Marcelle Konan", boutique_id=default_btq.id, phone="+229 97 00 00 01", balance=0.0),
            Client(name="Occasionnel", boutique_id=default_btq.id, balance=0.0),
        ])
        db.add(Supplier(
            name="SOBEBRA",
            boutique_id=default_btq.id,
            phone="+229 21 00 00 00",
            contact_person="Service Commercial",
        ))
    else:
        if default_btq.owner_user_id == admin.id:
            default_btq.owner_user_id = commercant.id
            db.query(BoutiqueUserMembership).filter(
                BoutiqueUserMembership.boutique_id == default_btq.id,
                BoutiqueUserMembership.user_id == admin.id,
            ).delete()
            db.flush()

        existing_comm_m = db.query(BoutiqueUserMembership).filter(
            BoutiqueUserMembership.boutique_id == default_btq.id,
            BoutiqueUserMembership.user_id == commercant.id,
        ).first()
        if not existing_comm_m:
            first_mag = db.query(Magasin).filter(Magasin.boutique_id == default_btq.id).first()
            db.add(BoutiqueUserMembership(
                boutique_id=default_btq.id,
                user_id=commercant.id,
                role="owner",
                assigned_magasin_ids=[first_mag.id] if first_mag else [],
                is_active=True,
            ))

    db.commit()
