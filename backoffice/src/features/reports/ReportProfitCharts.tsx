import React from 'react';
import { BarChart2 } from 'lucide-react';
import {
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  Legend,
  CartesianGrid,
} from 'recharts';
import { FinancialKPIs, MonthlyTrendItem } from '../../types';
import { formatFCFA } from '../../lib/formatters';

interface ReportProfitChartsProps {
  kpis: FinancialKPIs;
  monthlyTrend: MonthlyTrendItem[];
  theme: string;
}

export const ReportProfitCharts: React.FC<ReportProfitChartsProps> = ({
  kpis,
  monthlyTrend,
  theme,
}) => {
  const maxComparisonVal =
    Math.max(kpis.net_sales, kpis.total_expenses, Math.max(0, kpis.gross_margin)) || 1;

  return (
    <>
      <div className="card-toc p-5 sm:p-6 space-y-4">
        <div className="flex items-center gap-2">
          <BarChart2 className="w-5 h-5 text-brand-500" />
          <h3 className="text-base font-bold text-[#1C2B3A] dark:text-white">
            Ventes vs Dépenses (Marge)
          </h3>
        </div>

        <div className="space-y-4 pt-1">
          <div>
            <div className="flex justify-between items-center text-xs font-bold mb-1.5">
              <span className="text-slate-700 dark:text-slate-300">CA (Ventes)</span>
              <span className="text-emerald-600 dark:text-emerald-400 font-mono text-sm font-extrabold">
                {formatFCFA(kpis.net_sales)}
              </span>
            </div>
            <div className="w-full bg-slate-100 dark:bg-dark-700 h-3 rounded-full overflow-hidden">
              <div
                className="bg-emerald-500 h-full rounded-full transition-all duration-500"
                style={{ width: `${Math.min(100, (kpis.net_sales / maxComparisonVal) * 100)}%` }}
              />
            </div>
          </div>

          <div>
            <div className="flex justify-between items-center text-xs font-bold mb-1.5">
              <span className="text-slate-700 dark:text-slate-300">Dépenses</span>
              <span className="text-rose-600 dark:text-rose-400 font-mono text-sm font-extrabold">
                {formatFCFA(kpis.total_expenses)}
              </span>
            </div>
            <div className="w-full bg-slate-100 dark:bg-dark-700 h-3 rounded-full overflow-hidden">
              <div
                className="bg-rose-500 h-full rounded-full transition-all duration-500"
                style={{ width: `${Math.min(100, (kpis.total_expenses / maxComparisonVal) * 100)}%` }}
              />
            </div>
          </div>

          <div>
            <div className="flex justify-between items-center text-xs font-bold mb-1.5">
              <span className="text-slate-700 dark:text-slate-300">Marge Brute</span>
              <span className="text-brand-600 dark:text-brand-400 font-mono text-sm font-extrabold">
                {formatFCFA(kpis.gross_margin > 0 ? kpis.gross_margin : 0)}
              </span>
            </div>
            <div className="w-full bg-slate-100 dark:bg-dark-700 h-3 rounded-full overflow-hidden">
              <div
                className="bg-brand-500 h-full rounded-full transition-all duration-500"
                style={{
                  width: `${Math.min(100, (Math.max(0, kpis.gross_margin) / maxComparisonVal) * 100)}%`,
                }}
              />
            </div>
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        <div className="lg:col-span-5 card-toc p-5 sm:p-6 flex flex-col justify-between">
          <div>
            <h2 className="text-base font-bold text-slate-900 dark:text-white mb-1">
              Compte de Résultat Synthétique
            </h2>
            <p className="text-xs text-slate-500 dark:text-slate-400 mb-5">
              Décomposition analytique de la rentabilité
            </p>

            <div className="space-y-3 text-sm">
              <div className="flex justify-between items-center py-1.5 border-b border-[#E8EFF5] dark:border-dark-600">
                <span className="text-slate-600 dark:text-slate-300">Chiffre d'Affaires Brut</span>
                <span className="font-semibold text-slate-900 dark:text-white font-mono">
                  {formatFCFA(kpis.gross_sales)}
                </span>
              </div>

              {kpis.discount_amount > 0 && (
                <div className="flex justify-between items-center py-1.5 border-b border-[#E8EFF5] dark:border-dark-600 text-rose-600 dark:text-rose-400">
                  <span>− Remises accordées</span>
                  <span className="font-mono">−{formatFCFA(kpis.discount_amount)}</span>
                </div>
              )}

              <div className="flex justify-between items-center py-1.5 border-b border-[#E8EFF5] dark:border-dark-600 font-medium">
                <span className="text-slate-900 dark:text-white font-bold">= Chiffre d'Affaires Net</span>
                <span className="font-extrabold text-slate-900 dark:text-white font-mono">
                  {formatFCFA(kpis.net_sales)}
                </span>
              </div>

              <div className="flex justify-between items-center py-1.5 border-b border-[#E8EFF5] dark:border-dark-600 text-slate-600 dark:text-slate-400">
                <span>− Coût Marchandises (COGS)</span>
                <span className="text-rose-600 dark:text-rose-400 font-mono">−{formatFCFA(kpis.cogs)}</span>
              </div>

              <div className="flex justify-between items-center py-2.5 bg-brand-50/60 dark:bg-brand-500/15 px-3.5 rounded-xl text-brand-800 dark:text-brand-300 font-bold border border-brand-100 dark:border-brand-500/30">
                <span>= Marge Brute Commerciale</span>
                <span className="font-mono">{formatFCFA(kpis.gross_margin)}</span>
              </div>

              <div className="flex justify-between items-center py-1.5 border-b border-[#E8EFF5] dark:border-dark-600 text-slate-600 dark:text-slate-400">
                <span>− Charges d'Exploitation (Dépenses)</span>
                <span className="text-rose-600 dark:text-rose-400 font-mono">
                  −{formatFCFA(kpis.total_expenses)}
                </span>
              </div>

              <div
                className={`flex justify-between items-center py-3 px-3.5 rounded-2xl font-extrabold text-base ${
                  kpis.net_profit >= 0 ? 'bg-emerald-600 text-white shadow-sm' : 'bg-rose-600 text-white shadow-sm'
                }`}
              >
                <span>= Résultat Net d'Exploitation</span>
                <span className="font-mono">{formatFCFA(kpis.net_profit)}</span>
              </div>
            </div>
          </div>

          <div className="mt-6 pt-4 border-t border-[#E8EFF5] dark:border-dark-600 flex items-center justify-between text-xs text-slate-500 dark:text-slate-400">
            <span>Taux de Marge Nette :</span>
            <span className="font-bold text-slate-900 dark:text-white font-mono">
              {kpis.net_margin_rate}%
            </span>
          </div>
        </div>

        <div className="lg:col-span-7 card-toc p-5 sm:p-6">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h2 className="text-base font-bold text-slate-900 dark:text-white">
                Évolution Historique (6 derniers mois)
              </h2>
              <p className="text-xs text-slate-500 dark:text-slate-400">
                Comparatif mensuel Chiffre d'Affaires vs Dépenses
              </p>
            </div>
          </div>

          <div className="h-72 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={monthlyTrend} margin={{ top: 10, right: 10, left: -10, bottom: 0 }}>
                <CartesianGrid
                  strokeDasharray="3 3"
                  vertical={false}
                  stroke={theme === 'dark' ? '#26384C' : '#E8EFF5'}
                />
                <XAxis
                  dataKey="period"
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
                <Legend wrapperStyle={{ fontSize: 12, paddingTop: '10px' }} />
                <Bar dataKey="sales" name="Chiffre d'Affaires" fill="#29ABE2" radius={[4, 4, 0, 0]} />
                <Bar dataKey="expenses" name="Dépenses d'Exploitation" fill="#E74C3C" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>
    </>
  );
};
