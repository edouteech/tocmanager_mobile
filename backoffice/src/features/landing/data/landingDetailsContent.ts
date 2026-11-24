import type {
  BentoCapability,
  EcosystemStoreDemo,
  OnboardingStep,
} from './landingContent';

export interface MerchantUseCase {
  id: string;
  sector: string;
  profile: string;
  challenge: string;
  modules: string[];
  outcome: string;
}

export interface FaqItem {
  id: string;
  question: string;
  answer: string;
}

export const BENTO_CAPABILITIES: BentoCapability[] = [
  {
    id: 'sync-uuid',
    title: 'Synchronisation idempotente UUID',
    description:
      'Chaque opération hors-ligne possède une signature unique : même en cas de réseau instable ou de renvois multiples, aucune vente n’est dupliquée.',
    metric: '0 doublon garanti',
    accent: 'cyan',
    featured: true,
  },
  {
    id: 'pamp-alerts',
    title: 'Alertes rupture & calcul PAMP',
    description:
      'Recevez une alerte dès qu’un article passe sous son seuil critique et valorisez votre stock au coût moyen pondéré à chaque approvisionnement.',
    metric: 'Marge réelle calculée',
    accent: 'emerald',
    featured: true,
  },
  {
    id: 'credits',
    title: 'Ventes à crédit & créances',
    description:
      'Suivez les encours clients et règlements fournisseurs avec historique de paiements et fiches imprimables.',
    metric: 'Encours maîtrisés',
    accent: 'amber',
    featured: false,
  },
  {
    id: 'cash-z',
    title: 'Clôture Z & retours produits',
    description:
      'Ouvrez et clôturez chaque session de caisse, contrôlez le fond de caisse et traitez les avoirs avec remise en stock.',
    metric: 'Contrôle fin de journée',
    accent: 'purple',
    featured: false,
  },
  {
    id: 'currencies',
    title: 'Multi-devises natif',
    description:
      'Exploitez vos boutiques en XOF, XAF, EUR ou USD avec paramétrage adapté à votre pays et votre réseau.',
    metric: 'XOF • XAF • EUR • USD',
    accent: 'cyan',
    featured: false,
  },
  {
    id: 'exports',
    title: 'Exports Excel, CSV & PDF',
    description:
      'Générez en un clic vos journaux de ventes, mouvements de stock, rapports P&L et factures SaaS.',
    metric: 'Prêt pour le comptable',
    accent: 'emerald',
    featured: false,
  },
];

export const ONBOARDING_STEPS: OnboardingStep[] = [
  {
    step: '01',
    title: 'Créez votre compte gérant',
    duration: '30 secondes',
    description:
      'Renseignez votre nom, votre email ou identifiant et votre mot de passe. Aucune carte bancaire demandée.',
  },
  {
    step: '02',
    title: 'Configurez votre boutique et devise',
    duration: '1 minute',
    description:
      'Choisissez le nom de votre enseigne, votre devise (FCFA, EUR, USD), votre 1er magasin et démarrez en Gratuit ou Essai Pro 14 jours.',
  },
  {
    step: '03',
    title: 'Encaissez sur mobile et pilotez sur le web',
    duration: 'Immédiat',
    description:
      'Importez vos premiers articles, affectez vos caissiers avec code PIN et suivez chaque vente en temps réel.',
  },
];

export const ECOSYSTEM_STORES: EcosystemStoreDemo[] = [
  {
    id: 'all',
    label: 'Vue consolidée (Mode Passer)',
    typeLabel: '3 points de vente connectés',
    revenue: '795 000 FCFA',
    tickets: '231 ventes aujourd’hui',
    staff: '4 collaborateurs actifs',
    stockStatus: '248 références • 3 alertes seuil',
    syncStatus: 'Cloud synchronisé il y a 12s',
  },
  {
    id: 'plateau',
    label: 'Point de Vente Plateau',
    typeLabel: 'Boutique principale',
    revenue: '485 000 FCFA',
    tickets: '142 ventes aujourd’hui',
    staff: '2 caissiers (PIN actif)',
    stockStatus: '184 références • 1 alerte seuil',
    syncStatus: '2 terminaux Android en ligne',
  },
  {
    id: 'almadies',
    label: 'Magasin Almadies',
    typeLabel: 'Succursale détail',
    revenue: '310 000 FCFA',
    tickets: '89 ventes aujourd’hui',
    staff: '1 gérant + 1 caissier',
    stockStatus: '146 références • Stock sain',
    syncStatus: 'Sync offline automatique active',
  },
  {
    id: 'entrepot',
    label: 'Entrepôt Central',
    typeLabel: 'Réserve & réapprovisionnement',
    revenue: 'Stock uniquement',
    tickets: '2 transferts validés ce matin',
    staff: '1 gestionnaire de stock',
    stockStatus: '6 420 unités en réserve',
    syncStatus: 'Réceptions PAMP à jour',
  },
];

export const MERCHANT_USE_CASES: MerchantUseCase[] = [
  {
    id: 'superette',
    sector: 'Supérette & Épicerie de proximité',
    profile: '1 point de vente • 2 caissiers en rotation',
    challenge:
      'Éviter les blocages en caisse lors des coupures internet et suivre les produits proches de la rupture.',
    modules: ['POS Mobile Offline', 'Code PIN Caissier', 'Alertes Stock'],
    outcome:
      'Encaissement continu sans perte de ticket et réassorts déclenchés avant la rupture rayon.',
  },
  {
    id: 'retail-chain',
    sector: 'Réseau Prêt-à-porter & Cosmétiques',
    profile: '2 à 5 boutiques • Équipe vendeurs & gérants',
    challenge:
      'Centraliser le chiffre d’affaires de chaque succursale tout en gardant des stocks et prix distincts.',
    modules: ['Multi-Magasins', 'Mode Passer', 'Clôture de caisse Z'],
    outcome:
      'Contrôle des écarts de caisse chaque soir et visibilité consolidée depuis le backoffice web.',
  },
  {
    id: 'wholesaler',
    sector: 'Grossiste & Dépôt de distribution',
    profile: 'Entrepôt central + points de vente + crédits clients',
    challenge:
      'Orchestrer les transferts vers les magasins, suivre les créances clients et connaître la marge nette réelle.',
    modules: ['Transferts de stock', 'Crédits & Créances', 'Rapports P&L'],
    outcome:
      'Transferts validés unité par unité et recouvrement structuré des comptes clients.',
  },
];

export const FAQ_ITEMS: FaqItem[] = [
  {
    id: 'offline',
    question: 'Que se passe-t-il si la connexion internet est coupée en pleine journée ?',
    answer:
      'L’application mobile TocManager stocke votre catalogue et vos tickets localement dans SQLite. Vos caissiers continuent d’encaisser normalement ; dès que la connexion revient, les ventes sont envoyées avec leur identifiant UUID unique sans aucun doublon.',
  },
  {
    id: 'trial',
    question: 'Faut-il une carte bancaire pour démarrer le Plan Gratuit ou l’essai Pro ?',
    answer:
      'Non. L’inscription s’effectue sans carte bancaire. Vous choisissez librement le Plan Gratuit permanent ou les 14 jours d’essai gratuit du Plan Pro ou Entreprise directement à l’étape 2.',
  },
  {
    id: 'payments',
    question: 'Comment payer ou renouveler mon abonnement SaaS ?',
    answer:
      'Les abonnements mensuels et annuels (avec 2 mois offerts) se règlent directement depuis votre espace client par Mobile Money via FeexPay : MTN MoMo, Moov Money, Wave, Orange Money, Celtiis, Coris ou Free Money dans 7 pays.',
  },
  {
    id: 'multistore',
    question: 'Puis-je gérer plusieurs boutiques et plusieurs magasins séparément ?',
    answer:
      'Oui. Un propriétaire peut piloter plusieurs boutiques (entreprises distinctes) et plusieurs magasins ou entrepôts au sein de chaque boutique, avec stocks séparés, transferts inter-magasins et vue consolidée en 1 clic.',
  },
  {
    id: 'hardware',
    question: 'Quel matériel est nécessaire pour utiliser TocManager ?',
    answer:
      'N’importe quel navigateur web moderne (PC, Mac ou tablette) suffit pour le backoffice d’administration, et un smartphone ou une tablette Android suffit pour la caisse mobile et l’impression/partage des tickets PDF.',
  },
  {
    id: 'security',
    question: 'Comment sécurisez-vous l’accès des caissiers et les données financières ?',
    answer:
      'Chaque collaborateur dispose d’un rôle (Propriétaire, Gérant ou Caissier), d’affectations magasins précises et d’un code PIN rapide à 4 ou 6 chiffres avec blocage automatique après plusieurs tentatives erronées, complété par un journal d’audit horodaté.',
  },
  {
    id: 'upgrade',
    question: 'Puis-je changer de forfait ou passer en facturation annuelle plus tard ?',
    answer:
      'Oui. Vous pouvez changer de plan à tout moment depuis le menu Abonnement de votre backoffice web et consulter vos factures PDF à tout instant.',
  },
];
