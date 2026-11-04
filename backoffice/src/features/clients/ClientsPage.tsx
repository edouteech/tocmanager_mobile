import React, { useState, useMemo } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Users,
  Search,
  Plus,
  DollarSign,
  AlertCircle,
  CheckCircle2,
  Phone,
  MapPin,
  CreditCard,
  Edit2,
  Trash2,
  FileSpreadsheet,
} from 'lucide-react';
import { clientsApi } from '../../lib/api';
import { formatFCFA, formatDateTime } from '../../lib/formatters';
import { Client } from '../../types';
import { Modal } from '../../components/common/Modal';
import { useDensity } from '../../context/DensityContext';
import { exportToExcel } from '../../lib/exportUtils';
import { PaymentReceiptModal, PaymentReceiptData } from '../../components/common/PaymentReceiptModal';
import { SummaryChipsRow, SummaryChipItem } from '../../components/common/SummaryChipsRow';
import { FilterPeriodChips, FilterChipItem, SortOption } from '../../components/common/FilterPeriodChips';
import { ViewToggle, ViewMode } from '../../components/common/ViewToggle';
import { ClientCard } from './ClientCard';

export const ClientsPage: React.FC = () => {
  const queryClient = useQueryClient();
  const { tableClasses } = useDensity();
  const [search, setSearch] = useState('');
  const [clientFilter, setClientFilter] = useState<string>('all');
  const [sortBy, setSortBy] = useState<string>('name_asc');
  const [viewMode, setViewMode] = useState<ViewMode>('cards');

  // Modals state
  const [isClientModalOpen, setIsClientModalOpen] = useState(false);
  const [selectedClient, setSelectedClient] = useState<Client | null>(null);
  const [isPaymentModalOpen, setIsPaymentModalOpen] = useState(false);
  const [paymentClient, setPaymentClient] = useState<Client | null>(null);
  const [isReceiptModalOpen, setIsReceiptModalOpen] = useState(false);
  const [receiptData, setReceiptData] = useState<PaymentReceiptData | null>(null);

  // Form states
  const [clientForm, setClientForm] = useState({
    name: '',
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

  // Fetch clients
  const { data: clients = [], isLoading } = useQuery({
    queryKey: ['clients'],
    queryFn: () => clientsApi.getAll(),
  });

  // Mutations
  const createMutation = useMutation({
    mutationFn: clientsApi.create,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['clients'] });
      setIsClientModalOpen(false);
      resetClientForm();
    },
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: Partial<Client> }) => clientsApi.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['clients'] });
      setIsClientModalOpen(false);
      setSelectedClient(null);
      resetClientForm();
    },
  });

  const deleteMutation = useMutation({
    mutationFn: clientsApi.delete,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['clients'] });
    },
  });

  const paymentMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: { amount: number; payment_method: string; notes?: string } }) =>
      clientsApi.recordPayment(id, data),
    onSuccess: (updatedClient, variables) => {
      queryClient.invalidateQueries({ queryKey: ['clients'] });
      setIsPaymentModalOpen(false);
      if (paymentClient) {
        setReceiptData({
          type: 'client',
          recipientName: paymentClient.name,
          phone: paymentClient.phone,
          amount: variables.data.amount,
          previousBalance: paymentClient.balance,
          newBalance: updatedClient.balance,
          paymentMethod: variables.data.payment_method,
          notes: variables.data.notes,
        });
        setIsReceiptModalOpen(true);
      }
      setPaymentClient(null);
      setPaymentForm({ amount: 0, payment_method: 'Espèces', notes: '' });
    },
  });

  // Stats calculation
  const stats = useMemo(() => {
    let debtors = 0;
    let upToDate = 0;
    let totalDebt = 0;

    clients.forEach((c) => {
      if (c.balance > 0) {
        debtors++;
        totalDebt += c.balance;
      } else {
        upToDate++;
      }
    });

    return { total: clients.length, debtors, upToDate, totalDebt };
  }, [clients]);

  // Summary chips
  const summaryChips: SummaryChipItem[] = [
    {
      label: 'Total Répertoire',
      value: stats.total,
      color: 'primary',
      icon: <Users className="w-4 h-4" />,
      subtext: 'Clients enregistrés',
    },
    {
      label: 'Créances Clients',
      value: formatFCFA(stats.totalDebt),
      color: stats.totalDebt > 0 ? 'warning' : 'success',
      icon: <AlertCircle className="w-4 h-4" />,
      subtext: 'Reste dû sur achats',
    },
    {
      label: 'Clients Débiteurs',
      value: stats.debtors,
      color: stats.debtors > 0 ? 'warning' : 'primary',
      icon: <DollarSign className="w-4 h-4" />,
      subtext: 'En attente de règlement',
    },
    {
      label: 'Clients à Jour',
      value: stats.upToDate,
      color: 'success',
      icon: <CheckCircle2 className="w-4 h-4" />,
      subtext: 'Solde entièrement soldé',
    },
  ];

  // Filter chips
  const filterChips: FilterChipItem[] = [
    { id: 'all', label: 'Tous', count: stats.total },
    { id: 'debtors', label: 'Débiteurs', count: stats.debtors },
    { id: 'uptodate', label: 'À jour', count: stats.upToDate },
  ];

  const sortOptions: SortOption[] = [
    { id: 'name_asc', label: 'Nom (A - Z)' },
    { id: 'debt_desc', label: 'Dette décroissante' },
    { id: 'debt_asc', label: 'Dette croissante' },
  ];

  // Filtered and sorted clients
  const filteredClients = useMemo(() => {
    return clients
      .filter((c) => {
        const term = search.toLowerCase();
        const matchesSearch =
          c.name.toLowerCase().includes(term) ||
          (c.phone && c.phone.toLowerCase().includes(term)) ||
          (c.email && c.email.toLowerCase().includes(term)) ||
          (c.address && c.address.toLowerCase().includes(term));

        if (!matchesSearch) return false;

        if (clientFilter === 'debtors' && c.balance <= 0) return false;
        if (clientFilter === 'uptodate' && c.balance > 0) return false;

        return true;
      })
      .sort((a, b) => {
        if (sortBy === 'debt_desc') return b.balance - a.balance;
        if (sortBy === 'debt_asc') return a.balance - b.balance;
        return a.name.localeCompare(b.name);
      });
  }, [clients, search, clientFilter, sortBy]);

  const handleExportExcel = () => {
    const exportData = filteredClients.map((c) => ({
      'Nom du Client': c.name,
      'Téléphone': c.phone || '',
      'Email': c.email || '',
      'Adresse': c.address || '',
      'Dette Restante (FCFA)': c.balance,
      'Date Création': c.created_at ? formatDateTime(c.created_at) : '',
    }));
    exportToExcel(exportData, `clients_${new Date().toISOString().slice(0, 10)}.xlsx`, 'Clients');
  };

  const resetClientForm = () => {
    setClientForm({
      name: '',
      phone: '',
      email: '',
      address: '',
      balance: 0,
      notes: '',
    });
  };

  const handleOpenCreate = () => {
    setSelectedClient(null);
    resetClientForm();
    setIsClientModalOpen(true);
  };

  const handleOpenEdit = (c: Client) => {
    setSelectedClient(c);
    setClientForm({
      name: c.name,
      phone: c.phone || '',
      email: c.email || '',
      address: c.address || '',
      balance: c.balance,
      notes: c.notes || '',
    });
    setIsClientModalOpen(true);
  };

  const handleOpenPayment = (c: Client) => {
    setPaymentClient(c);
    setPaymentForm({
      amount: c.balance,
      payment_method: 'Espèces',
      notes: `Règlement créance ${c.name}`,
    });
    setIsPaymentModalOpen(true);
  };

  const handleDelete = (c: Client) => {
    if (window.confirm(`Confirmer la suppression du client "${c.name}" ?`)) {
      deleteMutation.mutate(c.sync_id);
    }
  };

  const handleClientSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!clientForm.name.trim()) return;

    if (selectedClient) {
      updateMutation.mutate({
        id: selectedClient.sync_id,
        data: {
          name: clientForm.name,
          phone: clientForm.phone || null,
          email: clientForm.email || null,
          address: clientForm.address || null,
          notes: clientForm.notes || null,
        },
      });
    } else {
      createMutation.mutate(clientForm);
    }
  };

  const handlePaymentSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!paymentClient || paymentForm.amount <= 0) return;
    paymentMutation.mutate({
      id: paymentClient.sync_id,
      data: paymentForm,
    });
  };

  return (
    <div className="space-y-5 max-w-7xl mx-auto">
      {/* Top Header */}
      <div className="flex flex-col sm:flex-row justify-between items-stretch sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">Clients</h1>
          <p className="text-xs sm:text-sm text-[#5A7184] dark:text-slate-400 mt-0.5">
            Gestion du répertoire clients et suivi des règlements de dettes
          </p>
        </div>

        <div className="flex items-center gap-2 sm:gap-3 flex-wrap">
          <ViewToggle mode={viewMode} onChange={setViewMode} />

          <button
            onClick={handleExportExcel}
            className="btn-toc btn-outline flex items-center justify-center gap-2 py-2 px-3 text-xs font-bold"
            title="Exporter la liste des clients vers Excel"
          >
            <FileSpreadsheet className="w-4 h-4 text-emerald-600" />
            <span className="hidden sm:inline">Excel</span>
          </button>

          <button
            onClick={handleOpenCreate}
            className="btn-toc btn-primary flex items-center gap-2 py-2 px-3.5 text-xs font-bold shadow-sm"
          >
            <Plus className="w-4 h-4" />
            <span>Nouveau Client</span>
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
            placeholder="Rechercher nom, téléphone, adresse..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="input-toc pl-10 w-full text-xs sm:text-sm"
          />
        </div>

        {/* Filter Chips & Sort */}
        <FilterPeriodChips
          chips={filterChips}
          selectedChip={clientFilter}
          onSelectChip={setClientFilter}
          sortOptions={sortOptions}
          selectedSort={sortBy}
          onSelectSort={setSortBy}
        />
      </div>

      {/* Content: Cards View (Mobile style) or Table View */}
      {isLoading ? (
        <div className="card-toc p-12 text-center text-slate-400">
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-4 border-brand-500 border-t-transparent mb-3" />
          <p className="text-sm">Chargement des clients...</p>
        </div>
      ) : filteredClients.length === 0 ? (
        <div className="card-toc p-12 text-center text-slate-400">
          <div className="w-16 h-16 bg-slate-100 dark:bg-dark-700 rounded-full flex items-center justify-center mx-auto mb-3">
            <Users className="w-8 h-8 text-slate-400" />
          </div>
          <h3 className="text-base font-bold text-slate-800 dark:text-slate-200">
            Aucun client trouvé
          </h3>
          <p className="text-xs text-slate-400 mt-1 max-w-sm mx-auto">
            {search || clientFilter !== 'all'
              ? 'Aucun client ne correspond à vos critères de recherche.'
              : 'Enregistrez votre premier client en cliquant sur "Nouveau Client".'}
          </p>
        </div>
      ) : viewMode === 'cards' ? (
        /* Mobile Cards Grid */
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3.5">
          {filteredClients.map((c) => (
            <ClientCard
              key={c.sync_id}
              client={c}
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
                  <th className={tableClasses.th}>Client</th>
                  <th className={tableClasses.th}>Contact</th>
                  <th className={tableClasses.th}>Adresse / Notes</th>
                  <th className={`${tableClasses.th} text-right`}>Solde Dû</th>
                  <th className={`${tableClasses.th} text-right`}>Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#E8EFF5] dark:divide-dark-600/60">
                {filteredClients.map((c) => {
                  const hasDebt = c.balance > 0;
                  return (
                    <tr key={c.sync_id} className="hover:bg-brand-50/30 dark:hover:bg-dark-700/40 transition-colors">
                      <td className={tableClasses.td}>
                        <div className="font-bold text-slate-900 dark:text-white">{c.name}</div>
                        <div className="text-xs text-slate-400 mt-0.5">
                          Enregistré le {formatDateTime(c.created_at)}
                        </div>
                      </td>
                      <td className={tableClasses.td}>
                        {c.phone ? (
                          <div className="flex items-center gap-1.5 text-xs text-slate-600 dark:text-slate-300">
                            <Phone className="w-3.5 h-3.5 text-brand-500" />
                            <span>{c.phone}</span>
                          </div>
                        ) : (
                          <span className="text-slate-400 text-xs">Aucun tél.</span>
                        )}
                        {c.email && <div className="text-xs text-slate-400 mt-0.5">{c.email}</div>}
                      </td>
                      <td className={tableClasses.td}>
                        {c.address && (
                          <div className="flex items-center gap-1.5 text-xs text-slate-600 dark:text-slate-300">
                            <MapPin className="w-3.5 h-3.5 text-slate-400" />
                            <span>{c.address}</span>
                          </div>
                        )}
                        {c.notes && <div className="text-xs text-slate-400 italic mt-0.5">{c.notes}</div>}
                        {!c.address && !c.notes && <span className="text-slate-400 text-xs">-</span>}
                      </td>
                      <td className={`${tableClasses.td} text-right font-mono`}>
                        {hasDebt ? (
                          <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-bold bg-amber-50 dark:bg-amber-950/40 text-amber-700 dark:text-amber-400 border border-amber-200 dark:border-amber-900/50">
                            <AlertCircle className="w-3 h-3" />
                            {formatFCFA(c.balance)}
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
                              onClick={() => handleOpenPayment(c)}
                              className="px-2.5 py-1 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl text-xs font-bold transition shadow-xs"
                              title="Enregistrer un règlement"
                            >
                              Régler
                            </button>
                          )}
                          <button
                            onClick={() => handleOpenEdit(c)}
                            className="p-1.5 text-slate-400 hover:text-brand-600 hover:bg-brand-50 dark:hover:bg-dark-700 rounded-xl transition"
                            title="Modifier"
                          >
                            <Edit2 className="w-4 h-4" />
                          </button>
                          <button
                            onClick={() => handleDelete(c)}
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

      {/* Modal Création / Modification Client */}
      <Modal
        isOpen={isClientModalOpen}
        onClose={() => setIsClientModalOpen(false)}
        title={selectedClient ? 'Modifier le Client' : 'Nouveau Client'}
        subtitle="Renseignez les coordonnées du compte client"
        footer={
          <div className="flex items-center justify-end gap-2 w-full">
            <button
              type="button"
              onClick={() => setIsClientModalOpen(false)}
              className="btn-toc btn-secondary text-xs"
            >
              Annuler
            </button>
            <button
              type="button"
              onClick={handleClientSubmit}
              disabled={createMutation.isPending || updateMutation.isPending}
              className="btn-toc btn-primary text-xs"
            >
              {createMutation.isPending || updateMutation.isPending
                ? 'Enregistrement...'
                : selectedClient
                ? 'Mettre à jour'
                : 'Enregistrer'}
            </button>
          </div>
        }
      >
        <form onSubmit={handleClientSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Nom Complet *
            </label>
            <input
              type="text"
              required
              value={clientForm.name}
              onChange={(e) => setClientForm({ ...clientForm, name: e.target.value })}
              placeholder="Ex: Entreprise Toure ou Jean Dupont"
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
                value={clientForm.phone}
                onChange={(e) => setClientForm({ ...clientForm, phone: e.target.value })}
                placeholder="+225 07..."
                className="input-toc font-mono"
              />
            </div>
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Email
              </label>
              <input
                type="email"
                value={clientForm.email}
                onChange={(e) => setClientForm({ ...clientForm, email: e.target.value })}
                placeholder="client@mail.com"
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
              value={clientForm.address}
              onChange={(e) => setClientForm({ ...clientForm, address: e.target.value })}
              placeholder="Quartier, Rue, Ville"
              className="input-toc"
            />
          </div>

          {!selectedClient && (
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Solde Initial (Dette antérieure éventuelle)
              </label>
              <input
                type="number"
                min="0"
                value={clientForm.balance}
                onChange={(e) => setClientForm({ ...clientForm, balance: Number(e.target.value) })}
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
              value={clientForm.notes}
              onChange={(e) => setClientForm({ ...clientForm, notes: e.target.value })}
              placeholder="Remarques, conditions accordées..."
              className="input-toc"
            />
          </div>
        </form>
      </Modal>

      {/* Modal Règlement Dette Client */}
      <Modal
        isOpen={isPaymentModalOpen}
        onClose={() => setIsPaymentModalOpen(false)}
        title="Règlement de Créance Client"
        subtitle={paymentClient ? `Enregistrement d'un paiement pour ${paymentClient.name}` : ''}
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
              {paymentMutation.isPending ? 'Enregistrement...' : 'Valider le Règlement'}
            </button>
          </div>
        }
      >
        {paymentClient && (
          <form onSubmit={handlePaymentSubmit} className="space-y-4">
            <div className="p-4 rounded-2xl bg-amber-50 dark:bg-amber-950/30 border border-amber-200 dark:border-amber-900/50 flex justify-between items-center">
              <div>
                <span className="text-xs text-amber-800 dark:text-amber-300 font-semibold block">Dette actuelle due :</span>
                <span className="text-lg font-extrabold text-amber-900 dark:text-amber-200 font-mono">
                  {formatFCFA(paymentClient.balance)}
                </span>
              </div>
              <button
                type="button"
                onClick={() => setPaymentForm({ ...paymentForm, amount: paymentClient.balance })}
                className="px-2.5 py-1 text-xs font-bold bg-amber-200 dark:bg-amber-800 text-amber-900 dark:text-amber-100 rounded-lg hover:bg-amber-300 transition"
              >
                Tout solder
              </button>
            </div>

            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Montant Reçu (FCFA) *
              </label>
              <input
                type="number"
                min="1"
                required
                value={paymentForm.amount || ''}
                onChange={(e) => setPaymentForm({ ...paymentForm, amount: Number(e.target.value) })}
                placeholder="Montant du versement"
                className="input-toc text-base font-extrabold font-mono text-emerald-600"
              />
            </div>

            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Mode de Paiement
              </label>
              <select
                value={paymentForm.payment_method}
                onChange={(e) => setPaymentForm({ ...paymentForm, payment_method: e.target.value })}
                className="input-toc bg-white dark:bg-dark-700"
              >
                <option value="Espèces">Espèces</option>
                <option value="Wave">Wave</option>
                <option value="Orange Money">Orange Money</option>
                <option value="MTN MoMo">MTN MoMo</option>
                <option value="Virement Bancaire">Virement Bancaire</option>
                <option value="Chèque">Chèque</option>
              </select>
            </div>

            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Notes / Référence transaction
              </label>
              <input
                type="text"
                value={paymentForm.notes}
                onChange={(e) => setPaymentForm({ ...paymentForm, notes: e.target.value })}
                placeholder="Ex: Reçu N° 4582..."
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
