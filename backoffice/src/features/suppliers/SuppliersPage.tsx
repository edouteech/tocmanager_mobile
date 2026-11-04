import React, { useState, useMemo } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Truck,
  Search,
  Plus,
  DollarSign,
  AlertCircle,
  CheckCircle2,
  Phone,
  Mail,
  MapPin,
  CreditCard,
  Edit2,
  Trash2,
  FileSpreadsheet,
} from 'lucide-react';
import { suppliersApi } from '../../lib/api';
import { formatFCFA, formatDateTime } from '../../lib/formatters';
import { Supplier } from '../../types';
import { Modal } from '../../components/common/Modal';
import { useDensity } from '../../context/DensityContext';
import { exportToExcel } from '../../lib/exportUtils';
import { PaymentReceiptModal, PaymentReceiptData } from '../../components/common/PaymentReceiptModal';
import { SummaryChipsRow, SummaryChipItem } from '../../components/common/SummaryChipsRow';
import { FilterPeriodChips, FilterChipItem, SortOption } from '../../components/common/FilterPeriodChips';
import { ViewToggle, ViewMode } from '../../components/common/ViewToggle';
import { SupplierCard } from './SupplierCard';

export const SuppliersPage: React.FC = () => {
  const queryClient = useQueryClient();
  const { tableClasses } = useDensity();
  const [search, setSearch] = useState('');
  const [supplierFilter, setSupplierFilter] = useState<string>('all');
  const [sortBy, setSortBy] = useState<string>('name_asc');
  const [viewMode, setViewMode] = useState<ViewMode>('cards');

  // Modals state
  const [isSupplierModalOpen, setIsSupplierModalOpen] = useState(false);
  const [selectedSupplier, setSelectedSupplier] = useState<Supplier | null>(null);
  const [isPaymentModalOpen, setIsPaymentModalOpen] = useState(false);
  const [paymentSupplier, setPaymentSupplier] = useState<Supplier | null>(null);
  const [isReceiptModalOpen, setIsReceiptModalOpen] = useState(false);
  const [receiptData, setReceiptData] = useState<PaymentReceiptData | null>(null);

  // Form states
  const [supplierForm, setSupplierForm] = useState({
    name: '',
    contact_person: '',
    phone: '',
    email: '',
    address: '',
    balance: 0,
    notes: '',
  });

  const [paymentForm, setPaymentForm] = useState({
    amount: 0,
    payment_method: 'Espèces',
    notes: '',
  });

  // Fetch suppliers
  const { data: suppliers = [], isLoading } = useQuery({
    queryKey: ['suppliers'],
    queryFn: () => suppliersApi.getAll(),
  });

  // Mutations
  const createMutation = useMutation({
    mutationFn: suppliersApi.create,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['suppliers'] });
      setIsSupplierModalOpen(false);
      resetSupplierForm();
    },
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: Partial<Supplier> }) => suppliersApi.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['suppliers'] });
      setIsSupplierModalOpen(false);
      setSelectedSupplier(null);
      resetSupplierForm();
    },
  });

  const deleteMutation = useMutation({
    mutationFn: suppliersApi.delete,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['suppliers'] });
    },
  });

  const paymentMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: { amount: number; payment_method: string; notes?: string } }) =>
      suppliersApi.recordPayment(id, data),
    onSuccess: (updatedSupplier, variables) => {
      queryClient.invalidateQueries({ queryKey: ['suppliers'] });
      setIsPaymentModalOpen(false);
      if (paymentSupplier) {
        setReceiptData({
          type: 'supplier',
          recipientName: paymentSupplier.name,
          phone: paymentSupplier.phone,
          amount: variables.data.amount,
          previousBalance: paymentSupplier.balance,
          newBalance: updatedSupplier.balance,
          paymentMethod: variables.data.payment_method,
          notes: variables.data.notes,
        });
        setIsReceiptModalOpen(true);
      }
      setPaymentSupplier(null);
      setPaymentForm({ amount: 0, payment_method: 'Espèces', notes: '' });
    },
  });

  // Stats calculation
  const stats = useMemo(() => {
    let creditors = 0;
    let upToDate = 0;
    let totalDebt = 0;

    suppliers.forEach((s) => {
      if (s.balance > 0) {
        creditors++;
        totalDebt += s.balance;
      } else {
        upToDate++;
      }
    });

    return { total: suppliers.length, creditors, upToDate, totalDebt };
  }, [suppliers]);

  // Summary chips
  const summaryChips: SummaryChipItem[] = [
    {
      label: 'Fournisseurs Enregistrés',
      value: stats.total,
      color: 'primary',
      icon: <Truck className="w-4 h-4" />,
      subtext: 'Partenaires d’approvisionnement',
    },
    {
      label: 'Dettes Fournisseurs',
      value: formatFCFA(stats.totalDebt),
      color: stats.totalDebt > 0 ? 'warning' : 'success',
      icon: <AlertCircle className="w-4 h-4" />,
      subtext: 'Montant total restant dû',
    },
    {
      label: 'Dettes en Cours',
      value: stats.creditors,
      color: stats.creditors > 0 ? 'warning' : 'primary',
      icon: <DollarSign className="w-4 h-4" />,
      subtext: 'Fournisseurs à régler',
    },
    {
      label: 'Fournisseurs à Jour',
      value: stats.upToDate,
      color: 'success',
      icon: <CheckCircle2 className="w-4 h-4" />,
      subtext: 'Comptes entièrement soldés',
    },
  ];

  // Filter chips
  const filterChips: FilterChipItem[] = [
    { id: 'all', label: 'Tous', count: stats.total },
    { id: 'creditors', label: 'Dettes en cours', count: stats.creditors },
    { id: 'uptodate', label: 'À jour', count: stats.upToDate },
  ];

  const sortOptions: SortOption[] = [
    { id: 'name_asc', label: 'Nom (A - Z)' },
    { id: 'debt_desc', label: 'Dette décroissante' },
    { id: 'debt_asc', label: 'Dette croissante' },
  ];

  // Filtered & Sorted suppliers
  const filteredSuppliers = useMemo(() => {
    return suppliers
      .filter((s) => {
        const term = search.toLowerCase();
        const matchesSearch =
          s.name.toLowerCase().includes(term) ||
          (s.contact_person && s.contact_person.toLowerCase().includes(term)) ||
          (s.phone && s.phone.toLowerCase().includes(term)) ||
          (s.email && s.email.toLowerCase().includes(term)) ||
          (s.address && s.address.toLowerCase().includes(term));

        if (!matchesSearch) return false;

        if (supplierFilter === 'creditors' && s.balance <= 0) return false;
        if (supplierFilter === 'uptodate' && s.balance > 0) return false;

        return true;
      })
      .sort((a, b) => {
        if (sortBy === 'debt_desc') return b.balance - a.balance;
        if (sortBy === 'debt_asc') return a.balance - b.balance;
        return a.name.localeCompare(b.name);
      });
  }, [suppliers, search, supplierFilter, sortBy]);

  const handleExportExcel = () => {
    const exportData = filteredSuppliers.map((s) => ({
      'Raison Sociale': s.name,
      'Contact Référent': s.contact_person || '',
      'Téléphone': s.phone || '',
      'Email': s.email || '',
      'Adresse': s.address || '',
      'Dette Due (FCFA)': s.balance,
      'Date Création': s.created_at ? formatDateTime(s.created_at) : '',
    }));
    exportToExcel(exportData, `fournisseurs_${new Date().toISOString().slice(0, 10)}.xlsx`, 'Fournisseurs');
  };

  const resetSupplierForm = () => {
    setSupplierForm({
      name: '',
      contact_person: '',
      phone: '',
      email: '',
      address: '',
      balance: 0,
      notes: '',
    });
  };

  const handleOpenCreate = () => {
    setSelectedSupplier(null);
    resetSupplierForm();
    setIsSupplierModalOpen(true);
  };

  const handleOpenEdit = (s: Supplier) => {
    setSelectedSupplier(s);
    setSupplierForm({
      name: s.name,
      contact_person: s.contact_person || '',
      phone: s.phone || '',
      email: s.email || '',
      address: s.address || '',
      balance: s.balance,
      notes: s.notes || '',
    });
    setIsSupplierModalOpen(true);
  };

  const handleOpenPayment = (s: Supplier) => {
    setPaymentSupplier(s);
    setPaymentForm({
      amount: s.balance,
      payment_method: 'Espèces',
      notes: `Règlement facture ${s.name}`,
    });
    setIsPaymentModalOpen(true);
  };

  const handleDelete = (s: Supplier) => {
    if (window.confirm(`Confirmer la suppression du fournisseur "${s.name}" ?`)) {
      deleteMutation.mutate(s.sync_id);
    }
  };

  const handleSupplierSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!supplierForm.name.trim()) return;

    if (selectedSupplier) {
      updateMutation.mutate({
        id: selectedSupplier.sync_id,
        data: {
          name: supplierForm.name,
          contact_person: supplierForm.contact_person || null,
          phone: supplierForm.phone || null,
          email: supplierForm.email || null,
          address: supplierForm.address || null,
          notes: supplierForm.notes || null,
        },
      });
    } else {
      createMutation.mutate(supplierForm);
    }
  };

  const handlePaymentSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!paymentSupplier || paymentForm.amount <= 0) return;
    paymentMutation.mutate({
      id: paymentSupplier.sync_id,
      data: paymentForm,
    });
  };

  return (
    <div className="space-y-5 max-w-7xl mx-auto">
      {/* Top Header */}
      <div className="flex flex-col sm:flex-row justify-between items-stretch sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">Fournisseurs</h1>
          <p className="text-xs sm:text-sm text-[#5A7184] dark:text-slate-400 mt-0.5">
            Gestion des approvisionnements, fabricants et dettes fournisseurs
          </p>
        </div>

        <div className="flex items-center gap-2 sm:gap-3 flex-wrap">
          <ViewToggle mode={viewMode} onChange={setViewMode} />

          <button
            onClick={handleExportExcel}
            className="btn-toc btn-outline flex items-center justify-center gap-2 py-2 px-3 text-xs font-bold"
            title="Exporter la liste des fournisseurs vers Excel"
          >
            <FileSpreadsheet className="w-4 h-4 text-emerald-600" />
            <span className="hidden sm:inline">Excel</span>
          </button>

          <button
            onClick={handleOpenCreate}
            className="btn-toc btn-primary flex items-center gap-2 py-2 px-3.5 text-xs font-bold shadow-sm"
          >
            <Plus className="w-4 h-4" />
            <span>Nouveau Fournisseur</span>
          </button>
        </div>
      </div>

      {/* Mobile-Style Summary Chips Row */}
      <SummaryChipsRow chips={summaryChips} />

      {/* Search & Filter Bar */}
      <div className="card-toc p-3.5 sm:p-4 space-y-3">
        {/* Search Input */}
        <div className="relative w-full">
          <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-slate-400">
            <Search className="w-4 h-4" />
          </div>
          <input
            type="text"
            placeholder="Rechercher fournisseur, contact, téléphone, ville..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="input-toc pl-10 w-full text-xs sm:text-sm"
          />
        </div>

        {/* Filter Chips & Sort */}
        <FilterPeriodChips
          chips={filterChips}
          selectedChip={supplierFilter}
          onSelectChip={setSupplierFilter}
          sortOptions={sortOptions}
          selectedSort={sortBy}
          onSelectSort={setSortBy}
        />
      </div>

      {/* Content: Cards View (Mobile style) or Table View */}
      {isLoading ? (
        <div className="card-toc p-12 text-center text-slate-400">
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-4 border-brand-500 border-t-transparent mb-3" />
          <p className="text-sm">Chargement des fournisseurs...</p>
        </div>
      ) : filteredSuppliers.length === 0 ? (
        <div className="card-toc p-12 text-center text-slate-400">
          <div className="w-16 h-16 bg-slate-100 dark:bg-dark-700 rounded-full flex items-center justify-center mx-auto mb-3">
            <Truck className="w-8 h-8 text-slate-400" />
          </div>
          <h3 className="text-base font-bold text-slate-800 dark:text-slate-200">
            Aucun fournisseur trouvé
          </h3>
          <p className="text-xs text-slate-400 mt-1 max-w-sm mx-auto">
            {search || supplierFilter !== 'all'
              ? 'Aucun fournisseur ne correspond à vos critères de recherche.'
              : 'Enregistrez votre premier partenaire en cliquant sur "Nouveau Fournisseur".'}
          </p>
        </div>
      ) : viewMode === 'cards' ? (
        /* Mobile Cards Grid */
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3.5">
          {filteredSuppliers.map((s) => (
            <SupplierCard
              key={s.sync_id}
              supplier={s}
              onEdit={handleOpenEdit}
              onDelete={handleDelete}
              onPayment={handleOpenPayment}
            />
          ))}
        </div>
      ) : (
        /* Desktop Table View */
        <div className="card-toc overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left min-w-[650px]">
              <thead className="bg-[#F5FAFD] dark:bg-dark-700/50 border-b border-[#E8EFF5] dark:border-dark-600">
                <tr>
                  <th className={tableClasses.th}>Fournisseur</th>
                  <th className={tableClasses.th}>Contact</th>
                  <th className={tableClasses.th}>Adresse / Notes</th>
                  <th className={`${tableClasses.th} text-right`}>Dette Due</th>
                  <th className={`${tableClasses.th} text-right`}>Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#E8EFF5] dark:divide-dark-600/60">
                {filteredSuppliers.map((s) => {
                  const hasDebt = s.balance > 0;
                  return (
                    <tr key={s.sync_id} className="hover:bg-brand-50/30 dark:hover:bg-dark-700/40 transition-colors">
                      <td className={tableClasses.td}>
                        <div className="font-bold text-slate-900 dark:text-white">{s.name}</div>
                        {s.contact_person && (
                          <div className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
                            Réf: {s.contact_person}
                          </div>
                        )}
                      </td>
                      <td className={tableClasses.td}>
                        {s.phone ? (
                          <div className="flex items-center gap-1.5 text-xs text-slate-600 dark:text-slate-300">
                            <Phone className="w-3.5 h-3.5 text-brand-500" />
                            <span>{s.phone}</span>
                          </div>
                        ) : (
                          <span className="text-slate-400 text-xs">Aucun tél.</span>
                        )}
                        {s.email && <div className="text-xs text-slate-400 mt-0.5">{s.email}</div>}
                      </td>
                      <td className={tableClasses.td}>
                        {s.address && (
                          <div className="flex items-center gap-1.5 text-xs text-slate-600 dark:text-slate-300">
                            <MapPin className="w-3.5 h-3.5 text-slate-400" />
                            <span>{s.address}</span>
                          </div>
                        )}
                        {s.notes && <div className="text-xs text-slate-400 italic mt-0.5">{s.notes}</div>}
                        {!s.address && !s.notes && <span className="text-slate-400 text-xs">-</span>}
                      </td>
                      <td className={`${tableClasses.td} text-right font-mono`}>
                        {hasDebt ? (
                          <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-bold bg-amber-50 dark:bg-amber-950/40 text-amber-700 dark:text-amber-400 border border-amber-200 dark:border-amber-900/50">
                            <AlertCircle className="w-3 h-3" />
                            {formatFCFA(s.balance)}
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-400 border border-emerald-100 dark:border-emerald-900/50">
                            <CheckCircle2 className="w-3 h-3" />
                            À jour (0 F)
                          </span>
                        )}
                      </td>
                      <td className={`${tableClasses.td} text-right`}>
                        <div className="flex items-center justify-end gap-2">
                          {hasDebt && (
                            <button
                              onClick={() => handleOpenPayment(s)}
                              className="px-2.5 py-1 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl text-xs font-bold transition shadow-xs"
                              title="Enregistrer un règlement"
                            >
                              Régler
                            </button>
                          )}
                          <button
                            onClick={() => handleOpenEdit(s)}
                            className="p-1.5 text-slate-400 hover:text-brand-600 hover:bg-brand-50 dark:hover:bg-dark-700 rounded-xl transition"
                            title="Modifier"
                          >
                            <Edit2 className="w-4 h-4" />
                          </button>
                          <button
                            onClick={() => handleDelete(s)}
                            className="p-1.5 text-slate-400 hover:text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-950/30 rounded-xl transition"
                            title="Supprimer"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Modal Création / Modification Fournisseur */}
      <Modal
        isOpen={isSupplierModalOpen}
        onClose={() => setIsSupplierModalOpen(false)}
        title={selectedSupplier ? 'Modifier le Fournisseur' : 'Nouveau Fournisseur'}
        subtitle="Renseignez les coordonnées et contacts du fournisseur"
        footer={
          <div className="flex items-center justify-end gap-2 w-full">
            <button
              type="button"
              onClick={() => setIsSupplierModalOpen(false)}
              className="btn-toc btn-secondary text-xs"
            >
              Annuler
            </button>
            <button
              type="button"
              onClick={handleSupplierSubmit}
              disabled={createMutation.isPending || updateMutation.isPending}
              className="btn-toc btn-primary text-xs"
            >
              {createMutation.isPending || updateMutation.isPending
                ? 'Enregistrement...'
                : selectedSupplier
                ? 'Mettre à jour'
                : 'Enregistrer'}
            </button>
          </div>
        }
      >
        <form onSubmit={handleSupplierSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Raison Sociale / Nom *
            </label>
            <input
              type="text"
              required
              value={supplierForm.name}
              onChange={(e) => setSupplierForm({ ...supplierForm, name: e.target.value })}
              placeholder="Ex: Société Générale de Distribution (SGD)"
              className="input-toc"
            />
          </div>

          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Contact Référent (Personne à contacter)
            </label>
            <input
              type="text"
              value={supplierForm.contact_person}
              onChange={(e) => setSupplierForm({ ...supplierForm, contact_person: e.target.value })}
              placeholder="Ex: M. Jean Konan (Commercial)"
              className="input-toc"
            />
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Téléphone
              </label>
              <input
                type="tel"
                value={supplierForm.phone}
                onChange={(e) => setSupplierForm({ ...supplierForm, phone: e.target.value })}
                placeholder="+225 05..."
                className="input-toc font-mono"
              />
            </div>
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Email
              </label>
              <input
                type="email"
                value={supplierForm.email}
                onChange={(e) => setSupplierForm({ ...supplierForm, email: e.target.value })}
                placeholder="contact@fournisseur.com"
                className="input-toc"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Adresse physique
            </label>
            <input
              type="text"
              value={supplierForm.address}
              onChange={(e) => setSupplierForm({ ...supplierForm, address: e.target.value })}
              placeholder="Zone Industrielle, Ville"
              className="input-toc"
            />
          </div>

          {!selectedSupplier && (
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Solde Initial (Dette antérieure éventuelle)
              </label>
              <input
                type="number"
                min="0"
                value={supplierForm.balance}
                onChange={(e) => setSupplierForm({ ...supplierForm, balance: Number(e.target.value) })}
                className="input-toc font-bold font-mono"
              />
            </div>
          )}

          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Notes
            </label>
            <textarea
              rows={2}
              value={supplierForm.notes}
              onChange={(e) => setSupplierForm({ ...supplierForm, notes: e.target.value })}
              placeholder="Délais de paiement, coordonnées bancaires..."
              className="input-toc"
            />
          </div>
        </form>
      </Modal>

      {/* Modal Règlement Dette Fournisseur */}
      <Modal
        isOpen={isPaymentModalOpen}
        onClose={() => setIsPaymentModalOpen(false)}
        title="Règlement Facture Fournisseur"
        subtitle={paymentSupplier ? `Paiement en faveur de ${paymentSupplier.name}` : ''}
        footer={
          <div className="flex items-center justify-end gap-2 w-full">
            <button
              type="button"
              onClick={() => setIsPaymentModalOpen(false)}
              className="btn-toc btn-secondary text-xs"
            >
              Annuler
            </button>
            <button
              type="button"
              onClick={handlePaymentSubmit}
              disabled={paymentMutation.isPending || paymentForm.amount <= 0}
              className="btn-toc btn-primary text-xs bg-emerald-600 hover:bg-emerald-700"
            >
              {paymentMutation.isPending ? 'Enregistrement...' : 'Valider le Décaissement'}
            </button>
          </div>
        }
      >
        {paymentSupplier && (
          <form onSubmit={handlePaymentSubmit} className="space-y-4">
            <div className="p-4 rounded-2xl bg-amber-50 dark:bg-amber-950/30 border border-amber-200 dark:border-amber-900/50 flex justify-between items-center">
              <div>
                <span className="text-xs text-amber-800 dark:text-amber-300 font-semibold block">Dette à régler :</span>
                <span className="text-lg font-extrabold text-amber-900 dark:text-amber-200 font-mono">
                  {formatFCFA(paymentSupplier.balance)}
                </span>
              </div>
              <button
                type="button"
                onClick={() => setPaymentForm({ ...paymentForm, amount: paymentSupplier.balance })}
                className="px-2.5 py-1 text-xs font-bold bg-amber-200 dark:bg-amber-800 text-amber-900 dark:text-amber-100 rounded-lg hover:bg-amber-300 transition"
              >
                Tout solder
              </button>
            </div>

            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Montant Payé (FCFA) *
              </label>
              <input
                type="number"
                min="1"
                required
                value={paymentForm.amount || ''}
                onChange={(e) => setPaymentForm({ ...paymentForm, amount: Number(e.target.value) })}
                placeholder="Montant du décaissement"
                className="input-toc text-base font-extrabold font-mono text-emerald-600"
              />
            </div>

            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Mode de Règlement
              </label>
              <select
                value={paymentForm.payment_method}
                onChange={(e) => setPaymentForm({ ...paymentForm, payment_method: e.target.value })}
                className="input-toc bg-white dark:bg-dark-700"
              >
                <option value="Espèces">Espèces</option>
                <option value="Virement Bancaire">Virement Bancaire</option>
                <option value="Chèque">Chèque</option>
                <option value="Wave">Wave Pro</option>
                <option value="Orange Money">Orange Money</option>
                <option value="MTN MoMo">MTN MoMo</option>
              </select>
            </div>

            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Notes / Référence du virement ou chèque
              </label>
              <input
                type="text"
                value={paymentForm.notes}
                onChange={(e) => setPaymentForm({ ...paymentForm, notes: e.target.value })}
                placeholder="Ex: Facture N° 849..."
                className="input-toc"
              />
            </div>
          </form>
        )}
      </Modal>

      {/* Reçu de Paiement Modal */}
      <PaymentReceiptModal
        isOpen={isReceiptModalOpen}
        onClose={() => setIsReceiptModalOpen(false)}
        data={receiptData}
      />
    </div>
  );
};
