import { describe, expect, it } from 'vitest';
import type { SaasPlan } from '../types';
import {
  formatPlanPrice,
  getPlanCtaLabel,
  getPlanPrice,
  getVisiblePlanFeatures,
  getYearlySavingsPercent,
} from '../features/landing/utils/pricingHelpers';
import { FALLBACK_PLANS } from '../features/landing/data/fallbackPlans';

describe('pricingHelpers', () => {
  const freePlan = FALLBACK_PLANS[0];
  const proPlan = FALLBACK_PLANS[1];

  it('returns monthly or yearly price according to billing cycle', () => {
    expect(getPlanPrice(proPlan, 'monthly')).toBe(15000);
    expect(getPlanPrice(proPlan, 'yearly')).toBe(150000);
  });

  it('computes yearly savings percentage and returns 0 when free or not discounted', () => {
    expect(getYearlySavingsPercent(freePlan)).toBe(0);
    expect(getYearlySavingsPercent(proPlan)).toBe(17);

    const nonDiscounted: SaasPlan = {
      ...proPlan,
      price_monthly: 10000,
      price_yearly: 120000,
    };
    expect(getYearlySavingsPercent(nonDiscounted)).toBe(0);
  });

  it('formats price with currency symbol in French locale', () => {
    expect(formatPlanPrice(15000, 'XOF')).toMatch(/15[\s\u00a0\u202f]000\sFCFA/);
    expect(formatPlanPrice(0, 'XOF')).toBe('0 FCFA');
  });

  it('returns expected CTA labels for trial, free, and non-trial paid plans', () => {
    expect(getPlanCtaLabel(proPlan)).toBe('Essayer 14 jours gratuitement');
    expect(getPlanCtaLabel(freePlan)).toBe('Commencer gratuitement');
    expect(
      getPlanCtaLabel({
        ...proPlan,
        code: 'starter',
        trial_period_days: 0,
      })
    ).toBe('Choisir ce forfait');
  });

  it('maps -1 numeric limit to Illimite and filters out hidden features', () => {
    const enterprisePlan = FALLBACK_PLANS[2];
    const features = getVisiblePlanFeatures(enterprisePlan, 5);
    expect(features[0].label).toContain('Illimité');

    const hiddenPlan: SaasPlan = {
      ...freePlan,
      features: [
        {
          id: 'hidden-1',
          feature_code: 'hidden_feat',
          feature_name: 'Feature Masquée',
          value_type: 'boolean',
          boolean_value: true,
          int_limit: 0,
          show_on_pricing: false,
        },
        ...freePlan.features,
      ],
    };

    const visible = getVisiblePlanFeatures(hiddenPlan, 10);
    expect(visible.some((f) => f.label === 'Feature Masquée')).toBe(false);
  });
});
