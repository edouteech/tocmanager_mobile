from sqlalchemy.orm import Session
from app.models import SaasPlan, SaasPlanFeature


def seed_saas_plans(db: Session) -> None:
    """Initialise les forfaits SaaS par défaut si absents."""
    plan_free = db.query(SaasPlan).filter(SaasPlan.code == "free").first()
    if not plan_free:
        plan_free = SaasPlan(
            name="Plan Gratuit",
            code="free",
            description="Idéal pour démarrer avec un point de vente unique",
            price_monthly=0.0,
            price_yearly=0.0,
            currency="XOF",
            trial_period_days=0,
            badge="GRATUIT",
            is_active=True,
        )
        db.add(plan_free)
        db.flush()

        db.add_all([
            SaasPlanFeature(plan_id=plan_free.id, feature_code="max_magasins", feature_name="Nombre de magasins", value_type="limit_number", int_limit=1),
            SaasPlanFeature(plan_id=plan_free.id, feature_code="max_products", feature_name="Articles catalogue", value_type="limit_number", int_limit=100),
            SaasPlanFeature(plan_id=plan_free.id, feature_code="max_users", feature_name="Comptes collaborateurs", value_type="limit_number", int_limit=2),
            SaasPlanFeature(plan_id=plan_free.id, feature_code="stock_transfers", feature_name="Transferts de stock inter-magasins", value_type="boolean", boolean_value=False),
            SaasPlanFeature(plan_id=plan_free.id, feature_code="pnl_reports", feature_name="Rapports financiers P&L avancés", value_type="boolean", boolean_value=False),
            SaasPlanFeature(plan_id=plan_free.id, feature_code="data_exports", feature_name="Exports comptables PDF/Excel", value_type="boolean", boolean_value=False),
            SaasPlanFeature(plan_id=plan_free.id, feature_code="custom_branding", feature_name="Personnalisation tickets de caisse", value_type="boolean", boolean_value=False),
        ])

    plan_pro = db.query(SaasPlan).filter(SaasPlan.code == "pro").first()
    if not plan_pro:
        plan_pro = SaasPlan(
            name="Plan Pro",
            code="pro",
            description="Pour les commerces en croissance et réseaux de boutiques",
            price_monthly=15000.0,
            price_yearly=150000.0,
            currency="XOF",
            trial_period_days=14,
            badge="POPULAIRE",
            is_active=True,
        )
        db.add(plan_pro)
        db.flush()

        db.add_all([
            SaasPlanFeature(plan_id=plan_pro.id, feature_code="max_magasins", feature_name="Nombre de magasins", value_type="limit_number", int_limit=5),
            SaasPlanFeature(plan_id=plan_pro.id, feature_code="max_products", feature_name="Articles catalogue", value_type="limit_number", int_limit=2000),
            SaasPlanFeature(plan_id=plan_pro.id, feature_code="max_users", feature_name="Comptes collaborateurs", value_type="limit_number", int_limit=10),
            SaasPlanFeature(plan_id=plan_pro.id, feature_code="stock_transfers", feature_name="Transferts de stock inter-magasins", value_type="boolean", boolean_value=True),
            SaasPlanFeature(plan_id=plan_pro.id, feature_code="pnl_reports", feature_name="Rapports financiers P&L avancés", value_type="boolean", boolean_value=True),
            SaasPlanFeature(plan_id=plan_pro.id, feature_code="data_exports", feature_name="Exports comptables PDF/Excel", value_type="boolean", boolean_value=True),
            SaasPlanFeature(plan_id=plan_pro.id, feature_code="custom_branding", feature_name="Personnalisation tickets de caisse", value_type="boolean", boolean_value=True),
        ])

    plan_ent = db.query(SaasPlan).filter(SaasPlan.code == "enterprise").first()
    if not plan_ent:
        plan_ent = SaasPlan(
            name="Plan Entreprise",
            code="enterprise",
            description="Solution complète et illimitée pour grands réseaux commerciaux",
            price_monthly=40000.0,
            price_yearly=400000.0,
            currency="XOF",
            trial_period_days=14,
            badge="ILLIMITÉ",
            is_active=True,
        )
        db.add(plan_ent)
        db.flush()

        db.add_all([
            SaasPlanFeature(plan_id=plan_ent.id, feature_code="max_magasins", feature_name="Nombre de magasins", value_type="limit_number", int_limit=-1),
            SaasPlanFeature(plan_id=plan_ent.id, feature_code="max_products", feature_name="Articles catalogue", value_type="limit_number", int_limit=-1),
            SaasPlanFeature(plan_id=plan_ent.id, feature_code="max_users", feature_name="Comptes collaborateurs", value_type="limit_number", int_limit=-1),
            SaasPlanFeature(plan_id=plan_ent.id, feature_code="stock_transfers", feature_name="Transferts de stock inter-magasins", value_type="boolean", boolean_value=True),
            SaasPlanFeature(plan_id=plan_ent.id, feature_code="pnl_reports", feature_name="Rapports financiers P&L avancés", value_type="boolean", boolean_value=True),
            SaasPlanFeature(plan_id=plan_ent.id, feature_code="data_exports", feature_name="Exports comptables PDF/Excel", value_type="boolean", boolean_value=True),
            SaasPlanFeature(plan_id=plan_ent.id, feature_code="custom_branding", feature_name="Personnalisation tickets de caisse", value_type="boolean", boolean_value=True),
        ])

    db.commit()
