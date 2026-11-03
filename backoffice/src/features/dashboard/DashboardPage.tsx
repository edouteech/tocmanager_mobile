import React from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  TrendingUp,
  AlertTriangle,
  Receipt,
  Users,
  Wallet,
  RefreshCw,
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
import { api } from '../../lib/api';
import { formatFCFA, formatDateTime } from '../../lib/formatters';
import { DashboardStats, Vente } from '../../types';
import { useDensity } from '../../context/DensityContext';
import { useTheme } from '../../context/ThemeContext';

export const DashboardPage: React.FC = () => {
  const { tableClasses } = useDensity();
  const { theme } = useTheme();

  // Query dashboard statistics
  const { data: stats, isLoading: statsLoading, refetch: refetchStats } = useQuery<DashboardStats>({
    queryKey: ['dashboard-stats'],
    queryFn: async () => {
      const res = await api.get('/reports/dashboard');
      return res.data;
    },
    refetchInterval: 15000,
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

  return (
    <div className="space-y-7 max-w-7xl mx-auto">
      {/* Header bar */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-slate-900 dark:text-white tracking-tight">
            Tableau de Bord
          </h1>
          <p className="text-xs sm:text-sm text-slate-500 dark:text-slate-400 mt-1">
            Supervision en temps réel des ventes, alertes de stock et situation de trésorerie.
          </p>
        </div>
        <button
          onClick={() => refetchStats()}
          className="btn-secondary self-start"
        >
          <RefreshCw className="w-3.5 h-3.5 text-brand-500" />
          <span>Actualiser les flux</span>
        </button>
      </div>

      {/* KPI Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
        {/* Card 1: Today's sales */}
        <div className="card-toc card-hover p-5">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
              Ventes Aujourd'hui
            </span>
            <div className="w-9 h-9 rounded-xl bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 flex items-center justify-center border border-emerald-100 dark:border-emerald-800/40">
              <TrendingUp className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-3">
            <div className="text-2xl font-extrabold text-slate-900 dark:text-white">
              {statsLoading ? '...' : formatFCFA(stats?.today_sales_amount || 0)}
            </div>
            <div className="text-xs text-slate-500 dark:text-slate-400 mt-1 font-medium">
              <span>{stats?.today_sales_count || 0} tickets encaissés</span>
            </div>
          </div>
        </div>

        {/* Card 2: Total Sales */}
        <div className="card-toc card-hover p-5">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
              CA Global Cumulé
            </span>
            <div className="w-9 h-9 rounded-xl bg-brand-50 dark:bg-brand-500/15 text-brand-600 dark:text-brand-400 flex items-center justify-center border border-brand-200 dark:border-brand-500/30">
              <Receipt className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-3">
            <div className="text-2xl font-extrabold text-slate-900 dark:text-white">
              {statsLoading ? '...' : formatFCFA(stats?.total_sales_amount || 0)}
            </div>
            <div className="text-xs text-slate-500 dark:text-slate-400 mt-1 font-medium">
              <span>{stats?.total_sales_count || 0} ventes au total</span>
            </div>
          </div>
        </div>

        {/* Card 3: Receivables */}
        <div className="card-toc card-hover p-5">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
              Créances Clients (Crédits)
            </span>
            <div className="w-9 h-9 rounded-xl bg-amber-50 dark:bg-amber-950/40 text-amber-600 dark:text-amber-400 flex items-center justify-center border border-amber-100 dark:border-amber-800/40">
              <Users className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-3">
            <div className="text-2xl font-extrabold text-amber-600 dark:text-amber-400">
              {statsLoading ? '...' : formatFCFA(stats?.total_receivables || 0)}
            </div>
            <div className="text-xs text-slate-500 dark:text-slate-400 mt-1 font-medium">
              <span>Solde total restant dû</span>
            </div>
          </div>
        </div>

        {/* Card 4: Low Stock Alert */}
        <div className="card-toc card-hover p-5">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
              Alertes Rupture Stock
            </span>
            <div className="w-9 h-9 rounded-xl bg-rose-50 dark:bg-rose-950/40 text-rose-600 dark:text-rose-400 flex items-center justify-center border border-rose-100 dark:border-rose-800/40">
              <AlertTriangle className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-3">
            <div className="text-2xl font-extrabold text-rose-600 dark:text-rose-400">
              {statsLoading ? '...' : stats?.low_stock_count || 0}
            </div>
            <div className="text-xs text-slate-500 dark:text-slate-400 mt-1 font-medium">
              <span>Articles sous le seuil d'alerte</span>
            </div>
          </div>
        </div>
      </div>

      {/* Analytics Charts & Summary */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Sales Chart */}
        <div className="lg:col-span-2 card-toc p-6 flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between mb-4">
              <div>
                <h3 className="text-base font-bold text-slate-900 dark:text-white">
                  Dernières Ventes Encaissées
                </h3>
                <p className="text-xs text-slate-500 dark:text-slate-400">Montant par ticket en direct</p>
              </div>
              <span className="text-xs font-semibold text-brand-600 dark:text-brand-400 bg-brand-50 dark:bg-brand-500/15 px-2.5 py-1 rounded-full border border-brand-200 dark:border-brand-500/30">
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
                      backgroundColor: theme === 'dark' ? '#16222F' : '#1C2B3A',
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
            <h3 className="text-base font-bold text-slate-900 dark:text-white mb-1">
              Aperçu Financier Global
            </h3>
            <p className="text-xs text-slate-500 dark:text-slate-400 mb-6">Recettes vs Décaissements</p>

            <div className="space-y-4">
              <div className="flex items-center justify-between p-3.5 bg-brand-50/50 dark:bg-dark-700/60 rounded-xl border border-brand-100 dark:border-dark-600">
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-lg bg-brand-100 dark:bg-brand-500/20 text-brand-600 dark:text-brand-400 flex items-center justify-center font-bold">
                    <Receipt className="w-4 h-4" />
                  </div>
                  <div>
                    <div className="text-xs font-bold text-slate-900 dark:text-white">Recettes Ventes</div>
                    <div className="text-[11px] text-slate-500 dark:text-slate-400">Encaissées</div>
                  </div>
                </div>
                <div className="text-sm font-extrabold text-slate-900 dark:text-white">
                  {formatFCFA(stats?.total_sales_amount || 0)}
                </div>
              </div>

              <div className="flex items-center justify-between p-3.5 bg-rose-50/60 dark:bg-rose-950/30 rounded-xl border border-rose-100 dark:border-rose-900/40">
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-lg bg-rose-100 dark:bg-rose-900/40 text-rose-600 dark:text-rose-400 flex items-center justify-center">
                    <Wallet className="w-4 h-4" />
                  </div>
                  <div>
                    <div className="text-xs font-bold text-rose-900 dark:text-rose-200">Charges & Dépenses</div>
                    <div className="text-[11px] text-rose-600 dark:text-rose-400">Décaissements</div>
                  </div>
                </div>
                <div className="text-sm font-extrabold text-rose-600 dark:text-rose-400">
                  - {formatFCFA(stats?.total_expenses || 0)}
                </div>
              </div>

              <div className="pt-2 border-t border-[#E8EFF5] dark:border-dark-600 flex items-center justify-between">
                <span className="text-xs font-bold text-slate-500 dark:text-slate-400 uppercase">Solde Net Théorique</span>
                <span className="text-base font-extrabold text-emerald-600 dark:text-emerald-400">
                  {formatFCFA((stats?.total_sales_amount || 0) - (stats?.total_expenses || 0))}
                </span>
              </div>
            </div>
          </div>

          <div className="mt-6 pt-4 border-t border-[#E8EFF5] dark:border-dark-600 text-[11px] text-slate-400 dark:text-slate-500">
            Ce solde n'inclut pas les créances clients restant à recouvrer.
          </div>
        </div>
      </div>

      {/* Recent Sales Table with Density support */}
      <div className="card-toc overflow-hidden">
        <div className="px-6 py-4 border-b border-[#E8EFF5] dark:border-dark-600 flex items-center justify-between">
          <h3 className="text-base font-bold text-slate-900 dark:text-white">
            Dernières Ventes Encaissées
          </h3>
          <span className="text-xs text-slate-500 dark:text-slate-400">Flux en direct des caisses</span>
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
                  <td colSpan={5} className="px-6 py-8 text-center text-slate-400">
                    Chargement des ventes...
                  </td>
                </tr>
              ) : recentVentes && recentVentes.length > 0 ? (
                recentVentes.map((vente) => (
                  <tr key={vente.sync_id} className="hover:bg-brand-50/30 dark:hover:bg-dark-700/40 transition-colors">
                    <td className={`${tableClasses.td} font-bold text-brand-600 dark:text-brand-400 font-mono`}>
                      {vente.ticket_number}
                    </td>
                    <td className={`${tableClasses.td} font-medium`}>
                      {vente.client_name || 'Occasionnel'}
                    </td>
                    <td className={tableClasses.td}>
                      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-brand-50 dark:bg-brand-500/15 text-brand-600 dark:text-brand-400 border border-brand-200 dark:border-brand-500/30">
                        {vente.payment_method}
                      </span>
                    </td>
                    <td className={`${tableClasses.td} text-slate-500 dark:text-slate-400`}>
                      {formatDateTime(vente.created_at)}
                    </td>
                    <td className={`${tableClasses.td} text-right font-extrabold text-slate-900 dark:text-white font-mono`}>
                      {formatFCFA(vente.total_amount)}
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={5} className="px-6 py-8 text-center text-slate-400">
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
