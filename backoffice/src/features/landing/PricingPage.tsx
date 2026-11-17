import React, { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Store, Check, Sparkles, Shield, ArrowRight, Zap, CheckCircle2 } from 'lucide-react';
import { saasApi } from '../../lib/api';
import { SaasPlan } from '../../types';

export const PricingPage: React.FC = () => {
  const navigate = useNavigate();
  const [plans, setPlans] = useState<SaasPlan[]>([]);
  const [billingCycle, setBillingCycle] = useState<'monthly' | 'yearly'>('monthly');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    saasApi
      .getPlans()
      .then((data) => setPlans(data))
      .catch((e) => console.error('Error fetching plans:', e))
      .finally(() => setLoading(false));
  }, []);

  const handleSelectPlan = (planCode: string) => {
    navigate(`/inscription?plan=${planCode}`);
  };

  return (
    <div className="min-h-screen bg-slate-50 dark:bg-slate-950 text-slate-800 dark:text-slate-100 flex flex-col font-sans transition-colors duration-200">
      {/* Header */}
      <header className="sticky top-0 z-40 bg-white/80 dark:bg-slate-900/80 backdrop-blur-md border-b border-slate-200 dark:border-slate-800">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
          <Link to="/" className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-indigo-600 to-indigo-800 flex items-center justify-center text-white shadow-md">
              <Store className="w-6 h-6" />
            </div>
            <span className="text-xl font-black text-slate-900 dark:text-white">
              Toc<span className="text-indigo-600">Manager</span>
            </span>
          </Link>

          <div className="flex items-center gap-4">
            <Link to="/login" className="text-sm font-medium hover:text-indigo-600">
              Connexion
            </Link>
            <Link
              to="/inscription"
              className="px-4 py-2 text-sm font-semibold text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg shadow-sm transition"
            >
              Inscription Gratuite
            </Link>
          </div>
        </div>
      </header>

      {/* Hero Tarifs */}
      <section className="pt-12 pb-8 text-center px-4 space-y-4">
        <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-indigo-100 dark:bg-indigo-950 text-indigo-700 dark:text-indigo-300">
          <Sparkles className="w-3.5 h-3.5" />
          <span>Tarifs Clairs, Sans Surprise</span>
        </div>
        <h1 className="text-4xl font-extrabold text-slate-900 dark:text-white tracking-tight">
          Des forfaits conçus pour chaque étape de votre croissance
        </h1>
        <p className="text-slate-600 dark:text-slate-300 text-sm max-w-xl mx-auto">
          Démarrez gratuitement avec un magasin. Passez au pack Pro pour connecter vos succursales et gérer vos transferts de stocks en toute liberté.
        </p>

        {/* Switcher Mensuel / Annuel */}
        <div className="flex items-center justify-center gap-3 pt-4">
          <span className={`text-sm font-medium ${billingCycle === 'monthly' ? 'text-indigo-600 font-bold' : 'text-slate-500'}`}>
            Facturation Mensuelle
          </span>
          <button
            onClick={() => setBillingCycle(billingCycle === 'monthly' ? 'yearly' : 'monthly')}
            className="w-12 h-6 rounded-full bg-slate-300 dark:bg-slate-700 p-1 relative transition flex items-center"
          >
            <div
              className={`w-4 h-4 rounded-full bg-white transition transform ${
                billingCycle === 'yearly' ? 'translate-x-6 bg-indigo-600' : 'translate-x-0'
              }`}
            />
          </button>
          <span className={`text-sm font-medium flex items-center gap-1.5 ${billingCycle === 'yearly' ? 'text-indigo-600 font-bold' : 'text-slate-500'}`}>
            Facturation Annuelle
            <span className="px-2 py-0.5 text-[10px] bg-emerald-100 dark:bg-emerald-950 text-emerald-700 dark:text-emerald-400 font-bold rounded-full">
              2 MOIS OFFERTS
            </span>
          </span>
        </div>
      </section>

      {/* Cartes de Prix */}
      <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10 w-full">
        {loading ? (
          <div className="text-center py-16 text-slate-400">Chargement des tarifs en cours...</div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 items-stretch">
            {plans.map((plan) => {
              const isPro = plan.code === 'pro';
              const price = billingCycle === 'monthly' ? plan.price_monthly : plan.price_yearly;

              return (
                <div
                  key={plan.id}
                  className={`relative flex flex-col justify-between rounded-2xl p-8 transition duration-200 ${
                    isPro
                      ? 'bg-white dark:bg-slate-900 border-2 border-indigo-600 shadow-xl ring-4 ring-indigo-500/10'
                      : 'bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 shadow-sm hover:shadow-md'
                  }`}
                >
                  {plan.badge && (
                    <div className="absolute -top-3.5 left-1/2 -translate-x-1/2 px-3 py-1 rounded-full text-[11px] font-bold uppercase tracking-wider bg-indigo-600 text-white shadow-sm">
                      {plan.badge}
                    </div>
                  )}

                  <div className="space-y-4">
                    <div>
                      <h3 className="text-xl font-bold text-slate-900 dark:text-white">{plan.name}</h3>
                      <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">{plan.description}</p>
                    </div>

                    <div className="pt-2 pb-4 border-b border-slate-100 dark:border-slate-800">
                      <div className="flex items-baseline gap-1">
                        <span className="text-3xl sm:text-4xl font-extrabold text-slate-900 dark:text-white">
                          {price.toLocaleString('fr-FR')}
                        </span>
                        <span className="text-xs font-semibold text-slate-500">
                          {plan.currency} / {billingCycle === 'monthly' ? 'mois' : 'an'}
                        </span>
                      </div>
                      {plan.trial_period_days > 0 && (
                        <div className="text-xs text-indigo-600 dark:text-indigo-400 font-semibold mt-1">
                          🎁 {plan.trial_period_days} jours d'essai gratuit offerts
                        </div>
                      )}
                    </div>

                    {/* Features list */}
                    <div className="space-y-3 pt-2 text-xs">
                      {plan.features?.map((feat) => {
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
                              <CheckCircle2 className="w-4 h-4 text-emerald-500 shrink-0" />
                            ) : (
                              <div className="w-4 h-4 rounded-full border border-slate-300 dark:border-slate-700 flex items-center justify-center text-[10px] text-slate-400">
                                ✕
                              </div>
                            )}
                            <span className={isGranted ? 'text-slate-700 dark:text-slate-200' : 'text-slate-400 line-through'}>
                              {feat.feature_name}
                              {valueText ? ` (${valueText})` : ''}
                            </span>
                          </div>
                        );
                      })}
                    </div>
                  </div>

                  <div className="pt-8">
                    <button
                      onClick={() => handleSelectPlan(plan.code)}
                      className={`w-full py-3 rounded-xl text-xs font-bold transition flex items-center justify-center gap-2 ${
                        isPro
                          ? 'bg-indigo-600 hover:bg-indigo-700 text-white shadow-md'
                          : 'bg-slate-100 hover:bg-slate-200 dark:bg-slate-800 dark:hover:bg-slate-700 text-slate-800 dark:text-slate-200'
                      }`}
                    >
                      <span>
                        {plan.trial_period_days > 0
                          ? `Essayer 14 jours gratuitement`
                          : plan.code === 'free'
                          ? 'Commencer Gratuitement'
                          : 'Choisir ce forfait'}
                      </span>
                      <ArrowRight className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </section>

      {/* FAQ & Reassurance */}
      <section className="bg-white dark:bg-slate-900 border-t border-slate-200 dark:border-slate-800 py-12">
        <div className="max-w-4xl mx-auto px-4 text-center space-y-4">
          <Shield className="w-8 h-8 text-indigo-600 mx-auto" />
          <h2 className="text-xl font-bold">Sans engagement, sans carte bancaire à l'inscription</h2>
          <p className="text-xs text-slate-500 max-w-lg mx-auto">
            Testez TocManager à votre rythme. Vous pouvez à tout moment faire évoluer votre forfait ou revenir au plan gratuit depuis votre espace d'administration.
          </p>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-slate-50 dark:bg-slate-950 border-t border-slate-200 dark:border-slate-800 py-8 text-xs text-center text-slate-500">
        © 2026 TocManager SaaS • Tous droits réservés
      </footer>
    </div>
  );
};
