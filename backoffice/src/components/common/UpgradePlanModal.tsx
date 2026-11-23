import React, { useState } from 'react';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { X, Sparkles, CheckCircle2, ArrowRight, ShieldCheck, Zap, AlertCircle } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '../../stores/authStore';
import { useTenantStore } from '../../stores/tenantStore';
import { saasApi, tenantApi } from '../../lib/api';
import { FeexPayCheckoutWidget } from '../../features/subscription/FeexPayCheckoutWidget';

export const UpgradePlanModal: React.FC = () => {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const user = useAuthStore((s) => s.user);
  const { currentPlan, upgradeModalOpen, upgradeModalData, closeUpgradeModal, fetchPlanStatus } =
    useTenantStore();
  const [loading, setLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  const { data: plans = [] } = useQuery({
    queryKey: ['saas-plans'],
    queryFn: saasApi.getPlans,
    enabled: upgradeModalOpen,
  });

  if (!upgradeModalOpen) return null;

  const isOwner = user?.role === 'owner' || user?.role === 'merchant';
  const defaultCode = currentPlan?.plan_code === 'pro' ? 'enterprise' : 'pro';
  const requestedCode = upgradeModalData?.recommendedPlan || defaultCode;
  const targetPlan =
    plans.find((p) => p.code === requestedCode && p.code !== 'free') ||
    plans.find((p) => p.code === defaultCode) ||
    plans.find((p) => p.code !== 'free') ||
    null;

  const canActivateTrial = Boolean(
    targetPlan && targetPlan.trial_period_days > 0 && !currentPlan?.has_used_trial
  );
  const visibleFeatures = (targetPlan?.features || [])
    .filter((f) => f.show_on_pricing !== false && (f.value_type !== 'boolean' || f.boolean_value))
    .slice(0, 6);

  const handleSuccessRefresh = async (message: string) => {
    setSuccessMsg(message);
    await fetchPlanStatus();
    await queryClient.invalidateQueries();
    window.setTimeout(() => {
      setSuccessMsg(null);
      closeUpgradeModal();
    }, 1200);
  };

  const handleStartTrial = async () => {
    if (!targetPlan) return;
    setLoading(true);
    setErrorMsg(null);
    try {
      const res = await tenantApi.upgradePlan(targetPlan.code);
      await handleSuccessRefresh(res.message || `Essai ${targetPlan.name} active.`);
    } catch (err: any) {
      const detail = err.response?.data?.detail;
      setErrorMsg(typeof detail === 'string' ? detail : detail?.message || 'Activation impossible.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
      <div className="relative w-full max-w-xl bg-white dark:bg-dark-800 rounded-2xl shadow-2xl border border-[#E8EFF5] dark:border-dark-600 overflow-hidden">
        <div className="h-2.5 toc-gradient" />

        <button
          type="button"
          onClick={closeUpgradeModal}
          className="absolute top-4 right-4 p-2 rounded-full text-slate-400 hover:text-slate-600 hover:bg-slate-100 dark:hover:bg-dark-700 transition"
        >
          <X className="w-5 h-5" />
        </button>

        <div className="p-6 space-y-5 max-h-[85vh] overflow-y-auto">
          <div className="flex items-center gap-3">
            <div className="w-11 h-11 rounded-xl toc-gradient flex items-center justify-center text-white shrink-0">
              <Sparkles className="w-5 h-5" />
            </div>
            <div>
              <span className="badge-toc-purple">
                <Zap className="w-3 h-3" /> {targetPlan?.name || 'Forfait Pro'}
              </span>
              <h3 className="text-lg font-extrabold text-[#1C2B3A] dark:text-white mt-1">
                {upgradeModalData?.title || 'Passez au forfait superieur'}
              </h3>
            </div>
          </div>

          <p className="text-xs sm:text-sm text-[#5A7184] dark:text-slate-300 leading-relaxed">
            {upgradeModalData?.message ||
              'Debloquez davantage de quotas et de modules professionnels pour votre reseau de vente.'}
          </p>

          {visibleFeatures.length > 0 && (
            <div className="bg-[#F5FAFD] dark:bg-dark-700/60 rounded-xl p-4 border border-[#E8EFF5] dark:border-dark-600 grid grid-cols-1 sm:grid-cols-2 gap-2 text-xs text-[#1C2B3A] dark:text-slate-200">
              {visibleFeatures.map((f) => (
                <div key={f.feature_code} className="flex items-center gap-2">
                  <CheckCircle2 className="w-4 h-4 text-[#27AE60] shrink-0" />
                  <span>
                    {f.feature_name}
                    {f.value_type === 'limit_number' && ` (${f.int_limit === -1 ? 'Illimite' : f.int_limit})`}
                  </span>
                </div>
              ))}
            </div>
          )}

          {errorMsg && (
            <div className="p-3 rounded-xl bg-[#FDEBE9] text-[#E74C3C] text-xs font-semibold flex items-center gap-2">
              <AlertCircle className="w-4 h-4 shrink-0" />
              <span>{errorMsg}</span>
            </div>
          )}

          {successMsg && (
            <div className="p-3 rounded-xl bg-[#E8F8F0] text-[#27AE60] text-xs font-bold text-center">
              {successMsg}
            </div>
          )}

          {!isOwner ? (
            <div className="p-3.5 rounded-xl bg-[#FEF5E7] text-[#F39C12] text-xs font-semibold">
              Seul le proprietaire de la boutique peut modifier l abonnement ou effectuer un paiement.
            </div>
          ) : canActivateTrial && targetPlan ? (
            <div className="flex items-center justify-between gap-3 pt-1">
              <button
                type="button"
                onClick={() => {
                  closeUpgradeModal();
                  navigate('/abonnement');
                }}
                className="text-xs text-[#29ABE2] font-semibold hover:underline flex items-center gap-1"
              >
                <span>Voir tous les forfaits</span>
                <ArrowRight className="w-3.5 h-3.5" />
              </button>
              <button
                type="button"
                disabled={loading}
                onClick={handleStartTrial}
                className="btn-primary text-xs"
              >
                <ShieldCheck className="w-4 h-4" />
                <span>
                  {loading
                    ? 'Activation...'
                    : `Activer l essai gratuit (${targetPlan.trial_period_days}j)`}
                </span>
              </button>
            </div>
          ) : targetPlan ? (
            <FeexPayCheckoutWidget
              plan={targetPlan}
              onPaymentSuccess={() => handleSuccessRefresh(`Forfait ${targetPlan.name} active.`)}
            />
          ) : null}
        </div>
      </div>
    </div>
  );
};
