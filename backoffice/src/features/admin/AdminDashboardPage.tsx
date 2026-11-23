import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import {
  TrendingUp,
  Store,
  ShoppingBag,
  ShieldCheck,
  DollarSign,
  ArrowRight,
  Layers,
} from 'lucide-react';
import { adminApi } from '../../lib/api';
import { PlatformKPIs } from '../../types';

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
    return <div className="p-8 text-center text-[#5A7184] text-sm">Chargement des indicateurs SaaS...</div>;
  }

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      <div className="rounded-3xl toc-gradient p-6 sm:p-8 text-white shadow-soft flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div className="space-y-1.5">
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-white/20 text-[11px] font-semibold">
            Pilotage Plateforme SaaS
          </span>
          <h1 className="text-2xl sm:text-3xl font-extrabold tracking-tight">
            Tableau de Bord Super-Administrateur
          </h1>
          <p className="text-xs sm:text-sm text-white/85">
            Performances commerciales, revenus récurrents et supervision des tenants.
          </p>
        </div>

        <div className="flex flex-wrap gap-2">
          <Link
            to="/admin/plans"
            className="px-4 py-2 rounded-xl bg-white text-[#1A8FBF] text-xs font-bold hover:bg-[#F0F9FE] transition inline-flex items-center gap-1.5"
          >
            <Layers className="w-3.5 h-3.5" />
            <span>Forfaits</span>
          </Link>
          <Link
            to="/admin/boutiques"
            className="px-4 py-2 rounded-xl bg-white/15 border border-white/25 text-white text-xs font-bold hover:bg-white/25 transition inline-flex items-center gap-1.5"
          >
            <Store className="w-3.5 h-3.5" />
            <span>Boutiques</span>
          </Link>
        </div>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
        <div className="card-toc card-hover p-5">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-[#5A7184] dark:text-slate-400 uppercase tracking-wider">
              MRR Mensuel
            </span>
            <div className="p-2 rounded-xl bg-[#E8F8F0] dark:bg-[#27AE60]/15 text-[#27AE60]">
              <TrendingUp className="w-4 h-4" />
            </div>
          </div>
          <div className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white mt-2 font-mono">
            {(kpis?.mrr || 0).toLocaleString('fr-FR')} {kpis?.currency}
          </div>
          <div className="text-[11px] text-[#5A7184] dark:text-slate-400 mt-1">
            ARR estimé : {(kpis?.arr || 0).toLocaleString('fr-FR')} {kpis?.currency}
          </div>
        </div>

        <div className="card-toc card-hover p-5">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-[#5A7184] dark:text-slate-400 uppercase tracking-wider">
              Boutiques Clientes
            </span>
            <div className="p-2 rounded-xl bg-[#E8F5FD] dark:bg-[#29ABE2]/15 text-[#29ABE2]">
              <Store className="w-4 h-4" />
            </div>
          </div>
          <div className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white mt-2">
            {kpis?.active_boutiques}{' '}
            <span className="text-sm font-normal text-[#9FB3C8]">/ {kpis?.total_boutiques}</span>
          </div>
          <div className="text-[11px] text-[#27AE60] font-semibold mt-1">
            {kpis?.trialing_subscriptions} en période d'essai Pro
          </div>
        </div>

        <div className="card-toc card-hover p-5">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-[#5A7184] dark:text-slate-400 uppercase tracking-wider">
              Points de Vente
            </span>
            <div className="p-2 rounded-xl bg-[#F5EEF8] dark:bg-[#8E44AD]/15 text-[#8E44AD]">
              <ShoppingBag className="w-4 h-4" />
            </div>
          </div>
          <div className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white mt-2">
            {kpis?.total_magasins}
          </div>
          <div className="text-[11px] text-[#5A7184] dark:text-slate-400 mt-1">
            Caisses & réserves connectées
          </div>
        </div>

        <div className="card-toc card-hover p-5">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-[#5A7184] dark:text-slate-400 uppercase tracking-wider">
              Volume d'Affaires GMV
            </span>
            <div className="p-2 rounded-xl bg-[#FEF5E7] dark:bg-[#F39C12]/15 text-[#F39C12]">
              <DollarSign className="w-4 h-4" />
            </div>
          </div>
          <div className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white mt-2 font-mono">
            {(kpis?.total_gmv || 0).toLocaleString('fr-FR')} {kpis?.currency}
          </div>
          <div className="text-[11px] text-[#5A7184] dark:text-slate-400 mt-1">
            Total des ventes enregistrées
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="card-toc card-hover p-6 space-y-4">
          <div className="flex items-center gap-2.5">
            <div className="p-2 rounded-xl bg-[#E8F5FD] dark:bg-[#29ABE2]/15 text-[#29ABE2]">
              <ShieldCheck className="w-5 h-5" />
            </div>
            <h3 className="font-bold text-base text-[#1C2B3A] dark:text-white">
              Gestionnaire des Forfaits & Délais d'Essai
            </h3>
          </div>
          <p className="text-xs text-[#5A7184] dark:text-slate-400 leading-relaxed">
            Créez de nouvelles formules, configurez les droits d'accès par plan, ajustez les tarifs mensuels et annuels ainsi que les périodes d'essai gratuit.
          </p>
          <Link to="/admin/plans" className="btn-primary text-xs">
            <span>Configurer les Forfaits</span>
            <ArrowRight className="w-4 h-4" />
          </Link>
        </div>

        <div className="card-toc card-hover p-6 space-y-4">
          <div className="flex items-center gap-2.5">
            <div className="p-2 rounded-xl bg-[#E8F8F0] dark:bg-[#27AE60]/15 text-[#27AE60]">
              <Store className="w-5 h-5" />
            </div>
            <h3 className="font-bold text-base text-[#1C2B3A] dark:text-white">
              Annuaire des Entreprises & Boutiques
            </h3>
          </div>
          <p className="text-xs text-[#5A7184] dark:text-slate-400 leading-relaxed">
            Consultez chaque boutique inscrite, prolongez un essai gratuit, changez manuellement un forfait ou suspendez un compte.
          </p>
          <Link to="/admin/boutiques" className="btn-secondary text-xs">
            <span>Gérer les Boutiques</span>
            <ArrowRight className="w-4 h-4 text-[#29ABE2]" />
          </Link>
        </div>
      </div>
    </div>
  );
};
