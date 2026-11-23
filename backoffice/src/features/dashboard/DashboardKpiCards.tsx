import React from 'react';
import { useNavigate } from 'react-router-dom';
import {
  TrendingUp,
  AlertTriangle,
  Receipt,
  Users,
  Wallet,
  CheckCircle2,
  Package,
  Layers,
  ShoppingBag,
} from 'lucide-react';
import { DashboardStats } from '../../types';
import { formatFCFA } from '../../lib/formatters';

interface DashboardKpiCardsProps {
  stats?: DashboardStats;
  statsLoading: boolean;
  categoriesCount: number;
  lowStockCount: number;
}

export const DashboardKpiCards: React.FC<DashboardKpiCardsProps> = ({
  stats,
  statsLoading,
  categoriesCount,
  lowStockCount,
}) => {
  const navigate = useNavigate();

  return (
    <>
      <div>
        <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400 mb-3 px-1">
          Inventaire & Valorisation du Stock
        </h3>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-5">
          <div
            onClick={() => navigate('/produits')}
            className="card-toc p-4 sm:p-5 flex flex-col justify-between hover:border-brand-300 dark:hover:border-brand-500/40 transition-all cursor-pointer"
          >
            <div className="flex items-center justify-between">
              <span className="text-[11px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
                Produits
              </span>
              <div className="w-10 h-10 rounded-2xl bg-brand-50 dark:bg-brand-500/20 text-brand-600 dark:text-brand-400 flex items-center justify-center">
                <Package className="w-5 h-5" />
              </div>
            </div>
            <div className="mt-3">
              <div className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">
                {statsLoading ? '...' : stats?.products_count ?? 0}
              </div>
              <div className="text-xs text-slate-400 mt-0.5 font-medium">Articles au catalogue</div>
            </div>
          </div>

          <div
            onClick={() => navigate('/categories')}
            className="card-toc p-4 sm:p-5 flex flex-col justify-between hover:border-emerald-300 dark:hover:border-emerald-500/40 transition-all cursor-pointer"
          >
            <div className="flex items-center justify-between">
              <span className="text-[11px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
                Catégories
              </span>
              <div className="w-10 h-10 rounded-2xl bg-emerald-50 dark:bg-emerald-500/20 text-emerald-600 dark:text-emerald-400 flex items-center justify-center">
                <Layers className="w-5 h-5" />
              </div>
            </div>
            <div className="mt-3">
              <div className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">
                {statsLoading ? '...' : stats?.categories_count ?? categoriesCount}
              </div>
              <div className="text-xs text-slate-400 mt-0.5 font-medium">Rayons organisés</div>
            </div>
          </div>

          <div
            onClick={() => navigate('/produits')}
            className="card-toc p-4 sm:p-5 flex flex-col justify-between hover:border-purple-300 dark:hover:border-purple-500/40 transition-all cursor-pointer"
          >
            <div className="flex items-center justify-between">
              <span className="text-[11px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
                Valeur Stock (Vente)
              </span>
              <div className="w-10 h-10 rounded-2xl bg-purple-50 dark:bg-purple-500/20 text-purple-600 dark:text-purple-400 flex items-center justify-center">
                <TrendingUp className="w-5 h-5" />
              </div>
            </div>
            <div className="mt-3">
              <div className="text-2xl font-extrabold text-purple-600 dark:text-purple-400 font-mono tracking-tight">
                {statsLoading ? '...' : formatFCFA(stats?.stock_value || 0)}
              </div>
              <div className="text-xs text-slate-400 mt-0.5 font-medium">
                Coût : {formatFCFA(stats?.stock_cost || 0)}
              </div>
            </div>
          </div>

          <div
            onClick={() => navigate('/produits')}
            className="card-toc p-4 sm:p-5 flex flex-col justify-between hover:border-rose-300 dark:hover:border-rose-500/40 transition-all cursor-pointer"
          >
            <div className="flex items-center justify-between">
              <span className="text-[11px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
                Alertes Stock
              </span>
              <div className="w-10 h-10 rounded-2xl bg-rose-50 dark:bg-rose-500/20 text-rose-600 dark:text-rose-400 flex items-center justify-center">
                <AlertTriangle className="w-5 h-5" />
              </div>
            </div>
            <div className="mt-3">
              <div className="text-2xl font-extrabold text-rose-600 dark:text-rose-400 tracking-tight">
                {statsLoading ? '...' : lowStockCount}
              </div>
              <div className="text-xs text-slate-400 mt-0.5 font-medium">Sous le seuil d'alerte</div>
            </div>
          </div>
        </div>
      </div>

      <div>
        <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400 mb-3 px-1">
          Activité Commerciale & Trésorerie
        </h3>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-5">
          <div
            onClick={() => navigate('/ventes')}
            className="card-toc p-4 sm:p-5 flex flex-col justify-between hover:border-emerald-300 dark:hover:border-emerald-500/40 transition-all cursor-pointer"
          >
            <div className="flex items-center justify-between">
              <span className="text-[11px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
                Ventes Aujourd'hui
              </span>
              <div className="w-10 h-10 rounded-2xl bg-emerald-50 dark:bg-emerald-500/20 text-emerald-600 dark:text-emerald-400 flex items-center justify-center">
                <ShoppingBag className="w-5 h-5" />
              </div>
            </div>
            <div className="mt-3">
              <div className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white font-mono tracking-tight">
                {statsLoading ? '...' : formatFCFA(stats?.today_sales_amount || 0)}
              </div>
              <div className="text-xs text-slate-400 mt-0.5 font-medium flex items-center gap-1.5">
                <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />
                <span>{stats?.today_sales_count || 0} tickets encaissés</span>
              </div>
            </div>
          </div>

          <div
            onClick={() => navigate('/ventes')}
            className="card-toc p-4 sm:p-5 flex flex-col justify-between hover:border-brand-300 dark:hover:border-brand-500/40 transition-all cursor-pointer"
          >
            <div className="flex items-center justify-between">
              <span className="text-[11px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
                CA Global Cumulé
              </span>
              <div className="w-10 h-10 rounded-2xl bg-brand-50 dark:bg-brand-500/20 text-brand-600 dark:text-brand-400 flex items-center justify-center">
                <Receipt className="w-5 h-5" />
              </div>
            </div>
            <div className="mt-3">
              <div className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white font-mono tracking-tight">
                {statsLoading ? '...' : formatFCFA(stats?.total_sales_amount || 0)}
              </div>
              <div className="text-xs text-slate-400 mt-0.5 font-medium">
                {stats?.total_sales_count || 0} ventes au total
              </div>
            </div>
          </div>

          <div
            onClick={() => navigate('/clients')}
            className="card-toc p-4 sm:p-5 flex flex-col justify-between hover:border-amber-300 dark:hover:border-amber-500/40 transition-all cursor-pointer"
          >
            <div className="flex items-center justify-between">
              <span className="text-[11px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
                Créances Clients (Crédits)
              </span>
              <div className="w-10 h-10 rounded-2xl bg-amber-50 dark:bg-amber-500/20 text-amber-600 dark:text-amber-400 flex items-center justify-center">
                <Users className="w-5 h-5" />
              </div>
            </div>
            <div className="mt-3">
              <div className="text-2xl font-extrabold text-amber-600 dark:text-amber-400 font-mono tracking-tight">
                {statsLoading ? '...' : formatFCFA(stats?.total_receivables || 0)}
              </div>
              <div className="text-xs text-slate-400 mt-0.5 font-medium">Solde total restant dû</div>
            </div>
          </div>

          <div
            onClick={() => navigate('/depenses')}
            className="card-toc p-4 sm:p-5 flex flex-col justify-between hover:border-rose-300 dark:hover:border-rose-500/40 transition-all cursor-pointer"
          >
            <div className="flex items-center justify-between">
              <span className="text-[11px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
                Total Décaissements
              </span>
              <div className="w-10 h-10 rounded-2xl bg-rose-50 dark:bg-rose-500/20 text-rose-600 dark:text-rose-400 flex items-center justify-center">
                <Wallet className="w-5 h-5" />
              </div>
            </div>
            <div className="mt-3">
              <div className="text-2xl font-extrabold text-rose-600 dark:text-rose-400 font-mono tracking-tight">
                {statsLoading ? '...' : formatFCFA(stats?.total_expenses || 0)}
              </div>
              <div className="text-xs text-slate-400 mt-0.5 font-medium">Charges d'exploitation</div>
            </div>
          </div>
        </div>
      </div>
    </>
  );
};
