import React from 'react';
import type { BillingCycle } from '../utils/pricingHelpers';

interface PricingBillingToggleProps {
  billingCycle: BillingCycle;
  onChange: (cycle: BillingCycle) => void;
}

export const PricingBillingToggle: React.FC<PricingBillingToggleProps> = ({
  billingCycle,
  onChange,
}) => {
  const isYearly = billingCycle === 'yearly';

  return (
    <div className="flex flex-wrap items-center justify-center gap-3 pt-2">
      <button
        type="button"
        onClick={() => onChange('monthly')}
        className={`text-sm font-semibold transition ${
          !isYearly ? 'text-[#29ABE2]' : 'text-[#5A7184] dark:text-slate-400'
        }`}
      >
        Facturation Mensuelle
      </button>

      <button
        type="button"
        role="switch"
        aria-checked={isYearly}
        aria-label="Basculer entre facturation mensuelle et annuelle"
        onClick={() => onChange(isYearly ? 'monthly' : 'yearly')}
        className="w-12 h-6 rounded-full bg-slate-300 dark:bg-dark-700 p-1 relative transition flex items-center focus:outline-none focus:ring-2 focus:ring-[#29ABE2]"
      >
        <span
          className={`w-4 h-4 rounded-full bg-white transition transform ${
            isYearly ? 'translate-x-6 !bg-[#29ABE2]' : 'translate-x-0'
          }`}
        />
      </button>

      <button
        type="button"
        onClick={() => onChange('yearly')}
        className={`text-sm font-semibold flex items-center gap-1.5 transition ${
          isYearly ? 'text-[#29ABE2]' : 'text-[#5A7184] dark:text-slate-400'
        }`}
      >
        <span>Facturation Annuelle</span>
        <span className="badge-toc-success text-[10px]">2 MOIS OFFERTS</span>
      </button>
    </div>
  );
};
