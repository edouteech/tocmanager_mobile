import React from 'react';
import { Award, PieChart as PieChartIcon } from 'lucide-react';
import { ExpenseCategoryItem, TopProductItem } from '../../types';
import { formatFCFA } from '../../lib/formatters';

const CATEGORY_COLORS = ['#29ABE2', '#F39C12', '#E74C3C', '#27AE60', '#9B59B6', '#1ABC9C', '#E67E22'];

interface ReportBreakdownsProps {
  topProducts: TopProductItem[];
  expensesByCategory: ExpenseCategoryItem[];
}

export const ReportBreakdowns: React.FC<ReportBreakdownsProps> = ({
  topProducts,
  expensesByCategory,
}) => (
  <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
    <div className="card-toc p-5 sm:p-6">
      <div className="flex items-center gap-2 mb-4">
        <Award className="w-5 h-5 text-amber-500" />
        <h2 className="text-base font-bold text-slate-900 dark:text-white">
          Top Produits les plus vendus
        </h2>
      </div>

      {topProducts.length === 0 ? (
        <p className="text-xs text-slate-400 py-6 text-center">
          Aucune vente enregistrée sur cette période.
        </p>
      ) : (
        <div className="space-y-3">
          {topProducts.map((p, idx) => (
            <div
              key={idx}
              className="p-3.5 rounded-2xl border border-slate-100 dark:border-dark-600 bg-[#F5FAFD] dark:bg-dark-700/50 flex items-center justify-between gap-3 hover:border-brand-200 transition"
            >
              <div className="flex items-center gap-3 min-w-0">
                <span
                  className={`w-7 h-7 rounded-xl flex items-center justify-center font-bold text-xs shrink-0 ${
                    idx === 0
                      ? 'bg-amber-400 text-white'
                      : idx === 1
                        ? 'bg-slate-300 text-slate-800'
                        : idx === 2
                          ? 'bg-amber-600 text-white'
                          : 'bg-slate-100 dark:bg-dark-600 text-slate-500'
                  }`}
                >
                  {idx + 1}
                </span>
                <div className="min-w-0">
                  <h4 className="font-bold text-sm text-[#1C2B3A] dark:text-white truncate">
                    {p.product_name}
                  </h4>
                  <span className="text-[11px] text-slate-400 font-mono">
                    {p.quantity_sold} unité{p.quantity_sold > 1 ? 's' : ''} vendue
                    {p.quantity_sold > 1 ? 's' : ''}
                  </span>
                </div>
              </div>

              <div className="text-right shrink-0">
                <div className="font-mono text-sm font-extrabold text-slate-900 dark:text-white">
                  {formatFCFA(p.total_revenue)}
                </div>
                <span className="text-[11px] font-bold text-emerald-600 dark:text-emerald-400 font-mono">
                  +{formatFCFA(p.total_profit)}
                </span>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>

    <div className="card-toc p-5 sm:p-6">
      <div className="flex items-center gap-2 mb-4">
        <PieChartIcon className="w-5 h-5 text-brand-500" />
        <h2 className="text-base font-bold text-slate-900 dark:text-white">
          Répartition des Dépenses par Catégorie
        </h2>
      </div>

      {expensesByCategory.length === 0 ? (
        <p className="text-xs text-slate-400 py-6 text-center">
          Aucune dépense enregistrée sur cette période.
        </p>
      ) : (
        <div className="space-y-3.5">
          {expensesByCategory.map((e, idx) => {
            const color = CATEGORY_COLORS[idx % CATEGORY_COLORS.length];
            return (
              <div key={idx} className="space-y-1.5">
                <div className="flex justify-between items-center text-xs font-semibold">
                  <div className="flex items-center gap-2 min-w-0">
                    <span className="w-3 h-3 rounded-full shrink-0" style={{ backgroundColor: color }} />
                    <span className="text-slate-700 dark:text-slate-200 font-bold truncate">
                      {e.category}
                    </span>
                  </div>
                  <div className="text-right shrink-0 font-mono">
                    <span className="text-slate-400 mr-2">{e.percentage}%</span>
                    <span className="font-extrabold text-slate-900 dark:text-white">
                      {formatFCFA(e.total_amount)}
                    </span>
                  </div>
                </div>
                <div className="w-full bg-slate-100 dark:bg-dark-700 h-2.5 rounded-full overflow-hidden">
                  <div
                    className="h-full rounded-full transition-all duration-300"
                    style={{ width: `${Math.min(100, e.percentage)}%`, backgroundColor: color }}
                  />
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  </div>
);
