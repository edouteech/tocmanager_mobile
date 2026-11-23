import React, { useState } from 'react';
import { Users, Truck, Search, Plus, DollarSign, AlertCircle, CheckCircle2, FileSpreadsheet } from 'lucide-react';
import { Client, Supplier } from '../../types';
import { formatFCFA } from '../../lib/formatters';
import { ConfirmModal } from '../../components/common/ConfirmModal';
import { PaginationControls } from '../../components/common/PaginationControls';
import { PaymentReceiptModal } from '../../components/common/PaymentReceiptModal';
import { SummaryChipsRow, SummaryChipItem } from '../../components/common/SummaryChipsRow';
import { FilterPeriodChips, FilterChipItem, SortOption } from '../../components/common/FilterPeriodChips';
import { ViewToggle, ViewMode } from '../../components/common/ViewToggle';
import { ClientCard } from '../clients/ClientCard';
import { SupplierCard } from '../suppliers/SupplierCard';
import { PartnerFormModal, PartnerKind } from './PartnerFormModal';
import { PartnerPaymentModal } from './PartnerPaymentModal';
import { PartnerTable } from './PartnerTable';
import { usePartnersDirectory } from './usePartnersDirectory';
import { useAuthStore } from '../../stores/authStore';

const SORT_OPTIONS: SortOption[] = [
  { id: 'name_asc', label: 'Nom (A - Z)' },
  { id: 'debt_desc', label: 'Dette décroissante' },
  { id: 'debt_asc', label: 'Dette croissante' },
];

export const PartnersPage: React.FC<{ kind: PartnerKind }> = ({ kind }) => {
  const isSupplier = kind === 'supplier';
  const user = useAuthStore((s) => s.user);
  const canModify = isSupplier ? true : user?.role !== 'cashier';
  const [viewMode, setViewMode] = useState<ViewMode>('cards');
  const dir = usePartnersDirectory(kind);
  const debtFilterId = isSupplier ? 'creditors' : 'debtors';

  const summaryChips: SummaryChipItem[] = [
    {
      label: isSupplier ? 'Fournisseurs Enregistrés' : 'Total Répertoire',
      value: dir.stats.total,
      color: 'primary',
      icon: isSupplier ? <Truck className="w-4 h-4" /> : <Users className="w-4 h-4" />,
      subtext: isSupplier ? "Partenaires d'approvisionnement" : 'Clients enregistrés',
    },
    {
      label: isSupplier ? 'Dettes Fournisseurs' : 'Créances Clients',
      value: formatFCFA(dir.stats.totalDebt),
      color: dir.stats.totalDebt > 0 ? 'warning' : 'success',
      icon: <AlertCircle className="w-4 h-4" />,
      subtext: isSupplier ? 'Montant total restant dû' : 'Reste dû sur achats',
    },
    {
      label: isSupplier ? 'Dettes en Cours' : 'Clients Débiteurs',
      value: dir.stats.withDebt,
      color: dir.stats.withDebt > 0 ? 'warning' : 'primary',
      icon: <DollarSign className="w-4 h-4" />,
      subtext: isSupplier ? 'Fournisseurs à régler' : 'En attente de règlement',
    },
    {
      label: isSupplier ? 'Fournisseurs à Jour' : 'Clients à Jour',
      value: dir.stats.settled,
      color: 'success',
      icon: <CheckCircle2 className="w-4 h-4" />,
      subtext: isSupplier ? 'Comptes entièrement soldés' : 'Solde entièrement soldé',
    },
  ];

  const filterChips: FilterChipItem[] = [
    { id: 'all', label: 'Tous', count: dir.stats.total },
    { id: debtFilterId, label: isSupplier ? 'Dettes en cours' : 'Débiteurs', count: dir.stats.withDebt },
    { id: 'uptodate', label: 'À jour', count: dir.stats.settled },
  ];

  return (
    <div className="space-y-5 max-w-7xl mx-auto">
      <div className="flex flex-col sm:flex-row justify-between items-stretch sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">
            {isSupplier ? 'Fournisseurs' : 'Clients'}
          </h1>
          <p className="text-xs sm:text-sm text-[#5A7184] dark:text-slate-400 mt-0.5">
            {isSupplier
              ? "Gestion des partenaires d'approvisionnement et dettes fournisseurs"
              : 'Gestion du répertoire clients et suivi des règlements de dettes'}
          </p>
        </div>

        <div className="flex items-center gap-2 sm:gap-3 flex-wrap">
          <ViewToggle mode={viewMode} onChange={setViewMode} />
          <button onClick={dir.handleExport} className="btn-secondary flex items-center justify-center gap-2 py-2 px-3 text-xs font-bold">
            <FileSpreadsheet className="w-4 h-4 text-emerald-600" />
            <span className="hidden sm:inline">Excel</span>
          </button>
          <button onClick={dir.openCreate} className="btn-primary flex items-center gap-2 py-2 px-3.5 text-xs font-bold shadow-sm">
            <Plus className="w-4 h-4" />
            <span>{isSupplier ? 'Nouveau Fournisseur' : 'Nouveau Client'}</span>
          </button>
        </div>
      </div>

      <SummaryChipsRow chips={summaryChips} />

      <div className="card-toc p-3.5 sm:p-4 space-y-3">
        <div className="relative w-full">
          <Search className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
          <input
            type="text"
            placeholder={isSupplier ? 'Rechercher raison sociale, contact, téléphone...' : 'Rechercher nom, téléphone, adresse...'}
            value={dir.search}
            onChange={(e) => dir.setSearch(e.target.value)}
            className="input-toc pl-10 w-full text-xs sm:text-sm"
          />
        </div>
        <FilterPeriodChips
          chips={filterChips}
          selectedChip={dir.filterMode}
          onSelectChip={dir.setFilterMode}
          sortOptions={SORT_OPTIONS}
          selectedSort={dir.sortBy}
          onSelectSort={dir.setSortBy}
        />
      </div>

      {dir.isLoading ? (
        <div className="card-toc p-12 text-center text-slate-400">
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-4 border-brand-500 border-t-transparent mb-3" />
          <p className="text-sm">{isSupplier ? 'Chargement des fournisseurs...' : 'Chargement des clients...'}</p>
        </div>
      ) : dir.filteredPartners.length === 0 ? (
        <div className="card-toc p-12 text-center text-slate-400">
          <div className="w-16 h-16 bg-slate-100 dark:bg-dark-700 rounded-full flex items-center justify-center mx-auto mb-3">
            {isSupplier ? <Truck className="w-8 h-8 text-slate-400" /> : <Users className="w-8 h-8 text-slate-400" />}
          </div>
          <h3 className="text-base font-bold text-slate-800 dark:text-slate-200">
            {isSupplier ? 'Aucun fournisseur trouvé' : 'Aucun client trouvé'}
          </h3>
          <p className="text-xs text-slate-400 mt-1 max-w-sm mx-auto">
            {dir.search || dir.filterMode !== 'all'
              ? 'Aucun résultat ne correspond aux critères de recherche.'
              : isSupplier
                ? 'Enregistrez votre premier partenaire en cliquant sur "Nouveau Fournisseur".'
                : 'Enregistrez votre premier client en cliquant sur "Nouveau Client".'}
          </p>
        </div>
      ) : viewMode === 'cards' ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3.5">
          {dir.filteredPartners.map((p) =>
            isSupplier ? (
              <SupplierCard key={p.sync_id} supplier={p as Supplier} onEdit={dir.openEdit} onDelete={dir.setConfirmDelete} onPayment={dir.openPayment} />
            ) : (
              <ClientCard key={p.sync_id} client={p as Client} canModify={canModify} onEdit={dir.openEdit} onDelete={dir.setConfirmDelete} onPayment={dir.openPayment} />
            )
          )}
        </div>
      ) : (
        <PartnerTable kind={kind} partners={dir.filteredPartners} canModify={canModify} onEdit={dir.openEdit} onDelete={dir.setConfirmDelete} onPayment={dir.openPayment} />
      )}

      <PaginationControls
        page={dir.pagedData?.page || dir.page}
        pages={dir.pagedData?.pages || 1}
        total={dir.pagedData?.total || 0}
        limit={dir.limit}
        onPageChange={dir.setPage}
        onLimitChange={(nextLimit) => {
          dir.setLimit(nextLimit);
          dir.setPage(1);
        }}
        itemLabel={isSupplier ? 'fournisseurs' : 'clients'}
        isFetching={dir.isFetching}
      />

      <PartnerFormModal
        kind={kind}
        isOpen={dir.isFormModalOpen}
        isEditing={Boolean(dir.editingPartner)}
        values={dir.formValues}
        error={dir.formError}
        isPending={dir.isSavingForm}
        onClose={() => dir.setIsFormModalOpen(false)}
        onChange={dir.setFormValues}
        onSubmit={dir.submitForm}
      />

      <PartnerPaymentModal
        kind={kind}
        partner={dir.paymentTarget}
        values={dir.paymentValues}
        error={dir.paymentError}
        isPending={dir.isRecordingPayment}
        onClose={() => dir.setPaymentTarget(null)}
        onChange={dir.setPaymentValues}
        onSubmit={dir.submitPayment}
      />

      <ConfirmModal
        isOpen={Boolean(dir.confirmDelete)}
        onClose={() => dir.setConfirmDelete(null)}
        onConfirm={dir.confirmDeletion}
        title={isSupplier ? 'Supprimer le fournisseur' : 'Supprimer le client'}
        message={
          dir.confirmDelete
            ? `Confirmer la suppression ${isSupplier ? 'du fournisseur' : 'du client'} "${dir.confirmDelete.name}" ?`
            : ''
        }
        confirmLabel="Supprimer"
        isPending={dir.isDeleting}
      />

      <PaymentReceiptModal
        isOpen={Boolean(dir.receiptData)}
        onClose={() => dir.setReceiptData(null)}
        data={dir.receiptData}
      />
    </div>
  );
};
