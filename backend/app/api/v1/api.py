from fastapi import APIRouter
from app.api.v1.endpoints import auth, sync, products, categories, ventes, users, reports

api_router = APIRouter()

api_router.include_router(auth.router, prefix="/auth", tags=["Authentification"])
api_router.include_router(sync.router, prefix="/sync", tags=["Synchronisation Offline-First"])
api_router.include_router(products.router, prefix="/products", tags=["Produits"])
api_router.include_router(categories.router, prefix="/categories", tags=["Catégories"])
api_router.include_router(ventes.router, prefix="/ventes", tags=["Ventes & Caisses"])
api_router.include_router(users.router, prefix="/users", tags=["Utilisateurs & Rôles"])
api_router.include_router(reports.router, prefix="/reports", tags=["Rapports & Statistiques"])
