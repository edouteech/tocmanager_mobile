import React, { useEffect, useState } from 'react';
import { CheckCircle2, Copy, Edit2, LayoutGrid, Plus, Table2, X } from 'lucide-react';
import { adminApi } from '../../lib/api';
import { FeatureCatalogItem, SaasPlan, SaasPlanPayload } from '../../types';
import { PlanEditorModal } from './PlanEditorModal';
import { PlansMatrixView } from './PlansMatrixView';

export const AdminPlansPage: React.FC = () => {
  const [plans, setPlans] = useState<SaasPlan[]>([]);
  const [catalog, setCatalog] = useState<FeatureCatalogItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [viewMode, setViewMode] = useState<'cards' | 'matrix'>('cards');
  const [editorState, setEditorState] = useState<{
    isOpen: boolean;
    mode: 'create' | 'duplicate' | 'edit';
    plan: SaasPlan | null;
  }>({ isOpen: false, mode: 'edit', plan: null });
  const [saving, setSaving] = useState(false);
  const [saveError, setSaveError] = useState<string | null>(null);

  const fetchAll = () => {
    setLoading(true);
    Promise.all([adminApi.getPlans(), adminApi.getFeaturesCatalog()])
      .then(([pData, cData]) => {
        setPlans(pData);
        setCatalog(cData);
      })
      .catch((e) => console.error(e))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    fetchAll();
  }, []);

  const handleSavePlan = async (payload: SaasPlanPayload, planId?: string) => {
    setSaving(true);
    setSaveError(null);
    try {
      if (planId) {
        await adminApi.updatePlan(planId, payload);
      } else {
        await adminApi.createPlan(payload);
      }
      setEditorState({ isOpen: false, mode: 'edit', plan: null });
      fetchAll();
    } catch (err: any) {
      setSaveError(err.response?.data?.detail || 'Erreur lors de la sauvegarde du forfait.');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">
            Gestion des Forfaits & Droits d'Accès
          </h1>
          <p className="text-xs sm:text-sm text-[#5A7184] dark:text-slate-400 mt-0.5">
            Configurez tarifs, essais et l'intégralité des 28 permissions de chaque offre commerciale.
          </p>
        </div>

        <div className="flex items-center gap-2.5 flex-wrap">
          <div className="inline-flex rounded-xl bg-white dark:bg-dark-800 p-1 border border-[#E8EFF5] dark:border-dark-600 text-xs font-semibold">
            <button
              type="button"
              onClick={() => setViewMode('cards')}
              className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg transition ${
                viewMode === 'cards' ? 'bg-[#29ABE2] text-white' : 'text-[#5A7184]'
              }`}
            >
              <LayoutGrid className="w-3.5 h-3.5" />
              <span>Vue Cartes</span>
            </button>
            <button
              type="button"
              onClick={() => setViewMode('matrix')}
              className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg transition ${
                viewMode === 'matrix' ? 'bg-[#29ABE2] text-white' : 'text-[#5A7184]'
              }`}
            >
              <Table2 className="w-3.5 h-3.5" />
              <span>Vue Matrice (28)</span>
            </button>
          </div>

          <button
            type="button"
            onClick={() => {
              setSaveError(null);
              setEditorState({ isOpen: true, mode: 'create', plan: null });
            }}
            className="btn-primary text-xs"
          >
            <Plus className="w-4 h-4" />
            <span>Nouveau Forfait</span>
          </button>
        </div>
      </div>

      {loading ? (
        <div className="card-toc p-12 text-center text-sm text-[#5A7184]">Chargement des forfaits...</div>
      ) : viewMode === 'matrix' ? (
        <PlansMatrixView plans={plans} catalog={catalog} />
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {plans.map((p) => (
            <div key={p.id} className="card-toc card-hover p-6 space-y-4 flex flex-col justify-between">
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <span className="font-mono text-xs px-2.5 py-0.5 rounded-lg bg-[#F0F9FE] dark:bg-dark-700 text-[#5A7184] border border-[#E8EFF5] dark:border-dark-600">
                    {p.code}
                  </span>
                  <span className={p.is_active ? 'badge-toc-success' : 'badge-toc-danger'}>
                    {p.is_active ? 'ACTIF' : 'INACTIF'}
                  </span>
                </div>

                <div>
                  <h3 className="text-lg font-bold text-[#1C2B3A] dark:text-white flex items-center gap-2">
                    <span>{p.name}</span>
                    {p.badge && <span className="badge-toc-warning text-[10px]">{p.badge}</span>}
                  </h3>
                  <p className="text-xs text-[#5A7184] dark:text-slate-400 mt-1">{p.description}</p>
                </div>

                <div className="pt-2 border-t border-[#E8EFF5] dark:border-dark-600 space-y-1 text-xs">
                  <div className="flex justify-between">
                    <span className="text-[#5A7184]">Prix Mensuel :</span>
                    <span className="font-bold font-mono">{p.price_monthly.toLocaleString('fr-FR')} {p.currency}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-[#5A7184]">Prix Annuel :</span>
                    <span className="font-bold font-mono">{p.price_yearly.toLocaleString('fr-FR')} {p.currency}</span>
                  </div>
                  <div className="flex justify-between text-[#29ABE2] font-semibold">
                    <span>Délai d'essai :</span>
                    <span>{p.trial_period_days} jours</span>
                  </div>
                </div>

                <div className="pt-2 text-[11px] text-[#5A7184] dark:text-slate-300 space-y-1 max-h-56 overflow-y-auto pr-1">
                  {p.features?.map((f) => {
                    const isGranted = f.value_type === 'boolean' ? f.boolean_value : f.int_limit !== 0;
                    return (
                      <div key={f.id} className="flex items-center gap-1.5">
                        {isGranted ? (
                          <CheckCircle2 className="w-3.5 h-3.5 text-[#27AE60] shrink-0" />
                        ) : (
                          <X className="w-3.5 h-3.5 text-[#9FB3C8] shrink-0" />
                        )}
                        <span className={isGranted ? '' : 'line-through text-[#9FB3C8]'}>
                          {f.feature_name}
                          {f.value_type === 'limit_number' && f.int_limit !== -1 ? ` : ${f.int_limit}` : ''}
                          {f.int_limit === -1 ? ' : Illimité' : ''}
                        </span>
                      </div>
                    );
                  })}
                </div>
              </div>

              <div className="flex gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => {
                    setSaveError(null);
                    setEditorState({ isOpen: true, mode: 'edit', plan: p });
                  }}
                  className="btn-secondary flex-1 text-xs"
                >
                  <Edit2 className="w-3.5 h-3.5 text-[#29ABE2]" />
                  <span>Configurer</span>
                </button>
                <button
                  type="button"
                  onClick={() => {
                    setSaveError(null);
                    setEditorState({ isOpen: true, mode: 'duplicate', plan: p });
                  }}
                  className="btn-secondary px-3 text-xs"
                  title="Dupliquer ce forfait"
                >
                  <Copy className="w-3.5 h-3.5 text-[#5A7184]" />
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      <PlanEditorModal
        isOpen={editorState.isOpen}
        mode={editorState.mode}
        initialPlan={editorState.plan}
        catalog={catalog}
        isSubmitting={saving}
        externalError={saveError}
        onClose={() => setEditorState({ isOpen: false, mode: 'edit', plan: null })}
        onSave={handleSavePlan}
      />
    </div>
  );
};
