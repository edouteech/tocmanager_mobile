import React from 'react';
import { TrendingUp, TrendingDown, PieChart as PieChartIcon, Wallet } from 'lucide-react';
import { FinancialKPIs } from '../../types';
import { formatFCFA } from '../../lib/formatters';

interface ReportKpiGridProps {
  kpis: FinancialKPIs;
}

export const ReportKpiGrid: React.FC<ReportKpiGridProps> = ({ kpis }) => {
  const netCashflow = kpis.net_cashflow ?? kpis.net_sales - kpis.total_expenses;

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-5">
      <div className="card-toc p-4 sm:p-5 flex flex-col justify-between hover:border-emerald-300 dark:hover:border-emerald-500/40 transition-all">
        <div className="flex items-center justify-between">
          <span className="text-[11px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
            Chiffre d'Affaires
          </span>
          <div className="w-10 h-10 rounded-2xl bg-emerald-50 dark:bg-emerald-500/20 text-emerald-600 dark:text-emerald-400 flex items-center justify-center">
            <TrendingUp className="w-5 h-5" />
          </div>
        </div>
        <div className="mt-4">
          <div className="text-2xl font-extrabold text-emerald-600 dark:text-emerald-400 font-mono tracking-tight">
            {formatFCFA(kpis.net_sales)}
          </div>
          <div className="text-xs text-slate-400 mt-1 font-medium">Recettes des ventes</div>
        </div>
      </div>

      <div className="card-toc p-4 sm:p-5 flex flex-col justify-between hover:border-brand-300 dark:hover:border-brand-500/40 transition-all">
        <div className="flex items-center justify-between">
          <span className="text-[11px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
            Marge Brute
          </span>
          <div className="w-10 h-10 rounded-2xl bg-brand-50 dark:bg-brand-500/20 text-brand-600 dark:text-brand-400 flex items-center justify-center">
            <PieChartIcon className="w-5 h-5" />
          </div>
        </div>
        <div className="mt-4">
          <div className="text-2xl font-extrabold text-brand-600 dark:text-brand-400 font-mono tracking-tight">
            {formatFCFA(kpis.gross_margin)}
          </div>
          <div className="text-xs text-brand-600 dark:text-brand-400 mt-1 font-bold">
            {kpis.gross_margin_rate}% du CA
          </div>
        </div>
      </div>

      <div className="card-toc p-4 sm:p-5 flex flex-col justify-between hover:border-rose-300 dark:hover:border-rose-500/40 transition-all">
        <div className="flex items-center justify-between">
          <span className="text-[11px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
            Total Dépenses
          </span>
          <div className="w-10 h-10 rounded-2xl bg-rose-50 dark:bg-rose-500/20 text-rose-600 dark:text-rose-400 flex items-center justify-center">
            <TrendingDown className="w-5 h-5" />
          </div>
        </div>
        <div className="mt-4">
          <div className="text-2xl font-extrabold text-rose-600 dark:text-rose-400 font-mono tracking-tight">
            {formatFCFA(kpis.total_expenses)}
          </div>
          <div className="text-xs text-slate-400 mt-1 font-medium">Décaissements enregistrés</div>
        </div>
      </div>

      <div className="card-toc p-4 sm:p-5 flex flex-col justify-between hover:border-sky-300 dark:hover:border-sky-500/40 transition-all">
        <div className="flex items-center justify-between">
          <span className="text-[11px] font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
            Trésorerie Nette
          </span>
          <div
            className={`w-10 h-10 rounded-2xl flex items-center justify-center ${
              netCashflow >= 0
                ? 'bg-emerald-50 dark:bg-emerald-500/20 text-emerald-600 dark:text-emerald-400'
                : 'bg-rose-50 dark:bg-rose-500/20 text-rose-600 dark:text-rose-400'
            }`}
          >
            <Wallet className="w-5 h-5" />
          </div>
        </div>
        <div className="mt-4">
          <div
            className={`text-2xl font-extrabold font-mono tracking-tight ${
              netCashflow >= 0 ? 'text-emerald-600 dark:text-emerald-400' : 'text-rose-600 dark:text-rose-400'
            }`}
          >
            {formatFCFA(netCashflow)}
          </div>
          <div className="text-xs text-slate-400 mt-1 font-medium">CA − Dépenses</div>
        </div>
      </div>
    </div>
  );
};
