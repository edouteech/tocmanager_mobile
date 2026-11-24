import type { SaasPlan } from '../../../types';
import { getCurrencySymbol } from '../../../lib/currencies';

export type BillingCycle = 'monthly' | 'yearly';

export interface NormalizedPlanFeature {
  id: string;
  label: string;
  granted: boolean;
}

export function getPlanPrice(plan: SaasPlan, cycle: BillingCycle): number {
  return cycle === 'yearly' ? plan.price_yearly : plan.price_monthly;
}

export function getYearlySavingsPercent(plan: SaasPlan): number {
  const annualAtMonthlyRate = plan.price_monthly * 12;
  if (annualAtMonthlyRate <= 0 || plan.price_yearly >= annualAtMonthlyRate) {
    return 0;
  }
  return Math.round(((annualAtMonthlyRate - plan.price_yearly) / annualAtMonthlyRate) * 100);
}

export function formatPlanPrice(amount: number, currency = 'XOF'): string {
  const formatted = new Intl.NumberFormat('fr-FR', {
    style: 'decimal',
    maximumFractionDigits: 0,
  }).format(amount || 0);
  const code = (currency || 'XOF').toUpperCase();
  const displayCurrency =
    code === 'XOF' || code === 'XAF' || code === 'FCFA'
      ? 'FCFA'
      : getCurrencySymbol(code);
  return `${formatted} ${displayCurrency}`;
}

export function getPlanCtaLabel(plan: SaasPlan): string {
  if (plan.trial_period_days > 0) {
    return `Essayer ${plan.trial_period_days} jours gratuitement`;
  }
  if (plan.code === 'free') {
    return 'Commencer gratuitement';
  }
  return 'Choisir ce forfait';
}

export function getVisiblePlanFeatures(
  plan: SaasPlan,
  maxItems = 10
): NormalizedPlanFeature[] {
  return (plan.features || [])
    .filter((feat) => feat.show_on_pricing !== false)
    .slice(0, maxItems)
    .map((feat) => {
      const granted =
        feat.value_type === 'boolean' ? feat.boolean_value : feat.int_limit !== 0;
      const limitLabel =
        feat.value_type === 'limit_number'
          ? feat.int_limit === -1
            ? 'Illimité'
            : String(feat.int_limit)
          : null;

      return {
        id: feat.id || feat.feature_code,
        label: limitLabel !== null ? `${feat.feature_name} (${limitLabel})` : feat.feature_name,
        granted,
      };
    });
}
