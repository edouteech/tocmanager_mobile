from sqlalchemy.orm import Session
from app.models import SaasPlan
from app.services.feature_catalog import sync_plan_features_from_catalog

DEFAULT_PLANS = (
    {
        "name": "Plan Gratuit",
        "code": "free",
        "description": "Idéal pour démarrer avec un point de vente unique",
        "price_monthly": 0.0,
        "price_yearly": 0.0,
        "currency": "XOF",
        "trial_period_days": 0,
        "badge": "GRATUIT",
    },
    {
        "name": "Plan Pro",
        "code": "pro",
        "description": "Pour les commerces en croissance et réseaux de boutiques",
        "price_monthly": 15000.0,
        "price_yearly": 150000.0,
        "currency": "XOF",
        "trial_period_days": 14,
        "badge": "POPULAIRE",
    },
    {
        "name": "Plan Entreprise",
        "code": "enterprise",
        "description": "Solution complète et illimitée pour grands réseaux commerciaux",
        "price_monthly": 40000.0,
        "price_yearly": 400000.0,
        "currency": "XOF",
        "trial_period_days": 14,
        "badge": "ILLIMITÉ",
    },
)


def seed_saas_plans(db: Session) -> None:
    """Seed the 3 SaaS plans and sync all 28 catalog features idempotently."""
    for cfg in DEFAULT_PLANS:
        plan = db.query(SaasPlan).filter(SaasPlan.code == cfg["code"]).first()
        if not plan:
            plan = SaasPlan(**cfg, is_active=True)
            db.add(plan)
            db.flush()
        sync_plan_features_from_catalog(db, plan, provided_features=None, use_plan_defaults=True)

    db.commit()
