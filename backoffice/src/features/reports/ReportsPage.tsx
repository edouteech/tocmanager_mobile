import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  TrendingUp,
  TrendingDown,
  DollarSign,
  Download,
  Layers,
  Award,
  PieChart as PieChartIcon,
  Percent,
} from 'lucide-react';
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
import { reportsApi } from '../../lib/api';
import { formatFCFA } from '../../lib/formatters';
import { useDensity } from '../../context/DensityContext';
import { useTheme } from '../../context/ThemeContext';

export const ReportsPage: React.FC = () => {
  const { tableClasses } = useDensity();
  const { theme } = useTheme();
  const [periodDays, setPeriodDays] = useState<number>(30);

  // Compute start/end dates
  const endDate = new Date().toISOString();
  const startDate = new Date(Date.now() - periodDays * 24 * 60 * 60 * 1000).toISOString();

  const { data: report, isLoading } = useQuery({
    queryKey: ['financial-report', periodDays],
    queryFn: () => reportsApi.getFinancial({ start_date: startDate, end_date: endDate }),
  });

  const exportCSV = () => {
    if (!report) return;
    const { kpis, top_products, expenses_by_category } = report;

    let csvContent = 'data:text/csv;charset=utf-8,';
    csvContent += 'COMPTE DE RESULTAT ET RENTABILITE TOCMANAGER\n';
    csvContent += `Periode : Derniers ${periodDays} jours\n\n`;

    csvContent += 'INDICATEUR FINANCIER,MONTANT (FCFA),POURCENTAGE\n';
    csvContent += `Chiffre d'Affaires Brut,${kpis.gross_sales},100%\n`;
    csvContent += `Remises commerciales accordees,-${kpis.discount_amount},-\n`;
    csvContent += `Chiffre d'Affaires Net,${kpis.net_sales},100%\n`;
    csvContent += `Cout des marchandises vendues (COGS),-${kpis.cogs},${Math.round((kpis.cogs / (kpis.net_sales || 1)) * 100)}%\n`;
    csvContent += `Marge Brute Commerciale,${kpis.gross_margin},${kpis.gross_margin_rate}%\n`;
    csvContent += `Total Charges et Decaissements,-${kpis.total_expenses},${Math.round((kpis.total_expenses / (kpis.net_sales || 1)) * 100)}%\n`;
    csvContent += `Resultat Net d'Exploitation,${kpis.net_profit},${kpis.net_margin_rate}%\n\n`;

    csvContent += 'TOP PRODUITS PAR CHIFFRE D AFFAIRES\n';
    csvContent += 'Article,Quantite Vendue,Chiffre d Affaires,Marge Beneficiaire\n';
    top_products.forEach((p) => {
      csvContent += `"${p.product_name}",${p.quantity_sold},${p.total_revenue},${p.total_profit}\n`;
    });

    csvContent += '\nVENTILATION DES DEPENSES PAR CATEGORIE\n';
    csvContent += 'Categorie,Montant (FCFA),Part (%)\n';
    expenses_by_category.forEach((e) => {
      csvContent += `"${e.category}",${e.total_amount},${e.percentage}%\n`;
    });

    const encodedUri = encodeURI(csvContent);
    const link = document.createElement('a');
    link.setAttribute('href', encodedUri);
    link.setAttribute('download', `Rapport_Financier_TocManager_${new Date().toISOString().slice(0, 10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  if (isLoading || !report) {
    return (
      <div className="card-toc p-12 text-center text-slate-400 text-sm">
        Génération du rapport financier et des calculs de rentabilité...
      </div>
    );
  }

  const { kpis, top_products, expenses_by_category, monthly_trend } = report;

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-stretch sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">Rapports & Analytique</h1>
          <p className="text-xs sm:text-sm text-[#5A7184] dark:text-slate-400 mt-1">
            Compte de résultat analytique, marge commerciale et rentabilité
          </p>
        </div>
        <div className="flex flex-wrap items-center gap-2.5 sm:gap-3">
          <div className="flex items-center bg-white dark:bg-dark-800 border border-[#E8EFF5] dark:border-dark-600 rounded-xl p-1 text-xs font-semibold text-slate-600 dark:text-slate-300 shadow-soft">
            <button
              onClick={() => setPeriodDays(7)}
              className={`px-3 py-1.5 rounded-lg transition ${
                periodDays === 7 ? 'bg-brand-500 text-white font-bold' : 'hover:bg-slate-100 dark:hover:bg-dark-700'
              }`}
            >
              7 jours
            </button>
            <button
              onClick={() => setPeriodDays(30)}
              className={`px-3 py-1.5 rounded-lg transition ${
                periodDays === 30 ? 'bg-brand-500 text-white font-bold' : 'hover:bg-slate-100 dark:hover:bg-dark-700'
              }`}
            >
              30 jours
            </button>
            <button
              onClick={() => setPeriodDays(90)}
              className={`px-3 py-1.5 rounded-lg transition ${
                periodDays === 90 ? 'bg-brand-500 text-white font-bold' : 'hover:bg-slate-100 dark:hover:bg-dark-700'
              }`}
            >
              90 jours
            </button>
          </div>
          <button
            onClick={exportCSV}
            className="btn-secondary"
          >
            <Download className="w-4 h-4 text-brand-500" />
            <span>Export CSV</span>
          </button>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
        {/* Chiffre d'affaires Net */}
        <div className="card-toc card-hover p-5">
          <div className="flex items-center justify-between">
            <p className="text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Chiffre d'Affaires Net</p>
            <div className="w-8 h-8 rounded-xl bg-brand-50 dark:bg-brand-500/15 text-brand-600 dark:text-brand-400 flex items-center justify-center border border-brand-200 dark:border-brand-500/30">
              <DollarSign className="w-4 h-4" />
            </div>
          </div>
          <p className="text-2xl font-extrabold text-slate-900 dark:text-white mt-2">{formatFCFA(kpis.net_sales)}</p>
          <p className="text-xs text-slate-400 dark:text-slate-500 mt-2">Total des ventes enregistrées</p>
        </div>

        {/* Coût des Marchandises (COGS) */}
        <div className="card-toc card-hover p-5">
          <div className="flex items-center justify-between">
            <p className="text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Coût des Ventes (COGS)</p>
            <div className="w-8 h-8 rounded-xl bg-slate-100 dark:bg-dark-700 text-slate-600 dark:text-slate-300 flex items-center justify-center border border-slate-200 dark:border-dark-600">
              <Layers className="w-4 h-4" />
            </div>
          </div>
          <p className="text-2xl font-extrabold text-slate-700 dark:text-slate-200 mt-2">{formatFCFA(kpis.cogs)}</p>
          <p className="text-xs text-slate-400 dark:text-slate-500 mt-2">Prix d'achat des articles vendus</p>
        </div>

        {/* Marge Brute */}
        <div className="card-toc card-hover p-5">
          <div className="flex items-center justify-between">
            <p className="text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Marge Brute</p>
            <div className="w-8 h-8 rounded-xl bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 flex items-center justify-center border border-emerald-100 dark:border-emerald-800/40">
              <Percent className="w-4 h-4" />
            </div>
          </div>
          <p className="text-2xl font-extrabold text-emerald-600 dark:text-emerald-400 mt-2">{formatFCFA(kpis.gross_margin)}</p>
          <p className="text-xs text-emerald-700 dark:text-emerald-300 font-semibold mt-2">
            Taux de marge brute : {kpis.gross_margin_rate}%
          </p>
        </div>

        {/* Résultat Net */}
        <div className="card-toc card-hover p-5">
          <div className="flex items-center justify-between">
            <p className="text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Résultat Net</p>
            <div
              className={`w-8 h-8 rounded-xl flex items-center justify-center border ${
                kpis.net_profit >= 0
                  ? 'bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 border-emerald-100 dark:border-emerald-800/40'
                  : 'bg-rose-50 dark:bg-rose-950/40 text-rose-600 dark:text-rose-400 border-rose-100 dark:border-rose-800/40'
              }`}
            >
              {kpis.net_profit >= 0 ? <TrendingUp className="w-4 h-4" /> : <TrendingDown className="w-4 h-4" />}
            </div>
          </div>
          <p
            className={`text-2xl font-extrabold mt-2 ${
              kpis.net_profit >= 0 ? 'text-emerald-600 dark:text-emerald-400' : 'text-rose-600 dark:text-rose-400'
            }`}
          >
            {formatFCFA(kpis.net_profit)}
          </p>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-2">Après charges ({formatFCFA(kpis.total_expenses)})</p>
        </div>
      </div>

      {/* Financial Statement & Trend Chart */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* Synthetic P&L Table */}
        <div className="lg:col-span-5 card-toc p-6 flex flex-col justify-between">
          <div>
            <h2 className="text-base font-bold text-slate-900 dark:text-white mb-1">Compte de Résultat Synthétique</h2>
            <p className="text-xs text-slate-500 dark:text-slate-400 mb-5">Décomposition de la formation du bénéfice net</p>

            <div className="space-y-3 text-sm">
              <div className="flex justify-between items-center py-1.5 border-b border-[#E8EFF5] dark:border-dark-600">
                <span className="text-slate-600 dark:text-slate-300">Chiffre d'Affaires Brut</span>
                <span className="font-semibold text-slate-900 dark:text-white font-mono">{formatFCFA(kpis.gross_sales)}</span>
              </div>

              {kpis.discount_amount > 0 && (
                <div className="flex justify-between items-center py-1.5 border-b border-[#E8EFF5] dark:border-dark-600 text-rose-600 dark:text-rose-400">
                  <span>- Remises accordées</span>
                  <span className="font-mono">-{formatFCFA(kpis.discount_amount)}</span>
                </div>
              )}

              <div className="flex justify-between items-center py-1.5 border-b border-[#E8EFF5] dark:border-dark-600 font-medium">
                <span className="text-slate-900 dark:text-white font-bold">= Chiffre d'Affaires Net</span>
                <span className="font-extrabold text-slate-900 dark:text-white font-mono">{formatFCFA(kpis.net_sales)}</span>
              </div>

              <div className="flex justify-between items-center py-1.5 border-b border-[#E8EFF5] dark:border-dark-600 text-slate-600 dark:text-slate-400">
                <span>- Coût Marchandises Vendues (COGS)</span>
                <span className="text-rose-600 dark:text-rose-400 font-mono">-{formatFCFA(kpis.cogs)}</span>
              </div>

              <div className="flex justify-between items-center py-2.5 bg-brand-50/60 dark:bg-brand-500/15 px-3.5 rounded-xl text-brand-800 dark:text-brand-300 font-bold border border-brand-100 dark:border-brand-500/30">
                <span>= Marge Brute Commerciale</span>
                <span className="font-mono">{formatFCFA(kpis.gross_margin)}</span>
              </div>

              <div className="flex justify-between items-center py-1.5 border-b border-[#E8EFF5] dark:border-dark-600 text-slate-600 dark:text-slate-400">
                <span>- Charges d'Exploitation (Dépenses)</span>
                <span className="text-rose-600 dark:text-rose-400 font-mono">-{formatFCFA(kpis.total_expenses)}</span>
              </div>

              <div
                className={`flex justify-between items-center py-3 px-3.5 rounded-xl font-extrabold text-base ${
                  kpis.net_profit >= 0 ? 'bg-emerald-600 text-white shadow-sm' : 'bg-rose-600 text-white shadow-sm'
                }`}
              >
                <span>= Bénéfice Net d'Exploitation</span>
                <span className="font-mono">{formatFCFA(kpis.net_profit)}</span>
              </div>
            </div>
          </div>

          <div className="mt-6 pt-4 border-t border-[#E8EFF5] dark:border-dark-600 flex items-center justify-between text-xs text-slate-500 dark:text-slate-400">
            <span>Taux de Marge Nette :</span>
            <span className="font-bold text-slate-900 dark:text-white">{kpis.net_margin_rate}%</span>
          </div>
        </div>

        {/* Monthly Trend Chart */}
        <div className="lg:col-span-7 card-toc p-6">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h2 className="text-base font-bold text-slate-900 dark:text-white">Évolution Temporelle (6 derniers mois)</h2>
              <p className="text-xs text-slate-500 dark:text-slate-400">Comparatif Chiffre d'Affaires vs Dépenses</p>
            </div>
          </div>

          <div className="h-72 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={monthly_trend} margin={{ top: 10, right: 10, left: -10, bottom: 0 }}>
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

      {/* Top Products & Expense Breakdown */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Top Products */}
        <div className="card-toc p-6">
          <div className="flex items-center gap-2 mb-4">
            <Award className="w-5 h-5 text-amber-500" />
            <h2 className="text-base font-bold text-slate-900 dark:text-white">Top 10 Produits par Rentabilité</h2>
          </div>

          {top_products.length === 0 ? (
            <p className="text-xs text-slate-400 py-6 text-center">Aucune vente enregistrée sur cette période.</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-[#F5FAFD] dark:bg-dark-700/50 text-slate-500 dark:text-slate-400 uppercase font-semibold border-b border-[#E8EFF5] dark:border-dark-600">
                  <tr>
                    <th className={tableClasses.th}>Article</th>
                    <th className={`${tableClasses.th} text-center`}>Qté</th>
                    <th className={`${tableClasses.th} text-right`}>C.A.</th>
                    <th className={`${tableClasses.th} text-right`}>Profit</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#E8EFF5] dark:divide-dark-600/60">
                  {top_products.map((p, idx) => (
                    <tr key={idx} className="hover:bg-brand-50/20 dark:hover:bg-dark-700/40">
                      <td className={`${tableClasses.td} font-medium text-slate-900 dark:text-white`}>{p.product_name}</td>
                      <td className={`${tableClasses.td} text-center text-slate-600 dark:text-slate-300 font-mono`}>{p.quantity_sold}</td>
                      <td className={`${tableClasses.td} text-right font-mono font-medium text-slate-900 dark:text-white`}>
                        {formatFCFA(p.total_revenue)}
                      </td>
                      <td className={`${tableClasses.td} text-right font-mono font-bold text-emerald-600 dark:text-emerald-400`}>
                        +{formatFCFA(p.total_profit)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>

        {/* Expenses by Category */}
        <div className="card-toc p-6">
          <div className="flex items-center gap-2 mb-4">
            <PieChartIcon className="w-5 h-5 text-brand-500" />
            <h2 className="text-base font-bold text-slate-900 dark:text-white">Répartition des Dépenses par Catégorie</h2>
          </div>

          {expenses_by_category.length === 0 ? (
            <p className="text-xs text-slate-400 py-6 text-center">Aucune dépense sur cette période.</p>
          ) : (
            <div className="space-y-4">
              {expenses_by_category.map((e, idx) => (
                <div key={idx}>
                  <div className="flex justify-between items-center text-xs font-semibold mb-1.5">
                    <span className="text-slate-700 dark:text-slate-200">{e.category}</span>
                    <span className="font-bold text-slate-900 dark:text-white font-mono">
                      {formatFCFA(e.total_amount)} ({e.percentage}%)
                    </span>
                  </div>
                  <div className="w-full bg-slate-100 dark:bg-dark-700 h-2.5 rounded-full overflow-hidden">
                    <div
                      className="bg-brand-500 h-full rounded-full transition-all duration-300"
                      style={{ width: `${Math.min(100, e.percentage)}%` }}
                    />
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
