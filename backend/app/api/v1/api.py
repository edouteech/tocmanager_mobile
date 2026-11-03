from fastapi import APIRouter
from app.api.v1.endpoints import (
    auth, sync, products, categories, ventes, users, reports, audit,
    clients, suppliers, approvisionnements, decaissements, settings
)

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["Authentification"])
api_router.include_router(sync.router, prefix="/sync", tags=["Synchronisation Offline-First"])
api_router.include_router(products.router, prefix="/products", tags=["Produits"])
api_router.include_router(categories.router, prefix="/categories", tags=["Catégories"])
api_router.include_router(ventes.router, prefix="/ventes", tags=["Ventes & Caisses"])
api_router.include_router(clients.router, prefix="/clients", tags=["Clients & Créances"])
api_router.include_router(suppliers.router, prefix="/suppliers", tags=["Fournisseurs"])
api_router.include_router(approvisionnements.router, prefix="/approvisionnements", tags=["Approvisionnements & Stocks"])
api_router.include_router(decaissements.router, prefix="/decaissements", tags=["Dépenses & Décaissements"])
api_router.include_router(reports.router, prefix="/reports", tags=["Rapports & Statistiques"])
api_router.include_router(settings.router, prefix="/settings", tags=["Paramètres"])
api_router.include_router(users.router, prefix="/users", tags=["Utilisateurs & Rôles"])
api_router.include_router(audit.router, prefix="/audit", tags=["Journal d'Audit & Sécurité"])
