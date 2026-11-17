import React, { useEffect, useState } from 'react';
import { adminApi } from '../../lib/api';
import { SaasPlan } from '../../types';
import { Layers, Plus, Edit2, CheckCircle2, Shield, Sparkles } from 'lucide-react';

export const AdminPlansPage: React.FC = () => {
  const [plans, setPlans] = useState<SaasPlan[]>([]);
  const [loading, setLoading] = useState(true);
  const [editingPlan, setEditingPlan] = useState<SaasPlan | null>(null);

  // Form edit state
  const [name, setName] = useState('');
  const [priceMonthly, setPriceMonthly] = useState(0);
  const [priceYearly, setPriceYearly] = useState(0);
  const [trialDays, setTrialDays] = useState(0);
  const [badge, setBadge] = useState('');
  const [isActive, setIsActive] = useState(true);

  const fetchPlans = () => {
    setLoading(true);
    adminApi
      .getPlans()
      .then((data) => setPlans(data))
      .catch((e) => console.error(e))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    fetchPlans();
  }, []);

  const handleEditClick = (plan: SaasPlan) => {
    setEditingPlan(plan);
    setName(plan.name);
    setPriceMonthly(plan.price_monthly);
    setPriceYearly(plan.price_yearly);
    setTrialDays(plan.trial_period_days);
    setBadge(plan.badge || '');
    setIsActive(plan.is_active);
  };

  const handleSavePlan = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingPlan) return;

    try {
      await adminApi.updatePlan(editingPlan.id, {
        name,
        price_monthly: Number(priceMonthly),
        price_yearly: Number(priceYearly),
        trial_period_days: Number(trialDays),
        badge: badge.trim() || undefined,
        is_active: isActive,
      });
      setEditingPlan(null);
      fetchPlans();
    } catch (err: any) {
      alert(err.response?.data?.detail || 'Erreur lors de la mise à jour du plan.');
    }
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-black text-slate-900 dark:text-white">Gestion des Forfaits & Pricing</h1>
          <p className="text-xs text-slate-500 mt-0.5">
            Paramétrez les prix, les durées d'essai gratuit et les quotas de chaque offre commerciale.
          </p>
        </div>
      </div>

      {/* Liste des Plans */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {plans.map((p) => (
          <div
            key={p.id}
            className="bg-white dark:bg-slate-900 p-6 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm space-y-4 flex flex-col justify-between"
          >
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <span className="font-mono text-xs px-2 py-0.5 rounded bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300">
                  {p.code}
                </span>
                <span
                  className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${
                    p.is_active ? 'bg-emerald-100 text-emerald-700' : 'bg-rose-100 text-rose-700'
                  }`}
                >
                  {p.is_active ? 'ACTIF' : 'INACTIF'}
                </span>
              </div>

              <div>
                <h3 className="text-lg font-bold text-slate-900 dark:text-white flex items-center gap-2">
                  <span>{p.name}</span>
                  {p.badge && (
                    <span className="text-[10px] bg-amber-100 dark:bg-amber-950 text-amber-700 dark:text-amber-400 font-bold px-2 py-0.5 rounded-full">
                      {p.badge}
                    </span>
                  )}
                </h3>
                <p className="text-xs text-slate-500 mt-1">{p.description}</p>
              </div>

              <div className="pt-2 border-t border-slate-100 dark:border-slate-800 space-y-1 text-xs">
                <div className="flex justify-between">
                  <span className="text-slate-500">Prix Mensuel :</span>
                  <span className="font-bold text-slate-900 dark:text-white">
                    {p.price_monthly.toLocaleString('fr-FR')} {p.currency}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-slate-500">Prix Annuel :</span>
                  <span className="font-bold text-slate-900 dark:text-white">
                    {p.price_yearly.toLocaleString('fr-FR')} {p.currency}
                  </span>
                </div>
                <div className="flex justify-between text-indigo-600 dark:text-indigo-400 font-medium">
                  <span>Délai d'essai offert :</span>
                  <span>{p.trial_period_days} jours</span>
                </div>
              </div>

              {/* Features list */}
              <div className="pt-2 text-[11px] text-slate-600 dark:text-slate-300 space-y-1">
                {p.features?.map((f) => (
                  <div key={f.id} className="flex items-center gap-1.5">
                    <CheckCircle2 className="w-3.5 h-3.5 text-emerald-500 shrink-0" />
                    <span>
                      {f.feature_name}
                      {f.value_type === 'limit_number' && f.int_limit !== -1 ? ` : ${f.int_limit}` : ''}
                      {f.int_limit === -1 ? ' : Illimité' : ''}
                    </span>
                  </div>
                ))}
              </div>
            </div>

            <button
              onClick={() => handleEditClick(p)}
              className="mt-4 w-full py-2 bg-slate-100 hover:bg-slate-200 dark:bg-slate-800 dark:hover:bg-slate-750 text-slate-800 dark:text-slate-200 text-xs font-semibold rounded-xl transition flex items-center justify-center gap-2"
            >
              <Edit2 className="w-3.5 h-3.5" />
              <span>Modifier ce Forfait</span>
            </button>
          </div>
        ))}
      </div>

      {/* Modale d'édition */}
      {editingPlan && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
          <div className="bg-white dark:bg-slate-900 rounded-2xl p-6 max-w-md w-full border border-slate-200 dark:border-slate-800 shadow-2xl space-y-4">
            <h3 className="text-lg font-bold">Modifier le Forfait : {editingPlan.name}</h3>

            <form onSubmit={handleSavePlan} className="space-y-3 text-xs">
              <div>
                <label className="block font-semibold mb-1">Nom commercial</label>
                <input
                  type="text"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  className="w-full px-3 py-2 rounded-lg border border-slate-300 dark:border-slate-700 bg-transparent"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-semibold mb-1">Prix Mensuel ({editingPlan.currency})</label>
                  <input
                    type="number"
                    value={priceMonthly}
                    onChange={(e) => setPriceMonthly(Number(e.target.value))}
                    className="w-full px-3 py-2 rounded-lg border border-slate-300 dark:border-slate-700 bg-transparent"
                  />
                </div>
                <div>
                  <label className="block font-semibold mb-1">Prix Annuel ({editingPlan.currency})</label>
                  <input
                    type="number"
                    value={priceYearly}
                    onChange={(e) => setPriceYearly(Number(e.target.value))}
                    className="w-full px-3 py-2 rounded-lg border border-slate-300 dark:border-slate-700 bg-transparent"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-semibold mb-1">Délai d'Essai (Jours)</label>
                  <input
                    type="number"
                    value={trialDays}
                    onChange={(e) => setTrialDays(Number(e.target.value))}
                    className="w-full px-3 py-2 rounded-lg border border-slate-300 dark:border-slate-700 bg-transparent"
                  />
                </div>
                <div>
                  <label className="block font-semibold mb-1">Badge marketing (optionnel)</label>
                  <input
                    type="text"
                    value={badge}
                    placeholder="POPULAIRE, PRO..."
                    onChange={(e) => setBadge(e.target.value)}
                    className="w-full px-3 py-2 rounded-lg border border-slate-300 dark:border-slate-700 bg-transparent"
                  />
                </div>
              </div>

              <div className="flex items-center gap-2 pt-2">
                <input
                  type="checkbox"
                  id="activePlan"
                  checked={isActive}
                  onChange={(e) => setIsActive(e.target.checked)}
                  className="rounded text-indigo-600"
                />
                <label htmlFor="activePlan" className="font-semibold">
                  Plan actif et disponible aux nouveaux inscrits
                </label>
              </div>

              <div className="flex items-center justify-end gap-2 pt-4">
                <button
                  type="button"
                  onClick={() => setEditingPlan(null)}
                  className="px-4 py-2 rounded-lg text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800"
                >
                  Annuler
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 bg-indigo-600 hover:bg-indigo-700 text-white font-bold rounded-lg"
                >
                  Enregistrer les modifications
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
