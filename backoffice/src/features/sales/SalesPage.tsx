import React from 'react';
import { Search, ShoppingBag, Plus, FileSpreadsheet, DollarSign, TrendingUp, AlertCircle } from 'lucide-react';
import { formatFCFA } from '../../lib/formatters';
import { IconInput } from '../../components/common/IconInput';
import { PaginationControls } from '../../components/common/PaginationControls';
import { SummaryChipsRow, SummaryChipItem } from '../../components/common/SummaryChipsRow';
import { FilterPeriodChips, FilterChipItem, SortOption } from '../../components/common/FilterPeriodChips';
import { ViewToggle } from '../../components/common/ViewToggle';
import { CreateSaleModal } from './CreateSaleModal';
import { RefundSaleModal } from './RefundSaleModal';
import { SalesTable } from './SalesTable';
import { SaleDetailDrawer } from './SaleDetailDrawer';
import { VenteCard } from './VenteCard';
import { useSalesDirectory } from './useSalesDirectory';

const PERIOD_CHIPS: FilterChipItem[] = [
  { id: 'all', label: 'Toutes' },
  { id: 'today', label: "Aujourd'hui" },
  { id: 'week', label: 'Cette semaine' },
  { id: 'month', label: 'Ce mois-ci' },
];

const SORT_OPTIONS: SortOption[] = [
  { id: 'recent', label: 'Plus récentes' },
  { id: 'amount_desc', label: 'Montant le plus élevé' },
  { id: 'amount_asc', label: 'Montant croissant' },
  { id: 'client_asc', label: 'Nom Client (A - Z)' },
];

export const SalesPage: React.FC = () => {
  const {
    canRefund, storeDisplayName, magasinName,
    searchTerm, setSearchTerm, selectedVente, setSelectedVente, refundTarget, setRefundTarget,
    isCreateModalOpen, setIsCreateModalOpen, selectedPeriod, setSelectedPeriod,
    onlyCredit, setOnlyCredit, sortBy, setSortBy, viewMode, setViewMode,
    page, setPage, limit, setLimit, ventesPage, ventes, sortedVentes, filteredTotalAmount,
    salesSummary, isLoading, isFetching, handleShareWhatsApp, handleExportExcel, handleRefunded,
  } = useSalesDirectory();

  const summaryChips: SummaryChipItem[] = [
    {
      label: selectedPeriod !== 'all' || onlyCredit ? 'Ventes (filtre)' : 'Total ventes',
      value: ventesPage?.total ?? sortedVentes.length,
      color: 'primary',
      icon: <ShoppingBag className="w-4 h-4" />,
      subtext: `${salesSummary?.total_count ?? ventes.length} transactions au total`,
    },
    {
      label: "Aujourd'hui",
      value: formatFCFA(salesSummary?.today_amount ?? 0),
      color: 'success',
      icon: <TrendingUp className="w-4 h-4" />,
      subtext: 'Encaissements du jour',
    },
    {
      label: selectedPeriod !== 'all' || onlyCredit ? 'CA (filtre)' : "Chiffre d'aff.",
      value: formatFCFA(
        selectedPeriod !== 'all' || onlyCredit || searchTerm
          ? (salesSummary?.filtered_amount ?? filteredTotalAmount)
          : (salesSummary?.total_amount ?? filteredTotalAmount)
      ),
      color: 'purple',
      icon: <DollarSign className="w-4 h-4" />,
      subtext: 'Volume total vendu',
    },
    {
      label: 'Créances / Dettes',
      value: formatFCFA(salesSummary?.total_credit ?? 0),
      color: (salesSummary?.total_credit ?? 0) > 0 ? 'warning' : 'info',
      icon: <AlertCircle className="w-4 h-4" />,
      subtext: 'Reste dû sur ventes',
    },
  ];

  return (
    <div className="space-y-5 max-w-7xl mx-auto">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">Ventes</h1>
          <p className="text-xs sm:text-sm text-[#5A7184] dark:text-slate-400 mt-0.5">
            Registre des encaissements, tickets et factures de vente
          </p>
        </div>
        <div className="flex items-center gap-2 sm:gap-3 flex-wrap">
          <ViewToggle mode={viewMode} onChange={setViewMode} />
          <button onClick={handleExportExcel} className="btn-secondary flex items-center justify-center gap-2 py-2 px-3 text-xs font-bold" title="Exporter en Excel">
            <FileSpreadsheet className="w-4 h-4 text-emerald-600" />
            <span className="hidden sm:inline">Excel</span>
          </button>
          <button onClick={() => setIsCreateModalOpen(true)} className="btn-primary flex items-center gap-2 py-2 px-3.5 text-xs font-bold shadow-sm">
            <Plus className="w-4 h-4" />
            <span>Nouvelle Vente</span>
          </button>
        </div>
      </div>

      <SummaryChipsRow chips={summaryChips} />

      <div className="card-toc p-3.5 sm:p-4 space-y-3">
        <div className="flex flex-col sm:flex-row gap-2.5">
          <IconInput
            containerClassName="flex-1"
            icon={<Search className="w-4 h-4" />}
            iconClassName="text-slate-400"
            type="text"
            placeholder="Rechercher par ticket, client..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="text-xs sm:text-sm"
          />
          <button
            type="button"
            onClick={() => setOnlyCredit((prev) => !prev)}
            className={`px-3.5 py-2 rounded-xl text-xs font-bold border transition ${
              onlyCredit
                ? 'bg-amber-500 text-white border-amber-500'
                : 'bg-white dark:bg-dark-800 text-slate-600 dark:text-slate-300 border-slate-200 dark:border-dark-600'
            }`}
          >
            À crédit uniquement
          </button>
        </div>
        <FilterPeriodChips chips={PERIOD_CHIPS} selectedChip={selectedPeriod} onSelectChip={setSelectedPeriod} sortOptions={SORT_OPTIONS} selectedSort={sortBy} onSelectSort={setSortBy} />
      </div>

      {isLoading ? (
        <div className="card-toc p-12 text-center text-slate-400 text-sm">Chargement des ventes...</div>
      ) : sortedVentes.length === 0 ? (
        <div className="card-toc p-12 text-center text-slate-400 text-sm">Aucune vente trouvée pour cette sélection.</div>
      ) : viewMode === 'cards' ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3.5">
          {sortedVentes.map((v) => (
            <VenteCard key={v.sync_id} vente={v} onSelect={setSelectedVente} onPrint={setSelectedVente} onShareWhatsApp={handleShareWhatsApp} />
          ))}
        </div>
      ) : (
        <SalesTable ventes={sortedVentes} onSelect={setSelectedVente} onShareWhatsApp={handleShareWhatsApp} />
      )}

      <PaginationControls
        page={ventesPage?.page || page}
        pages={ventesPage?.pages || 1}
        total={ventesPage?.total || 0}
        limit={limit}
        onPageChange={setPage}
        onLimitChange={(nextLimit) => { setLimit(nextLimit); setPage(1); }}
        itemLabel="ventes"
        isFetching={isFetching}
      />

      <SaleDetailDrawer
        vente={selectedVente}
        storeDisplayName={storeDisplayName}
        magasinName={magasinName}
        canRefund={canRefund}
        onClose={() => setSelectedVente(null)}
        onShareWhatsApp={handleShareWhatsApp}
        onRequestRefund={setRefundTarget}
        onPrint={() => window.print()}
      />

      <CreateSaleModal isOpen={isCreateModalOpen} onClose={() => setIsCreateModalOpen(false)} />

      <RefundSaleModal vente={refundTarget} onClose={() => setRefundTarget(null)} onRefunded={handleRefunded} />
    </div>
  );
};
