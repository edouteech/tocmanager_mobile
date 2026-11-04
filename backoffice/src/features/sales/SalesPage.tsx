import React, { useState, useMemo } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  Search,
  Printer,
  FileText,
  CreditCard,
  ShoppingBag,
  Plus,
  FileSpreadsheet,
  Calendar,
  DollarSign,
  TrendingUp,
  AlertCircle,
  Share2,
} from 'lucide-react';
import { api } from '../../lib/api';
import { formatFCFA, formatDateTime } from '../../lib/formatters';
import { Vente } from '../../types';
import { Drawer } from '../../components/common/Drawer';
import { useDensity } from '../../context/DensityContext';
import { CreateSaleModal } from './CreateSaleModal';
import { exportToExcel } from '../../lib/exportUtils';
import { SummaryChipsRow, SummaryChipItem } from '../../components/common/SummaryChipsRow';
import { FilterPeriodChips, FilterChipItem, SortOption } from '../../components/common/FilterPeriodChips';
import { ViewToggle, ViewMode } from '../../components/common/ViewToggle';
import { VenteCard } from './VenteCard';

export const SalesPage: React.FC = () => {
  const { tableClasses } = useDensity();
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedVente, setSelectedVente] = useState<Vente | null>(null);
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
  const [selectedPeriod, setSelectedPeriod] = useState<string>('all');
  const [onlyCredit, setOnlyCredit] = useState<boolean>(false);
  const [sortBy, setSortBy] = useState<string>('recent');
  const [viewMode, setViewMode] = useState<ViewMode>('cards');

  const { data: ventes = [], isLoading } = useQuery<Vente[]>({
    queryKey: ['ventes'],
    queryFn: async () => {
      const res = await api.get('/ventes?limit=300');
      return res.data;
    },
  });

  // Calculate today's sales and total CA
  const todayStart = new Date();
  todayStart.setHours(0, 0, 0, 0);

  const todaySalesAmount = useMemo(() => {
    return ventes.reduce((sum, v) => {
      const d = new Date(v.created_at);
      if (d >= todayStart) {
        return sum + (v.total_amount || 0);
      }
      return sum;
    }, 0);
  }, [ventes, todayStart]);

  const totalSalesAmount = useMemo(() => {
    return ventes.reduce((sum, v) => sum + (v.total_amount || 0), 0);
  }, [ventes]);

  const totalCreditAmount = useMemo(() => {
    return ventes.reduce((sum, v) => {
      const rem = Math.max(0, (v.total_amount || 0) - (v.paid_amount || 0));
      return sum + rem;
    }, 0);
  }, [ventes]);

  // Period Chips definition
  const periodChips: FilterChipItem[] = [
    { id: 'all', label: 'Toutes' },
    { id: 'today', label: "Aujourd'hui" },
    { id: 'week', label: 'Cette semaine' },
    { id: 'month', label: 'Ce mois-ci' },
  ];

  const sortOptions: SortOption[] = [
    { id: 'recent', label: 'Plus récentes' },
    { id: 'amount_desc', label: 'Montant le plus élevé' },
    { id: 'amount_asc', label: 'Montant croissant' },
    { id: 'client_asc', label: 'Nom Client (A - Z)' },
  ];

  // Filtered & Sorted ventes
  const filteredVentes = useMemo(() => {
    const now = new Date();
    const dayOfWeek = (now.getDay() + 6) % 7; // Monday = 0
    const startOfWeek = new Date(now);
    startOfWeek.setDate(now.getDate() - dayOfWeek);
    startOfWeek.setHours(0, 0, 0, 0);

    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    return ventes
      .filter((v) => {
        // Search filter
        const term = searchTerm.toLowerCase();
        const matchesSearch =
          v.ticket_number.toLowerCase().includes(term) ||
          (v.client_name && v.client_name.toLowerCase().includes(term)) ||
          v.payment_method.toLowerCase().includes(term) ||
          (v.user_name && v.user_name.toLowerCase().includes(term));

        if (!matchesSearch) return false;

        // Credit filter
        if (onlyCredit) {
          const isCredit = v.payment_method === 'Crédit' || v.paid_amount < v.total_amount;
          if (!isCredit) return false;
        }

        // Period filter
        const vDate = new Date(v.created_at);
        if (selectedPeriod === 'today') {
          return vDate >= todayStart;
        } else if (selectedPeriod === 'week') {
          return vDate >= startOfWeek;
        } else if (selectedPeriod === 'month') {
          return vDate >= startOfMonth;
        }

        return true;
      })
      .sort((a, b) => {
        if (sortBy === 'amount_desc') {
          return (b.total_amount || 0) - (a.total_amount || 0);
        } else if (sortBy === 'amount_asc') {
          return (a.total_amount || 0) - (b.total_amount || 0);
        } else if (sortBy === 'client_asc') {
          return (a.client_name || '').localeCompare(b.client_name || '');
        }
        // Default: recent
        return new Date(b.created_at).getTime() - new Date(a.created_at).getTime();
      });
  }, [ventes, searchTerm, onlyCredit, selectedPeriod, sortBy, todayStart]);

  // Filtered summary calculations
  const filteredTotalAmount = useMemo(() => {
    return filteredVentes.reduce((sum, v) => sum + (v.total_amount || 0), 0);
  }, [filteredVentes]);

  // Summary Chips
  const summaryChips: SummaryChipItem[] = [
    {
      label: selectedPeriod !== 'all' || onlyCredit ? 'Ventes (filtre)' : 'Total ventes',
      value: filteredVentes.length,
      color: 'primary',
      icon: <ShoppingBag className="w-4 h-4" />,
      subtext: `${ventes.length} transactions au total`,
    },
    {
      label: "Aujourd'hui",
      value: formatFCFA(todaySalesAmount),
      color: 'success',
      icon: <TrendingUp className="w-4 h-4" />,
      subtext: 'Encaissements du jour',
    },
    {
      label: selectedPeriod !== 'all' || onlyCredit ? 'CA (filtre)' : "Chiffre d'aff.",
      value: formatFCFA(selectedPeriod !== 'all' || onlyCredit ? filteredTotalAmount : totalSalesAmount),
      color: 'purple',
      icon: <DollarSign className="w-4 h-4" />,
      subtext: 'Volume total vendu',
    },
    {
      label: 'Créances / Dettes',
      value: formatFCFA(totalCreditAmount),
      color: totalCreditAmount > 0 ? 'warning' : 'info',
      icon: <AlertCircle className="w-4 h-4" />,
      subtext: 'Reste dû sur ventes',
    },
  ];

  const handlePrintReceipt = () => {
    window.print();
  };

  const handleShareWhatsApp = (vente: Vente) => {
    const text = encodeURIComponent(
      `*REÇU DE VENTE - ${vente.ticket_number}*\n` +
      `Date : ${formatDateTime(vente.created_at)}\n` +
      `Client : ${vente.client_name || 'Occasionnel'}\n` +
      `Montant Total : ${formatFCFA(vente.total_amount)}\n` +
      `Mode : ${vente.payment_method}\n` +
      `Merci pour votre confiance !`
    );
    window.open(`https://wa.me/?text=${text}`, '_blank');
  };

  const handleExportExcel = () => {
    const exportData = filteredVentes.map((v) => ({
      'N° Ticket': v.ticket_number,
      'Date & Heure': formatDateTime(v.created_at),
      'Client': v.client_name || 'Occasionnel',
      'Mode Paiement': v.payment_method,
      'Nb Articles': v.items?.length || 0,
      'Montant Total (FCFA)': v.total_amount,
      'Montant Versé (FCFA)': v.paid_amount,
      'Remise (FCFA)': v.discount_amount,
      'Reste Dû (FCFA)': v.total_amount > v.paid_amount ? v.total_amount - v.paid_amount : 0,
      'Caissier': v.user_name || '',
    }));
    exportToExcel(exportData, `ventes_${new Date().toISOString().slice(0, 10)}.xlsx`, 'Journal des Ventes');
  };

  return (
    <div className="space-y-5 max-w-7xl mx-auto">
      {/* Header: Title & Main Action Buttons */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">
            Ventes
          </h1>
          <p className="text-xs sm:text-sm text-[#5A7184] dark:text-slate-400 mt-0.5">
            Registre des encaissements, tickets et factures de vente
          </p>
        </div>

        {/* Action buttons */}
        <div className="flex items-center gap-2 sm:gap-3 flex-wrap">
          <ViewToggle mode={viewMode} onChange={setViewMode} />

          <button
            onClick={handleExportExcel}
            className="btn-toc btn-outline flex items-center justify-center gap-2 py-2 px-3 text-xs font-bold"
            title="Exporter les ventes filtrées en Excel"
          >
            <FileSpreadsheet className="w-4 h-4 text-emerald-600" />
            <span className="hidden sm:inline">Excel</span>
          </button>

          <button
            onClick={() => setIsCreateModalOpen(true)}
            className="btn-toc btn-primary flex items-center gap-2 py-2 px-3.5 text-xs font-bold shadow-sm"
          >
            <Plus className="w-4 h-4" />
            <span>Nouvelle Vente</span>
          </button>
        </div>
      </div>

      {/* Mobile-Style Summary Chips Row */}
      <SummaryChipsRow chips={summaryChips} />

      {/* Search Bar & Period Filter Row (Mirrors mobile layout) */}
      <div className="card-toc p-3.5 sm:p-4 space-y-3">
        {/* Search Input */}
        <div className="relative w-full">
          <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-slate-400">
            <Search className="w-4 h-4" />
          </div>
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder="Rechercher ticket, client, caissier, mode paiement..."
            className="input-toc pl-10 w-full text-xs sm:text-sm"
          />
        </div>

        {/* Period Chips & Sort Popover */}
        <FilterPeriodChips
          chips={periodChips}
          selectedChip={selectedPeriod}
          onSelectChip={setSelectedPeriod}
          sortOptions={sortOptions}
          selectedSort={sortBy}
          onSelectSort={setSortBy}
          toggleLabel="À crédit"
          isToggleActive={onlyCredit}
          onToggle={() => setOnlyCredit((prev) => !prev)}
        />
      </div>

      {/* Content: Cards View (Mobile style) or Table View */}
      {isLoading ? (
        <div className="card-toc p-12 text-center text-slate-400">
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-4 border-brand-500 border-t-transparent mb-3" />
          <p className="text-sm">Chargement du journal des ventes...</p>
        </div>
      ) : filteredVentes.length === 0 ? (
        <div className="card-toc p-12 text-center text-slate-400">
          <div className="w-16 h-16 bg-slate-100 dark:bg-dark-700 rounded-full flex items-center justify-center mx-auto mb-3">
            <ShoppingBag className="w-8 h-8 text-slate-400" />
          </div>
          <h3 className="text-base font-bold text-slate-800 dark:text-slate-200">
            Aucune vente trouvée
          </h3>
          <p className="text-xs text-slate-400 mt-1 max-w-sm mx-auto">
            {searchTerm || selectedPeriod !== 'all' || onlyCredit
              ? 'Aucune vente ne correspond à vos filtres actuels. Essayez de réinitialiser la recherche.'
              : 'Enregistrez votre première transaction en cliquant sur "Nouvelle Vente".'}
          </p>
        </div>
      ) : viewMode === 'cards' ? (
        /* Mobile Cards Grid */
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3.5">
          {filteredVentes.map((v) => (
            <VenteCard
              key={v.sync_id}
              vente={v}
              onSelect={setSelectedVente}
              onPrint={setSelectedVente}
              onShareWhatsApp={handleShareWhatsApp}
            />
          ))}
        </div>
      ) : (
        /* Desktop Table View */
        <div className="card-toc overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left min-w-[700px]">
              <thead className="bg-[#F5FAFD] dark:bg-dark-700/50 border-b border-[#E8EFF5] dark:border-dark-600">
                <tr>
                  <th className={tableClasses.th}>Numéro Ticket</th>
                  <th className={tableClasses.th}>Client</th>
                  <th className={tableClasses.th}>Articles</th>
                  <th className={tableClasses.th}>Mode Paiement</th>
                  <th className={tableClasses.th}>Date & Heure</th>
                  <th className={`${tableClasses.th} text-right`}>Montant Total</th>
                  <th className={`${tableClasses.th} text-center`}>Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#E8EFF5] dark:divide-dark-600/60">
                {filteredVentes.map((v) => (
                  <tr
                    key={v.sync_id}
                    className="hover:bg-brand-50/30 dark:hover:bg-dark-700/40 transition-colors cursor-pointer"
                    onClick={() => setSelectedVente(v)}
                  >
                    <td className={`${tableClasses.td} font-mono font-bold text-brand-600 dark:text-brand-400`}>
                      {v.ticket_number}
                    </td>
                    <td className={`${tableClasses.td} font-semibold text-slate-900 dark:text-white`}>
                      {v.client_name || 'Occasionnel'}
                    </td>
                    <td className={`${tableClasses.td} text-slate-500 dark:text-slate-400`}>
                      <span className="inline-flex items-center gap-1">
                        <ShoppingBag className="w-3.5 h-3.5 text-brand-500" />
                        {v.items?.length || 0} article(s)
                      </span>
                    </td>
                    <td className={tableClasses.td}>
                      <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-brand-50 dark:bg-brand-500/15 text-brand-600 dark:text-brand-400 border border-brand-200 dark:border-brand-500/30">
                        <CreditCard className="w-3 h-3 text-brand-500" />
                        {v.payment_method}
                      </span>
                    </td>
                    <td className={`${tableClasses.td} text-slate-500 dark:text-slate-400`}>
                      {formatDateTime(v.created_at)}
                    </td>
                    <td className={`${tableClasses.td} text-right font-extrabold text-slate-900 dark:text-white font-mono`}>
                      {formatFCFA(v.total_amount)}
                    </td>
                    <td className={`${tableClasses.td} text-center`} onClick={(e) => e.stopPropagation()}>
                      <div className="flex items-center justify-center gap-1.5">
                        <button
                          onClick={() => handleShareWhatsApp(v)}
                          className="p-1.5 text-slate-400 hover:text-emerald-600 hover:bg-emerald-50 rounded-xl transition"
                          title="WhatsApp"
                        >
                          <Share2 className="w-3.5 h-3.5" />
                        </button>
                        <button
                          onClick={() => setSelectedVente(v)}
                          className="inline-flex items-center gap-1 px-2.5 py-1 bg-brand-50 hover:bg-brand-100 dark:bg-brand-500/15 text-brand-700 dark:text-brand-300 rounded-xl text-xs font-bold transition-all border border-brand-200 dark:border-brand-500/30"
                        >
                          <FileText className="w-3.5 h-3.5" />
                          <span>Détails</span>
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Mobile-Styled Slide-over Drawer for Ticket Detail */}
      <Drawer
        isOpen={!!selectedVente}
        onClose={() => setSelectedVente(null)}
        title={
          <div className="flex items-center gap-2">
            <FileText className="w-5 h-5 text-brand-500" />
            <span>Ticket {selectedVente?.ticket_number}</span>
          </div>
        }
        subtitle="Détail complet de la transaction de caisse"
        footer={
          <div className="flex items-center justify-between w-full gap-2">
            {selectedVente && (
              <button
                type="button"
                onClick={() => handleShareWhatsApp(selectedVente)}
                className="btn-toc btn-outline flex items-center gap-1.5 text-xs text-emerald-600"
              >
                <Share2 className="w-4 h-4" />
                <span>WhatsApp</span>
              </button>
            )}
            <button
              onClick={handlePrintReceipt}
              className="btn-toc btn-primary flex items-center gap-2 text-xs"
            >
              <Printer className="w-4 h-4" />
              <span>Imprimer le Reçu</span>
            </button>
          </div>
        }
      >
        {selectedVente && (
          <div className="space-y-5">
            {/* Ticket Header Card */}
            <div className="p-4 rounded-2xl bg-gradient-to-br from-brand-500/10 to-brand-500/5 border border-brand-500/20 text-center">
              <span className="font-mono text-xs font-bold text-brand-600 dark:text-brand-400 uppercase tracking-widest block mb-1">
                Ticket N° {selectedVente.ticket_number}
              </span>
              <div className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white font-mono">
                {formatFCFA(selectedVente.total_amount)}
              </div>
              <span className="inline-block mt-1.5 px-3 py-0.5 rounded-full text-xs font-bold bg-white dark:bg-dark-700 text-slate-700 dark:text-slate-300 border border-slate-200 dark:border-dark-600">
                Paiement : {selectedVente.payment_method}
              </span>
            </div>

            {/* Meta information */}
            <div className="grid grid-cols-2 gap-3 text-xs bg-[#F5FAFD] dark:bg-dark-700/60 p-4 rounded-2xl border border-[#E8EFF5] dark:border-dark-600">
              <div>
                <span className="text-slate-400 dark:text-slate-500 block mb-0.5">Client</span>
                <span className="font-bold text-slate-900 dark:text-white">
                  {selectedVente.client_name || 'Occasionnel'}
                </span>
              </div>
              <div>
                <span className="text-slate-400 dark:text-slate-500 block mb-0.5">Date & Heure</span>
                <span className="font-semibold text-slate-700 dark:text-slate-200">
                  {formatDateTime(selectedVente.created_at)}
                </span>
              </div>
              <div>
                <span className="text-slate-400 dark:text-slate-500 block mb-0.5">Montant Versé</span>
                <span className="font-semibold text-emerald-600 dark:text-emerald-400 font-mono">
                  {formatFCFA(selectedVente.paid_amount || 0)}
                </span>
              </div>
              <div>
                <span className="text-slate-400 dark:text-slate-500 block mb-0.5">Vendeur / Caissier</span>
                <span className="font-semibold text-slate-700 dark:text-slate-200">
                  {selectedVente.user_name || 'Système'}
                </span>
              </div>
              {selectedVente.paid_amount < selectedVente.total_amount && (
                <div className="col-span-2 pt-2 border-t border-slate-200 dark:border-dark-600 flex justify-between items-center text-amber-600 dark:text-amber-400 font-bold">
                  <span>Reste Dû (Crédit) :</span>
                  <span className="font-mono text-sm">
                    {formatFCFA(selectedVente.total_amount - selectedVente.paid_amount)}
                  </span>
                </div>
              )}
            </div>

            {/* Items List */}
            <div>
              <h4 className="text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-2.5">
                Articles Vendus ({selectedVente.items.length})
              </h4>
              <div className="border border-[#E8EFF5] dark:border-dark-600 rounded-2xl overflow-hidden divide-y divide-[#E8EFF5] dark:divide-dark-600/60 bg-white dark:bg-dark-800">
                {selectedVente.items.map((it, idx) => (
                  <div key={idx} className="p-3.5 text-xs flex items-center justify-between hover:bg-slate-50 dark:hover:bg-dark-700/40">
                    <div>
                      <div className="font-bold text-slate-900 dark:text-white">{it.product_name}</div>
                      <div className="text-slate-500 dark:text-slate-400 text-[11px] mt-0.5 font-mono">
                        {it.quantity} x {formatFCFA(it.unit_price)}
                      </div>
                    </div>
                    <div className="font-extrabold text-slate-900 dark:text-white font-mono text-sm">
                      {formatFCFA(it.total)}
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Discount if present */}
            {selectedVente.discount_amount > 0 && (
              <div className="flex justify-between items-center px-4 py-2 bg-amber-50 dark:bg-amber-500/10 rounded-xl text-xs font-bold text-amber-700 dark:text-amber-300 border border-amber-200 dark:border-amber-500/20">
                <span>Remise appliquée</span>
                <span>-{formatFCFA(selectedVente.discount_amount)}</span>
              </div>
            )}
          </div>
        )}
      </Drawer>

      {/* POS New Sale Modal */}
      <CreateSaleModal
        isOpen={isCreateModalOpen}
        onClose={() => setIsCreateModalOpen(false)}
      />
    </div>
  );
};
