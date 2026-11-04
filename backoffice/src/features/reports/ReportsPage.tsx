import React, { useState, useMemo } from 'react';
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
  FileSpreadsheet,
  Printer,
  Wallet,
  Calendar,
  BarChart2,
  Package,
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
import { exportToExcel } from '../../lib/exportUtils';
import { Modal } from '../../components/common/Modal';

export const ReportsPage: React.FC = () => {
  const { tableClasses } = useDensity();
  const { theme } = useTheme();

  // Period Preset State (default: 'thisMonth' matching mobile)
  const [periodPreset, setPeriodPreset] = useState<string>('thisMonth');
  const [customStart, setCustomStart] = useState<string>('');
  const [customEnd, setCustomEnd] = useState<string>('');
  const [isCustomModalOpen, setIsCustomModalOpen] = useState(false);

  // Compute active params
  const queryParams = useMemo(() => {
    if (periodPreset === 'customRange' && customStart && customEnd) {
      return {
        start_date: new Date(customStart).toISOString(),
        end_date: new Date(`${customEnd}T23:59:59.999Z`).toISOString(),
      };
    }
    return { preset: periodPreset };
  }, [periodPreset, customStart, customEnd]);

  const { data: report, isLoading } = useQuery({
    queryKey: ['financial-report', queryParams],
    queryFn: () => reportsApi.getFinancial(queryParams),
  });

  const periodOptions = [
    { id: 'today', label: "Aujourd'hui" },
    { id: 'thisWeek', label: 'Cette semaine' },
    { id: 'thisMonth', label: 'Ce mois-ci' },
    { id: 'thisYear', label: 'Cette année' },
    { id: 'all', label: "Tout l'historique" },
  ];

  const exportCSV = () => {
    if (!report) return;
    const { kpis, top_products, expenses_by_category } = report;

    let csvContent = 'data:text/csv;charset=utf-8,';
    csvContent += 'COMPTE DE RESULTAT ET RENTABILITE TOCMANAGER\n';
    csvContent += `Periode : ${periodPreset}\n\n`;

    csvContent += 'INDICATEUR FINANCIER,MONTANT (FCFA),POURCENTAGE\n';
    csvContent += `Chiffre d'Affaires Brut,${kpis.gross_sales},100%\n`;
    csvContent += `Remises commerciales accordees,-${kpis.discount_amount},-\n`;
    csvContent += `Chiffre d'Affaires Net,${kpis.net_sales},100%\n`;
    csvContent += `Cout des marchandises vendues (COGS),-${kpis.cogs},${Math.round((kpis.cogs / (kpis.net_sales || 1)) * 100)}%\n`;
    csvContent += `Marge Brute Commerciale,${kpis.gross_margin},${kpis.gross_margin_rate}%\n`;
    csvContent += `Total Charges et Decaissements,-${kpis.total_expenses},${Math.round((kpis.total_expenses / (kpis.net_sales || 1)) * 100)}%\n`;
    csvContent += `Tresorerie Nette (CA - Depenses),${kpis.net_cashflow ?? (kpis.net_sales - kpis.total_expenses)},-\n`;
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

  const exportExcel = () => {
    if (!report) return;
    const { kpis } = report;

    const kpiData = [
      { 'Indicateur Financier': "Chiffre d'Affaires Brut", 'Montant (FCFA)': kpis.gross_sales, 'Part / Marge': '100%' },
      { 'Indicateur Financier': 'Remises Commerciales', 'Montant (FCFA)': -kpis.discount_amount, 'Part / Marge': '-' },
      { 'Indicateur Financier': "Chiffre d'Affaires Net", 'Montant (FCFA)': kpis.net_sales, 'Part / Marge': '100%' },
      { 'Indicateur Financier': 'Coût des Marchandises Vendues (COGS)', 'Montant (FCFA)': -kpis.cogs, 'Part / Marge': `${Math.round((kpis.cogs / (kpis.net_sales || 1)) * 100)}%` },
      { 'Indicateur Financier': 'Marge Brute Commerciale', 'Montant (FCFA)': kpis.gross_margin, 'Part / Marge': `${kpis.gross_margin_rate}%` },
      { 'Indicateur Financier': 'Total Charges & Dépenses', 'Montant (FCFA)': -kpis.total_expenses, 'Part / Marge': `${Math.round((kpis.total_expenses / (kpis.net_sales || 1)) * 100)}%` },
      { 'Indicateur Financier': 'Trésorerie Nette (CA - Dépenses)', 'Montant (FCFA)': kpis.net_cashflow ?? (kpis.net_sales - kpis.total_expenses), 'Part / Marge': '-' },
      { 'Indicateur Financier': "Résultat Net d'Exploitation", 'Montant (FCFA)': kpis.net_profit, 'Part / Marge': `${kpis.net_margin_rate}%` },
    ];

    exportToExcel(kpiData, `Rapport_Financier_P&L_${new Date().toISOString().slice(0, 10)}.xlsx`, 'Compte de Résultat');
  };

  if (isLoading || !report) {
    return (
      <div className="card-toc p-12 text-center text-slate-400 text-sm">
        <div className="inline-block animate-spin rounded-full h-8 w-8 border-4 border-brand-500 border-t-transparent mb-3" />
        <p>Génération du rapport financier et des indicateurs de rentabilité...</p>
      </div>
    );
  }

  const { kpis, top_products, expenses_by_category, monthly_trend } = report;
  const netCashflow = kpis.net_cashflow ?? (kpis.net_sales - kpis.total_expenses);

  // Maximum value for horizontal bar comparison
  const maxComparisonVal = Math.max(kpis.net_sales, kpis.total_expenses, Math.max(0, kpis.gross_margin)) || 1;

  const categoryColors = [
    '#29ABE2', // brand blue
    '#F39C12', // warning orange
    '#E74C3C', // danger red
    '#27AE60', // success green
    '#9B59B6', // purple
    '#1ABC9C', // teal
    '#E67E22', // deep orange
  ];

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Header */}
      <div className="flex flex-col sm:flex-row justify-between items-stretch sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">
            Analytique & Rapports
          </h1>
          <p className="text-xs sm:text-sm text-[#5A7184] dark:text-slate-400 mt-0.5">
            Indicateurs financiers, rentabilité, marges et compte de résultat
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-2">
          <button
            onClick={exportExcel}
            className="btn-toc btn-outline flex items-center gap-1.5 py-2 px-3 text-xs font-bold"
            title="Exporter le rapport en fichier Excel (.xlsx)"
          >
            <FileSpreadsheet className="w-4 h-4 text-emerald-600" />
            <span className="hidden sm:inline">Excel</span>
          </button>
          <button
            onClick={exportCSV}
            className="btn-toc btn-outline flex items-center gap-1.5 py-2 px-3 text-xs font-bold"
            title="Exporter en CSV"
          >
            <Download className="w-4 h-4 text-brand-500" />
            <span className="hidden sm:inline">CSV</span>
          </button>
          <button
            onClick={() => window.print()}
            className="btn-toc btn-outline flex items-center gap-1.5 py-2 px-3 text-xs font-bold"
            title="Imprimer ou enregistrer en PDF"
          >
            <Printer className="w-4 h-4 text-slate-500" />
            <span className="hidden sm:inline">Imprimer / PDF</span>
          </button>
        </div>
      </div>

      {/* Period Filter Chips (Exact match with mobile reports_screen) */}
      <div className="card-toc p-3.5 flex items-center gap-2 overflow-x-auto no-scrollbar">
        {periodOptions.map((opt) => {
          const isSelected = periodPreset === opt.id;
          return (
            <button
              key={opt.id}
              type="button"
              onClick={() => setPeriodPreset(opt.id)}
              className={`px-3.5 py-1.5 rounded-xl text-xs font-bold whitespace-nowrap transition-all shrink-0 ${
                isSelected
                  ? 'bg-brand-600 text-white shadow-xs'
                  : 'bg-white dark:bg-dark-800 text-slate-600 dark:text-slate-300 border border-slate-200 dark:border-dark-600 hover:bg-slate-50 dark:hover:bg-dark-700'
              }`}
            >
              {opt.label}
            </button>
          );
        })}

        <button
          type="button"
          onClick={() => setIsCustomModalOpen(true)}
          className={`px-3.5 py-1.5 rounded-xl text-xs font-bold whitespace-nowrap transition-all flex items-center gap-1.5 shrink-0 ${
            periodPreset === 'customRange'
              ? 'bg-brand-600 text-white shadow-xs'
              : 'bg-brand-50 dark:bg-brand-500/15 text-brand-600 dark:text-brand-400 border border-brand-200 dark:border-brand-500/30 hover:bg-brand-100'
          }`}
        >
          <Calendar className="w-3.5 h-3.5" />
          <span>
            {periodPreset === 'customRange' && customStart && customEnd
              ? `${customStart} au ${customEnd}`
              : 'Période personnalisée...'}
          </span>
        </button>
      </div>

      {/* 4 Main KPI Cards (Exact replica of mobile _buildKpiGrid) */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 sm:gap-5">
        {/* KPI 1: Chiffre d'Affaires */}
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
            <div className="text-xs text-slate-400 mt-1 font-medium">
              Recettes des ventes
            </div>
          </div>
        </div>

        {/* KPI 2: Marge Brute */}
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

        {/* KPI 3: Total Dépenses */}
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
            <div className="text-xs text-slate-400 mt-1 font-medium">
              Décaissements enregistrés
            </div>
          </div>
        </div>

        {/* KPI 4: Trésorerie Nette (CA - Dépenses) */}
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
            <div className="text-xs text-slate-400 mt-1 font-medium">
              CA − Dépenses
            </div>
          </div>
        </div>
      </div>

      {/* Comparative Bar Chart Card (Exact replica of mobile _buildBarChartCard) */}
      <div className="card-toc p-5 sm:p-6 space-y-4">
        <div className="flex items-center gap-2">
          <BarChart2 className="w-5 h-5 text-brand-500" />
          <h3 className="text-base font-bold text-[#1C2B3A] dark:text-white">
            Ventes vs Dépenses (Marge)
          </h3>
        </div>

        <div className="space-y-4 pt-1">
          {/* Row 1: CA (Ventes) */}
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

          {/* Row 2: Dépenses */}
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

          {/* Row 3: Marge Brute */}
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
                style={{ width: `${Math.min(100, (Math.max(0, kpis.gross_margin) / maxComparisonVal) * 100)}%` }}
              />
            </div>
          </div>
        </div>
      </div>

      {/* Financial Statement & Trend Chart */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* Synthetic P&L Table */}
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
                <span className="font-semibold text-slate-900 dark:text-white font-mono">{formatFCFA(kpis.gross_sales)}</span>
              </div>

              {kpis.discount_amount > 0 && (
                <div className="flex justify-between items-center py-1.5 border-b border-[#E8EFF5] dark:border-dark-600 text-rose-600 dark:text-rose-400">
                  <span>− Remises accordées</span>
                  <span className="font-mono">−{formatFCFA(kpis.discount_amount)}</span>
                </div>
              )}

              <div className="flex justify-between items-center py-1.5 border-b border-[#E8EFF5] dark:border-dark-600 font-medium">
                <span className="text-slate-900 dark:text-white font-bold">= Chiffre d'Affaires Net</span>
                <span className="font-extrabold text-slate-900 dark:text-white font-mono">{formatFCFA(kpis.net_sales)}</span>
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
                <span className="text-rose-600 dark:text-rose-400 font-mono">−{formatFCFA(kpis.total_expenses)}</span>
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
            <span className="font-bold text-slate-900 dark:text-white font-mono">{kpis.net_margin_rate}%</span>
          </div>
        </div>

        {/* Monthly Trend Chart */}
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

      {/* Top Products & Expense Category Breakdown */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Top Products (Mirrors mobile _buildTopProductsList) */}
        <div className="card-toc p-5 sm:p-6">
          <div className="flex items-center gap-2 mb-4">
            <Award className="w-5 h-5 text-amber-500" />
            <h2 className="text-base font-bold text-slate-900 dark:text-white">
              Top Produits les plus vendus
            </h2>
          </div>

          {top_products.length === 0 ? (
            <p className="text-xs text-slate-400 py-6 text-center">
              Aucune vente enregistrée sur cette période.
            </p>
          ) : (
            <div className="space-y-3">
              {top_products.map((p, idx) => (
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
                        {p.quantity_sold} unité{p.quantity_sold > 1 ? 's' : ''} vendue{p.quantity_sold > 1 ? 's' : ''}
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

        {/* Expenses by Category (Mirrors mobile _buildExpenseCategoryChart) */}
        <div className="card-toc p-5 sm:p-6">
          <div className="flex items-center gap-2 mb-4">
            <PieChartIcon className="w-5 h-5 text-brand-500" />
            <h2 className="text-base font-bold text-slate-900 dark:text-white">
              Répartition des Dépenses par Catégorie
            </h2>
          </div>

          {expenses_by_category.length === 0 ? (
            <p className="text-xs text-slate-400 py-6 text-center">
              Aucune dépense enregistrée sur cette période.
            </p>
          ) : (
            <div className="space-y-3.5">
              {expenses_by_category.map((e, idx) => {
                const color = categoryColors[idx % categoryColors.length];
                return (
                  <div key={idx} className="space-y-1.5">
                    <div className="flex justify-between items-center text-xs font-semibold">
                      <div className="flex items-center gap-2 min-w-0">
                        <span
                          className="w-3 h-3 rounded-full shrink-0"
                          style={{ backgroundColor: color }}
                        />
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
                        style={{
                          width: `${Math.min(100, e.percentage)}%`,
                          backgroundColor: color,
                        }}
                      />
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>

      {/* Modal Période Personnalisée */}
      <Modal
        isOpen={isCustomModalOpen}
        onClose={() => setIsCustomModalOpen(false)}
        title="Sélectionner une Période"
        subtitle="Définissez les dates de début et de fin du rapport"
        footer={
          <div className="flex items-center justify-end gap-2 w-full">
            <button
              type="button"
              onClick={() => setIsCustomModalOpen(false)}
              className="btn-toc btn-secondary text-xs"
            >
              Annuler
            </button>
            <button
              type="button"
              onClick={() => {
                if (customStart && customEnd) {
                  setPeriodPreset('customRange');
                  setIsCustomModalOpen(false);
                }
              }}
              disabled={!customStart || !customEnd}
              className="btn-toc btn-primary text-xs"
            >
              Appliquer la Période
            </button>
          </div>
        }
      >
        <div className="space-y-4">
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Date de début *
            </label>
            <input
              type="date"
              required
              value={customStart}
              onChange={(e) => setCustomStart(e.target.value)}
              className="input-toc"
            />
          </div>

          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Date de fin *
            </label>
            <input
              type="date"
              required
              value={customEnd}
              onChange={(e) => setCustomEnd(e.target.value)}
              className="input-toc"
            />
          </div>
        </div>
      </Modal>
    </div>
  );
};
