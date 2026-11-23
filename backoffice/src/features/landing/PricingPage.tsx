import React, { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Store, Sparkles, Shield, ArrowRight, CheckCircle2, X, Gift } from 'lucide-react';
import { saasApi } from '../../lib/api';
import { FeatureCatalogItem, SaasPlan } from '../../types';
import { PricingComparisonMatrix } from './PricingComparisonMatrix';

export const PricingPage: React.FC = () => {
  const navigate = useNavigate();
  const [plans, setPlans] = useState<SaasPlan[]>([]);
  const [catalog, setCatalog] = useState<FeatureCatalogItem[]>([]);
  const [billingCycle, setBillingCycle] = useState<'monthly' | 'yearly'>('monthly');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([saasApi.getPlans(), saasApi.getFeaturesCatalog()])
      .then(([plansData, catalogData]) => {
        setPlans(plansData);
        setCatalog(catalogData);
      })
      .catch((e) => console.error('Error fetching pricing data:', e))
      .finally(() => setLoading(false));
  }, []);

  const handleSelectPlan = (planCode: string) => {
    navigate(`/inscription?plan=${planCode}&cycle=${billingCycle}`);
  };

  return (
    <div className="min-h-screen bg-[#F5FAFD] dark:bg-dark-900 text-[#1C2B3A] dark:text-slate-100 flex flex-col font-sans transition-colors duration-200">
      <header className="sticky top-0 z-40 bg-white/90 dark:bg-dark-800/90 backdrop-blur-md border-b border-[#E8EFF5] dark:border-dark-600">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
          <Link to="/" className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl toc-gradient flex items-center justify-center text-white shadow-soft">
              <Store className="w-6 h-6" />
            </div>
            <span className="text-xl font-black text-[#1C2B3A] dark:text-white">
              Toc<span className="text-[#29ABE2]">Manager</span>
            </span>
          </Link>

          <div className="flex items-center gap-4">
            <Link to="/contact" className="text-sm font-medium text-[#5A7184] hover:text-[#29ABE2]">
              Contact
            </Link>
            <Link to="/login" className="text-sm font-medium hover:text-[#29ABE2]">
              Connexion
            </Link>
            <Link to="/inscription" className="btn-primary py-2 text-xs sm:text-sm">
              Inscription Gratuite
            </Link>
          </div>
        </div>
      </header>

      <section className="pt-12 pb-8 text-center px-4 space-y-4">
        <div className="badge-toc-primary mx-auto">
          <Sparkles className="w-3.5 h-3.5" />
          <span>Tarifs Clairs, Sans Surprise</span>
        </div>
        <h1 className="text-3xl sm:text-4xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">
          Des forfaits conçus pour chaque étape de votre croissance
        </h1>
        <p className="text-[#5A7184] dark:text-slate-300 text-sm max-w-xl mx-auto">
          Démarrez gratuitement avec un magasin. Passez au pack Pro pour connecter vos succursales et gérer vos transferts de stocks.
        </p>

        <div className="flex items-center justify-center gap-3 pt-4">
          <span className={`text-sm font-medium ${billingCycle === 'monthly' ? 'text-[#29ABE2] font-bold' : 'text-[#5A7184]'}`}>
            Facturation Mensuelle
          </span>
          <button
            type="button"
            onClick={() => setBillingCycle(billingCycle === 'monthly' ? 'yearly' : 'monthly')}
            className="w-12 h-6 rounded-full bg-slate-300 dark:bg-dark-700 p-1 relative transition flex items-center"
            aria-label="Basculer facturation mensuelle ou annuelle"
          >
            <div
              className={`w-4 h-4 rounded-full bg-white transition transform ${
                billingCycle === 'yearly' ? 'translate-x-6 !bg-[#29ABE2]' : 'translate-x-0'
              }`}
            />
          </button>
          <span className={`text-sm font-medium flex items-center gap-1.5 ${billingCycle === 'yearly' ? 'text-[#29ABE2] font-bold' : 'text-[#5A7184]'}`}>
            Facturation Annuelle
            <span className="badge-toc-success text-[10px]">2 MOIS OFFERTS</span>
          </span>
        </div>
      </section>

      <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10 w-full">
        {loading ? (
          <div className="text-center py-16 text-[#5A7184]">Chargement des tarifs en cours...</div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 items-stretch">
            {plans.map((plan) => {
              const isPro = plan.code === 'pro';
              const price = billingCycle === 'monthly' ? plan.price_monthly : plan.price_yearly;
              const displayedFeatures = (plan.features || []).filter((f) => f.show_on_pricing !== false);

              return (
                <div
                  key={plan.id}
                  className={`relative flex flex-col justify-between rounded-2xl p-8 transition duration-200 bg-white dark:bg-dark-800 ${
                    isPro
                      ? 'border-2 border-[#29ABE2] shadow-soft-lg ring-4 ring-[#29ABE2]/10'
                      : 'border border-[#E8EFF5] dark:border-dark-600 shadow-soft'
                  }`}
                >
                  {plan.badge && (
                    <div className="absolute -top-3.5 left-1/2 -translate-x-1/2 px-3 py-1 rounded-full text-[11px] font-bold uppercase tracking-wider bg-[#29ABE2] text-white shadow-sm">
                      {plan.badge}
                    </div>
                  )}

                  <div className="space-y-4">
                    <div>
                      <h3 className="text-xl font-bold text-[#1C2B3A] dark:text-white">{plan.name}</h3>
                      <p className="text-xs text-[#5A7184] dark:text-slate-400 mt-1">{plan.description}</p>
                    </div>

                    <div className="pt-2 pb-4 border-b border-[#E8EFF5] dark:border-dark-600">
                      <div className="flex items-baseline gap-1">
                        <span className="text-3xl sm:text-4xl font-extrabold text-[#1C2B3A] dark:text-white">
                          {price.toLocaleString('fr-FR')}
                        </span>
                        <span className="text-xs font-semibold text-[#5A7184]">
                          {plan.currency} / {billingCycle === 'monthly' ? 'mois' : 'an'}
                        </span>
                      </div>
                      {plan.trial_period_days > 0 && (
                        <div className="inline-flex items-center gap-1.5 text-xs text-[#29ABE2] font-semibold mt-1.5">
                          <Gift className="w-3.5 h-3.5" />
                          <span>{plan.trial_period_days} jours d'essai gratuit offerts</span>
                        </div>
                      )}
                    </div>

                    <div className="space-y-2.5 pt-2 text-xs">
                      {displayedFeatures.slice(0, 10).map((feat) => {
                        const isGranted = feat.value_type === 'boolean' ? feat.boolean_value : feat.int_limit !== 0;
                        const valueText =
                          feat.value_type === 'limit_number'
                            ? feat.int_limit === -1
                              ? 'Illimité'
                              : feat.int_limit
                            : null;

                        return (
                          <div key={feat.id} className="flex items-center gap-2.5">
                            {isGranted ? (
                              <CheckCircle2 className="w-4 h-4 text-[#27AE60] shrink-0" />
                            ) : (
                              <div className="w-4 h-4 rounded-full border border-slate-300 dark:border-dark-600 flex items-center justify-center text-slate-400 shrink-0">
                                <X className="w-2.5 h-2.5" />
                              </div>
                            )}
                            <span className={isGranted ? 'text-[#1C2B3A] dark:text-slate-200' : 'text-[#9FB3C8] line-through'}>
                              {feat.feature_name}
                              {valueText !== null ? ` (${valueText})` : ''}
                            </span>
                          </div>
                        );
                      })}
                    </div>
                  </div>

                  <div className="pt-8 space-y-2">
                    <button
                      type="button"
                      onClick={() => handleSelectPlan(plan.code)}
                      className={`w-full py-3 rounded-xl text-xs font-bold transition flex items-center justify-center gap-2 ${
                        isPro
                          ? 'bg-[#29ABE2] hover:bg-[#1A8FBF] text-white'
                          : 'bg-[#F0F9FE] hover:bg-[#E8F5FD] dark:bg-dark-700 dark:hover:bg-dark-600 text-[#1C2B3A] dark:text-white'
                      }`}
                    >
                      <span>
                        {plan.trial_period_days > 0
                          ? `Essayer ${plan.trial_period_days} jours gratuitement`
                          : plan.code === 'free'
                          ? 'Commencer Gratuitement'
                          : 'Choisir ce forfait'}
                      </span>
                      <ArrowRight className="w-4 h-4" />
                    </button>
                    {plan.code === 'enterprise' && (
                      <Link
                        to="/contact"
                        className="block text-center text-[11px] font-semibold text-[#29ABE2] hover:underline pt-1"
                      >
                        Besoin d'un devis personnalisé ? Contactez-nous
                      </Link>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </section>

      <PricingComparisonMatrix plans={plans} catalog={catalog} />

      <section className="bg-white dark:bg-dark-800 border-t border-[#E8EFF5] dark:border-dark-600 py-12">
        <div className="max-w-4xl mx-auto px-4 text-center space-y-4">
          <Shield className="w-8 h-8 text-[#29ABE2] mx-auto" />
          <h2 className="text-xl font-bold">Sans engagement, sans carte bancaire à l'inscription</h2>
          <p className="text-xs text-[#5A7184] dark:text-slate-400 max-w-lg mx-auto">
            Testez TocManager à votre rythme. Vous pouvez à tout moment faire évoluer votre forfait ou revenir au plan gratuit depuis votre espace d'administration.
          </p>
        </div>
      </section>

      <footer className="bg-[#F5FAFD] dark:bg-dark-900 border-t border-[#E8EFF5] dark:border-dark-600 py-8 text-xs text-center text-[#5A7184]">
        © 2026 TocManager SaaS • Tous droits réservés •{' '}
        <Link to="/contact" className="text-[#29ABE2] hover:underline">
          Support & Contact
        </Link>
      </footer>
    </div>
  );
};
