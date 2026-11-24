import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { ArrowRight, ShieldCheck } from 'lucide-react';
import { usePublicPlans } from '../hooks/usePublicPlans';
import type { BillingCycle } from '../utils/pricingHelpers';
import { PricingBillingToggle } from './PricingBillingToggle';
import { PricingPlanCard } from './PricingPlanCard';

export const LandingPricingSection: React.FC = () => {
  const navigate = useNavigate();
  const [billingCycle, setBillingCycle] = useState<BillingCycle>('monthly');
  const { plans, isLoading } = usePublicPlans();

  const handleSelectPlan = (planCode: string) => {
    navigate(`/inscription?plan=${planCode}&cycle=${billingCycle}`);
  };

  return (
    <section
      id="tarifs"
      className="scroll-mt-20 landing-section-deferred py-20 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 space-y-10"
    >
      <div className="text-center max-w-3xl mx-auto space-y-4">
        <span className="text-xs font-bold uppercase tracking-wider text-[#29ABE2]">
          Tarification transparente
        </span>
        <h2 className="text-3xl sm:text-4xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">
          Des forfaits adaptés à chaque étape de votre activité
        </h2>
        <p className="text-sm sm:text-base text-[#5A7184] dark:text-slate-300">
          Commencez gratuitement sur un point de vente ou activez 14 jours d’essai gratuit sur le Plan Pro pour connecter tous vos magasins.
        </p>

        <PricingBillingToggle billingCycle={billingCycle} onChange={setBillingCycle} />
      </div>

      {isLoading ? (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8" aria-label="Chargement des tarifs">
          {[0, 1, 2].map((idx) => (
            <div
              key={idx}
              className="card-toc p-8 h-[420px] animate-pulse bg-white/70 dark:bg-dark-800/70"
            />
          ))}
        </div>
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

      <div className="flex flex-col sm:flex-row items-center justify-between gap-4 pt-4 text-xs text-[#5A7184] dark:text-slate-400">
        <div className="flex items-center gap-2">
          <ShieldCheck className="w-4 h-4 text-[#27AE60] shrink-0" />
          <span>Sans carte bancaire à l’inscription • Paiement Mobile Money FeexPay</span>
        </div>
        <Link
          to="/tarifs"
          className="inline-flex items-center gap-1.5 font-bold text-[#29ABE2] hover:text-[#1A8FBF] transition"
        >
          <span>Comparer les 28 fonctionnalités en détail</span>
          <ArrowRight className="w-4 h-4" />
        </Link>
      </div>
    </section>
  );
};
