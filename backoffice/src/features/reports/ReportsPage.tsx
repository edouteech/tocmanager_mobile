import React, { useState, useMemo } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Download, FileSpreadsheet, Printer, Calendar } from 'lucide-react';
import { reportsApi } from '../../lib/api';
import { useTheme } from '../../context/ThemeContext';
import { downloadCsvContent, exportToExcel, formatCsvCell } from '../../lib/exportUtils';
import { useTenantContextKey, useTenantStore } from '../../stores/tenantStore';
import { ReportKpiGrid } from './ReportKpiGrid';
import { ReportProfitCharts } from './ReportProfitCharts';
import { ReportBreakdowns } from './ReportBreakdowns';
import { ReportCustomPeriodModal } from './ReportCustomPeriodModal';

const PERIOD_OPTIONS = [
  { id: 'today', label: "Aujourd'hui" },
  { id: 'thisWeek', label: 'Cette semaine' },
  { id: 'thisMonth', label: 'Ce mois-ci' },
  { id: 'thisYear', label: 'Cette année' },
  { id: 'all', label: "Tout l'historique" },
];

export const ReportsPage: React.FC = () => {
  const { theme } = useTheme();
  const [boutiqueKey, magasinKey] = useTenantContextKey();
  const openUpgradeModal = useTenantStore((s) => s.openUpgradeModal);
  const [periodPreset, setPeriodPreset] = useState<string>('thisMonth');
  const [customStart, setCustomStart] = useState<string>('');
  const [customEnd, setCustomEnd] = useState<string>('');
  const [isCustomModalOpen, setIsCustomModalOpen] = useState(false);

  const queryParams = useMemo(() => {
    if (periodPreset === 'customRange' && customStart && customEnd) {
      return {
        start_date: new Date(customStart).toISOString(),
        end_date: new Date(`${customEnd}T23:59:59.999Z`).toISOString(),
      };
    }
    return { preset: periodPreset };
  }, [periodPreset, customStart, customEnd]);

  const { data: report, isLoading, isError, error, refetch } = useQuery({
    queryKey: ['financial-report', boutiqueKey, magasinKey, queryParams],
    queryFn: () => reportsApi.getFinancial(queryParams),
  });

  const exportCSV = () => {
    if (!report) return;
    const { kpis, top_products, expenses_by_category } = report;
    const rows: unknown[][] = [
      ['COMPTE DE RESULTAT ET RENTABILITE TOCMANAGER'],
      [`Periode : ${periodPreset}`],
      [],
      ['INDICATEUR FINANCIER', 'MONTANT (FCFA)', 'POURCENTAGE'],
      ["Chiffre d'Affaires Brut", kpis.gross_sales, '100%'],
      ['Remises commerciales accordees', -kpis.discount_amount, '-'],
      ["Chiffre d'Affaires Net", kpis.net_sales, '100%'],
      ['Cout des marchandises vendues (COGS)', -kpis.cogs, `${Math.round((kpis.cogs / (kpis.net_sales || 1)) * 100)}%`],
      ['Marge Brute Commerciale', kpis.gross_margin, `${kpis.gross_margin_rate}%`],
      ['Total Charges et Decaissements', -kpis.total_expenses, `${Math.round((kpis.total_expenses / (kpis.net_sales || 1)) * 100)}%`],
      ['Tresorerie Nette (CA - Depenses)', kpis.net_cashflow ?? kpis.net_sales - kpis.total_expenses, '-'],
      ["Resultat Net d'Exploitation", kpis.net_profit, `${kpis.net_margin_rate}%`],
      [],
      ['TOP PRODUITS PAR CHIFFRE D AFFAIRES'],
      ['Article', 'Quantite Vendue', "Chiffre d'Affaires", 'Marge Beneficiaire'],
      ...top_products.map((p) => [p.product_name, p.quantity_sold, p.total_revenue, p.total_profit]),
      [],
      ['VENTILATION DES DEPENSES PAR CATEGORIE'],
      ['Categorie', 'Montant (FCFA)', 'Part (%)'],
      ...expenses_by_category.map((e) => [e.category, e.total_amount, `${e.percentage}%`]),
    ];
    const csvBody = rows.map((row) => row.map((cell) => formatCsvCell(cell)).join(';')).join('\r\n');
    downloadCsvContent(csvBody, `Rapport_Financier_TocManager_${new Date().toISOString().slice(0, 10)}.csv`);
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
      { 'Indicateur Financier': 'Trésorerie Nette (CA - Dépenses)', 'Montant (FCFA)': kpis.net_cashflow ?? kpis.net_sales - kpis.total_expenses, 'Part / Marge': '-' },
      { 'Indicateur Financier': "Résultat Net d'Exploitation", 'Montant (FCFA)': kpis.net_profit, 'Part / Marge': `${kpis.net_margin_rate}%` },
    ];
    exportToExcel(kpiData, `Rapport_Financier_P&L_${new Date().toISOString().slice(0, 10)}.xlsx`, 'Compte de Résultat');
  };

  if (isLoading) {
    return (
      <div className="card-toc p-12 text-center text-slate-400 text-sm">
        <div className="inline-block animate-spin rounded-full h-8 w-8 border-4 border-brand-500 border-t-transparent mb-3" />
        <p>Génération du rapport financier et des indicateurs de rentabilité...</p>
      </div>
    );
  }

  if (isError || !report) {
    const axiosErr = error as {
      response?: { status?: number; data?: { detail?: { error?: string; message?: string; recommended_plan?: string } | string } };
    } | null;
    const status = axiosErr?.response?.status;
    const detail = axiosErr?.response?.data?.detail;
    const isPlanLocked = status === 403 && typeof detail === 'object' && detail?.error === 'PLAN_FEATURE_LOCKED';
    return (
      <div className="card-toc p-10 text-center space-y-4 max-w-xl mx-auto">
        <h2 className="text-base font-bold text-[#1C2B3A] dark:text-white">
          {isPlanLocked ? 'Rapports financiers réservés aux forfaits Pro et Entreprise' : 'Impossible de charger les rapports financiers'}
        </h2>
        <p className="text-xs text-[#5A7184] dark:text-slate-400">
          {typeof detail === 'object' ? detail?.message : typeof detail === 'string' ? detail : 'Une erreur serveur est survenue lors du calcul des indicateurs.'}
        </p>
        <div className="flex items-center justify-center gap-3">
          {isPlanLocked ? (
            <button
              type="button"
              onClick={() =>
                openUpgradeModal({
                  title: 'Débloquer les rapports P&L',
                  message: typeof detail === 'object' ? detail?.message : undefined,
                  featureCode: 'pnl_reports',
                  recommendedPlan: typeof detail === 'object' ? detail?.recommended_plan || 'pro' : 'pro',
                })
              }
              className="btn-primary text-xs"
            >
              Passer au forfait Pro
            </button>
          ) : (
            <button type="button" onClick={() => refetch()} className="btn-primary text-xs">
              Réessayer
            </button>
          )}
        </div>
      </div>
    );
  }

  const { kpis, top_products, expenses_by_category, monthly_trend } = report;

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      <div className="flex flex-col sm:flex-row justify-between items-stretch sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">
            Analytique & Rapports
          </h1>
          <p className="text-xs sm:text-sm text-[#5A7184] dark:text-slate-400 mt-0.5">
            Indicateurs financiers, rentabilité, marges et compte de résultat
          </p>
        </div>

        <div className="no-print flex flex-wrap items-center gap-2">
          <button onClick={exportExcel} className="btn-secondary flex items-center gap-1.5 py-2 px-3 text-xs font-bold" title="Exporter en Excel (.xlsx)">
            <FileSpreadsheet className="w-4 h-4 text-emerald-600" />
            <span className="hidden sm:inline">Excel</span>
          </button>
          <button onClick={exportCSV} className="btn-secondary flex items-center gap-1.5 py-2 px-3 text-xs font-bold" title="Exporter en CSV">
            <Download className="w-4 h-4 text-brand-500" />
            <span className="hidden sm:inline">CSV</span>
          </button>
          <button onClick={() => window.print()} className="btn-secondary flex items-center gap-1.5 py-2 px-3 text-xs font-bold" title="Imprimer ou PDF">
            <Printer className="w-4 h-4 text-slate-500" />
            <span className="hidden sm:inline">Imprimer / PDF</span>
          </button>
        </div>
      </div>

      <div className="no-print card-toc p-3.5 flex items-center gap-2 overflow-x-auto no-scrollbar">
        {PERIOD_OPTIONS.map((opt) => (
          <button
            key={opt.id}
            type="button"
            onClick={() => setPeriodPreset(opt.id)}
            className={`px-3.5 py-1.5 rounded-xl text-xs font-bold whitespace-nowrap transition-all shrink-0 ${
              periodPreset === opt.id
                ? 'bg-brand-600 text-white shadow-sm'
                : 'bg-white dark:bg-dark-800 text-slate-600 dark:text-slate-300 border border-slate-200 dark:border-dark-600 hover:bg-slate-50 dark:hover:bg-dark-700'
            }`}
          >
            {opt.label}
          </button>
        ))}

        <button
          type="button"
          onClick={() => setIsCustomModalOpen(true)}
          className={`px-3.5 py-1.5 rounded-xl text-xs font-bold whitespace-nowrap transition-all flex items-center gap-1.5 shrink-0 ${
            periodPreset === 'customRange'
              ? 'bg-brand-600 text-white shadow-sm'
              : 'bg-brand-50 dark:bg-brand-500/15 text-brand-600 dark:text-brand-400 border border-brand-200 dark:border-brand-500/30 hover:bg-brand-100'
          }`}
        >
          <Calendar className="w-3.5 h-3.5" />
          <span>{periodPreset === 'customRange' && customStart && customEnd ? `${customStart} au ${customEnd}` : 'Période personnalisée...'}</span>
        </button>
      </div>

      <ReportKpiGrid kpis={kpis} />
      <ReportProfitCharts kpis={kpis} monthlyTrend={monthly_trend} theme={theme} />
      <ReportBreakdowns topProducts={top_products} expensesByCategory={expenses_by_category} />

      <ReportCustomPeriodModal
        isOpen={isCustomModalOpen}
        customStart={customStart}
        customEnd={customEnd}
        onStartChange={setCustomStart}
        onEndChange={setCustomEnd}
        onClose={() => setIsCustomModalOpen(false)}
        onApply={() => {
          if (customStart && customEnd) {
            setPeriodPreset('customRange');
            setIsCustomModalOpen(false);
          }
        }}
      />
    </div>
  );
};
