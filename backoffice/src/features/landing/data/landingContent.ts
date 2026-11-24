export type ProductPillarId = 'pos' | 'multistore' | 'finance' | 'security';
export type ScreenshotPlatform = 'web' | 'mobile';
export type EcosystemStoreId = 'all' | 'plateau' | 'almadies' | 'entrepot';

export interface ProductPillar {
  id: ProductPillarId;
  tabLabel: string;
  eyebrow: string;
  title: string;
  description: string;
  highlights: string[];
  ctaLabel: string;
  ctaTo: string;
}

export interface ScreenshotItem {
  id: string;
  platform: ScreenshotPlatform;
  title: string;
  subtitle: string;
  badge: string;
  src: string;
  alt: string;
  highlights: string[];
}

export interface BentoCapability {
  id: string;
  title: string;
  description: string;
  metric: string;
  accent: 'cyan' | 'emerald' | 'purple' | 'amber';
  featured: boolean;
}

export interface OnboardingStep {
  step: string;
  title: string;
  duration: string;
  description: string;
}

export interface EcosystemStoreDemo {
  id: EcosystemStoreId;
  label: string;
  typeLabel: string;
  revenue: string;
  tickets: string;
  staff: string;
  stockStatus: string;
  syncStatus: string;
}

export const COMMERCE_SECTORS = [
  'Supérettes & Épiceries',
  'Prêt-à-porter & Mode',
  'Quincailleries & Matériaux',
  'Cosmétiques & Parapharmacies',
  'Électronique & Téléphonie',
  'Grossistes & Entrepôts',
] as const;

export const MOBILE_MONEY_NETWORKS = [
  'MTN MoMo',
  'Moov Money',
  'Wave',
  'Orange Money',
  'Celtiis',
  'Coris',
  'Free Money',
] as const;

export const FEEXPAY_COUNTRIES_LIST = [
  'Bénin',
  'Sénégal',
  "Côte d'Ivoire",
  'Togo',
  'Burkina Faso',
  'Mali',
  'Congo',
] as const;

export const HERO_METRICS = [
  { value: '100%', label: 'Fonctionnel hors-ligne (POS Mobile)' },
  { value: '< 3 sec', label: 'Par ticket de vente encaissé' },
  { value: '28', label: 'Droits, modules & quotas pilotables' },
  { value: '0 FCFA', label: 'Plan gratuit pour démarrer' },
] as const;

export const PRODUCT_PILLARS: ProductPillar[] = [
  {
    id: 'pos',
    tabLabel: 'Caisse POS Offline',
    eyebrow: 'Terminal Mobile Flutter + SQLite',
    title: 'Encaissez sans interruption, même en pleine coupure internet',
    description:
      'Chaque vente est enregistrée localement avec un identifiant UUID unique. Au retour du réseau, la synchronisation cloud pousse et consolide vos tickets sans jamais créer de doublon.',
    highlights: [
      'Catalogue rapide par catégorie et recherche code-barres',
      'File de synchronisation SQLite locale avec idempotence UUID',
      'Mode multi-paiements : espèces, Mobile Money et crédit client',
      'Tickets PDF et reçus personnalisés au nom de la boutique',
    ],
    ctaLabel: 'Tester le POS gratuitement',
    ctaTo: '/inscription?plan=pro',
  },
  {
    id: 'multistore',
    tabLabel: 'Multi-Magasins',
    eyebrow: 'Cloisonnement & Mode « Passer »',
    title: 'Pilotez un ou plusieurs points de vente depuis un cockpit unique',
    description:
      'Séparez les stocks, prix et équipes par magasin physique ou entrepôt, tout en gardant une vue financière consolidée sur l’ensemble de votre réseau.',
    highlights: [
      'Stocks cloisonnés et disponibilité paramétrable par magasin',
      'Transferts inter-magasins validés avec traçabilité complète',
      'Tarifs personnalisés par point de vente selon la zone',
      'Bascule instantanée entre magasin unique et vue consolidée',
    ],
    ctaLabel: 'Découvrir les forfaits multi-magasins',
    ctaTo: '/tarifs',
  },
  {
    id: 'finance',
    tabLabel: 'Finances & Clôture Z',
    eyebrow: 'Trésorerie, Marges P&L & Créances',
    title: 'Maîtrisez vos marges réelles et vos écarts de caisse chaque soir',
    description:
      'Suivez vos sessions de caisse Z, vos retours produits, les paiements clients à crédit, les dettes fournisseurs et le calcul automatique de marge nette.',
    highlights: [
      'Ouverture et clôture de caisse Z avec contrôle des écarts',
      'Calcul automatique du coût moyen pondéré (PAMP) à la réception',
      'Suivi des créances clients et échéanciers fournisseurs',
      'Exports Excel, CSV et PDF prêts pour votre comptabilité',
    ],
    ctaLabel: 'Activer 14 jours d’essai Pro',
    ctaTo: '/inscription?plan=pro',
  },
  {
    id: 'security',
    tabLabel: 'Sécurité & RBAC',
    eyebrow: 'Rôles, PIN Caissier & Journal d’Audit',
    title: 'Protégez votre caisse et tracez chaque action sensible',
    description:
      'Attribuez à chaque collaborateur un rôle précis, un périmètre magasin strict et un code PIN caisse dédié avec verrouillage automatique.',
    highlights: [
      'Rôles dédiés : Propriétaire, Gérant de magasin et Caissier',
      'Code PIN caisse à 4 ou 6 chiffres avec blocage anti-brute-force',
      'Journal d’audit détaillé (annulations, ajustements, transferts)',
      'Isolation stricte des données par entreprise (multi-tenant)',
    ],
    ctaLabel: 'Créer mon espace sécurisé',
    ctaTo: '/inscription',
  },
];

export const SCREENSHOT_ITEMS: ScreenshotItem[] = [
  {
    id: 'web-dashboard',
    platform: 'web',
    title: 'Tableau de bord Web consolidé',
    subtitle: 'Vue temps réel des ventes, valeur du stock, créances et alertes rupture sur tous vos magasins.',
    badge: 'Espace Web • Backoffice',
    src: '/assets/screenshots/web-dashboard.jpg',
    alt: "Capture d'écran du tableau de bord web TocManager affichant les indicateurs de ventes, stock et tickets récents",
    highlights: ['KPIs en direct par boutique/magasin', 'Graphique des ventes encaissées', 'Alertes de stock critique'],
  },
  {
    id: 'web-multistore',
    platform: 'web',
    title: 'Pilotage Multi-Magasins & Transferts',
    subtitle: 'Supervisez vos boutiques et votre entrepôt central, puis validez vos transferts de stock en quelques clics.',
    badge: 'Espace Web • Multi-Magasins',
    src: '/assets/screenshots/web-sales-multistore.jpg',
    alt: "Capture d'écran de l'espace web TocManager montrant les magasins actifs et le suivi des transferts de stock",
    highlights: ['Cloisonnement stocks par magasin', 'Suivi des transferts validés', 'Vue consolidée Mode Passer'],
  },
  {
    id: 'mobile-pos',
    platform: 'mobile',
    title: 'Caisse POS Mobile Offline-First',
    subtitle: 'Encaissez au comptoir ou en rayon même sans connexion : chaque ticket est sécurisé en file locale.',
    badge: 'App Mobile Flutter • POS',
    src: '/assets/screenshots/mobile-pos-offline.jpg',
    alt: "Capture d'écran de l'application mobile Flutter TocManager en mode caisse POS hors-ligne",
    highlights: ['Catalogue tactile ultra-rapide', 'File hors-ligne SQLite sécurisée', 'Encaissement en moins de 3 secondes'],
  },
  {
    id: 'mobile-dashboard',
    platform: 'mobile',
    title: 'Suivi Mobile & Sécurité PIN',
    subtitle: 'Consultez votre chiffre d’affaires du jour, le statut de caisse Z et verrouillez le terminal par code PIN.',
    badge: 'App Mobile Flutter • Pilotage',
    src: '/assets/screenshots/mobile-dashboard-pin.jpg',
    alt: "Capture d'écran du tableau de bord mobile TocManager avec indicateurs du jour et verrouillage PIN",
    highlights: ['Verrouillage PIN caissier 4/6 chiffres', 'État de synchronisation instantané', 'Résumé caisse & créances'],
  },
];
