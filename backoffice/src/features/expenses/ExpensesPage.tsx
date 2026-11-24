import React from 'react';
import { Receipt, Plus, DollarSign, TrendingDown, Tag, Search, FileSpreadsheet } from 'lucide-react';
import { formatFCFA } from '../../lib/formatters';
import { ConfirmModal } from '../../components/common/ConfirmModal';
import { IconInput } from '../../components/common/IconInput';
import { PaginationControls } from '../../components/common/PaginationControls';
import { SummaryChipsRow, SummaryChipItem } from '../../components/common/SummaryChipsRow';
import { ViewToggle } from '../../components/common/ViewToggle';
import { ExpenseCard } from './ExpenseCard';
import { ExpensesTable } from './ExpensesTable';
import { ExpenseFormModal } from './ExpenseFormModal';
import { getCategoryBadgeClass } from './expenseBadge';
import { useExpensesDirectory } from './useExpensesDirectory';

export const ExpensesPage: React.FC = () => {
  const {
    canDeleteExpense, magasins, showMagasinSelector, targetMagasinId, setTargetMagasinId,
    selectedCategory, setSelectedCategory, searchTerm, setSearchTerm, isModalOpen, setIsModalOpen,
    confirmDelete, setConfirmDelete, viewMode, setViewMode, page, setPage, limit, setLimit,
    form, setForm, formError, expensesPage, allExpenses, filterCategories, formCategories,
    totalCount, totalExpenses, avgExpense, filteredTotal,
    isLoading, isFetching, isSubmitting, isDeleting,
    confirmDeleteExpense, openCreateModal, handleSubmit, handleExportExcel,
  } = useExpensesDirectory();

  const summaryChips: SummaryChipItem[] = [
    { label: 'Total Décaissements', value: formatFCFA(totalExpenses), color: 'danger', icon: <TrendingDown className="w-4 h-4" />, subtext: `${totalCount} dépenses au total` },
    { label: 'Dépense Moyenne', value: formatFCFA(avgExpense), color: 'warning', icon: <DollarSign className="w-4 h-4" />, subtext: 'Montant unitaire moyen' },
    { label: selectedCategory ? `Total ${selectedCategory}` : 'Sélection Actuelle', value: formatFCFA(filteredTotal), color: 'purple', icon: <Receipt className="w-4 h-4" />, subtext: `${expensesPage?.total ?? allExpenses.length} dépense(s)` },
    { label: 'Catégories Actives', value: filterCategories.length, color: 'info', icon: <Tag className="w-4 h-4" />, subtext: 'Rayons de charges' },
  ];

  return (
    <div className="space-y-5 max-w-7xl mx-auto">
      <div className="flex flex-col sm:flex-row justify-between items-stretch sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">Décaissements</h1>
          <p className="text-xs sm:text-sm text-[#5A7184] dark:text-slate-400 mt-0.5">
            Suivi des charges d'exploitation et sorties de caisse
          </p>
        </div>
        <div className="flex items-center gap-2 sm:gap-3 flex-wrap">
          <ViewToggle mode={viewMode} onChange={setViewMode} />
          <button onClick={handleExportExcel} className="btn-secondary flex items-center justify-center gap-2 py-2 px-3 text-xs font-bold" title="Exporter en Excel">
            <FileSpreadsheet className="w-4 h-4 text-emerald-600" />
            <span className="hidden sm:inline">Excel</span>
          </button>
          <button onClick={openCreateModal} className="btn-primary flex items-center gap-2 py-2 px-3.5 text-xs font-bold shadow-sm">
            <Plus className="w-4 h-4" />
            <span>Nouveau Décaissement</span>
          </button>
        </div>
      </div>

      <SummaryChipsRow chips={summaryChips} />

      <div className="card-toc p-3.5 sm:p-4 space-y-3">
        <IconInput
          containerClassName="w-full"
          icon={<Search className="w-4 h-4" />}
          iconClassName="text-slate-400"
          type="text"
          placeholder="Rechercher motif, bénéficiaire, mode..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="text-xs sm:text-sm"
        />
        <div className="flex items-center gap-1.5 overflow-x-auto no-scrollbar py-1 text-xs">
          <button
            type="button"
            onClick={() => setSelectedCategory('')}
            className={`px-3 py-1.5 rounded-xl font-bold whitespace-nowrap transition-all shrink-0 ${
              selectedCategory === ''
                ? 'bg-brand-600 text-white shadow-sm'
                : 'bg-white dark:bg-dark-800 text-slate-600 dark:text-slate-300 border border-slate-200 dark:border-dark-600 hover:bg-slate-50 dark:hover:bg-dark-700'
            }`}
          >
            Toutes ({totalCount})
          </button>
          {filterCategories.map((cat) => {
            const isSelected = selectedCategory.toLowerCase().trim() === cat.toLowerCase().trim();
            return (
              <button
                key={cat}
                type="button"
                onClick={() => setSelectedCategory(isSelected ? '' : cat)}
                className={`px-3 py-1.5 rounded-xl font-bold whitespace-nowrap transition-all shrink-0 ${
                  isSelected
                    ? 'bg-brand-600 text-white shadow-sm'
                    : 'bg-white dark:bg-dark-800 text-slate-600 dark:text-slate-300 border border-slate-200 dark:border-dark-600 hover:bg-slate-50 dark:hover:bg-dark-700'
                }`}
              >
                {cat}
              </button>
            );
          })}
        </div>
      </div>

      {isLoading ? (
        <div className="card-toc p-12 text-center text-slate-400">
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-4 border-brand-500 border-t-transparent mb-3" />
          <p className="text-sm">Chargement des dépenses...</p>
        </div>
      ) : allExpenses.length === 0 ? (
        <div className="card-toc p-12 text-center text-slate-400">
          <div className="w-16 h-16 bg-slate-100 dark:bg-dark-700 rounded-full flex items-center justify-center mx-auto mb-3">
            <Receipt className="w-8 h-8 text-slate-400" />
          </div>
          <h3 className="text-base font-bold text-slate-800 dark:text-slate-200">Aucun décaissement trouvé</h3>
          <p className="text-xs text-slate-400 mt-1 max-w-sm mx-auto">
            {searchTerm || selectedCategory ? 'Aucune dépense ne correspond aux critères.' : 'Enregistrez votre première sortie de caisse.'}
          </p>
        </div>
      ) : viewMode === 'cards' ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3.5">
          {allExpenses.map((d) => (
            <ExpenseCard key={d.sync_id} expense={d} canDelete={canDeleteExpense} onDelete={setConfirmDelete} badgeClass={getCategoryBadgeClass(d.category || 'Général')} />
          ))}
        </div>
      ) : (
        <ExpensesTable expenses={allExpenses} canDelete={canDeleteExpense} onDelete={setConfirmDelete} />
      )}

      <PaginationControls
        page={expensesPage?.page || page}
        pages={expensesPage?.pages || 1}
        total={expensesPage?.total || 0}
        limit={limit}
        onPageChange={setPage}
        onLimitChange={(nextLimit) => { setLimit(nextLimit); setPage(1); }}
        itemLabel="dépenses"
        isFetching={isFetching}
      />

      <ExpenseFormModal
        isOpen={isModalOpen}
        form={form}
        formCategories={formCategories}
        formError={formError}
        isSubmitting={isSubmitting}
        showMagasinSelector={showMagasinSelector}
        magasins={magasins}
        targetMagasinId={targetMagasinId}
        onTargetMagasinChange={setTargetMagasinId}
        onClose={() => setIsModalOpen(false)}
        onChange={setForm}
        onSubmit={handleSubmit}
      />

      <ConfirmModal
        isOpen={Boolean(confirmDelete)}
        onClose={() => setConfirmDelete(null)}
        onConfirm={confirmDeleteExpense}
        title="Annuler le décaissement"
        message={confirmDelete ? `Confirmer l'annulation de la dépense "${confirmDelete.title}" (${formatFCFA(confirmDelete.amount)}) ?` : ''}
        confirmLabel="Confirmer l'annulation"
        isPending={isDeleting}
      />
    </div>
  );
};
