from dataclasses import dataclass
from typing import Dict, Tuple

DEMO_SLUG_PREFIX = "demo10y-"
DEMO_USER_PREFIX = "demo10y_"
DEMO_DEFAULT_PASSWORD = "Demo10y!2026"

SCALE_PRESETS: Dict[str, Dict[str, float]] = {
    "small": {"total_sales_target": 3200, "clients_mult": 1, "suppliers_mult": 1, "products_per_cat": 4, "movement_sample_rate": 0.50},
    "medium": {"total_sales_target": 20000, "clients_mult": 2, "suppliers_mult": 1, "products_per_cat": 7, "movement_sample_rate": 0.35},
    "stress": {"total_sales_target": 105000, "clients_mult": 4, "suppliers_mult": 2, "products_per_cat": 10, "movement_sample_rate": 0.25},
}

MONTH_SEASONALITY: Tuple[float, ...] = (0.88, 0.80, 0.94, 1.05, 1.00, 0.98, 1.03, 1.04, 0.90, 0.96, 1.14, 1.32)
PAYMENT_METHODS: Tuple[str, ...] = ("Espèces", "Mobile Money", "Wave", "Carte", "Crédit")
PAYMENT_WEIGHTS: Tuple[int, ...] = (46, 22, 16, 8, 8)
NETWORKS: Tuple[str, ...] = ("MTN", "MOOV", "ORANGE", "WAVE")
EXPENSE_CATEGORIES: Tuple[Tuple[str, str, float], ...] = (
    ("Loyer", "Loyer mensuel local commercial", 280000.0),
    ("Électricité & Eau", "Facture Senelec / CIE & Eau", 95000.0),
    ("Salaires", "Paie mensuelle équipe magasin", 420000.0),
    ("Logistique", "Transport et manutention livraisons", 65000.0),
    ("Maintenance", "Entretien climatisation et caisse", 35000.0),
)


@dataclass(frozen=True)
class StaffBlueprint:
    role_key: str
    role: str
    membership_role: str
    label: str
    pin: str
    is_active: bool = True
    magasin_index: int = 0


@dataclass(frozen=True)
class MagasinBlueprint:
    code: str
    name: str
    is_warehouse: bool = False


@dataclass(frozen=True)
class BoutiqueBlueprint:
    slug: str
    code: str
    name: str
    company_name: str
    sector: str
    plan_code: str
    sub_status: str
    currency: str
    country: str
    active_years: int
    sales_weight: float
    is_active: bool
    magasins: Tuple[MagasinBlueprint, ...]
    staff: Tuple[StaffBlueprint, ...]


BOUTIQUE_PROFILES: Tuple[BoutiqueBlueprint, ...] = (
    BoutiqueBlueprint(
        slug="demo10y-dakar-supermarche", code="DKR", name="Dakar Market Central",
        company_name="Dakar Distribution SARL", sector="retail", plan_code="enterprise",
        sub_status="active", currency="XOF", country="Sénégal", active_years=10,
        sales_weight=0.35, is_active=True,
        magasins=(
            MagasinBlueprint("DKR-PLT", "Point de Vente Plateau"),
            MagasinBlueprint("DKR-ALM", "Point de Vente Almadies"),
            MagasinBlueprint("DKR-PKN", "Entrepôt Pikine", is_warehouse=True),
        ),
        staff=(
            StaffBlueprint("owner", "merchant", "owner", "Ousmane Ndiaye", "1234"),
            StaffBlueprint("admin", "store_admin", "store_admin", "Awa Seck", "4321", magasin_index=0),
            StaffBlueprint("mgr", "manager", "manager", "Cheikh Fall", "567890", magasin_index=2),
            StaffBlueprint("c1", "cashier", "cashier", "Mariama Diallo", "1234", magasin_index=0),
            StaffBlueprint("c2", "cashier", "cashier", "Ibrahima Sarr", "4321", magasin_index=1),
            StaffBlueprint("c3_old", "cashier", "cashier", "Pape Gueye (Ancien)", "1234", is_active=False, magasin_index=0),
        ),
    ),
    BoutiqueBlueprint(
        slug="demo10y-abidjan-electro", code="ABJ", name="Abidjan Électro Pro",
        company_name="Électro Ivoire SA", sector="electronics", plan_code="pro",
        sub_status="active", currency="XOF", country="Côte d'Ivoire", active_years=10,
        sales_weight=0.25, is_active=True,
        magasins=(
            MagasinBlueprint("ABJ-COC", "Showroom Cocody"),
            MagasinBlueprint("ABJ-TRC", "Dépôt Treichville", is_warehouse=True),
        ),
        staff=(
            StaffBlueprint("owner", "merchant", "owner", "Kouadio Yao", "1234"),
            StaffBlueprint("admin", "store_admin", "store_admin", "Aminata Koné", "4321", magasin_index=0),
            StaffBlueprint("mgr", "manager", "manager", "Jean-Luc Bamba", "567890", magasin_index=1),
            StaffBlueprint("c1", "cashier", "cashier", "Fatoumata Coulibaly", "1234", magasin_index=0),
            StaffBlueprint("c2", "cashier", "cashier", "Serge Toure", "4321", magasin_index=0),
        ),
    ),
    BoutiqueBlueprint(
        slug="demo10y-cotonou-pharma", code="COO", name="Cotonou Para & Santé",
        company_name="Atlantique Santé SARL", sector="pharma", plan_code="pro",
        sub_status="active", currency="XOF", country="Bénin", active_years=8,
        sales_weight=0.18, is_active=True,
        magasins=(
            MagasinBlueprint("COO-GAN", "Boutique Ganhi"),
            MagasinBlueprint("COO-AKP", "Annexe Akpakpa"),
        ),
        staff=(
            StaffBlueprint("owner", "merchant", "owner", "Sènan Houngbédji", "1234"),
            StaffBlueprint("admin", "store_admin", "store_admin", "Nadine Dossou", "4321", magasin_index=0),
            StaffBlueprint("c1", "cashier", "cashier", "Brice Agossa", "1234", magasin_index=0),
            StaffBlueprint("c2", "cashier", "cashier", "Clarisse Zinsou", "4321", magasin_index=1),
        ),
    ),
    BoutiqueBlueprint(
        slug="demo10y-douala-quincaillerie", code="DLA", name="Douala Bâti Matériaux",
        company_name="Wouri Négoce SAS", sector="hardware", plan_code="enterprise",
        sub_status="trialing", currency="XAF", country="Cameroun", active_years=6,
        sales_weight=0.12, is_active=True,
        magasins=(
            MagasinBlueprint("DLA-AKW", "Agence Akwa"),
            MagasinBlueprint("DLA-BON", "Dépôt Bonabéri", is_warehouse=True),
        ),
        staff=(
            StaffBlueprint("owner", "merchant", "owner", "Alain Mbarga", "1234"),
            StaffBlueprint("mgr", "manager", "manager", "Chantal Fotso", "567890", magasin_index=1),
            StaffBlueprint("c1", "cashier", "cashier", "Eric Ndongo", "1234", magasin_index=0),
            StaffBlueprint("c2_old", "cashier", "cashier", "Paul Kamga (Ancien)", "1234", is_active=False, magasin_index=0),
        ),
    ),
    BoutiqueBlueprint(
        slug="demo10y-lome-mode", code="LFW", name="Lomé Wax & Mode",
        company_name="Togo Création", sector="fashion", plan_code="free",
        sub_status="active", currency="XOF", country="Togo", active_years=5,
        sales_weight=0.07, is_active=True,
        magasins=(MagasinBlueprint("LFW-CTR", "Boutique Grand Marché"),),
        staff=(
            StaffBlueprint("owner", "merchant", "owner", "Kofi Mensah", "1234"),
            StaffBlueprint("c1", "cashier", "cashier", "Afi Lawson", "1234", magasin_index=0),
        ),
    ),
    BoutiqueBlueprint(
        slug="demo10y-paris-import", code="PAR", name="Paris Afro Épicerie",
        company_name="Château Rouge Import SASU", sector="retail", plan_code="pro",
        sub_status="past_due", currency="EUR", country="France", active_years=3,
        sales_weight=0.03, is_active=False,
        magasins=(MagasinBlueprint("PAR-GDR", "Magasin Goutte d'Or"),),
        staff=(
            StaffBlueprint("owner", "merchant", "owner", "Moussa Traoré", "1234"),
            StaffBlueprint("c1", "cashier", "cashier", "Claire Martin", "4321", magasin_index=0),
        ),
    ),
)

SECTOR_CATALOGS: Dict[str, Tuple[Tuple[str, str, Tuple[Tuple[str, float, float, str], ...]], ...]] = {
    "retail": (
        ("Épicerie", "#29ABE2", (("Riz Parfumé 25kg", 14500, 12100, "sac"), ("Huile Végétale 5L", 6500, 5200, "bidon"), ("Sucre Cristal 1kg", 850, 650, "paquet"), ("Farine Boulangère", 700, 510, "kg"))),
        ("Boissons", "#16A34A", (("Jus Bissap 1L", 1200, 750, "bouteille"), ("Eau Minérale Pack 6", 2400, 1700, "pack"), ("Café Soluble 200g", 3900, 2900, "pot"), ("Thé Vert Menthe", 1100, 750, "boîte"))),
        ("Hygiène", "#F59E0B", (("Savon Marseille", 600, 380, "pièce"), ("Lessive Poudre 1kg", 1800, 1300, "sachet"), ("Dentifrice Fraîcheur", 950, 620, "tube"))),
    ),
    "electronics": (
        ("Téléphonie", "#2563EB", (("Smartphone 128Go", 115000, 92000, "pièce"), ("Écouteurs Bluetooth", 14500, 8800, "pièce"), ("Chargeur Rapide USB-C", 8500, 4800, "pièce"), ("Verre Trempé Pro", 3500, 1100, "pièce"))),
        ("Accessoires & Énergie", "#7C3AED", (("Batterie Externe 20000mAh", 22000, 15000, "pièce"), ("Multiprise Parafoudre", 9500, 6200, "pièce"), ("Câble HDMI 3m", 4500, 2200, "pièce"))),
        ("Informatique", "#0891B2", (("Clé USB 64Go", 6500, 3800, "pièce"), ("Souris Sans Fil", 8500, 5100, "pièce"), ("Routeur 4G Portable", 38000, 29000, "pièce"))),
    ),
    "pharma": (
        ("Parapharmacie", "#10B981", (("Gel Hydroalcoolique 250ml", 1800, 1050, "flacon"), ("Pansements Assortis", 1500, 800, "boîte"), ("Vitamine C 1000mg", 4200, 2700, "boîte"))),
        ("Soins & Bébé", "#EC4899", (("Crème Hydratante 400ml", 6800, 4600, "flacon"), ("Couches Bébé Pack 44", 7500, 5400, "pack"), ("Thermomètre Digital", 5500, 3200, "pièce"))),
    ),
    "hardware": (
        ("Gros Œuvre", "#EA580C", (("Ciment CPJ 45 50kg", 4800, 4100, "sac"), ("Fer à Béton 10mm", 4500, 3750, "barre"), ("Peinture Acrylique 20L", 34000, 26500, "seau"))),
        ("Outillage", "#475569", (("Disqueuse 125mm", 32000, 23500, "pièce"), ("Jeu Clés Plates 12p", 16500, 11200, "coffret"), ("Mètre Ruban 8m", 2500, 1400, "pièce"))),
    ),
    "fashion": (
        ("Tissus & Prêt-à-porter", "#DB2777", (("Pagne Wax 6 Yards", 28000, 20000, "pièce"), ("Chemise Lin Premium", 19500, 12500, "pièce"), ("Robe Cérémonie", 35000, 23000, "pièce"))),
        ("Chaussures & Sacs", "#9333EA", (("Sandales Cuir Artisanales", 15000, 9500, "paire"), ("Sac Cabas Cuir", 26000, 17500, "pièce"), ("Ceinture Cuir Tressé", 7500, 4200, "pièce"))),
    ),
}

CLIENT_FIRST_NAMES: Tuple[str, ...] = ("Fatou", "Moussa", "Aïssatou", "Kofi", "Aminata", "Yao", "Nadine", "Chantal", "Sébastien", "Claire")
CLIENT_LAST_NAMES: Tuple[str, ...] = ("Ndiaye", "Diop", "Kouassi", "Traoré", "Sow", "Mensah", "Mbarga", "Toure", "Faye", "Koné")
SUPPLIER_NAMES: Tuple[str, ...] = ("Sénégal Import Export", "CFAO Distribution", "Grandes Brasseries", "Prosuma Négoce", "Afrique Logistique", "EuroMed Trading")
