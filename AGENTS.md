# 🤖 Directives & Règles de Développement Agent — TocManager Mobile

Ce document contient les règles de process, d'architecture et de design à respecter scrupuleusement lors de tout développement ou modification sur le projet **TocManager Mobile**.

---

## 🎨 1. Règles d'UI / UX & Design System

- **⛔ Pas d'Émojis dans l'Interface** :
    - L'utilisation d'émojis Unicode dans les composants UI, titres ou boutons est **strictement proscrite**.
    - Utiliser exclusivement les icônes Material (`IconData` / `Icon` / `Icons.*`).

- **📱 Design Adaptatif (Mobile vs Tablette)** :
    - **Sur Smartphone / Mobile** :
        - Éviter les grands tableaux défilants horizontalement (`DataTable`).
        - Favoriser des listes sous forme de cartes simples (`ListView.builder`) affichant les informations minimales essentielles.
        - Un clic sur un élément ouvre un **Modal Bottom Sheet de détails** interactif.
        - Les filtres doivent être compacts et non bloquants.
    - **Sur Tablette / Écran large** :
        - Conserver l'affichage structuré sous forme de `DataTable` complète avec filtres en ligne.

- **🛒 Système de Caisse POS & Ventes Multi-Articles** :
    - **Structure Panier / Ticket de Caisse** : Une vente est un ticket (`VNT-YYYYMMDD-XXXX`) contenant **1 à N articles** avec gestion des modes de paiement (_Espèces, Mobile Money, Carte, Crédit_).
    - **Gestion des Crédits** : Si le montant encaissé est inférieur au total et qu'un client est sélectionné, le reliquat s'ajoute automatiquement au solde débiteur (`balance`) du client.
    - **Reçus & Impression** : Permettre la visualisation détaillée du ticket et l'impression directe au format thermique (format rouleau 80mm).

- **🥞 Navigation par Empilement (Stack Preservation)** :
    - Lorsqu'un Modal Bottom Sheet de détail s'affiche (ex: détail produit, client ou ticket de vente) et que l'utilisateur clique sur une action, l'écran/modal d'action doit s'empiler au-dessus.
    - La fermeture du modal/écran d'action (`Navigator.pop`) **doit ramener l'utilisateur sur le modal de détail** d'origine sans le fermer.

---

## 🏗️ 2. Architecture Codebase & Stack technique

- **Gestion d'État (State Management)** :
    - Utiliser l'écosystème **Provider** (`ChangeNotifier`, `Consumer`, `context.read`, `context.watch`).
    - Chaque module métier a son Provider propre (`ProductProvider`, `ClientProvider`, `SupplierProvider`, `VenteProvider`, `DecaissementProvider`, `CategoryProvider`).
    - Enregistrer les nouveaux providers dans le `MultiProvider` du `main.dart`.

- **Base de Données (SQLite Local-First v6)** :
    - Centraliser toutes les opérations SQLite dans `DatabaseHelper` (`lib/database/database_helper.dart`).
    - Gérer les montées de version via le système d'incrémentation SQLite (`version`, `onUpgrade`, `onOpen`).
    - `onOpen` s'assure dynamiquement que toutes les tables (`clients`, `suppliers`, `ventes`, `vente_items`, `approvisionnements`, `decaissements`, `categories`, `products`) existent à chaque démarrage.

- **Theme & Couleurs** :
    - Utiliser exclusivement les définitions de la charte graphique de `AppColors` (`lib/theme/app_theme.dart`).

---

## 📑 3. Conformité & Qualité de Code

- **Vérification Systématique** :
    - Avant de valider une tâche, exécuter `flutter analyze` et s'assurer d'obtenir **0 erreur de compilation**.
- **Formateurs & Locales** :
    - Formater les devises en **FCFA** sans décimales via `NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0)`.
    - Formater les dates au format localisé `dd/MM/yyyy HH:mm` (`fr_FR`).


- **POS Autocomplete Client & Création Automatique** :
  - Dans le formulaire de vente (`vente_screen.dart`), le champ client est une saisie avec auto-complétion (`RawAutocomplete<Client>`).
  - Si le champ est laissé vide, le nom par défaut est **"Occasionnel"**.
  - Si l'utilisateur saisit un nom de client inexistant dans la base (ex: "Marcelle Konan"), la vente valide l'enregistrement et crée automatiquement ce nouveau client dans la base SQLite (`ClientProvider.addClient`).
