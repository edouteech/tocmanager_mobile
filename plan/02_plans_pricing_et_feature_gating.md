# Section 2 : Système de Plans, Pricing & Feature Gating (Modèle Paywall Non Bloquant)

Ce document détaille le modèle économique SaaS, la gestion des forfaits par l'administrateur, et la stratégie UX de **Feature Gating interactif** (aucune fonctionnalité masquée, incitation soignée à la mise à niveau).

---

## 1. Principes du Modèle Économique

1. **Un Plan Gratuit Permanent (*Freemium*)** :
   - Accessible immédiatement sans carte bancaire ni engagement.
   - Permet à un petit commerçant de démarrer avec un périmètre restreint (ex: 1 seul magasin, catalogue limité à 50 produits, fonctionnalités de base de vente et caisse).
2. **Des Plans Payants Évolutifs (ex: Pro, Multi-Magasins, Entreprise)** :
   - Débloquent des fonctionnalités avancées (multi-magasins illimités, transferts inter-magasins, exports comptables avancés, gestion avancée des utilisateurs et permissions, journaux d'audit étendus).
3. **Période d'Essai Gratuit Personnalisable (*Free Trial*)** :
   - Le Super-Administrateur peut accorder un délai d'essai (ex: 14 jours, 30 jours) sur n'importe quel plan payant pour permettre aux prospects de tester la totalité des fonctionnalités avant d'être facturés.
4. **Tarification Flexible** :
   - Facturation mensuelle ou annuelle (avec remise incitative ex: 2 mois offerts).
   - Support des devises locales (FCFA / XOF, XAF, EUR, USD).

---

## 2. Matrice des Fonctionnalités & Quotas (Feature Flags)

Le système repose sur un dictionnaire de codes de fonctionnalités déclarés au niveau du backend et vérifiés par le middleware de permissions.

| Code Fonctionnalité | Libellé Fonctionnalité | Plan Gratuit | Plan Standard / Pro | Plan Entreprise |
| :--- | :--- | :---: | :---: | :---: |
| `max_magasins` | Nombre maximum de magasins | `1` | `3` à `5` | `Illimité` |
| `max_products` | Nombre maximum de références produits | `100` | `2 000` | `Illimité` |
| `max_users` | Nombre d'utilisateurs / caissiers | `2` | `10` | `Illimité` |
| `stock_transfers` | Transferts de stock inter-magasins | ❌ Non | ✅ Oui | ✅ Oui |
| `advanced_reports` | Rapports P&L financiers et marges détaillées | ❌ Non | ✅ Oui | ✅ Oui |
| `data_export` | Exports PDF / Excel & fiches de règlements | ⚠️ Basique | ✅ Complet | ✅ Complet + API |
| `audit_logs` | Historique détaillé et traçabilité des actions | ❌ 3 jours max | ✅ 90 jours | ✅ Illimité |
| `custom_branding` | Logo d'entreprise sur tickets de caisse & devis | ❌ Non | ✅ Oui | ✅ Oui |

---

## 3. Expérience Utilisateur : Le "Feature Gating Interactif"

### 3.1 Règle d'Or UX
> **Les fonctionnalités non incluses ne sont JAMAIS dissimulées ni désactivées de manière opaque.**

- Les entrées de menu (ex: "Transferts de stock", "Rapports financiers avancés", "Nouveau Magasin") restent **visibles et cliquables**.
- Les boutons d'action (ex: "Ajouter un second magasin", "Exporter le rapport P&L", "Transférer du stock") restent accessibles.
- Un badge visuel discret (ex: petite étiquette violette ou dorée `PRO` ou `PREMIUM`) signale simplement qu'il s'agit d'un avantage étendu.

### 3.2 La Modale de Paywall / Upsell
Dès que l'utilisateur clique sur une action ou accède à une page nécessitant un forfait supérieur (ou s'il dépasse un quota comme le nombre max de produits ou de magasins) :

```
┌────────────────────────────────────────────────────────────────────────┐
│  ⭐ Passez à TocManager Pro                                       [✕] │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│   🚀 Débloquez la gestion Multi-Magasins & Transferts de Stock         │
│                                                                        │
│   Votre formule actuelle (Plan Gratuit) est limitée à 1 magasin.      │
│   Pour ouvrir de nouveaux points de vente et gérer les transferts de   │
│   marchandises en temps réel, activez le Plan Pro dès aujourd'hui !    │
│                                                                        │
│   ✨ Ce que vous obtenez en passant à Pro :                           │
│   ✔ Jusqu'à 5 magasins et entrepôts connectés                         │
│   ✔ Transferts de stock et réassorts automatiques                      │
│   ✔ Rapports financiers P&L et suivi des marges en direct              │
│   ✔ Utilisateurs et caissiers illimités                                │
│                                                                        │
│   🎁 Profitez de 14 jours d'essai gratuit, sans engagement.           │
│                                                                        │
│   [  Explorer les Forfaits  ]        [  Activer l'essai Pro 14j  ]     │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

1. **Bouton d'action principal** : Démarre l'essai gratuit en 1 clic (si éligible) ou redirige vers la page de sélection d'abonnements.
2. **Retour sans blocage** : L'utilisateur peut fermer la modale et continuer son travail habituel sans frustration.

---

## 4. Pouvoirs d'Administration du Super-Admin

Depuis le back-office Super-Admin (`admin.tocmanager.com`), l'administrateur a le contrôle complet sur le catalogue tarifaire :

1. **Gestion des Forfaits** :
   - Création de nouveaux forfaits (nom, description marketing, couleur de mise en avant).
   - Modification des prix (mensuel et annuel) et des devises.
   - Activation / Désactivation d'un plan pour les nouvelles souscriptions.
2. **Matrice des Droits & Limites** :
   - Cocher/Décocher les fonctionnalités incluses par plan.
   - Ajuster les compteurs limites (ex: passer le quota de magasins du Plan Pro de 3 à 5).
3. **Gestion des Périodes d'Essai** :
   - Définir le nombre de jours d'essai offerts pour chaque plan payant (ex: 14 jours).
   - Possibilité d'accorder manuellement une extension d'essai à un commerçant spécifique depuis sa fiche.
4. **Suivi des Conversions & Revenus** :
   - Taux de conversion de l'essai gratuit vers le forfait payant.
   - Chiffre d'Affaires Récurrent Mensuel (MRR) et Annuel (ARR).
   - Suivi du désabonnement (*churn*).
