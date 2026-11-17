# Section 4 : Back-Office Super-Administrateur (`admin.tocmanager.com`)

Ce document détaille l'espace d'administration central réservé aux gestionnaires de la plateforme SaaS TocManager, permettant de gouverner l'écosystème commercial, les abonnements, les tarifs et les métriques globales.

---

## 1. Sécurité & Contrôle d'Accès

- **Accès Restreint** : Réservé aux comptes détenteurs du rôle `superadmin` dans la table `public.platform_users`.
- **Authentification Renforcée** : JWT dédié avec vérification stricte de l'origine et possibilité d'activer l'authentification à deux facteurs (2FA / TOTP) pour les actions sensibles.
- **Isolation d'Exécution** : Les requêtes exécutées par le Super-Admin s'opèrent sur le schéma `public` ou via des vues d'agrégation sécurisées, sans modifier directement les schémas opérationnels des boutiques sans trace d'audit.

---

## 2. Modules Fonctionnels de la Console Super-Admin

### 2.1 Tableau de Bord Global & KPIs SaaS (`/admin/dashboard`)
Vue macroscopique en direct sur la santé de la plateforme :
- **MRR (Monthly Recurring Revenue)** & **ARR (Annual Recurring Revenue)**.
- **Nombre total de Boutiques (Tenants)** actives, en période d'essai et suspendues.
- **Nombre total de Magasins (Points de vente)** déployés sur le terrain.
- **Taux de Conversion des Essais Gratuits** vers les plans payants.
- **Volume d'Affaires Global (GMV)** : Montant cumulé des ventes enregistrées à travers l'ensemble des boutiques.

```
┌────────────────────────────────────────────────────────────────────────┐
│  📊 KPIs PLATEFORME SAAS                                              │
├────────────────────┬────────────────────┬──────────────────────────────┤
│  MRR Estimé        │  Boutiques Actives │  Magasins Déployés           │
│  4 850 000 FCFA    │  342 Entreprises   │  789 Points de vente         │
├────────────────────┼────────────────────┼──────────────────────────────┤
│  En Essai Pro      │  Taux Conversion   │  Ventes Totales (Mois)       │
│  68 Boutiques      │  24.5 %            │  145 200 000 FCFA            │
└────────────────────┴────────────────────┴──────────────────────────────┘
```

---

### 2.2 Gestion des Plans, Tarifs & Périodes d'Essai (`/admin/plans`)
Module d'administration dynamique des offres commerciales :

1. **Création & Modification des Plans** :
   - Nom commercial (ex: *Starter*, *Pro Croissance*, *Réseau Multi-Boutiques*).
   - Code technique unique (ex: `plan_pro_annual`).
   - Prix Mensuel et Prix Annuel dans les devises supportées.
   - Statut de commercialisation (Actif / Archivé).
2. **Matrice des Droits & Quotas par Plan** :
   - Nombre maximal de magasins autorisés (ex: 1 pour Gratuit, 5 pour Pro, illimité pour Réseau).
   - Nombre d'utilisateurs max par boutique.
   - Interrupteurs pour fonctionnalités avancées :
     - Transferts de stock inter-magasins (`stock_transfers`).
     - Rapports financiers de rentabilité consolidée (`pnl_reports`).
     - Exports PDF / Excel de grand livre (`data_exports`).
     - Conservation étendue des audits (`extended_audit`).
3. **Paramétrage des Périodes d'Essai (*Free Trial*)** :
   - Définition du nombre de jours d'essai offerts pour chaque plan payant (ex: 14 jours, 30 jours, 0 jour).
   - Option d'activation/désactivation de l'essai gratuit selon les campagnes promotionnelles.

---

### 2.3 Annuaire des Entreprises & Boutiques (`/admin/boutiques`)
Gestion du portefeuille de clients commerçants :
- **Recherche & Filtrage Avancé** : Par nom d'entreprise, propriétaire, statut d'abonnement, pays, ou date d'inscription.
- **Fiche Détaillée d'une Boutique** :
  - Identité du propriétaire (nom, email, téléphone).
  - Date d'inscription et historique d'activité.
  - Nom du schéma PostgreSQL technique (`schema_name`).
  - Nombre de magasins rattachés et nombre de collaborateurs.
  - Plan actuel, statut d'essai, date d'échéance du prochain renouvellement.
- **Actions Administratives Privilégiées** :
  - **Prolonger manuellement un essai gratuit** (pour un prospect en négociation).
  - **Changer de plan manuellement** (ex: accorder un plan sur-mesure ou offrir des quotas supplémentaires).
  - **Suspendre / Réactiver une boutique** (en cas de défaut de paiement ou non-respect des CGU).
  - **Mode Impersonation / Support Assistance** : Permet à un agent support d'accéder en lecture seule à l'espace client pour guider le commerçant, avec traçabilité complète dans les journaux d'audit.

---

### 2.4 Suivi des Abonnements & Facturation (`/admin/subscriptions`)
- Liste exhaustive de tous les abonnements en cours :
  - `trialing` (en période d'essai actif).
  - `active` (abonnement payé en cours de validité).
  - `past_due` (incident de paiement ou renouvellement en attente).
  - `canceled` (abonnement résilié, repassé automatiquement en plan gratuit).
- Historique des transactions et reçus de facturation SaaS.

---

### 2.5 Journal d'Audit & Sécurité Plateforme (`/admin/audit`)
- Journalisation horodatée de toutes les opérations d'administration :
  - Créations/modifications de plans tarifaires.
  - Attributions manuelles d'essais ou changements de forfaits.
  - Suspensions de comptes ou suppressions de données.
  - Connexions administrateur et adresses IP sources.
