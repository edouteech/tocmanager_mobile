# Tocmanager Ecosystem

Écosystème complet de gestion commerciale hors-ligne (Offline-First) avec synchronisation cloud et backoffice centralisé.

---

## Architecture du Projet

```text
Tocmanager/
├── backend/            # API Python FastAPI (Auth JWT, Sync idempotente, Rapports)
├── backoffice/         # Web Backoffice React 18 + Vite + Tailwind CSS
├── mobile/             # Application Mobile Flutter (SQLite v13, Déverrouillage PIN)
└── docker-compose.yml  # Déploiement conteneurisé du Backend et du Backoffice
```

---

## 1. Démarrage Rapide avec Docker

Pour lancer le backend API et le backoffice web en une seule commande :

```bash
docker compose up --build
```

- **API Backend** : `http://localhost:8000/docs` (Swagger UI interactif)
- **Backoffice Web** : `http://localhost:3000`

---

## 2. Lancement Manuel en Développement

### Backend (FastAPI)
```bash
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python run.py
```
> Tests unitaires : `pytest -v`

### Backoffice Web (React + Vite)
```bash
cd backoffice
npm install
npm run dev
```
> Build de production : `npm run build`

### Application Mobile (Flutter)
```bash
cd mobile
flutter pub get
flutter run
```
> Tests automatisés : `flutter test`  
> Analyse statique : `flutter analyze`

---

## 3. Identifiants par Défaut (Environnement de Test)

| Rôle | Nom d'utilisateur | Mot de passe | Code PIN Mobile |
| :--- | :--- | :--- | :--- |
| **Administrateur** | `admin` | `admin1234` | `1234` |
| **Caissier** | `caissier1` | `caisse1234` | `0000` |

---

## 4. Fonctionnalités Clés & Sécurité

- **Offline-First & Idempotence** : Chaque vente et transaction génère un UUID (`sync_id`). Même en cas de coupure réseau ou de renvois multiples, aucune donnée n'est dupliquée sur le serveur.
- **Migration v13 SQLite sans perte** : Sauvegarde automatique `.bak` avant migration, conservation intégrale des ventes locales antérieures.
- **Déverrouillage par Code PIN** : Accès rapide sur le terminal de vente avec pavé numérique tactile sans ressaisie d'identifiants à chaque session.
- **Gestion Centralisée des Utilisateurs** : Configuration des rôles et des codes PIN directement depuis le backoffice web.
