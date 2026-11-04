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
  Package,
  Layers,
  ShoppingBag,
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
  const { data: categories = [] } = useQuery<Category[]>({
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
                <span>{stats?.categories_count ?? categories.length} catégories</span>
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

      {/* 3. Core Inventory & Stock Valuation Cards (Exact match with Mobile _buildStatsGrid) */}
      <div>
        <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400 mb-3 px-1">
          Inventaire & Valorisation du Stock
        </h3>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-5">
          {/* Card 1: Produits */}
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
              <div className="text-xs text-slate-400 mt-0.5 font-medium">
                Articles au catalogue
              </div>
            </div>
          </div>

          {/* Card 2: Catégories */}
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
                {statsLoading ? '...' : stats?.categories_count ?? categories.length}
              </div>
              <div className="text-xs text-slate-400 mt-0.5 font-medium">
                Rayons organisés
              </div>
            </div>
          </div>

          {/* Card 3: Valeur Stock (Vente & Coût) */}
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

          {/* Card 4: Alertes Stock */}
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
              <div className="text-xs text-slate-400 mt-0.5 font-medium">
                Sous le seuil d'alerte
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* 4. Operational Financial KPI Cards (Ventes, CA, Créances, Dépenses) */}
      <div>
        <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400 mb-3 px-1">
          Activité Commerciale & Trésorerie
        </h3>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-5">
          {/* Card 1: Ventes Aujourd'hui */}
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

          {/* Card 2: CA Global Cumulé */}
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

          {/* Card 3: Créances Clients (Crédits) */}
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
              <div className="text-xs text-slate-400 mt-0.5 font-medium">
                Solde total restant dû
              </div>
            </div>
          </div>

          {/* Card 4: Total Décaissements */}
          <div
            onClick={() => navigate('/decaissements')}
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
              <div className="text-xs text-slate-400 mt-0.5 font-medium">
                Charges d'exploitation
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* 5. Analytics & Live Sales Activity */}
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
              {ventesLoading ? (
                <div className="h-full flex items-center justify-center text-xs text-slate-400">
                  Chargement du graphique...
                </div>
              ) : chartData.length > 0 ? (
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={chartData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                    <CartesianGrid
                      strokeDasharray="3 3"
                      vertical={false}
                      stroke={theme === 'dark' ? '#26384C' : '#E8EFF5'}
                    />
                    <XAxis
                      dataKey="ticket"
                      stroke={theme === 'dark' ? '#5A7184' : '#94A3B8'}
                      fontSize={11}
                      tickLine={false}
                    />
                    <YAxis
                      stroke={theme === 'dark' ? '#5A7184' : '#94A3B8'}
                      fontSize={11}
                      tickLine={false}
                    />
                    <Tooltip
                      formatter={(val: number) => formatFCFA(val)}
                      contentStyle={{
                        backgroundColor: theme === 'dark' ? '#16222F' : '#1C2B3A',
                        color: '#fff',
                        borderRadius: '12px',
                        border: 'none',
                        fontSize: '12px',
                      }}
                    />
                    <Bar
                      dataKey="montant"
                      name="Montant (FCFA)"
                      fill="#29ABE2"
                      radius={[6, 6, 0, 0]}
                    />
                  </BarChart>
                </ResponsiveContainer>
              ) : (
                <div className="h-full flex items-center justify-center text-xs text-slate-400">
                  Aucune vente enregistrée pour le moment.
                </div>
              )}
            </div>
          </div>

          <div className="pt-4 mt-2 border-t border-[#E8EFF5] dark:border-dark-600 flex items-center justify-between">
            <span className="text-xs text-[#5A7184] dark:text-slate-400">
              Synchronisation automatique active
            </span>
            <button
              onClick={() => navigate('/ventes')}
              className="inline-flex items-center gap-1 text-xs font-bold text-brand-500 hover:text-brand-600 transition"
            >
              <span>Consulter le journal</span>
              <ArrowRight className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>

        {/* Recent Transactions List */}
        <div className="card-toc p-6 flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between mb-4">
              <h3 className="text-base font-bold text-[#1C2B3A] dark:text-white">
                Tickets Récents
              </h3>
              <button
                onClick={() => navigate('/ventes')}
                className="text-xs font-bold text-brand-500 hover:underline"
              >
                Tout voir
              </button>
            </div>

            <div className="space-y-3">
              {ventesLoading ? (
                <p className="text-xs text-slate-400">Chargement...</p>
              ) : (recentVentes || []).length > 0 ? (
                (recentVentes || []).slice(0, 5).map((v) => (
                  <div
                    key={v.sync_id}
                    onClick={() => navigate('/ventes')}
                    className="flex items-center justify-between p-2.5 rounded-xl hover:bg-[#F0F9FE] dark:hover:bg-dark-700/50 transition cursor-pointer"
                  >
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 rounded-lg bg-brand-50 dark:bg-brand-500/15 text-brand-500 flex items-center justify-center font-bold text-xs">
                        #
                      </div>
                      <div>
                        <p className="text-xs font-bold text-[#1C2B3A] dark:text-white">
                          {v.ticket_number}
                        </p>
                        <p className="text-[11px] text-[#5A7184] dark:text-slate-400">
                          {v.client_name || 'Occasionnel'} • {formatDateTime(v.created_at)}
                        </p>
                      </div>
                    </div>
                    <span className="text-xs font-extrabold text-emerald-600 dark:text-emerald-400 font-mono">
                      {formatFCFA(v.total_amount)}
                    </span>
                  </div>
                ))
              ) : (
                <p className="text-xs text-slate-400">Aucune vente récente.</p>
              )}
            </div>
          </div>

          <div className="pt-4 border-t border-[#E8EFF5] dark:border-dark-600 mt-4">
            <button
              onClick={() => navigate('/rapports')}
              className="w-full py-2 bg-slate-50 hover:bg-slate-100 dark:bg-dark-700 dark:hover:bg-dark-600 text-slate-700 dark:text-slate-200 rounded-xl text-xs font-bold transition flex items-center justify-center gap-1.5"
            >
              <span>Voir le rapport financier complet</span>
              <ChevronRight className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
