import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Shield, Sparkles } from 'lucide-react';
import { saasApi } from '../../lib/api';
import { FeatureCatalogItem } from '../../types';
import { PublicNavbar } from '../../components/public/PublicNavbar';
import { PublicFooter } from '../../components/public/PublicFooter';
import { usePublicPlans } from './hooks/usePublicPlans';
import { usePageTitle } from './hooks/usePageTitle';
import { PricingBillingToggle } from './components/PricingBillingToggle';
import { PricingPlanCard } from './components/PricingPlanCard';
import { PricingComparisonMatrix } from './PricingComparisonMatrix';
import type { BillingCycle } from './utils/pricingHelpers';

export const PricingPage: React.FC = () => {
  const navigate = useNavigate();
  const { plans, isLoading } = usePublicPlans();
  const [catalog, setCatalog] = useState<FeatureCatalogItem[]>([]);
  const [billingCycle, setBillingCycle] = useState<BillingCycle>('monthly');

  usePageTitle(
    'Tarifs & Forfaits — TocManager SaaS',
    'Comparez les forfaits Gratuit, Pro et Entreprise de TocManager et démarrez votre essai gratuit de 14 jours.'
  );

  useEffect(() => {
    saasApi
      .getFeaturesCatalog()
      .then((catalogData) => setCatalog(catalogData))
      .catch((e) => console.error('Error fetching pricing catalog:', e));
  }, []);

  const handleSelectPlan = (planCode: string) => {
    navigate(`/inscription?plan=${planCode}&cycle=${billingCycle}`);
  };

  return (
    <div className="min-h-screen bg-[#F5FAFD] dark:bg-dark-900 text-[#1C2B3A] dark:text-slate-100 flex flex-col font-sans transition-colors duration-200">
      <PublicNavbar />

      <main id="main-content" className="flex-1">
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

          <PricingBillingToggle billingCycle={billingCycle} onChange={setBillingCycle} />
        </section>

        <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10 w-full">
          {isLoading ? (
            <div className="text-center py-16 text-[#5A7184]">Chargement des tarifs en cours...</div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-3 gap-8 items-stretch">
              {plans.map((plan) => (
                <PricingPlanCard
                  key={plan.id}
                  plan={plan}
                  billingCycle={billingCycle}
                  onSelectPlan={handleSelectPlan}
                />
              ))}
            </div>
          )}
        </section>

        <PricingComparisonMatrix plans={plans} catalog={catalog} />

        <section className="bg-white dark:bg-dark-800 border-t border-[#E8EFF5] dark:border-dark-600 py-12">
          <div className="max-w-4xl mx-auto px-4 text-center space-y-4">
            <Shield className="w-8 h-8 text-[#29ABE2] mx-auto" />
            <h2 className="text-xl font-bold">Sans engagement, sans carte bancaire à l’inscription</h2>
            <p className="text-xs text-[#5A7184] dark:text-slate-400 max-w-lg mx-auto">
              Testez TocManager à votre rythme. Vous pouvez à tout moment faire évoluer votre forfait ou revenir au plan gratuit depuis votre espace d’administration.
            </p>
          </div>
        </section>
      </main>

      <PublicFooter />
    </div>
  );
};
