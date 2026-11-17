import React, { useEffect, useState } from 'react';
import { adminApi } from '../../lib/api';
import { PlatformKPIs } from '../../types';
import { TrendingUp, Store, ShoppingBag, ShieldCheck, DollarSign, Users } from 'lucide-react';

export const AdminDashboardPage: React.FC = () => {
  const [kpis, setKpis] = useState<PlatformKPIs | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    adminApi
      .getKpis()
      .then((data) => setKpis(data))
      .catch((e) => console.error('Error fetching admin KPIs:', e))
      .finally(() => setLoading(false));
  }, []);

  if (loading) {
    return <div className="p-8 text-center text-slate-400">Chargement des indicateurs SaaS...</div>;
  }

  return (
    <div className="space-y-8 max-w-7xl mx-auto">
      <div>
        <h1 className="text-2xl font-black text-slate-900 dark:text-white">Tableau de Bord Super-Administrateur</h1>
        <p className="text-xs text-slate-500 mt-1">
          Performances commerciales, métriques d'abonnements et croissance de la plateforme SaaS.
        </p>
      </div>

      {/* Grille des KPIs */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
        {/* MRR */}
        <div className="bg-white dark:bg-slate-900 p-5 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">MRR Mensuel</span>
            <div className="p-2 rounded-xl bg-emerald-100 dark:bg-emerald-950/60 text-emerald-600">
              <TrendingUp className="w-4 h-4" />
            </div>
          </div>
          <div className="text-2xl font-extrabold text-slate-900 dark:text-white mt-2">
            {(kpis?.mrr || 0).toLocaleString('fr-FR')} {kpis?.currency}
          </div>
          <div className="text-[11px] text-slate-400 mt-1">
            ARR estimé : {(kpis?.arr || 0).toLocaleString('fr-FR')} {kpis?.currency}
          </div>
        </div>

        {/* Boutiques Actives */}
        <div className="bg-white dark:bg-slate-900 p-5 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">Boutiques Clientes</span>
            <div className="p-2 rounded-xl bg-indigo-100 dark:bg-indigo-950/60 text-indigo-600">
              <Store className="w-4 h-4" />
            </div>
          </div>
          <div className="text-2xl font-extrabold text-slate-900 dark:text-white mt-2">
            {kpis?.active_boutiques} <span className="text-sm font-normal text-slate-400">/ {kpis?.total_boutiques}</span>
          </div>
          <div className="text-[11px] text-emerald-600 dark:text-emerald-400 font-semibold mt-1">
            {kpis?.trialing_subscriptions} en période d'essai Pro
          </div>
        </div>

        {/* Magasins Déployés */}
        <div className="bg-white dark:bg-slate-900 p-5 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">Points de Vente</span>
            <div className="p-2 rounded-xl bg-purple-100 dark:bg-purple-950/60 text-purple-600">
              <ShoppingBag className="w-4 h-4" />
            </div>
          </div>
          <div className="text-2xl font-extrabold text-slate-900 dark:text-white mt-2">
            {kpis?.total_magasins}
          </div>
          <div className="text-[11px] text-slate-400 mt-1">Caisses & réserves connectées</div>
        </div>

        {/* GMV Global */}
        <div className="bg-white dark:bg-slate-900 p-5 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">Volume d'Affaires GMV</span>
            <div className="p-2 rounded-xl bg-amber-100 dark:bg-amber-950/60 text-amber-600">
              <DollarSign className="w-4 h-4" />
            </div>
          </div>
          <div className="text-2xl font-extrabold text-slate-900 dark:text-white mt-2">
            {(kpis?.total_gmv || 0).toLocaleString('fr-FR')} {kpis?.currency}
          </div>
          <div className="text-[11px] text-slate-400 mt-1">Total des ventes enregistrées</div>
        </div>
      </div>

      {/* Raccourcis Rapides */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="p-6 bg-gradient-to-br from-indigo-900 to-slate-900 text-white rounded-2xl space-y-4">
          <div className="flex items-center gap-2">
            <ShieldCheck className="w-5 h-5 text-amber-400" />
            <h3 className="font-bold text-base">Gestionnaire des Forfaits & Délais d'Essai</h3>
          </div>
          <p className="text-xs text-indigo-200 leading-relaxed">
            Créez de nouvelles formules, ajustez les prix mensuels et annuels, activez ou désactivez les périodes d'essai gratuit de chaque forfait.
          </p>
          <a
            href="/admin/plans"
            className="inline-block px-4 py-2 bg-indigo-600 hover:bg-indigo-500 text-white rounded-lg text-xs font-bold transition"
          >
            Configurer les Forfaits →
          </a>
        </div>

        <div className="p-6 bg-gradient-to-br from-purple-900 to-slate-900 text-white rounded-2xl space-y-4">
          <div className="flex items-center gap-2">
            <Store className="w-5 h-5 text-emerald-400" />
            <h3 className="font-bold text-base">Annuaire des Entreprises & Boutiques</h3>
          </div>
          <p className="text-xs text-purple-200 leading-relaxed">
            Consultez les informations détaillées de chaque boutique inscrite, prolongez manuellement un essai gratuit (+14j) ou suspendez un compte.
          </p>
          <a
            href="/admin/boutiques"
            className="inline-block px-4 py-2 bg-purple-600 hover:bg-purple-500 text-white rounded-lg text-xs font-bold transition"
          >
            Gérer les Boutiques →
          </a>
        </div>
      </div>
    </div>
  );
};
