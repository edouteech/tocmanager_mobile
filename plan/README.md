# Plan d'Architecture & Transformation SaaS Multi-Tenant : TocManager

Ce dossier rassemble l'ensemble des spécifications et plans directeurs pour la transformation de **TocManager** en une plateforme SaaS multi-locataire (*multi-tenant*), multi-boutiques et multi-magasins.

---

## 🎯 Vision du Projet

TocManager évolue d'une application monocaisse / mono-entreprise vers un **service SaaS à guichet unique** permettant à n'importe quel commerçant ou entreprise commerciale de créer un compte, définir son entreprise, gérer plusieurs boutiques, et pour chaque boutique administrer un réseau de magasins (points de vente physiques) avec stocks individualisés.

Le projet s'articule autour de **trois piliers d'interfaces web** (sous-domaines distincts dans un monorepo) et d'une **application mobile Flutter** :
1. **`www.tocmanager.com`** : Vitrine marketing, page de pricing interactive, flux d'inscription fluide (identifiants puis onboarding entreprise).
2. **`app.tocmanager.com`** : Espace client / Dashboard commerçant multi-boutiques & multi-magasins, vue financière consolidée, gestion des stocks par point de vente, et incitations de mise à niveau (*paywall non bloquant*).
3. **`admin.tocmanager.com`** : Back-office Super-Administrateur de la plateforme pour piloter les plans, fonctionnalités, périodes d'essai, souscriptions et métriques globales.
4. **Application Mobile (Flutter)** : Caisse et gestion de terrain offline-first avec sélection de boutique et magasin, et mode consolidé financier pour le propriétaire.

---

## 🧭 Plan Orchestrateur : Structure des Fichiers Détaillés

Le plan complet est subdivisé en **7 sections techniques spécialisées** :

| Fichier | Titre | Description sommaire |
| :--- | :--- | :--- |
| [**01_architecture_et_schema_multitenant.md**](./01_architecture_et_schema_multitenant.md) | **Architecture & Schéma Multi-Tenant** | Isolation stricte par schéma PostgreSQL (`schema-per-tenant`), schéma `public` global, modèles de données (Entreprise, Boutique, Magasin, Stocks). |
| [**02_plans_pricing_et_feature_gating.md**](./02_plans_pricing_et_feature_gating.md) | **Plans, Pricing & Feature Gating** | Modèle freemium, plans payants dynamiques, périodes d'essai, moteur de permissions et UX de paywall non bloquant (modale d'upsell interactive). |
| [**03_landing_pricing_et_onboarding_web.md**](./03_landing_pricing_et_onboarding_web.md) | **Landing, Pricing & Onboarding Web** | Interface publique `www` : présentation produit, comparateur de forfaits, inscription en 2 étapes (identifiants -> création entreprise). |
| [**04_backoffice_superadmin.md**](./04_backoffice_superadmin.md) | **Back-office Super-Administrateur** | Interface `admin` : catalogue des plans & tarifs, gestion des accès par plan, suivi des abonnements, annuaire des commerçants et métriques SaaS. |
| [**05_backoffice_client_multimagasin.md**](./05_backoffice_client_multimagasin.md) | **Back-office Client & Multi-Magasins** | Interface `app` : sélecteur/switch de boutique, gestion des magasins, stocks dissociés par magasin, affectation du personnel et vue financière propriétaire. |
| [**06_mobile_flutter_multimagasin_sync.md**](./06_mobile_flutter_multimagasin_sync.md) | **Application Mobile & Sync Décentralisée** | Refonte du login mobile : sélection boutique/magasin, bouton « Passer » propriétaire, moteur de synchronisation SQLite ciblé par magasin. |
| [**07_roadmap_implementation_et_tests.md**](./07_roadmap_implementation_et_tests.md) | **Roadmap d'Exécution & Stratégie de Test** | Découpage en phases jalonnées, scripts de migration PostgreSQL, tests automatisés backend/frontend/mobile et critères de validation. |

---

## 🏛️ Vue d'Ensemble de l'Architecture Système

```mermaid
flowchart TD
    subgraph Clients["Applications & Points d'Entrée"]
        WWW["www.tocmanager.com<br/>(Landing, Pricing, Onboarding)"]
        APP["app.tocmanager.com<br/>(Espace Client Marchand)"]
        ADMIN["admin.tocmanager.com<br/>(Back-office Super-Admin)"]
        MOBILE["Application Mobile Flutter<br/>(Caisse & Vente Hors-Ligne)"]
    end

    subgraph BackendGateway["FastAPI Gateway & Middlewares"]
        AUTH_ROUTER["Service Auth & JWT"]
        TENANT_MIDDLEWARE["Tenant Resolver Middleware<br/>(Header / Token / Subdomain)"]
        FEATURE_GUARD["Feature Gating & Plan Enforcer"]
    end

    subgraph Storage["PostgreSQL Multi-Schémas"]
        subgraph PublicSchema["Schéma: public (Global)"]
            GLOBAL_USERS["Comptes Utilisateurs & Propriétaires"]
            PLANS["Plans, Prix, Features & Périodes d'essai"]
            TENANTS["Annuaire des Boutiques (Tenants)"]
            SUBSCRIPTIONS["Abonnements & Transactions"]
            PLATFORM_AUDIT["Audit Logs Plateforme"]
        end

        subgraph TenantSchema1["Schéma: tenant_boutique_abc"]
            MAGASINS_1["Magasins (Points de vente)"]
            PRODUCTS_1["Catalogue & Stocks par Magasin"]
            SALES_1["Ventes & Caisse"]
            SUPPLIERS_1["Approvisionnements & Dépenses"]
            CLIENTS_1["Clients & Dettes"]
        end

        subgraph TenantSchema2["Schéma: tenant_boutique_xyz"]
            MAGASINS_2["Magasins (Points de vente)"]
            PRODUCTS_2["Catalogue & Stocks par Magasin"]
            SALES_2["Ventes & Caisse"]
            SUPPLIERS_2["Approvisionnements & Dépenses"]
            CLIENTS_2["Clients & Dettes"]
        end
    end

    WWW --> AUTH_ROUTER
    APP --> TENANT_MIDDLEWARE
    ADMIN --> AUTH_ROUTER
    MOBILE --> TENANT_MIDDLEWARE

    AUTH_ROUTER --> PublicSchema
    FEATURE_GUARD --> PublicSchema
    TENANT_MIDDLEWARE --> FEATURE_GUARD
    TENANT_MIDDLEWARE --> TenantSchema1
    TENANT_MIDDLEWARE --> TenantSchema2
```

---

## 🔑 Règles Clés d'Expérience Utilisateur & Métier

1. **Hiérarchie Commerciale** :
   - `Propriétaire` ➔ Gère 1 ou plusieurs `Boutiques` (entreprises).
   - `Boutique` ➔ Possède 1 ou plusieurs `Magasins` (points de vente physiques).
   - `Utilisateurs` (caissiers, gérants) ➔ Affectés à un ou plusieurs magasins d'une boutique donnée.
2. **Stocks et Catalogue Cloisonnés** :
   - Un produit peut être présent dans le magasin A et absent dans le magasin B.
   - Les niveaux de stock sont indépendants par magasin.
3. **Parcours Propriétaire Fluide** :
   - À la connexion, un bouton **« Passer »** permet au propriétaire d'ignorer la sélection d'un magasin précis pour consulter immédiatement la **vue financière consolidée** de sa boutique.
4. **Feature Gating Non Bloquant (Upsell UX)** :
   - Les boutons et fonctionnalités des plans supérieurs restent visibles et cliquables.
   - Lors d'une tentative d'exécution, une modale soignée présente la fonctionnalité et propose une mise à niveau vers le forfait adéquat.
