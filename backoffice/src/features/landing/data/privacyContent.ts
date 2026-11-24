import type { LegalSection } from './termsContent';

export const PRIVACY_META = {
  badge: 'Protection des données',
  title: 'Politique de Confidentialité',
  subtitle:
    'Découvrez comment TocManager collecte, isole, protège et traite les données de votre compte, de vos collaborateurs et de vos points de vente.',
  lastUpdated: 'Mise à jour : novembre 2026',
};

export const PRIVACY_SECTIONS: LegalSection[] = [
  {
    id: 'responsable',
    title: '1. Périmètre et engagements de confidentialité',
    paragraphs: [
      "La présente Politique de Confidentialité s'applique à l'ensemble de l'écosystème TocManager (vitrine publique, espace backoffice web et application mobile Android). Nous traitons vos données dans le strict respect des principes de minimisation, de cloisonnement multi-tenant et de transparence.",
    ],
  },
  {
    id: 'donnees-collectees',
    title: '2. Données collectées',
    paragraphs: [
      'Selon votre utilisation du service, TocManager traite uniquement les données nécessaires au fonctionnement commercial et à la facturation de votre abonnement :',
    ],
    bullets: [
      'Données d’identification : nom complet, email ou identifiant de connexion, numéro de téléphone, rôle et code PIN chiffré.',
      'Données d’entreprise et de gestion : noms de boutiques et magasins, devise, catalogue produits, ventes, clôtures de caisse Z, clients, fournisseurs et mouvements de stock.',
      'Données de facturation SaaS : forfait choisi, cycle de facturation, références et statuts de transaction Mobile Money (sans stockage de code secret Mobile Money).',
      'Journaux techniques et d’audit : horodatage des connexions, actions sensibles en boutique et journaux d’erreurs applicatifs.',
    ],
  },
  {
    id: 'finalites',
    title: '3. Finalités des traitements',
    paragraphs: [
      "Vos données ne sont jamais vendues ni louées à des tiers. Elles servent exclusivement à :",
    ],
    bullets: [
      'Fournir l’encaissement POS, la synchronisation multi-magasins et le calcul de vos indicateurs financiers.',
      'Sécuriser l’accès aux sessions (authentification JWT, verrouillage PIN, 2FA TOTP pour l’administration plateforme).',
      'Gérer vos abonnements, périodes d’essai, factures PDF et notifications de sécurité (réinitialisation de mot de passe, vérification email).',
      'Traiter vos demandes envoyées depuis le formulaire de contact public.',
    ],
  },
  {
    id: 'isolation-securite',
    title: '4. Isolation multi-tenant et sécurité technique',
    paragraphs: [
      "Chaque boutique dispose d'un cloisonnement logique strict (contrôle d'accès par tenant, vérifications RBAC sur chaque endpoint API et règles d'isolation en base PostgreSQL). Les mots de passe et codes PIN sont hachés de façon irréversible (bcrypt).",
      "Les échanges entre l'application mobile, le backoffice web et le serveur sont chiffrés via HTTPS. Les médias téléversés et sauvegardes de base de données reposent sur un stockage objet sécurisé.",
    ],
  },
  {
    id: 'sous-traitants',
    title: '5. Partenaires techniques et paiements',
    paragraphs: [
      "Pour délivrer le service, TocManager s'appuie sur des prestataires spécialisés strictement encadrés :",
    ],
    bullets: [
      'FeexPay : traitement sécurisé des paiements Mobile Money pour les abonnements SaaS.',
      'Fournisseur d’envoi d’emails transactionnels : acheminement des emails de vérification, réinitialisation et facturation.',
      'Hébergement cloud et stockage objet chiffré : conservation des bases de données et sauvegardes automatisées.',
    ],
  },
  {
    id: 'stockage-local',
    title: '6. Stockage local mobile (Offline-First)',
    paragraphs: [
      "L'application mobile Android stocke localement vos données opérationnelles dans une base SQLite et vos jetons dans le stockage sécurisé du terminal afin de permettre la vente hors connexion. Lors de la déconnexion explicite d'un utilisateur, la purge locale est effectuée pour protéger la confidentialité entre postes partagés.",
    ],
  },
  {
    id: 'conservation',
    title: '7. Durée de conservation',
    paragraphs: [
      "Les données commerciales de la boutique sont conservées pendant toute la durée d'activité du compte client. La profondeur consultable du journal d'audit dépend du forfait souscrit (par défaut de 3 jours sur le Plan Gratuit à illimité sur le Plan Entreprise). Les demandes publiques envoyées via la page Contact sont conservées le temps du suivi commercial.",
    ],
  },
  {
    id: 'droits',
    title: '8. Vos droits sur vos données',
    paragraphs: [
      "Vous disposez d'un droit d'accès, de rectification, d'exportation (portabilité au format Excel/CSV/PDF depuis votre espace) et de suppression de vos données personnelles et commerciales.",
    ],
  },
  {
    id: 'exercice-droits',
    title: '9. Exercer vos droits ou poser une question',
    paragraphs: [
      "Pour toute demande liée à la confidentialité, à la suppression d'un espace ou à la sécurité de vos données, contactez notre équipe via le formulaire dédié sur la page Contact.",
    ],
  },
];
