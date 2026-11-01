import uuid
from datetime import datetime, timezone, timedelta
from app.core.database import engine, SessionLocal, Base
from app.core.security import get_password_hash, hash_pin
from app.models import (
    User, Category, Product, Client, Supplier,
    Vente, VenteItem, Approvisionnement, Decaissement, AuditLog
)

def run_seed():
    print("Initializing database tables...")
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()

    try:
        # Check if already seeded to avoid duplicates
        existing_users = db.query(User).count()
        if existing_users > 0:
            print(f"Database already contains {existing_users} users. Clearing previous sample data...")
            db.query(AuditLog).delete()
            db.query(VenteItem).delete()
            db.query(Vente).delete()
            db.query(Approvisionnement).delete()
            db.query(Decaissement).delete()
            db.query(Product).delete()
            db.query(Category).delete()
            db.query(Client).delete()
            db.query(Supplier).delete()
            db.query(User).delete()
            db.commit()

        print("Seeding Users & Roles...")
        now = datetime.now(timezone.utc)

        users = [
            User(
                id=str(uuid.uuid4()),
                username="admin",
                email="admin@tocmanager.com",
                full_name="Administrateur Central",
                hashed_password=get_password_hash("admin1234"),
                pin_hash=hash_pin("1234"),
                role="admin",
                permissions=["*"],
                is_active=True,
                created_at=now - timedelta(days=60),
            ),
            User(
                id=str(uuid.uuid4()),
                username="manager1",
                email="manager@tocmanager.com",
                full_name="Aïcha Gérante",
                hashed_password=get_password_hash("manager1234"),
                pin_hash=hash_pin("4321"),
                role="manager",
                permissions=["sales.*", "inventory.*", "reports.*", "users.view"],
                is_active=True,
                created_at=now - timedelta(days=45),
            ),
            User(
                id=str(uuid.uuid4()),
                username="caissier1",
                email="caissier1@tocmanager.com",
                full_name="Jean Caissier",
                hashed_password=get_password_hash("caisse1234"),
                pin_hash=hash_pin("0000"),
                role="cashier",
                permissions=["sales.create", "sales.view_own", "products.view_price"],
                is_active=True,
                created_at=now - timedelta(days=30),
            ),
            User(
                id=str(uuid.uuid4()),
                username="caissier2",
                email="caissier2@tocmanager.com",
                full_name="Koffi Vendeur",
                hashed_password=get_password_hash("caisse5678"),
                pin_hash=hash_pin("1111"),
                role="cashier",
                permissions=["sales.create", "sales.view_own", "products.view_price"],
                is_active=True,
                created_at=now - timedelta(days=20),
            ),
        ]
        db.add_all(users)
        db.flush()

        print("Seeding Categories...")
        categories = [
            Category(sync_id=str(uuid.uuid4()), name="Boissons & Eaux", description="Sodas, jus et eaux minérales", color="#1E88E5", icon="local_drink"),
            Category(sync_id=str(uuid.uuid4()), name="Épicerie & Féculents", description="Riz, pâtes, huiles et farines", color="#43A047", icon="shopping_basket"),
            Category(sync_id=str(uuid.uuid4()), name="Hygiène & Entretien", description="Savons, détergents et lessives", color="#00ACC1", icon="clean_hands"),
            Category(sync_id=str(uuid.uuid4()), name="Snacks & Confiserie", description="Biscuits, chocolats et chips", color="#FB8C00", icon="cookie"),
            Category(sync_id=str(uuid.uuid4()), name="Conserves & Sauces", description="Tomate pâte, sardines et assaisonnements", color="#E53935", icon="restaurant"),
        ]
        db.add_all(categories)
        db.flush()

        cat_boisson = categories[0]
        cat_epicerie = categories[1]
        cat_hygiene = categories[2]
        cat_snack = categories[3]
        cat_conserve = categories[4]

        print("Seeding Products...")
        products = [
            Product(sync_id=str(uuid.uuid4()), name="Eau Minérale Possotomé 1.5L", category_sync_id=cat_boisson.sync_id, price=400.0, cost_price=275.0, average_cost_price=275.0, stock=85.0, min_stock=15.0, unit="bouteille", barcode="615110001001"),
            Product(sync_id=str(uuid.uuid4()), name="Coca-Cola Canette 33cl", category_sync_id=cat_boisson.sync_id, price=500.0, cost_price=350.0, average_cost_price=350.0, stock=64.0, min_stock=20.0, unit="canette", barcode="615110001002"),
            Product(sync_id=str(uuid.uuid4()), name="Jus d'Ananas Naturel 1L", category_sync_id=cat_boisson.sync_id, price=1200.0, cost_price=850.0, average_cost_price=850.0, stock=22.0, min_stock=5.0, unit="bouteille", barcode="615110001003"),
            Product(sync_id=str(uuid.uuid4()), name="Malta Guinness 33cl", category_sync_id=cat_boisson.sync_id, price=600.0, cost_price=450.0, average_cost_price=450.0, stock=40.0, min_stock=10.0, unit="bouteille", barcode="615110001004"),

            Product(sync_id=str(uuid.uuid4()), name="Riz Parfumé Royal 5kg", category_sync_id=cat_epicerie.sync_id, price=4800.0, cost_price=4100.0, average_cost_price=4100.0, stock=35.0, min_stock=8.0, unit="sac", barcode="615110002001"),
            Product(sync_id=str(uuid.uuid4()), name="Pâtes Spaghetti Maman 500g", category_sync_id=cat_epicerie.sync_id, price=450.0, cost_price=325.0, average_cost_price=325.0, stock=110.0, min_stock=25.0, unit="paquet", barcode="615110002002"),
            Product(sync_id=str(uuid.uuid4()), name="Huile Végétale Mayor 1L", category_sync_id=cat_epicerie.sync_id, price=1300.0, cost_price=1050.0, average_cost_price=1050.0, stock=42.0, min_stock=10.0, unit="bouteille", barcode="615110002003"),
            Product(sync_id=str(uuid.uuid4()), name="Sucre Blanc Morceaux 1kg", category_sync_id=cat_epicerie.sync_id, price=900.0, cost_price=720.0, average_cost_price=720.0, stock=28.0, min_stock=5.0, unit="paquet", barcode="615110002004"),

            Product(sync_id=str(uuid.uuid4()), name="Savon Liquide Mains 500ml", category_sync_id=cat_hygiene.sync_id, price=1500.0, cost_price=1100.0, average_cost_price=1100.0, stock=18.0, min_stock=5.0, unit="flacon", barcode="615110003001"),
            Product(sync_id=str(uuid.uuid4()), name="Détergent Omo 400g", category_sync_id=cat_hygiene.sync_id, price=650.0, cost_price=500.0, average_cost_price=500.0, stock=50.0, min_stock=15.0, unit="sachet", barcode="615110003002"),
            Product(sync_id=str(uuid.uuid4()), name="Eau de Javel La Croix 1L", category_sync_id=cat_hygiene.sync_id, price=800.0, cost_price=600.0, average_cost_price=600.0, stock=3.0, min_stock=6.0, unit="bouteille", barcode="615110003003"), # Stock bas exprès pour alerte

            Product(sync_id=str(uuid.uuid4()), name="Biscuits Oreo Original 154g", category_sync_id=cat_snack.sync_id, price=750.0, cost_price=550.0, average_cost_price=550.0, stock=45.0, min_stock=10.0, unit="paquet", barcode="615110004001"),
            Product(sync_id=str(uuid.uuid4()), name="Chips Pringles Paprika 165g", category_sync_id=cat_snack.sync_id, price=1800.0, cost_price=1350.0, average_cost_price=1350.0, stock=20.0, min_stock=6.0, unit="boîte", barcode="615110004002"),

            Product(sync_id=str(uuid.uuid4()), name="Sardines à l'Huile Titus 125g", category_sync_id=cat_conserve.sync_id, price=550.0, cost_price=420.0, average_cost_price=420.0, stock=75.0, min_stock=20.0, unit="boîte", barcode="615110005001"),
            Product(sync_id=str(uuid.uuid4()), name="Tomate Pâte Gino 70g", category_sync_id=cat_conserve.sync_id, price=200.0, cost_price=140.0, average_cost_price=140.0, stock=150.0, min_stock=30.0, unit="sachet", barcode="615110005002"),
        ]
        db.add_all(products)
        db.flush()

        print("Seeding Clients...")
        clients = [
            Client(sync_id=str(uuid.uuid4()), name="Client Comptoir / Occasionnel", phone="", balance=0.0, notes="Client sans compte"),
            Client(sync_id=str(uuid.uuid4()), name="Marcelle Konan", phone="+229 97 12 34 56", balance=0.0, notes="Cliente régulière épicerie"),
            Client(sync_id=str(uuid.uuid4()), name="Superette de l'Étoile", phone="+229 96 11 22 33", balance=15000.0, notes="Client demi-gros, paiement à 7 jours"),
            Client(sync_id=str(uuid.uuid4()), name="Restaurant Le Palmier", phone="+229 95 44 55 66", balance=28000.0, notes="Livraison hebdomadaire"),
            Client(sync_id=str(uuid.uuid4()), name="David Mensah", phone="+229 90 77 88 99", balance=0.0, notes="Paiement Mobile Money systématique"),
        ]
        db.add_all(clients)
        db.flush()

        print("Seeding Suppliers...")
        suppliers = [
            Supplier(sync_id=str(uuid.uuid4()), name="SOBEBRA SA", phone="+229 21 33 00 11", contact_person="M. Tossou", email="commandes@sobebra.bj"),
            Supplier(sync_id=str(uuid.uuid4()), name="Les Grands Moulins du Bénin", phone="+229 21 32 44 55", contact_person="Mme Houeto", email="commercial@gmb.bj"),
            Supplier(sync_id=str(uuid.uuid4()), name="Distributeur Unilever Cotonou", phone="+229 21 30 77 88", contact_person="M. Alapini", email="distrib@unilever-bj.com"),
        ]
        db.add_all(suppliers)
        db.flush()

        print("Seeding Approvisionnements...")
        approvs = [
            Approvisionnement(
                sync_id=str(uuid.uuid4()),
                supplier_sync_id=suppliers[0].sync_id,
                supplier_name=suppliers[0].name,
                product_sync_id=products[0].sync_id,
                product_name=products[0].name,
                quantity=100.0,
                unit_cost=275.0,
                total_cost=27500.0,
                payment_status="Payé",
                date=now - timedelta(days=7),
            ),
            Approvisionnement(
                sync_id=str(uuid.uuid4()),
                supplier_sync_id=suppliers[1].sync_id,
                supplier_name=suppliers[1].name,
                product_sync_id=products[4].sync_id,
                product_name=products[4].name,
                quantity=40.0,
                unit_cost=4100.0,
                total_cost=164000.0,
                payment_status="Payé",
                date=now - timedelta(days=6),
            ),
            Approvisionnement(
                sync_id=str(uuid.uuid4()),
                supplier_sync_id=suppliers[2].sync_id,
                supplier_name=suppliers[2].name,
                product_sync_id=products[8].sync_id,
                product_name=products[8].name,
                quantity=25.0,
                unit_cost=1100.0,
                total_cost=27500.0,
                payment_status="Payé",
                date=now - timedelta(days=3),
            ),
        ]
        db.add_all(approvs)

        print("Seeding Décaissements (Dépenses)...")
        decaissements = [
            Decaissement(
                sync_id=str(uuid.uuid4()),
                title="Facture Électricité SBEE Boutique",
                amount=45000.0,
                category="Énergie",
                beneficiary="SBEE Cotonou",
                payment_method="Espèces",
                date=now - timedelta(days=10),
                notes="Facture du mois précédent",
            ),
            Decaissement(
                sync_id=str(uuid.uuid4()),
                title="Achat sachets et rouleaux de caisse thermique",
                amount=18500.0,
                category="Consommables",
                beneficiary="Papeterie Moderne",
                payment_method="Espèces",
                date=now - timedelta(days=5),
            ),
            Decaissement(
                sync_id=str(uuid.uuid4()),
                title="Entretien et vidange groupe électrogène",
                amount=25000.0,
                category="Entretien",
                beneficiary="Technicien Rufin",
                payment_method="Espèces",
                date=now - timedelta(days=3),
            ),
            Decaissement(
                sync_id=str(uuid.uuid4()),
                title="Abonnement Internet Fibre Optique",
                amount=22000.0,
                category="Télécoms",
                beneficiary="Moov Africa Bénin",
                payment_method="Mobile Money",
                date=now - timedelta(days=2),
            ),
            Decaissement(
                sync_id=str(uuid.uuid4()),
                title="Frais de transport livraison marchandises",
                amount=12000.0,
                category="Transport",
                beneficiary="Chauffeur Nestor",
                payment_method="Espèces",
                date=now - timedelta(days=1),
            ),
        ]
        db.add_all(decaissements)

        print("Seeding Ventes & VenteItems...")
        sample_sales_data = [
            {
                "days_ago": 4,
                "ticket": "TK-202611-001",
                "client": clients[0],
                "user": users[2],
                "payment": "Espèces",
                "items": [
                    (products[0], 3, 400.0),   # 1 200
                    (products[1], 2, 500.0),   # 1 000
                    (products[11], 2, 750.0),  # 1 500
                ]
            },
            {
                "days_ago": 3,
                "ticket": "TK-202611-002",
                "client": clients[1],
                "user": users[2],
                "payment": "Espèces",
                "items": [
                    (products[4], 1, 4800.0),  # 4 800
                    (products[6], 2, 1300.0),  # 2 600
                    (products[5], 4, 450.0),   # 1 800
                ]
            },
            {
                "days_ago": 3,
                "ticket": "TK-202611-003",
                "client": clients[4],
                "user": users[3],
                "payment": "Mobile Money",
                "items": [
                    (products[2], 2, 1200.0),  # 2 400
                    (products[12], 1, 1800.0), # 1 800
                ]
            },
            {
                "days_ago": 2,
                "ticket": "TK-202611-004",
                "client": clients[0],
                "user": users[2],
                "payment": "Espèces",
                "items": [
                    (products[3], 4, 600.0),   # 2 400
                    (products[13], 3, 550.0),  # 1 650
                    (products[14], 5, 200.0),  # 1 000
                ]
            },
            {
                "days_ago": 2,
                "ticket": "TK-202611-005",
                "client": clients[2],
                "user": users[1],
                "payment": "Chèque / Virement",
                "items": [
                    (products[4], 3, 4800.0),  # 14 400
                    (products[6], 6, 1300.0),  # 7 800
                    (products[0], 24, 380.0),  # 9 120 (tarif demi-gros)
                ]
            },
            {
                "days_ago": 1,
                "ticket": "TK-202611-006",
                "client": clients[0],
                "user": users[2],
                "payment": "Espèces",
                "items": [
                    (products[8], 1, 1500.0),  # 1 500
                    (products[9], 2, 650.0),   # 1 300
                    (products[10], 1, 800.0),  # 800
                ]
            },
            {
                "days_ago": 1,
                "ticket": "TK-202611-007",
                "client": clients[3],
                "user": users[2],
                "payment": "Espèces",
                "items": [
                    (products[0], 12, 400.0),  # 4 800
                    (products[1], 12, 500.0),  # 6 000
                    (products[7], 5, 900.0),   # 4 500
                ]
            },
            {
                "days_ago": 0,
                "ticket": "TK-202611-008",
                "client": clients[0],
                "user": users[2],
                "payment": "Espèces",
                "items": [
                    (products[1], 4, 500.0),   # 2 000
                    (products[11], 3, 750.0),  # 2 250
                ]
            },
            {
                "days_ago": 0,
                "ticket": "TK-202611-009",
                "client": clients[4],
                "user": users[3],
                "payment": "Mobile Money",
                "items": [
                    (products[4], 1, 4800.0),  # 4 800
                    (products[5], 2, 450.0),   # 900
                    (products[13], 2, 550.0),  # 1 100
                ]
            },
            {
                "days_ago": 0,
                "ticket": "TK-202611-010",
                "client": clients[0],
                "user": users[2],
                "payment": "Espèces",
                "items": [
                    (products[0], 6, 400.0),   # 2 400
                    (products[2], 1, 1200.0),  # 1 200
                    (products[3], 2, 600.0),   # 1 200
                ]
            },
        ]

        for s_data in sample_sales_data:
            s_time = now - timedelta(days=s_data["days_ago"], hours=2, minutes=15)
            vente_uuid = str(uuid.uuid4())
            total_amt = 0.0

            vente_items = []
            for prod, qty, price in s_data["items"]:
                line_total = qty * price
                total_amt += line_total
                vente_items.append(
                    VenteItem(
                        sync_id=str(uuid.uuid4()),
                        vente_sync_id=vente_uuid,
                        product_sync_id=prod.sync_id,
                        product_name=prod.name,
                        quantity=float(qty),
                        unit_price=float(price),
                        cost_price=float(prod.cost_price),
                        total=float(line_total),
                    )
                )

            vente = Vente(
                sync_id=vente_uuid,
                ticket_number=s_data["ticket"],
                client_sync_id=s_data["client"].sync_id,
                client_name=s_data["client"].name,
                user_id=s_data["user"].id,
                user_name=s_data["user"].full_name,
                total_amount=total_amt,
                paid_amount=total_amt,
                discount_amount=0.0,
                payment_method=s_data["payment"],
                notes="Vente enregistrée en caisse",
                created_at=s_time,
                updated_at=s_time,
            )
            db.add(vente)
            db.flush()
            for vi in vente_items:
                db.add(vi)

            # Audit log de la vente
            db.add(
                AuditLog(
                    id=str(uuid.uuid4()),
                    user_id=s_data["user"].id,
                    user_name=s_data["user"].full_name,
                    action="SALE_CREATE",
                    entity_type="vente",
                    entity_id=vente_uuid,
                    details={
                        "ticket_number": s_data["ticket"],
                        "total_amount": total_amt,
                        "client": s_data["client"].name,
                        "payment_method": s_data["payment"],
                    },
                    created_at=s_time,
                )
            )

        db.commit()
        print("✓ Database successfully seeded with all realistic data!")
        print("Summary:")
        print(f"  - Users: {db.query(User).count()}")
        print(f"  - Categories: {db.query(Category).count()}")
        print(f"  - Products: {db.query(Product).count()}")
        print(f"  - Clients: {db.query(Client).count()}")
        print(f"  - Suppliers: {db.query(Supplier).count()}")
        print(f"  - Ventes: {db.query(Vente).count()} (Articles: {db.query(VenteItem).count()})")
        print(f"  - Approvisionnements: {db.query(Approvisionnement).count()}")
        print(f"  - Décaissements: {db.query(Decaissement).count()}")

    except Exception as e:
        db.rollback()
        print(f"Error seeding database: {e}")
        raise
    finally:
        db.close()

if __name__ == "__main__":
    run_seed()
