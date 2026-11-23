import React, { useEffect, useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { useSearchParams } from 'react-router-dom';
import { CheckCircle2, CreditCard, ShieldCheck, Sparkles, X } from 'lucide-react';
import { billingApi, saasApi, tenantApi } from '../../lib/api';
import { formatDateOnly } from '../../lib/formatters';
import { useAuthStore } from '../../stores/authStore';
import { useTenantStore } from '../../stores/tenantStore';
import { SaasPlan } from '../../types';
import { FeexPayCheckoutWidget } from './FeexPayCheckoutWidget';
import { InvoicesTable } from './InvoicesTable';
import { PlanUsageMeters } from './PlanUsageMeters';

export const SubscriptionPage: React.FC = () => {
  const [searchParams, setSearchParams] = useSearchParams();
  const queryClient = useQueryClient();
  const user = useAuthStore((s) => s.user);
  const { currentPlan, fetchPlanStatus } = useTenantStore();
  const [checkoutPlan, setCheckoutPlan] = useState<SaasPlan | null>(null);
  const [bannerMsg, setBannerMsg] = useState<string | null>(null);
  const [trialLoading, setTrialLoading] = useState<string | null>(null);
  const [showAllFeatures, setShowAllFeatures] = useState(false);

  const isOwner = user?.role === 'owner' || user?.role === 'merchant';

  const { data: plans = [] } = useQuery({
    queryKey: ['saas-plans'],
    queryFn: saasApi.getPlans,
  });

  const { data: invoices = [], refetch: refetchInvoices } = useQuery({
    queryKey: ['billing-invoices'],
    queryFn: billingApi.getInvoices,
  });

  useEffect(() => {
    const ref = searchParams.get('ref');
    if (searchParams.get('payment') === 'return' && ref) {
      billingApi.getStatus(ref).then(async (res) => {
        if (res.status === 'successful') {
          await fetchPlanStatus();
          await refetchInvoices();
          setBannerMsg('Paiement confirme et abonnement mis a jour.');
        }
        setSearchParams({}, { replace: true });
      }).catch(() => {});
    }
  }, [searchParams, setSearchParams, fetchPlanStatus, refetchInvoices]);

  const handleSuccess = async () => {
    await fetchPlanStatus();
    await refetchInvoices();
    await queryClient.invalidateQueries();
    setCheckoutPlan(null);
    setBannerMsg('Votre abonnement a ete mis a jour avec succes.');
  };

  const handleActivateTrial = async (planCode: string) => {
    setTrialLoading(planCode);
    try {
      const res = await tenantApi.upgradePlan(planCode);
      setBannerMsg(res.message || 'Essai gratuit active.');
      await fetchPlanStatus();
      await queryClient.invalidateQueries();
    } finally {
      setTrialLoading(null);
    }
  };

  return (
    <div className="space-y-6 max-w-6xl mx-auto">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">
            Abonnement & Facturation
          </h1>
          <p className="text-xs sm:text-sm text-[#5A7184] dark:text-slate-400 mt-1">
            Gerez votre formule SaaS, vos quotas et vos paiements Mobile Money FeexPay
          </p>
        </div>
        <button
          type="button"
          onClick={() => setShowAllFeatures((v) => !v)}
          className="btn-secondary text-xs"
        >
          {showAllFeatures ? 'Vue condensee' : 'Comparer les 28 droits'}
        </button>
      </div>

      {bannerMsg && (
        <div className="p-3.5 rounded-2xl bg-[#E8F8F0] border border-[#27AE60]/30 text-[#27AE60] text-xs font-bold flex items-center justify-between">
          <span>{bannerMsg}</span>
          <button type="button" onClick={() => setBannerMsg(null)}><X className="w-4 h-4" /></button>
        </div>
      )}

      {currentPlan && (
        <div className="card-toc p-5 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <div className="w-11 h-11 rounded-2xl toc-gradient text-white flex items-center justify-center shrink-0">
              <Sparkles className="w-5 h-5" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="text-lg font-extrabold text-[#1C2B3A] dark:text-white">
                  {currentPlan.plan_name}
                </span>
                <span className="badge-toc-primary uppercase">{currentPlan.status}</span>
              </div>
              <p className="text-xs text-[#5A7184] dark:text-slate-400 mt-0.5">
                {currentPlan.trial_active
                  ? `Periode d essai : ${currentPlan.trial_days_left} jour(s) restant(s)`
                  : currentPlan.current_period_end
                    ? `Echeance en cours : ${formatDateOnly(currentPlan.current_period_end)}`
                    : 'Formule de base sans engagement'}
              </p>
            </div>
          </div>
          <div className="text-xs text-[#5A7184] dark:text-slate-400 flex items-center gap-1.5">
            <CreditCard className="w-4 h-4 text-[#29ABE2]" />
            <span>Retention audit : {currentPlan.audit_retention_days === -1 ? 'Illimitee' : `${currentPlan.audit_retention_days || 3}j`}</span>
          </div>
        </div>
      )}

      {currentPlan && <PlanUsageMeters status={currentPlan} />}

      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        {plans.map((plan) => {
          const isCurrent = currentPlan?.plan_code === plan.code;
          const features = (plan.features || [])
            .filter((f) => showAllFeatures || f.show_on_pricing !== false)
            .sort((a, b) => (a.display_order || 0) - (b.display_order || 0));
          const canTrial = plan.trial_period_days > 0 && !currentPlan?.has_used_trial && plan.code !== 'free';

          return (
            <div
              key={plan.id}
              className={`card-toc p-5 flex flex-col justify-between space-y-4 ${
                isCurrent ? 'ring-2 ring-[#29ABE2]' : ''
              }`}
            >
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <h3 className="text-base font-extrabold text-[#1C2B3A] dark:text-white">{plan.name}</h3>
                  {plan.badge && <span className="badge-toc-purple">{plan.badge}</span>}
                </div>
                <div className="text-2xl font-black text-[#29ABE2]">
                  {plan.price_monthly === 0
                    ? 'Gratuit'
                    : `${plan.price_monthly.toLocaleString('fr-FR')} ${plan.currency}/mois`}
                </div>
                <ul className="space-y-1.5 text-xs text-[#5A7184] dark:text-slate-300 max-h-64 overflow-y-auto pr-1">
                  {features.map((f) => {
                    const enabled = f.value_type === 'boolean' ? f.boolean_value : true;
                    return (
                      <li key={f.feature_code} className={`flex items-start gap-2 ${!enabled ? 'opacity-45' : ''}`}>
                        <CheckCircle2 className={`w-3.5 h-3.5 mt-0.5 shrink-0 ${enabled ? 'text-[#27AE60]' : 'text-slate-400'}`} />
                        <span>
                          {f.feature_name}
                          {f.value_type === 'limit_number' && (
                            <strong className="ml-1">({f.int_limit === -1 ? 'Illimite' : f.int_limit})</strong>
                          )}
                        </span>
                      </li>
                    );
                  })}
                </ul>
              </div>

              {plan.code === 'free' ? (
                <div className="text-xs font-semibold text-center py-2 text-[#5A7184]">
                  {isCurrent ? 'Forfait actif' : 'Inclus de base'}
                </div>
              ) : !isOwner ? (
                <div className="text-xs text-center py-2 text-[#5A7184]">Reserve au proprietaire</div>
              ) : canTrial ? (
                <button
                  type="button"
                  disabled={trialLoading === plan.code}
                  onClick={() => handleActivateTrial(plan.code)}
                  className="btn-primary w-full text-xs"
                >
                  <ShieldCheck className="w-4 h-4" />
                  <span>{trialLoading === plan.code ? 'Activation...' : `Essai gratuit ${plan.trial_period_days}j`}</span>
                </button>
              ) : (
                <button
                  type="button"
                  onClick={() => setCheckoutPlan(plan)}
                  className="btn-primary w-full text-xs"
                >
                  {isCurrent ? 'Renouveler via FeexPay' : `Passer au ${plan.name}`}
                </button>
              )}
            </div>
          );
        })}
      </div>

      {checkoutPlan && (
        <div className="card-toc p-5 space-y-4 border-[#29ABE2]">
          <div className="flex items-center justify-between">
            <h3 className="text-sm font-extrabold text-[#1C2B3A] dark:text-white">
              Souscription {checkoutPlan.name} via FeexPay
            </h3>
            <button type="button" onClick={() => setCheckoutPlan(null)} className="text-xs text-[#5A7184]">
              Fermer
            </button>
          </div>
          <FeexPayCheckoutWidget plan={checkoutPlan} onPaymentSuccess={handleSuccess} />
        </div>
      )}

      <InvoicesTable invoices={invoices} />
    </div>
  );
};
