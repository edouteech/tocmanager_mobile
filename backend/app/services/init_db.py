from sqlalchemy import text
from sqlalchemy.orm import Session
from app.core.database import engine, Base
from app.core.security import get_password_hash, hash_pin
from app.models import (
    User, Category, Product, Client, Supplier, AuditLog,
    SaasPlan, SaasPlanFeature, SaasSubscription, Boutique, BoutiqueUserMembership, Magasin
)

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

        # Colonnes d'audit & utilisateurs
        add_col_if_missing("clients", "user_id", "VARCHAR(36)")
        add_col_if_missing("clients", "user_name", "VARCHAR(255)")
        add_col_if_missing("suppliers", "user_id", "VARCHAR(36)")
        add_col_if_missing("suppliers", "user_name", "VARCHAR(255)")
        add_col_if_missing("ventes", "user_name", "VARCHAR(255)")
        add_col_if_missing("approvisionnements", "user_id", "VARCHAR(36)")
        add_col_if_missing("approvisionnements", "user_name", "VARCHAR(255)")
        add_col_if_missing("decaissements", "user_id", "VARCHAR(36)")
        add_col_if_missing("decaissements", "user_name", "VARCHAR(255)")

        # Colonnes Multi-Tenant (Boutique & Magasins)
        add_col_if_missing("categories", "boutique_id", "VARCHAR(36)")
        add_col_if_missing("products", "boutique_id", "VARCHAR(36)")
        add_col_if_missing("clients", "boutique_id", "VARCHAR(36)")
        add_col_if_missing("suppliers", "boutique_id", "VARCHAR(36)")
        add_col_if_missing("ventes", "boutique_id", "VARCHAR(36)")
        add_col_if_missing("ventes", "magasin_id", "VARCHAR(36)")
        add_col_if_missing("approvisionnements", "boutique_id", "VARCHAR(36)")
        add_col_if_missing("approvisionnements", "magasin_id", "VARCHAR(36)")
        add_col_if_missing("decaissements", "boutique_id", "VARCHAR(36)")
        add_col_if_missing("decaissements", "magasin_id", "VARCHAR(36)")
        add_col_if_missing("audit_logs", "boutique_id", "VARCHAR(36)")
        add_col_if_missing("sync_events", "boutique_id", "VARCHAR(36)")
        add_col_if_missing("sync_events", "magasin_id", "VARCHAR(36)")

def seed_saas_plans(db: Session) -> None:
    """Initialise les forfaits SaaS par défaut si absents."""
    plan_free = db.query(SaasPlan).filter(SaasPlan.code == "free").first()
    if not plan_free:
        plan_free = SaasPlan(
            name="Plan Gratuit",
            code="free",
            description="Idéal pour démarrer avec un point de vente unique",
            price_monthly=0.0,
            price_yearly=0.0,
            currency="XOF",
            trial_period_days=0,
            badge="GRATUIT",
            is_active=True,
        )
        db.add(plan_free)
        db.flush()

        features_free = [
            SaasPlanFeature(plan_id=plan_free.id, feature_code="max_magasins", feature_name="Nombre de magasins", value_type="limit_number", int_limit=1),
            SaasPlanFeature(plan_id=plan_free.id, feature_code="max_products", feature_name="Articles catalogue", value_type="limit_number", int_limit=100),
            SaasPlanFeature(plan_id=plan_free.id, feature_code="max_users", feature_name="Comptes collaborateurs", value_type="limit_number", int_limit=2),
            SaasPlanFeature(plan_id=plan_free.id, feature_code="stock_transfers", feature_name="Transferts de stock inter-magasins", value_type="boolean", boolean_value=False),
            SaasPlanFeature(plan_id=plan_free.id, feature_code="pnl_reports", feature_name="Rapports financiers P&L avancés", value_type="boolean", boolean_value=False),
            SaasPlanFeature(plan_id=plan_free.id, feature_code="data_exports", feature_name="Exports comptables PDF/Excel", value_type="boolean", boolean_value=False),
            SaasPlanFeature(plan_id=plan_free.id, feature_code="custom_branding", feature_name="Personnalisation tickets de caisse", value_type="boolean", boolean_value=False),
        ]
        db.add_all(features_free)

    plan_pro = db.query(SaasPlan).filter(SaasPlan.code == "pro").first()
    if not plan_pro:
        plan_pro = SaasPlan(
            name="Plan Pro",
            code="pro",
            description="Pour les commerces en croissance et réseaux de boutiques",
            price_monthly=15000.0,
            price_yearly=150000.0,
            currency="XOF",
            trial_period_days=14,
            badge="POPULAIRE",
            is_active=True,
        )
        db.add(plan_pro)
        db.flush()

        features_pro = [
            SaasPlanFeature(plan_id=plan_pro.id, feature_code="max_magasins", feature_name="Nombre de magasins", value_type="limit_number", int_limit=5),
            SaasPlanFeature(plan_id=plan_pro.id, feature_code="max_products", feature_name="Articles catalogue", value_type="limit_number", int_limit=2000),
            SaasPlanFeature(plan_id=plan_pro.id, feature_code="max_users", feature_name="Comptes collaborateurs", value_type="limit_number", int_limit=10),
            SaasPlanFeature(plan_id=plan_pro.id, feature_code="stock_transfers", feature_name="Transferts de stock inter-magasins", value_type="boolean", boolean_value=True),
            SaasPlanFeature(plan_id=plan_pro.id, feature_code="pnl_reports", feature_name="Rapports financiers P&L avancés", value_type="boolean", boolean_value=True),
            SaasPlanFeature(plan_id=plan_pro.id, feature_code="data_exports", feature_name="Exports comptables PDF/Excel", value_type="boolean", boolean_value=True),
            SaasPlanFeature(plan_id=plan_pro.id, feature_code="custom_branding", feature_name="Personnalisation tickets de caisse", value_type="boolean", boolean_value=True),
        ]
        db.add_all(features_pro)

    plan_ent = db.query(SaasPlan).filter(SaasPlan.code == "enterprise").first()
    if not plan_ent:
        plan_ent = SaasPlan(
            name="Plan Entreprise",
            code="enterprise",
            description="Solution complète et illimitée pour grands réseaux commerciaux",
            price_monthly=40000.0,
            price_yearly=400000.0,
            currency="XOF",
            trial_period_days=14,
            badge="ILLIMITÉ",
            is_active=True,
        )
        db.add(plan_ent)
        db.flush()

        features_ent = [
            SaasPlanFeature(plan_id=plan_ent.id, feature_code="max_magasins", feature_name="Nombre de magasins", value_type="limit_number", int_limit=-1),
            SaasPlanFeature(plan_id=plan_ent.id, feature_code="max_products", feature_name="Articles catalogue", value_type="limit_number", int_limit=-1),
            SaasPlanFeature(plan_id=plan_ent.id, feature_code="max_users", feature_name="Comptes collaborateurs", value_type="limit_number", int_limit=-1),
            SaasPlanFeature(plan_id=plan_ent.id, feature_code="stock_transfers", feature_name="Transferts de stock inter-magasins", value_type="boolean", boolean_value=True),
            SaasPlanFeature(plan_id=plan_ent.id, feature_code="pnl_reports", feature_name="Rapports financiers P&L avancés", value_type="boolean", boolean_value=True),
            SaasPlanFeature(plan_id=plan_ent.id, feature_code="data_exports", feature_name="Exports comptables PDF/Excel", value_type="boolean", boolean_value=True),
            SaasPlanFeature(plan_id=plan_ent.id, feature_code="custom_branding", feature_name="Personnalisation tickets de caisse", value_type="boolean", boolean_value=True),
        ]
        db.add_all(features_ent)

    db.commit()

def init_db(db: Session) -> None:
    # 1. Migration des colonnes manquantes
    _migrate_columns()
    
    # 2. Création de toutes les tables si absentes
    Base.metadata.create_all(bind=engine)
    
    # 3. Seed des forfaits SaaS
    seed_saas_plans(db)

    # 4. Compte Super-Administrateur Plateforme (Gestionnaire SaaS pur, pas de boutique client)
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
    else:
        if admin.role != "superadmin":
            admin.role = "superadmin"
            db.commit()

    # Compte Client / Commerçant Démo (Propriétaire de boutique)
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

    # Utilisateur caissier exemple
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

    # 5. Création de la boutique par défaut rattachée au commerçant
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
            is_active=True,
        )
        db.add(default_btq)
        db.flush()

        # Magasin principal
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

        # Membership commerçant (owner)
        membership_commercant = BoutiqueUserMembership(
            boutique_id=default_btq.id,
            user_id=commercant.id,
            role="owner",
            assigned_magasin_ids=[main_magasin.id],
            is_active=True,
        )
        db.add(membership_commercant)

        # Membership caissier
        membership_cashier = BoutiqueUserMembership(
            boutique_id=default_btq.id,
            user_id=cashier_user.id,
            role="cashier",
            assigned_magasin_ids=[main_magasin.id],
            is_active=True,
        )
        db.add(membership_cashier)
    else:
        # S'assurer que le propriétaire de la boutique est le commerçant et non l'admin de plateforme
        if default_btq.owner_user_id == admin.id:
            default_btq.owner_user_id = commercant.id
            db.query(BoutiqueUserMembership).filter(
                BoutiqueUserMembership.boutique_id == default_btq.id,
                BoutiqueUserMembership.user_id == admin.id
            ).delete()
            db.commit()

        # S'assurer que le commercant a son membership
        existing_comm_m = db.query(BoutiqueUserMembership).filter(
            BoutiqueUserMembership.boutique_id == default_btq.id,
            BoutiqueUserMembership.user_id == commercant.id
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

        # Abonnement initial Pro en période d'essai
        pro_plan = db.query(SaasPlan).filter(SaasPlan.code == "pro").first()
        if pro_plan:
            sub = SaasSubscription(
                boutique_id=default_btq.id,
                plan_id=pro_plan.id,
                status="trialing",
                billing_cycle="monthly",
            )
            db.add(sub)

        # Création des catégories démo
        cat_boisson = Category(name="Boissons", boutique_id=default_btq.id, description="Jus, eaux et sodas", color="#2196F3", icon="local_drink")
        cat_epicerie = Category(name="Épicerie", boutique_id=default_btq.id, description="Produits alimentaires secs", color="#4CAF50", icon="shopping_basket")
        db.add(cat_boisson)
        db.add(cat_epicerie)
        db.flush()

        # Produits démo
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

        # Clients démo
        cl1 = Client(name="Marcelle Konan", boutique_id=default_btq.id, phone="+229 97 00 00 01", balance=0.0)
        cl_def = Client(name="Occasionnel", boutique_id=default_btq.id, balance=0.0)
        db.add_all([cl1, cl_def])

        # Fournisseur démo
        sup = Supplier(name="SOBEBRA", boutique_id=default_btq.id, phone="+229 21 00 00 00", contact_person="Service Commercial")
        db.add(sup)

    db.commit()
