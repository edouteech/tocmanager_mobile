import React from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import {
  TrendingUp,
  AlertTriangle,
  Receipt,
  Users,
  Wallet,
  RefreshCw,
  Store,
  ArrowRight,
  ChevronRight,
  CheckCircle2,
} from 'lucide-react';
import {
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
} from 'recharts';
import { api, categoriesApi } from '../../lib/api';
import { formatFCFA, formatDateTime } from '../../lib/formatters';
import { DashboardStats, Vente, Category } from '../../types';
import { useDensity } from '../../context/DensityContext';
import { useTheme } from '../../context/ThemeContext';

export const DashboardPage: React.FC = () => {
  const navigate = useNavigate();
  const { tableClasses } = useDensity();
  const { theme } = useTheme();

  // Query dashboard statistics
  const {
    data: stats,
    isLoading: statsLoading,
    refetch: refetchStats,
    isFetching: statsFetching,
  } = useQuery<DashboardStats>({
    queryKey: ['dashboard-stats'],
    queryFn: async () => {
      const res = await api.get('/reports/dashboard');
      return res.data;
    },
    refetchInterval: 15000,
  });

  // Query categories for summary pill
  const { data: categories } = useQuery<Category[]>({
    queryKey: ['categories'],
    queryFn: () => categoriesApi.getAll(),
  });

  // Query recent ventes
  const { data: recentVentes, isLoading: ventesLoading } = useQuery<Vente[]>({
    queryKey: ['recent-ventes'],
    queryFn: async () => {
      const res = await api.get('/ventes?limit=7');
      return res.data;
    },
    refetchInterval: 15000,
  });

  // Prepare chart data from recent ventes
  const chartData = (recentVentes || [])
    .slice()
    .reverse()
    .map((v) => ({
      ticket: v.ticket_number.replace('VNT-', '').slice(-6),
      montant: v.total_amount,
    }));

  // Greeting & Date format (same as mobile)
  const hour = new Date().getHours();
  const greeting = hour < 12 ? 'Bonjour' : hour < 18 ? 'Bon après-midi' : 'Bonsoir';
  const rawDate = new Intl.DateTimeFormat('fr-FR', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  }).format(new Date());
  const dateStr = rawDate.charAt(0).toUpperCase() + rawDate.slice(1);

  const lowStockCount = stats?.low_stock_count || 0;

  return (
    <div className="space-y-6 max-w-7xl mx-auto select-none">
      {/* 1. Greeting Banner signature Mobile (Dégradé #1A8FBF -> #29ABE2) */}
      <div className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-[#1A8FBF] to-[#29ABE2] p-6 sm:p-8 text-white shadow-soft">
        <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-6">
          <div className="space-y-2">
            <h1 className="text-2xl sm:text-3xl font-extrabold tracking-tight text-white leading-tight">
              {greeting} !
            </h1>
            <p className="text-xs sm:text-sm text-white/80 font-medium">
              {dateStr}
            </p>

            <div className="pt-2">
              <span className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-white/20 backdrop-blur-xs text-xs font-semibold text-white">
                <span>{stats?.products_count ?? 0} produits</span>
                <span className="opacity-60">•</span>
                <span>{categories?.length ?? 0} catégories</span>
              </span>
            </div>
          </div>

          <div className="flex items-center gap-4">
            <button
              onClick={() => refetchStats()}
              className="inline-flex items-center gap-2 px-4 py-2 bg-white/15 hover:bg-white/25 active:scale-95 text-white rounded-xl text-xs font-semibold backdrop-blur-xs border border-white/20 transition-all"
              title="Actualiser les données"
            >
              <RefreshCw className={`w-3.5 h-3.5 ${statsFetching ? 'animate-spin' : ''}`} />
              <span className="hidden sm:inline">Actualiser</span>
            </button>

            <div className="p-3.5 bg-white/20 backdrop-blur-xs rounded-2xl hidden sm:flex items-center justify-center border border-white/20">
              <Store className="w-8 h-8 text-white" />
            </div>
          </div>
        </div>

        {/* Decorative background circle */}
        <div className="absolute -right-8 -bottom-10 w-48 h-48 bg-white/10 rounded-full blur-2xl pointer-events-none" />
      </div>

      {/* 2. Alert Banner (Exactement calquée sur _buildAlertCard du mobile) */}
      {lowStockCount > 0 && (
        <div
          onClick={() => navigate('/produits')}
          className="cursor-pointer p-4 rounded-2xl bg-[#FDEBE9] dark:bg-[#E74C3C]/15 border border-[#E74C3C]/30 flex items-center justify-between gap-4 transition-all hover:bg-[#fbdad7] dark:hover:bg-[#E74C3C]/20"
        >
          <div className="flex items-center gap-3.5">
            <div className="w-10 h-10 rounded-xl bg-[#E74C3C] text-white flex items-center justify-center shrink-0 shadow-xs">
              <AlertTriangle className="w-5 h-5" />
            </div>
            <div>
              <h4 className="text-sm font-bold text-[#1C2B3A] dark:text-white">
                {lowStockCount} article{lowStockCount > 1 ? 's' : ''} en rupture ou stock critique
              </h4>
              <p className="text-xs text-[#E74C3C] font-semibold mt-0.5">
                Cliquez pour voir les articles et planifier un approvisionnement
              </p>
            </div>
          </div>

          <div className="flex items-center gap-1 text-xs font-bold text-[#E74C3C] shrink-0">
            <span className="hidden sm:inline">Gérer le stock</span>
            <ChevronRight className="w-4 h-4" />
          </div>
        </div>
      )}

      {/* 3. KPI Cards Grid (Palette canonique Mobile) */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-5">
        {/* Card 1: Ventes Aujourd'hui */}
        <div className="card-toc card-hover p-5 flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-[11px] font-bold uppercase tracking-wider text-[#5A7184] dark:text-slate-400">
              Ventes Aujourd'hui
            </span>
            <div className="w-10 h-10 rounded-xl bg-[#E8F8F0] dark:bg-[#27AE60]/20 text-[#27AE60] flex items-center justify-center">
              <TrendingUp className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-4">
            <div className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">
              {statsLoading ? '...' : formatFCFA(stats?.today_sales_amount || 0)}
            </div>
            <div className="text-xs text-[#5A7184] dark:text-slate-400 mt-1 font-medium flex items-center gap-1.5">
              <CheckCircle2 className="w-3.5 h-3.5 text-[#27AE60]" />
              <span>{stats?.today_sales_count || 0} tickets encaissés</span>
            </div>
          </div>
        </div>

        {/* Card 2: CA Global Cumulé */}
        <div className="card-toc card-hover p-5 flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-[11px] font-bold uppercase tracking-wider text-[#5A7184] dark:text-slate-400">
              CA Global Cumulé
            </span>
            <div className="w-10 h-10 rounded-xl bg-[#E8F5FD] dark:bg-[#29ABE2]/20 text-[#29ABE2] flex items-center justify-center">
              <Receipt className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-4">
            <div className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">
              {statsLoading ? '...' : formatFCFA(stats?.total_sales_amount || 0)}
            </div>
            <div className="text-xs text-[#5A7184] dark:text-slate-400 mt-1 font-medium">
              <span>{stats?.total_sales_count || 0} ventes au total</span>
            </div>
          </div>
        </div>

        {/* Card 3: Créances Clients */}
        <div className="card-toc card-hover p-5 flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-[11px] font-bold uppercase tracking-wider text-[#5A7184] dark:text-slate-400">
              Créances Clients (Crédits)
            </span>
            <div className="w-10 h-10 rounded-xl bg-[#FEF5E7] dark:bg-[#F39C12]/20 text-[#F39C12] flex items-center justify-center">
              <Users className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-4">
            <div className="text-2xl font-extrabold text-[#F39C12] tracking-tight">
              {statsLoading ? '...' : formatFCFA(stats?.total_receivables || 0)}
            </div>
            <div className="text-xs text-[#5A7184] dark:text-slate-400 mt-1 font-medium">
              <span>Solde total restant dû</span>
            </div>
          </div>
        </div>

        {/* Card 4: Ruptures de Stock */}
        <div
          onClick={() => navigate('/produits')}
          className="card-toc card-hover p-5 flex flex-col justify-between cursor-pointer"
        >
          <div className="flex items-center justify-between">
            <span className="text-[11px] font-bold uppercase tracking-wider text-[#5A7184] dark:text-slate-400">
              Alertes Stock
            </span>
            <div className="w-10 h-10 rounded-xl bg-[#FDEBE9] dark:bg-[#E74C3C]/20 text-[#E74C3C] flex items-center justify-center">
              <AlertTriangle className="w-5 h-5" />
            </div>
          </div>
          <div className="mt-4">
            <div className="text-2xl font-extrabold text-[#E74C3C] tracking-tight">
              {statsLoading ? '...' : lowStockCount}
            </div>
            <div className="text-xs text-[#5A7184] dark:text-slate-400 mt-1 font-medium">
              <span>Articles sous le seuil d'alerte</span>
            </div>
          </div>
        </div>
      </div>

      {/* 4. Analytics & Financial Breakdown */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Sales Chart */}
        <div className="lg:col-span-2 card-toc p-6 flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between mb-4">
              <div>
                <h3 className="text-base font-bold text-[#1C2B3A] dark:text-white">
                  Dernières Ventes Encaissées
                </h3>
                <p className="text-xs text-[#5A7184] dark:text-slate-400">Montant par ticket en direct</p>
              </div>
              <span className="badge-toc-primary">
                Temps Réel
              </span>
            </div>

            <div className="h-64 w-full">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={chartData} margin={{ top: 10, right: 10, left: -10, bottom: 0 }}>
                  <CartesianGrid
                    strokeDasharray="3 3"
                    vertical={false}
                    stroke={theme === 'dark' ? '#26384C' : '#E8EFF5'}
                  />
                  <XAxis
                    dataKey="ticket"
                    stroke={theme === 'dark' ? '#5A7184' : '#9FB3C8'}
                    fontSize={11}
                    tickLine={false}
                  />
                  <YAxis
                    stroke={theme === 'dark' ? '#5A7184' : '#9FB3C8'}
                    fontSize={11}
                    tickLine={false}
                  />
                  <Tooltip
                    formatter={(val: number) => formatFCFA(val)}
                    contentStyle={{
                      backgroundColor: theme === 'dark' ? '#121E2A' : '#1C2B3A',
                      color: '#fff',
                      borderRadius: '12px',
                      border: 'none',
                      fontSize: '12px',
                    }}
                  />
                  <Bar dataKey="montant" fill="#29ABE2" radius={[6, 6, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          </div>
        </div>

        {/* Financial Snapshot */}
        <div className="card-toc p-6 flex flex-col justify-between">
          <div>
            <h3 className="text-base font-bold text-[#1C2B3A] dark:text-white mb-1">
              Aperçu Financier Global
            </h3>
            <p className="text-xs text-[#5A7184] dark:text-slate-400 mb-6">Recettes vs Décaissements</p>

            <div className="space-y-3.5">
              <div className="flex items-center justify-between p-3.5 bg-[#F0F9FE] dark:bg-dark-700/60 rounded-xl border border-[#E8EFF5] dark:border-dark-600">
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-lg bg-[#E8F5FD] dark:bg-[#29ABE2]/20 text-[#29ABE2] flex items-center justify-center font-bold">
                    <Receipt className="w-4 h-4" />
                  </div>
                  <div>
                    <div className="text-xs font-bold text-[#1C2B3A] dark:text-white">Recettes Ventes</div>
                    <div className="text-[11px] text-[#5A7184] dark:text-slate-400">Encaissées</div>
                  </div>
                </div>
                <div className="text-sm font-extrabold text-[#1C2B3A] dark:text-white font-mono">
                  {formatFCFA(stats?.total_sales_amount || 0)}
                </div>
              </div>

              <div className="flex items-center justify-between p-3.5 bg-[#FDEBE9]/50 dark:bg-rose-950/30 rounded-xl border border-[#E74C3C]/20 dark:border-rose-900/40">
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-lg bg-[#FDEBE9] dark:bg-rose-900/40 text-[#E74C3C] flex items-center justify-center">
                    <Wallet className="w-4 h-4" />
                  </div>
                  <div>
                    <div className="text-xs font-bold text-[#E74C3C]">Charges & Dépenses</div>
                    <div className="text-[11px] text-[#5A7184] dark:text-slate-400">Décaissements</div>
                  </div>
                </div>
                <div className="text-sm font-extrabold text-[#E74C3C] font-mono">
                  - {formatFCFA(stats?.total_expenses || 0)}
                </div>
              </div>

              <div className="pt-3 border-t border-[#E8EFF5] dark:border-dark-600 flex items-center justify-between">
                <span className="text-xs font-bold text-[#5A7184] dark:text-slate-400 uppercase">Solde Net Théorique</span>
                <span className="text-base font-extrabold text-[#27AE60] font-mono">
                  {formatFCFA((stats?.total_sales_amount || 0) - (stats?.total_expenses || 0))}
                </span>
              </div>
            </div>
          </div>

          <div className="mt-6 pt-4 border-t border-[#E8EFF5] dark:border-dark-600 text-[11px] text-[#9FB3C8]">
            Ce solde n'inclut pas les créances clients restant à recouvrer.
          </div>
        </div>
      </div>

      {/* 5. Recent Sales Table with Density support */}
      <div className="card-toc overflow-hidden">
        <div className="px-6 py-4 border-b border-[#E8EFF5] dark:border-dark-600 flex items-center justify-between">
          <div>
            <h3 className="text-base font-bold text-[#1C2B3A] dark:text-white">
              Dernières Ventes Encaissées
            </h3>
            <span className="text-xs text-[#5A7184] dark:text-slate-400">Flux en direct des caisses</span>
          </div>

          <button
            onClick={() => navigate('/ventes')}
            className="inline-flex items-center gap-1.5 text-xs font-semibold text-[#29ABE2] hover:text-[#1A8FBF] transition"
          >
            <span>Voir tout le journal</span>
            <ArrowRight className="w-3.5 h-3.5" />
          </button>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead className="bg-[#F5FAFD] dark:bg-dark-700/50 border-b border-[#E8EFF5] dark:border-dark-600">
              <tr>
                <th className={tableClasses.th}>Numéro Ticket</th>
                <th className={tableClasses.th}>Client</th>
                <th className={tableClasses.th}>Mode Paiement</th>
                <th className={tableClasses.th}>Date & Heure</th>
                <th className={`${tableClasses.th} text-right`}>Montant Total</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#E8EFF5] dark:divide-dark-600/60">
              {ventesLoading ? (
                <tr>
                  <td colSpan={5} className="px-6 py-8 text-center text-[#9FB3C8]">
                    Chargement des ventes...
                  </td>
                </tr>
              ) : recentVentes && recentVentes.length > 0 ? (
                recentVentes.map((vente) => (
                  <tr key={vente.sync_id} className="hover:bg-[#F0F9FE]/60 dark:hover:bg-dark-700/40 transition-colors">
                    <td className={`${tableClasses.td} font-bold text-[#29ABE2] font-mono`}>
                      {vente.ticket_number}
                    </td>
                    <td className={`${tableClasses.td} font-medium text-[#1C2B3A] dark:text-slate-200`}>
                      {vente.client_name || 'Occasionnel'}
                    </td>
                    <td className={tableClasses.td}>
                      <span className="badge-toc-primary">
                        {vente.payment_method}
                      </span>
                    </td>
                    <td className={`${tableClasses.td} text-[#5A7184] dark:text-slate-400`}>
                      {formatDateTime(vente.created_at)}
                    </td>
                    <td className={`${tableClasses.td} text-right font-extrabold text-[#1C2B3A] dark:text-white font-mono`}>
                      {formatFCFA(vente.total_amount)}
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={5} className="px-6 py-8 text-center text-[#9FB3C8]">
                    Aucune vente enregistrée pour le moment.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
