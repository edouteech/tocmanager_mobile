import React from 'react';
import { Link } from 'react-router-dom';
import { ArrowRight, CheckCircle2, Gift, X } from 'lucide-react';
import type { SaasPlan } from '../../../types';
import {
  formatPlanPrice,
  getPlanCtaLabel,
  getPlanPrice,
  getVisiblePlanFeatures,
  getYearlySavingsPercent,
  type BillingCycle,
} from '../utils/pricingHelpers';

interface PricingPlanCardProps {
  plan: SaasPlan;
  billingCycle: BillingCycle;
  onSelectPlan: (planCode: string) => void;
}

export const PricingPlanCard: React.FC<PricingPlanCardProps> = ({
  plan,
  billingCycle,
  onSelectPlan,
}) => {
  const isPro = plan.code === 'pro';
  const price = getPlanPrice(plan, billingCycle);
  const savings = billingCycle === 'yearly' ? getYearlySavingsPercent(plan) : 0;
  const features = getVisiblePlanFeatures(plan, 10);

  return (
    <div
      className={`relative flex flex-col justify-between rounded-2xl p-7 sm:p-8 transition duration-200 bg-white dark:bg-dark-800 ${
        isPro
          ? 'border-2 border-[#29ABE2] shadow-soft-lg ring-4 ring-[#29ABE2]/10'
          : 'border border-[#E8EFF5] dark:border-dark-600 shadow-soft'
      }`}
    >
      {plan.badge && (
        <div className="absolute -top-3.5 left-1/2 -translate-x-1/2 px-3 py-1 rounded-full text-[11px] font-bold uppercase tracking-wider bg-[#29ABE2] text-white shadow-sm whitespace-nowrap">
          {plan.badge}
        </div>
      )}

      <div className="space-y-4">
        <div>
          <h3 className="text-xl font-bold text-[#1C2B3A] dark:text-white">{plan.name}</h3>
          <p className="text-xs text-[#5A7184] dark:text-slate-400 mt-1">{plan.description}</p>
        </div>

        <div className="pt-2 pb-4 border-b border-[#E8EFF5] dark:border-dark-600 space-y-1.5">
          <div className="flex items-baseline gap-1.5 flex-wrap">
            <span className="text-3xl sm:text-4xl font-extrabold text-[#1C2B3A] dark:text-white">
              {formatPlanPrice(price, plan.currency)}
            </span>
            <span className="text-xs font-semibold text-[#5A7184] dark:text-slate-400">
              / {billingCycle === 'monthly' ? 'mois' : 'an'}
            </span>
          </div>

          {savings > 0 && (
            <div className="inline-flex items-center px-2 py-0.5 rounded-full text-[11px] font-bold bg-[#E8F8F0] text-[#27AE60] dark:bg-[#27AE60]/15">
              Économisez {savings}% en annuel
            </div>
          )}

          {plan.trial_period_days > 0 && (
            <div className="flex items-center gap-1.5 text-xs text-[#29ABE2] font-semibold">
              <Gift className="w-3.5 h-3.5 shrink-0" />
              <span>{plan.trial_period_days} jours d’essai gratuit offerts</span>
            </div>
          )}
        </div>

        <div className="space-y-2.5 pt-1 text-xs">
          {features.map((feat) => (
            <div key={feat.id} className="flex items-center gap-2.5">
              {feat.granted ? (
                <CheckCircle2 className="w-4 h-4 text-[#27AE60] shrink-0" />
              ) : (
                <div className="w-4 h-4 rounded-full border border-slate-300 dark:border-dark-600 flex items-center justify-center text-slate-400 shrink-0">
                  <X className="w-2.5 h-2.5" />
                </div>
              )}
              <span
                className={
                  feat.granted
                    ? 'text-[#1C2B3A] dark:text-slate-200'
                    : 'text-[#9FB3C8] line-through'
                }
              >
                {feat.label}
              </span>
            </div>
          ))}
        </div>
      </div>

      <div className="pt-8 space-y-2">
        <button
          type="button"
          onClick={() => onSelectPlan(plan.code)}
          className={`w-full py-3 rounded-xl text-xs font-bold transition flex items-center justify-center gap-2 ${
            isPro
              ? 'bg-[#29ABE2] hover:bg-[#1A8FBF] text-white'
              : 'bg-[#F0F9FE] hover:bg-[#E8F5FD] dark:bg-dark-700 dark:hover:bg-dark-600 text-[#1C2B3A] dark:text-white'
          }`}
        >
          <span>{getPlanCtaLabel(plan)}</span>
          <ArrowRight className="w-4 h-4" />
        </button>

        {plan.code === 'enterprise' && (
          <Link
            to="/contact"
            className="block text-center text-[11px] font-semibold text-[#29ABE2] hover:underline pt-1"
          >
            Besoin d’un devis personnalisé ? Contactez-nous
          </Link>
        )}
      </div>
    </div>
  );
};
