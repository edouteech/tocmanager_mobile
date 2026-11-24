from fastapi import APIRouter
from app.api.v1.endpoints import (
    auth, auth_security, sync, products, categories, ventes, users, reports, audit,
    clients, suppliers, approvisionnements, decaissements, settings,
    saas_public, saas_admin, tenant, billing, transfers, stock_movements, cash_sessions, uploads
)

api_router = APIRouter()

# SaaS Public, Pricing & Inscription
api_router.include_router(saas_public.router, prefix="/saas", tags=["SaaS Public & Pricing"])

# Super-Admin Platform Console
api_router.include_router(saas_admin.router, prefix="/admin", tags=["Super-Admin Console"])

# Tenant Operations (Multi-Boutiques & Multi-Magasins)
api_router.include_router(tenant.router, prefix="/tenant", tags=["Boutiques & Magasins (Tenant)"])

# SaaS Billing & FeexPay Webhooks
api_router.include_router(billing.router, prefix="/billing", tags=["Facturation SaaS"])
api_router.include_router(billing.webhook_router, prefix="/webhooks", tags=["Webhooks Paiement"])

# Core Modules
api_router.include_router(auth.router, prefix="/auth", tags=["Authentification"])
api_router.include_router(auth_security.router, prefix="/auth", tags=["Authentification & Securite"])
api_router.include_router(sync.router, prefix="/sync", tags=["Synchronisation Offline-First"])
api_router.include_router(products.router, prefix="/products", tags=["Produits"])
api_router.include_router(categories.router, prefix="/categories", tags=["Catégories"])
api_router.include_router(ventes.router, prefix="/ventes", tags=["Ventes & Caisses"])
api_router.include_router(cash_sessions.router, prefix="/cash-sessions", tags=["Sessions de Caisse & Clôture Z"])
api_router.include_router(clients.router, prefix="/clients", tags=["Clients & Créances"])
api_router.include_router(suppliers.router, prefix="/suppliers", tags=["Fournisseurs"])
api_router.include_router(approvisionnements.router, prefix="/approvisionnements", tags=["Approvisionnements & Stocks"])
api_router.include_router(transfers.router, prefix="/transfers", tags=["Transferts Inter-Magasins"])
api_router.include_router(stock_movements.router, prefix="/stock-movements", tags=["Journal Mouvements & Inventaire"])
api_router.include_router(decaissements.router, prefix="/decaissements", tags=["Dépenses & Décaissements"])
api_router.include_router(reports.router, prefix="/reports", tags=["Rapports & Statistiques"])
api_router.include_router(settings.router, prefix="/settings", tags=["Paramètres"])
api_router.include_router(users.router, prefix="/users", tags=["Utilisateurs & Rôles"])
api_router.include_router(audit.router, prefix="/audit", tags=["Journal d'Audit & Sécurité"])
api_router.include_router(uploads.router, prefix="/uploads", tags=["Stockage Médias"])
