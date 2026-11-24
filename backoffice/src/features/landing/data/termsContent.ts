export interface LegalSection {
  id: string;
  title: string;
  paragraphs: string[];
  bullets?: string[];
}

export const TERMS_META = {
  badge: 'Document contractuel',
  title: "Conditions Générales d'Utilisation (CGU)",
  subtitle:
    "Les présentes conditions encadrent l'accès et l'utilisation de la plateforme web et mobile TocManager par les commerçants, gérants et collaborateurs autorisés.",
  lastUpdated: 'Mise à jour : novembre 2026',
};

export const TERMS_SECTIONS: LegalSection[] = [
  {
    id: 'objet',
    title: '1. Objet et champ d’application',
    paragraphs: [
      "Les présentes Conditions Générales d'Utilisation (CGU) définissent les modalités d'accès et d'utilisation des services logiciels TocManager, comprenant l'espace d'administration web, l'API de synchronisation et l'application mobile Android de point de vente.",
      "Toute création de compte ou utilisation de la plateforme implique l'acceptation pleine et entière des présentes CGU par l'entreprise cliente et son représentant légal ou gérant.",
    ],
  },
  {
    id: 'acces',
    title: '2. Création de compte et espace multi-tenant',
    paragraphs: [
      "L'inscription s'effectue en deux étapes : création des identifiants personnels du propriétaire, puis configuration de l'entreprise, de la devise et du premier point de vente.",
      "Le client garantit l'exactitude des informations fournies lors de l'inscription et demeure seul responsable de la confidentialité de ses mots de passe, jetons d'accès et codes PIN attribués à ses collaborateurs.",
    ],
  },
  {
    id: 'services',
    title: '3. Description des services Web et Mobile',
    paragraphs: [
      "TocManager met à disposition des outils de gestion commerciale incluant selon le forfait souscrit : caisse POS, gestion de catalogue et stocks par magasin, transferts inter-magasins, clôture de caisse Z, suivi des créances et dettes, rapports P&L, exports comptables et journal d'audit.",
    ],
    bullets: [
      'Application mobile Android dotée d’une base locale SQLite pour encaisser hors connexion.',
      'Backoffice web centralisé pour le pilotage multi-boutiques et multi-magasins.',
      'Mises à jour logicielles continues incluses pendant toute la durée de l’abonnement.',
    ],
  },
  {
    id: 'tarifs',
    title: '4. Offres, essai gratuit et facturation Mobile Money',
    paragraphs: [
      "TocManager propose un Plan Gratuit permanent soumis à des quotas d'utilisation, ainsi que des offres payantes (Pro et Entreprise) facturées mensuellement ou annuellement selon les tarifs en vigueur affichés sur la page Tarifs.",
      "Un essai gratuit de 14 jours peut être activé sans carte bancaire à l'ouverture de la boutique sur les offres éligibles. À l'issue de l'essai, le client peut souscrire par Mobile Money via notre partenaire de paiement FeexPay ou revenir aux limites du Plan Gratuit sans suppression de ses données.",
    ],
  },
  {
    id: 'offline',
    title: '5. Fonctionnement hors-ligne et synchronisation',
    paragraphs: [
      "En mode hors connexion, les opérations saisies sur l'application mobile sont enregistrées localement sur le terminal et marquées d'un identifiant unique (UUID). Le client s'engage à reconnecter régulièrement ses terminaux à internet afin de permettre la synchronisation cloud et la sauvegarde centralisée des écritures.",
    ],
  },
  {
    id: 'responsabilites',
    title: '6. Obligations et responsabilité du commerçant',
    paragraphs: [
      "Le client utilise TocManager pour ses activités commerciales licites. Il demeure exclusivement responsable de la conformité fiscale et comptable de ses tickets, factures, prix affichés et déclarations légales dans son pays d'exercice.",
    ],
    bullets: [
      'Gestion des droits d’accès (Propriétaire, Gérant, Caissier) et révocation immédiate en cas de départ d’un employé.',
      'Exactitude des saisies de stock, réceptions fournisseurs et clôtures de caisse.',
      'Interdiction de contourner les contrôles d’accès, quotas d’abonnement ou d’effectuer une rétro-ingénierie du service.',
    ],
  },
  {
    id: 'disponibilite',
    title: '7. Disponibilité, maintenance et sauvegardes',
    paragraphs: [
      "L'éditeur met en œuvre les moyens techniques raisonnables pour assurer une disponibilité continue de l'API et du backoffice web, sous réserve des opérations de maintenance planifiées ou des incidents réseau externes.",
      "Des sauvegardes automatisées des bases de données hébergées sont réalisées régulièrement pour préserver l'intégrité des écritures synchronisées.",
    ],
  },
  {
    id: 'propriete',
    title: '8. Propriété intellectuelle et propriété des données',
    paragraphs: [
      "La plateforme TocManager, son code source, son interface graphique, ses marques et sa documentation restent la propriété exclusive de l'éditeur. En contrepartie, toutes les données commerciales saisies par le client (produits, ventes, clients, rapports) demeurent la propriété exclusive du client.",
    ],
  },
  {
    id: 'resiliation',
    title: '9. Durée, suspension et résiliation',
    paragraphs: [
      "L'abonnement est sans engagement de durée au-delà de la période mensuelle ou annuelle payée. Le client peut exporter ses données à tout moment via les fonctions d'export disponibles dans son forfait. En cas de violation grave des présentes CGU ou de tentative d'atteinte à la sécurité de la plateforme, l'accès peut être suspendu après notification.",
    ],
  },
  {
    id: 'contact',
    title: '10. Évolution des CGU et support',
    paragraphs: [
      "TocManager se réserve le droit de faire évoluer les présentes CGU pour tenir compte des améliorations techniques ou évolutions réglementaires. Pour toute question contractuelle ou demande d'assistance Entreprise, vous pouvez contacter notre équipe depuis la page Contact.",
    ],
  },
];
