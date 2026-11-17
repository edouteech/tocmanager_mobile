import React, { useState } from 'react';
import { X, Sparkles, CheckCircle2, ArrowRight, ShieldCheck, Zap } from 'lucide-react';
import { useTenantStore } from '../../stores/tenantStore';
import { tenantApi } from '../../lib/api';

export const UpgradePlanModal: React.FC = () => {
  const { upgradeModalOpen, upgradeModalData, closeUpgradeModal, fetchPlanStatus } = useTenantStore();
  const [loading, setLoading] = useState(false);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  if (!upgradeModalOpen) return null;

  const handleStartTrial = async () => {
    setLoading(true);
    try {
      const res = await tenantApi.upgradePlan('pro');
      setSuccessMsg(res.message || 'Passage au Plan Pro réussi !');
      await fetchPlanStatus();
      setTimeout(() => {
        setSuccessMsg(null);
        closeUpgradeModal();
        window.location.reload();
      }, 1500);
    } catch (e: any) {
      alert(e.response?.data?.detail || "Erreur lors de l'activation du forfait.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-fadeIn">
      <div className="relative w-full max-w-xl bg-white dark:bg-slate-900 rounded-2xl shadow-2xl border border-slate-200 dark:border-slate-800 overflow-hidden">
        {/* Banner Décorative Gradient */}
        <div className="h-3 bg-gradient-to-r from-amber-500 via-indigo-600 to-purple-600" />

        {/* Close Button */}
        <button
          onClick={closeUpgradeModal}
          className="absolute top-5 right-5 p-2 rounded-full text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800 transition"
        >
          <X className="w-5 h-5" />
        </button>

        <div className="p-6 md:p-8 space-y-6">
          {/* Badge & Titre */}
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-xl bg-gradient-to-tr from-amber-500 to-indigo-600 flex items-center justify-center text-white shadow-lg shadow-indigo-500/20">
              <Sparkles className="w-6 h-6" />
            </div>
            <div>
              <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-amber-100 dark:bg-amber-950/60 text-amber-700 dark:text-amber-400 border border-amber-300 dark:border-amber-800">
                <Zap className="w-3 h-3" /> AVANTAGE PRO & ENTREPRISE
              </span>
              <h3 className="text-xl font-bold text-slate-900 dark:text-white mt-1">
                {upgradeModalData?.title || 'Passez à la Vitesse Supérieure'}
              </h3>
            </div>
          </div>

          {/* Message descriptif */}
          <p className="text-sm text-slate-600 dark:text-slate-300 leading-relaxed">
            {upgradeModalData?.message ||
              "Cette fonctionnalité fait partie des forfaits professionnels de TocManager. Débloquez-la pour développer votre réseau de vente sans contraintes."}
          </p>

          {/* Grille des Bénéfices Pro */}
          <div className="bg-slate-50 dark:bg-slate-800/60 rounded-xl p-4 border border-slate-100 dark:border-slate-750 space-y-3">
            <h4 className="text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
              Ce que vous débloquez immédiatement avec le Plan Pro :
            </h4>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5 text-xs text-slate-700 dark:text-slate-200">
              <div className="flex items-center gap-2">
                <CheckCircle2 className="w-4 h-4 text-emerald-500 shrink-0" />
                <span>Jusqu'à 5 magasins & entrepôts</span>
              </div>
              <div className="flex items-center gap-2">
                <CheckCircle2 className="w-4 h-4 text-emerald-500 shrink-0" />
                <span>Transferts de stock inter-magasins</span>
              </div>
              <div className="flex items-center gap-2">
                <CheckCircle2 className="w-4 h-4 text-emerald-500 shrink-0" />
                <span>Rapports financiers P&L consolidés</span>
              </div>
              <div className="flex items-center gap-2">
                <CheckCircle2 className="w-4 h-4 text-emerald-500 shrink-0" />
                <span>Gestion multi-utilisateurs & caissiers</span>
              </div>
            </div>
          </div>

          {/* Message Succès Feedback */}
          {successMsg && (
            <div className="p-3 bg-emerald-50 dark:bg-emerald-950/60 border border-emerald-300 text-emerald-800 dark:text-emerald-200 rounded-lg text-sm text-center font-medium animate-fadeIn">
              {successMsg}
            </div>
          )}

          {/* Actions CTA */}
          <div className="flex flex-col sm:flex-row items-center justify-between gap-3 pt-2">
            <a
              href="/tarifs"
              target="_blank"
              rel="noreferrer"
              className="text-xs text-indigo-600 dark:text-indigo-400 font-medium hover:underline flex items-center gap-1"
            >
              <span>Découvrir tous les forfaits</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </a>

            <div className="flex items-center gap-2 w-full sm:w-auto">
              <button
                type="button"
                onClick={closeUpgradeModal}
                className="w-1/2 sm:w-auto px-4 py-2.5 text-xs font-medium text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg transition"
              >
                Plus tard
              </button>

              <button
                type="button"
                disabled={loading}
                onClick={handleStartTrial}
                className="w-1/2 sm:w-auto px-5 py-2.5 text-xs font-semibold text-white bg-gradient-to-r from-indigo-600 to-purple-600 hover:from-indigo-700 hover:to-purple-700 rounded-lg shadow-md hover:shadow-lg transition flex items-center justify-center gap-2"
              >
                {loading ? (
                  <span>Activation en cours...</span>
                ) : (
                  <>
                    <ShieldCheck className="w-4 h-4" />
                    <span>Activer 14j d'essai Pro</span>
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
