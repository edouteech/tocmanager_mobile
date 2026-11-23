from dataclasses import dataclass
from typing import Any, Dict, List, Optional
from sqlalchemy.orm import Session
from app.models import SaasPlan, SaasPlanFeature


@dataclass(frozen=True)
class FeatureDefinition:
    feature_code: str
    feature_name: str
    category: str
    value_type: str
    description: str
    display_order: int
    show_on_pricing: bool
    free_default: Any
    pro_default: Any
    enterprise_default: Any


FEATURE_CATALOG: tuple[FeatureDefinition, ...] = (
    FeatureDefinition("max_boutiques", "Boutiques par propriétaire", "quotas", "limit_number", "Nombre maximum de boutiques actives pour un même propriétaire (-1 = illimité).", 1, True, 1, 3, -1),
    FeatureDefinition("max_magasins", "Magasins par boutique", "quotas", "limit_number", "Nombre de points de vente ou entrepôts par boutique (-1 = illimité).", 2, True, 1, 5, -1),
    FeatureDefinition("max_products", "Articles catalogue", "quotas", "limit_number", "Nombre maximum d'articles actifs dans le catalogue (-1 = illimité).", 3, True, 100, 2000, -1),
    FeatureDefinition("max_users", "Comptes collaborateurs", "quotas", "limit_number", "Nombre maximum d'utilisateurs actifs dans la boutique (-1 = illimité).", 4, True, 2, 10, -1),
    FeatureDefinition("max_clients", "Fiches clients", "quotas", "limit_number", "Nombre maximum de clients enregistrés (-1 = illimité).", 5, True, 50, 1000, -1),
    FeatureDefinition("max_suppliers", "Fiches fournisseurs", "quotas", "limit_number", "Nombre maximum de fournisseurs enregistrés (-1 = illimité).", 6, False, 10, 100, -1),
    FeatureDefinition("audit_retention_days", "Rétention audit (jours)", "quotas", "limit_number", "Profondeur d'historique consultable dans le journal d'audit (-1 = illimité).", 7, False, 3, 90, -1),
    FeatureDefinition("module_pos_sales", "Caisse & ventes POS", "modules", "boolean", "Encaissement et émission des tickets de vente.", 10, True, True, True, True),
    FeatureDefinition("module_credit_sales", "Ventes à crédit & créances", "modules", "boolean", "Ventes à crédit client et encaissement des dettes.", 11, True, False, True, True),
    FeatureDefinition("module_clients", "Gestion fichier clients", "modules", "boolean", "Création et mise à jour des fiches clients.", 12, False, True, True, True),
    FeatureDefinition("module_suppliers", "Gestion fournisseurs & dettes", "modules", "boolean", "Annuaire fournisseurs, soldes et règlements.", 13, True, False, True, True),
    FeatureDefinition("module_supplies", "Approvisionnements stock", "modules", "boolean", "Réceptions d'achats fournisseurs et calcul PAMP.", 14, True, False, True, True),
    FeatureDefinition("module_expenses", "Décaissements & charges", "modules", "boolean", "Suivi des dépenses de boutique par catégorie.", 15, False, True, True, True),
    FeatureDefinition("module_cash_register_z", "Clôture de caisse Z", "modules", "boolean", "Ouverture et clôture Z des sessions de caisse.", 16, True, False, True, True),
    FeatureDefinition("module_returns_refunds", "Retours & avoirs", "modules", "boolean", "Traitement des retours produits et remboursements.", 17, False, False, True, True),
    FeatureDefinition("module_audit_logs", "Journal d'audit boutique", "modules", "boolean", "Traçabilité des actions sensibles de la boutique.", 18, True, False, True, True),
    FeatureDefinition("multi_magasin_view", "Vue consolidée multi-magasins", "multi_magasin", "boolean", "Agrégation des indicateurs sur l'ensemble des magasins.", 20, True, False, True, True),
    FeatureDefinition("magasin_custom_pricing", "Prix spécifiques par magasin", "multi_magasin", "boolean", "Tarification et disponibilité par point de vente.", 21, False, False, True, True),
    FeatureDefinition("stock_transfers", "Transferts inter-magasins", "multi_magasin", "boolean", "Transferts de stock validés entre magasins.", 22, True, False, True, True),
    FeatureDefinition("stock_inventory", "Inventaires & ajustements", "multi_magasin", "boolean", "Sessions d'inventaire physique et écarts de stock.", 23, False, False, True, True),
    FeatureDefinition("stock_movements_history", "Historique mouvements stock", "multi_magasin", "boolean", "Grand livre unitaire des entrées et sorties de stock.", 24, False, False, True, True),
    FeatureDefinition("dashboard_kpis", "Tableau de bord KPIs", "analytics_platform", "boolean", "Indicateurs synthétiques d'activité et alerte stock.", 30, False, True, True, True),
    FeatureDefinition("pnl_reports", "Rapports financiers P&L", "analytics_platform", "boolean", "Analyse des marges, COGS et résultats nets.", 31, True, False, True, True),
    FeatureDefinition("data_exports", "Exports Excel, CSV & PDF", "analytics_platform", "boolean", "Exportation comptable des ventes, stocks et rapports.", 32, True, False, True, True),
    FeatureDefinition("custom_branding", "Personnalisation tickets", "analytics_platform", "boolean", "Logo et mentions légales personnalisés sur reçus.", 33, True, False, True, True),
    FeatureDefinition("mobile_offline_sync", "Synchronisation mobile offline", "analytics_platform", "boolean", "Synchronisation hors-ligne avec l'application Flutter.", 34, True, True, True, True),
    FeatureDefinition("multi_currency", "Support multi-devises avancé", "analytics_platform", "boolean", "Paramétrage multi-devises et taux de conversion.", 35, True, False, False, True),
    FeatureDefinition("priority_support", "Support prioritaire", "analytics_platform", "boolean", "Assistance prioritaire et SLA dédié.", 36, True, False, False, True),
)

FEATURE_CATALOG_BY_CODE: Dict[str, FeatureDefinition] = {
    item.feature_code: item for item in FEATURE_CATALOG
}


def serialize_feature_catalog() -> List[Dict[str, Any]]:
    """Return catalog metadata sorted by display_order for public/admin UI."""
    return [
        {
            "feature_code": item.feature_code,
            "feature_name": item.feature_name,
            "category": item.category,
            "value_type": item.value_type,
            "description": item.description,
            "display_order": item.display_order,
            "show_on_pricing": item.show_on_pricing,
            "defaults": {
                "free": item.free_default,
                "pro": item.pro_default,
                "enterprise": item.enterprise_default,
            },
        }
        for item in FEATURE_CATALOG
    ]


def validate_plan_features(features_payload: Optional[List[Dict[str, Any]]]) -> None:
    if not features_payload:
        return
    seen: set[str] = set()
    for entry in features_payload:
        code = str(entry.get("feature_code") or "").strip()
        if code not in FEATURE_CATALOG_BY_CODE:
            raise ValueError(f"Code d'accès inconnu dans le catalogue : '{code}'")
        if code in seen:
            raise ValueError(f"Doublon détecté pour le code d'accès : '{code}'")
        seen.add(code)
        defn = FEATURE_CATALOG_BY_CODE[code]
        if defn.value_type == "limit_number":
            limit_val = entry.get("int_limit", 0)
            if limit_val is None or int(limit_val) < -1:
                raise ValueError(f"La limite '{code}' doit être >= -1 (-1 = illimité)")


def _default_for_plan(defn: FeatureDefinition, plan_code: str, use_plan_defaults: bool) -> Any:
    if use_plan_defaults:
        if plan_code == "free":
            return defn.free_default
        if plan_code == "pro":
            return defn.pro_default
        if plan_code == "enterprise":
            return defn.enterprise_default
    return False if defn.value_type == "boolean" else 0


def sync_plan_features_from_catalog(
    db: Session,
    plan: SaasPlan,
    provided_features: Optional[List[Dict[str, Any]]] = None,
    use_plan_defaults: bool = False,
) -> None:
    """Ensure all 28 catalog features exist on a plan with safe defaults."""
    provided_map = {
        str(f.get("feature_code")).strip(): f
        for f in (provided_features or [])
        if f.get("feature_code")
    }
    existing_map = {
        row.feature_code: row
        for row in db.query(SaasPlanFeature).filter(SaasPlanFeature.plan_id == plan.id).all()
    }

    for defn in FEATURE_CATALOG:
        code = defn.feature_code
        payload_item = provided_map.get(code)
        existing = existing_map.get(code)

        if payload_item is not None:
            bool_val = bool(payload_item.get("boolean_value", False)) if defn.value_type == "boolean" else False
            int_val = int(payload_item.get("int_limit", 0)) if defn.value_type == "limit_number" else 0
            show_pricing = bool(payload_item.get("show_on_pricing", defn.show_on_pricing))
            feat_name = str(payload_item.get("feature_name") or defn.feature_name)
        else:
            if existing is not None and provided_features is None and use_plan_defaults:
                existing.category = defn.category
                existing.description = defn.description
                existing.display_order = defn.display_order
                continue
            default_val = _default_for_plan(defn, plan.code, use_plan_defaults)
            bool_val = bool(default_val) if defn.value_type == "boolean" else False
            int_val = int(default_val) if defn.value_type == "limit_number" else 0
            show_pricing = defn.show_on_pricing
            feat_name = defn.feature_name

        if existing:
            existing.feature_name = feat_name
            existing.category = defn.category
            existing.description = defn.description
            existing.display_order = defn.display_order
            existing.show_on_pricing = show_pricing
            existing.value_type = defn.value_type
            existing.boolean_value = bool_val
            existing.int_limit = int_val
        else:
            db.add(SaasPlanFeature(
                plan_id=plan.id,
                feature_code=code,
                feature_name=feat_name,
                category=defn.category,
                description=defn.description,
                display_order=defn.display_order,
                show_on_pricing=show_pricing,
                value_type=defn.value_type,
                boolean_value=bool_val,
                int_limit=int_val,
            ))
