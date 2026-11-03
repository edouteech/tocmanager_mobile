import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  TrendingUp,
  TrendingDown,
  DollarSign,
  Download,
  Calendar,
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

export const ReportsPage: React.FC = () => {
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
      <div className="p-12 text-center text-slate-400 text-sm bg-white rounded-xl border border-slate-200">
        Génération du rapport financier et des calculs de rentabilité...
      </div>
    );
  }

  const { kpis, top_products, expenses_by_category, monthly_trend } = report;

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Rapports & Rentabilité (P&L)</h1>
          <p className="text-sm text-slate-500">
            Compte de résultat analytique, marge brute commerciale et bénéfice net d'exploitation
          </p>
        </div>
        <div className="flex items-center gap-3">
          <div className="flex items-center bg-white border border-slate-200 rounded-lg p-1 text-xs font-semibold text-slate-600 shadow-xs">
            <button
              onClick={() => setPeriodDays(7)}
              className={`px-3 py-1.5 rounded-md transition ${
                periodDays === 7 ? 'bg-indigo-600 text-white' : 'hover:bg-slate-100'
              }`}
            >
              7 jours
            </button>
            <button
              onClick={() => setPeriodDays(30)}
              className={`px-3 py-1.5 rounded-md transition ${
                periodDays === 30 ? 'bg-indigo-600 text-white' : 'hover:bg-slate-100'
              }`}
            >
              30 jours
            </button>
            <button
              onClick={() => setPeriodDays(90)}
              className={`px-3 py-1.5 rounded-md transition ${
                periodDays === 90 ? 'bg-indigo-600 text-white' : 'hover:bg-slate-100'
              }`}
            >
              90 jours
            </button>
          </div>
          <button
            onClick={exportCSV}
            className="inline-flex items-center gap-2 px-3.5 py-2 bg-slate-900 text-white rounded-lg text-sm font-medium hover:bg-slate-800 transition shadow-xs"
          >
            <Download className="w-4 h-4" />
            <span>Export CSV</span>
          </button>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-5">
        {/* Chiffre d'affaires Net */}
        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between">
            <p className="text-xs font-medium text-slate-500 uppercase tracking-wider">Chiffre d'Affaires Net</p>
            <div className="w-8 h-8 rounded-lg bg-indigo-50 text-indigo-600 flex items-center justify-center">
              <DollarSign className="w-4 h-4" />
            </div>
          </div>
          <p className="text-2xl font-bold text-slate-900 mt-2">{formatFCFA(kpis.net_sales)}</p>
          <p className="text-xs text-slate-400 mt-2">Total des ventes enregistrées</p>
        </div>

        {/* Coût des Marchandises (COGS) */}
        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between">
            <p className="text-xs font-medium text-slate-500 uppercase tracking-wider">Coût des Ventes (COGS)</p>
            <div className="w-8 h-8 rounded-lg bg-slate-100 text-slate-600 flex items-center justify-center">
              <Layers className="w-4 h-4" />
            </div>
          </div>
          <p className="text-2xl font-bold text-slate-700 mt-2">{formatFCFA(kpis.cogs)}</p>
          <p className="text-xs text-slate-400 mt-2">Prix d'achat des articles vendus</p>
        </div>

        {/* Marge Brute */}
        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between">
            <p className="text-xs font-medium text-slate-500 uppercase tracking-wider">Marge Brute</p>
            <div className="w-8 h-8 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center">
              <Percent className="w-4 h-4" />
            </div>
          </div>
          <p className="text-2xl font-bold text-emerald-600 mt-2">{formatFCFA(kpis.gross_margin)}</p>
          <p className="text-xs text-emerald-700 font-semibold mt-2">
            Taux de marge brute : {kpis.gross_margin_rate}%
          </p>
        </div>

        {/* Résultat Net */}
        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between">
            <p className="text-xs font-medium text-slate-500 uppercase tracking-wider">Résultat Net</p>
            <div
              className={`w-8 h-8 rounded-lg flex items-center justify-center ${
                kpis.net_profit >= 0 ? 'bg-emerald-50 text-emerald-600' : 'bg-rose-50 text-rose-600'
              }`}
            >
              {kpis.net_profit >= 0 ? <TrendingUp className="w-4 h-4" /> : <TrendingDown className="w-4 h-4" />}
            </div>
          </div>
          <p
            className={`text-2xl font-bold mt-2 ${
              kpis.net_profit >= 0 ? 'text-emerald-600' : 'text-rose-600'
            }`}
          >
            {formatFCFA(kpis.net_profit)}
          </p>
          <p className="text-xs text-slate-500 mt-2">Après déduction des charges ({formatFCFA(kpis.total_expenses)})</p>
        </div>
      </div>

      {/* Financial Statement & Trend Chart */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* Synthetic P&L Table */}
        <div className="lg:col-span-5 bg-white p-6 rounded-xl border border-slate-200 shadow-sm flex flex-col justify-between">
          <div>
            <h2 className="text-base font-bold text-slate-900 mb-1">Compte de Résultat Synthétique</h2>
            <p className="text-xs text-slate-500 mb-5">Décomposition de la formation du bénéfice net</p>

            <div className="space-y-3.5 text-sm">
              <div className="flex justify-between items-center py-1.5 border-b border-slate-100">
                <span className="text-slate-600">Chiffre d'Affaires Brut</span>
                <span className="font-semibold text-slate-900">{formatFCFA(kpis.gross_sales)}</span>
              </div>

              {kpis.discount_amount > 0 && (
                <div className="flex justify-between items-center py-1.5 border-b border-slate-100 text-rose-600">
                  <span>- Remises accordées</span>
                  <span>-{formatFCFA(kpis.discount_amount)}</span>
                </div>
              )}

              <div className="flex justify-between items-center py-1.5 border-b border-slate-100 font-medium">
                <span className="text-slate-900">= Chiffre d'Affaires Net</span>
                <span className="font-bold text-slate-900">{formatFCFA(kpis.net_sales)}</span>
              </div>

              <div className="flex justify-between items-center py-1.5 border-b border-slate-100 text-slate-600">
                <span>- Coût Marchandises Vendues (COGS)</span>
                <span className="text-rose-600 font-mono">-{formatFCFA(kpis.cogs)}</span>
              </div>

              <div className="flex justify-between items-center py-2 bg-emerald-50/60 px-3 rounded-lg text-emerald-800 font-bold">
                <span>= Marge Brute Commerciale</span>
                <span>{formatFCFA(kpis.gross_margin)}</span>
              </div>

              <div className="flex justify-between items-center py-1.5 border-b border-slate-100 text-slate-600">
                <span>- Charges d'Exploitation (Dépenses)</span>
                <span className="text-rose-600 font-mono">-{formatFCFA(kpis.total_expenses)}</span>
              </div>

              <div
                className={`flex justify-between items-center py-3 px-3 rounded-lg font-bold text-base ${
                  kpis.net_profit >= 0 ? 'bg-emerald-600 text-white' : 'bg-rose-600 text-white'
                }`}
              >
                <span>= Bénéfice Net d'Exploitation</span>
                <span>{formatFCFA(kpis.net_profit)}</span>
              </div>
            </div>
          </div>

          <div className="mt-6 pt-4 border-t border-slate-100 flex items-center justify-between text-xs text-slate-500">
            <span>Taux de Marge Nette :</span>
            <span className="font-bold text-slate-900">{kpis.net_margin_rate}%</span>
          </div>
        </div>

        {/* Monthly Trend Chart */}
        <div className="lg:col-span-7 bg-white p-6 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h2 className="text-base font-bold text-slate-900">Évolution Temporelle (6 derniers mois)</h2>
              <p className="text-xs text-slate-500">Comparatif Chiffre d'Affaires vs Dépenses</p>
            </div>
          </div>

          <div className="h-72 w-full">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={monthly_trend} margin={{ top: 10, right: 10, left: -10, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#E2E8F0" />
                <XAxis dataKey="period" stroke="#94A3B8" fontSize={12} tickLine={false} />
                <YAxis stroke="#94A3B8" fontSize={11} tickLine={false} />
                <Tooltip
                  formatter={(val: number) => formatFCFA(val)}
                  contentStyle={{ backgroundColor: '#1E293B', color: '#fff', borderRadius: '8px', border: 'none' }}
                />
                <Legend wrapperStyle={{ fontSize: 12 }} />
                <Bar dataKey="sales" name="Chiffre d'Affaires" fill="#4F46E5" radius={[4, 4, 0, 0]} />
                <Bar dataKey="expenses" name="Dépenses d'Exploitation" fill="#F43F5E" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      {/* Top Products & Expense Breakdown */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Top Products */}
        <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center gap-2 mb-4">
            <Award className="w-5 h-5 text-amber-500" />
            <h2 className="text-base font-bold text-slate-900">Top 10 Produits par Rentabilité</h2>
          </div>

          {top_products.length === 0 ? (
            <p className="text-xs text-slate-400 py-6 text-center">Aucune vente enregistrée sur cette période.</p>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-slate-50 text-slate-500 uppercase font-semibold border-b border-slate-100">
                  <tr>
                    <th className="py-2.5 px-3">Article</th>
                    <th className="py-2.5 px-3 text-center">Qté</th>
                    <th className="py-2.5 px-3 text-right">C.A.</th>
                    <th className="py-2.5 px-3 text-right">Profit</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {top_products.map((p, idx) => (
                    <tr key={idx} className="hover:bg-slate-50/50">
                      <td className="py-2.5 px-3 font-medium text-slate-900">{p.product_name}</td>
                      <td className="py-2.5 px-3 text-center text-slate-600">{p.quantity_sold}</td>
                      <td className="py-2.5 px-3 text-right font-mono font-medium text-slate-900">
                        {formatFCFA(p.total_revenue)}
                      </td>
                      <td className="py-2.5 px-3 text-right font-mono font-bold text-emerald-600">
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
        <div className="bg-white p-6 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center gap-2 mb-4">
            <PieChartIcon className="w-5 h-5 text-indigo-600" />
            <h2 className="text-base font-bold text-slate-900">Répartition des Dépenses par Catégorie</h2>
          </div>

          {expenses_by_category.length === 0 ? (
            <p className="text-xs text-slate-400 py-6 text-center">Aucune dépense sur cette période.</p>
          ) : (
            <div className="space-y-3.5">
              {expenses_by_category.map((e, idx) => (
                <div key={idx}>
                  <div className="flex justify-between items-center text-xs font-medium mb-1">
                    <span className="text-slate-700">{e.category}</span>
                    <span className="font-bold text-slate-900">
                      {formatFCFA(e.total_amount)} ({e.percentage}%)
                    </span>
                  </div>
                  <div className="w-full bg-slate-100 h-2 rounded-full overflow-hidden">
                    <div
                      className="bg-indigo-600 h-full rounded-full transition-all duration-300"
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
