import React from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  TrendingUp,
  CreditCard,
  AlertTriangle,
  Receipt,
  Users,
  Wallet,
  ArrowUpRight,
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

export const DashboardPage: React.FC = () => {
  // Query dashboard statistics
  const { data: stats, isLoading: statsLoading, refetch: refetchStats } = useQuery<DashboardStats>({
    queryKey: ['dashboard-stats'],
    queryFn: async () => {
      const res = await api.get('/reports/dashboard');
      return res.data;
    },
    refetchInterval: 15000, // auto refresh every 15s
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
      ticket: v.ticket_number.replace('VNT-', ''),
      montant: v.total_amount,
    }));

  return (
    <div className="space-y-8 max-w-7xl mx-auto">
      {/* Header bar */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl font-bold text-slate-900 tracking-tight">
            Tableau de Bord
          </h2>
          <p className="text-sm text-slate-500 mt-1">
            Supervision des ventes en direct, alertes stocks et trésorerie globale.
          </p>
        </div>
        <button
          onClick={() => refetchStats()}
          className="inline-flex items-center gap-2 px-3.5 py-2 bg-white border border-slate-200 rounded-xl text-xs font-semibold text-slate-700 hover:bg-slate-50 transition shadow-sm self-start"
        >
          <RefreshCw className="w-3.5 h-3.5 text-slate-500" />
          <span>Actualiser les données</span>
        </button>
      </div>

      {/* KPI Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
        {/* Card 1: Today's sales */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">
              Ventes Aujourd'hui
            </span>
            <div className="w-8 h-8 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center">
              <TrendingUp className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-3">
            <div className="text-2xl font-bold text-slate-900">
              {statsLoading ? '...' : formatFCFA(stats?.today_sales_amount || 0)}
            </div>
            <div className="text-xs text-slate-500 mt-1 flex items-center gap-1">
              <span>{stats?.today_sales_count || 0} tickets encaissés</span>
            </div>
          </div>
        </div>

        {/* Card 2: Total Sales */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">
              CA Global Cumulé
            </span>
            <div className="w-8 h-8 rounded-lg bg-indigo-50 text-indigo-600 flex items-center justify-center">
              <Receipt className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-3">
            <div className="text-2xl font-bold text-slate-900">
              {statsLoading ? '...' : formatFCFA(stats?.total_sales_amount || 0)}
            </div>
            <div className="text-xs text-slate-500 mt-1">
              <span>{stats?.total_sales_count || 0} ventes au total</span>
            </div>
          </div>
        </div>

        {/* Card 3: Receivables */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">
              Créances Clients (Crédits)
            </span>
            <div className="w-8 h-8 rounded-lg bg-amber-50 text-amber-600 flex items-center justify-center">
              <Users className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-3">
            <div className="text-2xl font-bold text-slate-900">
              {statsLoading ? '...' : formatFCFA(stats?.total_receivables || 0)}
            </div>
            <div className="text-xs text-amber-600 font-medium mt-1">
              En attente de règlement
            </div>
          </div>
        </div>

        {/* Card 4: Low stock alert */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-sm">
          <div className="flex items-center justify-between">
            <span className="text-xs font-semibold uppercase tracking-wider text-slate-500">
              Alertes Stocks
            </span>
            <div className="w-8 h-8 rounded-lg bg-rose-50 text-rose-600 flex items-center justify-center">
              <AlertTriangle className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-3">
            <div className="text-2xl font-bold text-slate-900">
              {statsLoading ? '...' : `${stats?.low_stock_count || 0} article(s)`}
            </div>
            <div className="text-xs text-rose-600 font-medium mt-1">
              Stock inférieur au seuil minimal
            </div>
          </div>
        </div>
      </div>

      {/* Chart & Recent Activity section */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        {/* Sales Chart (2 cols) */}
        <div className="lg:col-span-2 bg-white p-6 rounded-2xl border border-slate-200/80 shadow-sm">
          <div className="flex items-center justify-between mb-6">
            <div>
              <h3 className="text-base font-bold text-slate-900">
                Aperçu des Dernières Ventes
              </h3>
              <p className="text-xs text-slate-500 mt-0.5">
                Montant par ticket émis récemment
              </p>
            </div>
          </div>

          <div className="h-64 w-full">
            {chartData.length > 0 ? (
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={chartData} margin={{ top: 10, right: 10, left: 0, bottom: 0 }}>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
                  <XAxis
                    dataKey="ticket"
                    stroke="#94a3b8"
                    fontSize={11}
                    tickLine={false}
                    axisLine={{ stroke: '#e2e8f0' }}
                  />
                  <YAxis
                    stroke="#94a3b8"
                    fontSize={11}
                    tickLine={false}
                    axisLine={{ stroke: '#e2e8f0' }}
                    tickFormatter={(val) => `${val} F`}
                  />
                  <Tooltip
                    formatter={(val: any) => [formatFCFA(Number(val)), 'Montant']}
                    labelFormatter={(label) => `Ticket #${label}`}
                    contentStyle={{
                      backgroundColor: '#1e293b',
                      borderRadius: '8px',
                      color: '#fff',
                      fontSize: '12px',
                      border: 'none',
                    }}
                  />
                  <Bar dataKey="montant" fill="#4f46e5" radius={[6, 6, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            ) : (
              <div className="h-full flex items-center justify-center text-sm text-slate-400">
                Aucune vente récente enregistrée.
              </div>
            )}
          </div>
        </div>

        {/* Financial Recap / Quick stats (1 col) */}
        <div className="bg-white p-6 rounded-2xl border border-slate-200/80 shadow-sm flex flex-col justify-between">
          <div>
            <h3 className="text-base font-bold text-slate-900 mb-1">
              Bilan Trésorerie Rapide
            </h3>
            <p className="text-xs text-slate-500 mb-6">
              Rapprochement caisse et sorties
            </p>

            <div className="space-y-4">
              <div className="flex items-center justify-between p-3.5 bg-slate-50 rounded-xl">
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-lg bg-indigo-100 text-indigo-700 flex items-center justify-center">
                    <Receipt className="w-4 h-4" />
                  </div>
                  <div>
                    <div className="text-xs font-semibold text-slate-700">Recettes Ventes</div>
                    <div className="text-[11px] text-slate-500">Encaissées</div>
                  </div>
                </div>
                <div className="text-sm font-bold text-slate-900">
                  {formatFCFA(stats?.total_sales_amount || 0)}
                </div>
              </div>

              <div className="flex items-center justify-between p-3.5 bg-slate-50 rounded-xl">
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 rounded-lg bg-rose-100 text-rose-700 flex items-center justify-center">
                    <Wallet className="w-4 h-4" />
                  </div>
                  <div>
                    <div className="text-xs font-semibold text-slate-700">Dépenses Exploitation</div>
                    <div className="text-[11px] text-slate-500">Décaissements</div>
                  </div>
                </div>
                <div className="text-sm font-bold text-rose-600">
                  - {formatFCFA(stats?.total_expenses || 0)}
                </div>
              </div>

              <div className="pt-2 border-t border-slate-100 flex items-center justify-between">
                <span className="text-xs font-bold text-slate-600 uppercase">Solde Net Théorique</span>
                <span className="text-base font-extrabold text-emerald-600">
                  {formatFCFA((stats?.total_sales_amount || 0) - (stats?.total_expenses || 0))}
                </span>
              </div>
            </div>
          </div>

          <div className="mt-6 pt-4 border-t border-slate-100 text-xs text-slate-400">
            Ce solde n'inclut pas les créances clients non encore perçues.
          </div>
        </div>
      </div>

      {/* Recent Sales Table */}
      <div className="bg-white rounded-2xl border border-slate-200/80 shadow-sm overflow-hidden">
        <div className="px-6 py-4 border-b border-slate-200/80 flex items-center justify-between">
          <h3 className="text-base font-bold text-slate-900">
            Dernières Ventes Encaissées
          </h3>
          <span className="text-xs text-slate-500">Flux en direct des caisses</span>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm text-slate-600">
            <thead className="bg-slate-50 text-[11px] font-semibold text-slate-500 uppercase tracking-wider border-b border-slate-200/80">
              <tr>
                <th className="px-6 py-3">Numéro Ticket</th>
                <th className="px-6 py-3">Client</th>
                <th className="px-6 py-3">Mode Paiement</th>
                <th className="px-6 py-3">Date & Heure</th>
                <th className="px-6 py-3 text-right">Montant Total</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {ventesLoading ? (
                <tr>
                  <td colSpan={5} className="px-6 py-8 text-center text-slate-400">
                    Chargement des ventes...
                  </td>
                </tr>
              ) : recentVentes && recentVentes.length > 0 ? (
                recentVentes.map((vente) => (
                  <tr key={vente.sync_id} className="hover:bg-slate-50/70 transition">
                    <td className="px-6 py-3.5 font-medium text-slate-900 font-mono text-xs">
                      {vente.ticket_number}
                    </td>
                    <td className="px-6 py-3.5">
                      {vente.client_name || 'Occasionnel'}
                    </td>
                    <td className="px-6 py-3.5">
                      <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-slate-100 text-slate-700">
                        {vente.payment_method}
                      </span>
                    </td>
                    <td className="px-6 py-3.5 text-xs text-slate-500">
                      {formatDateTime(vente.created_at)}
                    </td>
                    <td className="px-6 py-3.5 text-right font-bold text-slate-900">
                      {formatFCFA(vente.total_amount)}
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={5} className="px-6 py-8 text-center text-slate-400">
                    Aucune vente pour le moment.
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
