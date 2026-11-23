import React, { useEffect, useState } from 'react';
import { adminApi } from '../../lib/api';
import { SaasPlan } from '../../types';
import { Edit2, CheckCircle2, X } from 'lucide-react';

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
          <h1 className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">
            Gestion des Forfaits & Pricing
          </h1>
          <p className="text-xs sm:text-sm text-[#5A7184] dark:text-slate-400 mt-0.5">
            Paramétrez les prix, les durées d'essai gratuit et les quotas de chaque offre commerciale.
          </p>
        </div>
      </div>

      {loading ? (
        <div className="card-toc p-12 text-center text-sm text-[#5A7184]">Chargement des forfaits...</div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {plans.map((p) => (
            <div
              key={p.id}
              className="card-toc card-hover p-6 space-y-4 flex flex-col justify-between"
            >
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <span className="font-mono text-xs px-2.5 py-0.5 rounded-lg bg-[#F0F9FE] dark:bg-dark-700 text-[#5A7184] dark:text-slate-300 border border-[#E8EFF5] dark:border-dark-600">
                    {p.code}
                  </span>
                  <span className={p.is_active ? 'badge-toc-success' : 'badge-toc-danger'}>
                    {p.is_active ? 'ACTIF' : 'INACTIF'}
                  </span>
                </div>

                <div>
                  <h3 className="text-lg font-bold text-[#1C2B3A] dark:text-white flex items-center gap-2">
                    <span>{p.name}</span>
                    {p.badge && (
                      <span className="badge-toc-warning text-[10px]">{p.badge}</span>
                    )}
                  </h3>
                  <p className="text-xs text-[#5A7184] dark:text-slate-400 mt-1">{p.description}</p>
                </div>

                <div className="pt-2 border-t border-[#E8EFF5] dark:border-dark-600 space-y-1 text-xs">
                  <div className="flex justify-between">
                    <span className="text-[#5A7184] dark:text-slate-400">Prix Mensuel :</span>
                    <span className="font-bold text-[#1C2B3A] dark:text-white font-mono">
                      {p.price_monthly.toLocaleString('fr-FR')} {p.currency}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-[#5A7184] dark:text-slate-400">Prix Annuel :</span>
                    <span className="font-bold text-[#1C2B3A] dark:text-white font-mono">
                      {p.price_yearly.toLocaleString('fr-FR')} {p.currency}
                    </span>
                  </div>
                  <div className="flex justify-between text-[#29ABE2] font-semibold">
                    <span>Délai d'essai offert :</span>
                    <span>{p.trial_period_days} jours</span>
                  </div>
                </div>

                <div className="pt-2 text-[11px] text-[#5A7184] dark:text-slate-300 space-y-1">
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

              <button
                type="button"
                onClick={() => handleEditClick(p)}
                className="btn-secondary w-full text-xs mt-4"
              >
                <Edit2 className="w-3.5 h-3.5 text-[#29ABE2]" />
                <span>Modifier ce Forfait</span>
              </button>
            </div>
          ))}
        </div>
      )}

      {editingPlan && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-[#1C2B3A]/60 backdrop-blur-sm">
          <div className="card-toc p-6 max-w-md w-full shadow-soft-lg space-y-4">
            <h3 className="text-lg font-bold text-[#1C2B3A] dark:text-white">
              Modifier le Forfait : {editingPlan.name}
            </h3>

            <form onSubmit={handleSavePlan} className="space-y-3 text-xs">
              <div>
                <label className="block font-semibold mb-1">Nom commercial</label>
                <input
                  type="text"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  className="input-toc"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-semibold mb-1">Prix Mensuel ({editingPlan.currency})</label>
                  <input
                    type="number"
                    value={priceMonthly}
                    onChange={(e) => setPriceMonthly(Number(e.target.value))}
                    className="input-toc font-mono"
                  />
                </div>
                <div>
                  <label className="block font-semibold mb-1">Prix Annuel ({editingPlan.currency})</label>
                  <input
                    type="number"
                    value={priceYearly}
                    onChange={(e) => setPriceYearly(Number(e.target.value))}
                    className="input-toc font-mono"
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
                    className="input-toc font-mono"
                  />
                </div>
                <div>
                  <label className="block font-semibold mb-1">Badge marketing (optionnel)</label>
                  <input
                    type="text"
                    value={badge}
                    placeholder="POPULAIRE, PRO..."
                    onChange={(e) => setBadge(e.target.value)}
                    className="input-toc"
                  />
                </div>
              </div>

              <div className="flex items-center gap-2 pt-2">
                <input
                  type="checkbox"
                  id="activePlan"
                  checked={isActive}
                  onChange={(e) => setIsActive(e.target.checked)}
                  className="rounded text-[#29ABE2]"
                />
                <label htmlFor="activePlan" className="font-semibold">
                  Plan actif et disponible aux nouveaux inscrits
                </label>
              </div>

              <div className="flex items-center justify-end gap-2 pt-4">
                <button
                  type="button"
                  onClick={() => setEditingPlan(null)}
                  className="btn-secondary text-xs"
                >
                  Annuler
                </button>
                <button type="submit" className="btn-primary text-xs">
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
