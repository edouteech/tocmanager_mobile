import React, { useState } from 'react';
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
} from 'lucide-react';
import { clientsApi } from '../../lib/api';
import { formatFCFA, formatDateTime } from '../../lib/formatters';
import { Client } from '../../types';
import { Modal } from '../../components/common/Modal';
import { useDensity } from '../../context/DensityContext';

export const ClientsPage: React.FC = () => {
  const queryClient = useQueryClient();
  const { tableClasses } = useDensity();
  const [search, setSearch] = useState('');
  const [onlyDebtors, setOnlyDebtors] = useState(false);

  // Modals state
  const [isClientModalOpen, setIsClientModalOpen] = useState(false);
  const [selectedClient, setSelectedClient] = useState<Client | null>(null);
  const [isPaymentModalOpen, setIsPaymentModalOpen] = useState(false);
  const [paymentClient, setPaymentClient] = useState<Client | null>(null);

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
    queryKey: ['clients', search, onlyDebtors],
    queryFn: () => clientsApi.getAll({ q: search || undefined, only_debtors: onlyDebtors }),
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
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['clients'] });
      setIsPaymentModalOpen(false);
      setPaymentClient(null);
      setPaymentForm({ amount: 0, payment_method: 'Espèces', notes: '' });
    },
  });

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

  // KPIs
  const totalReceivables = clients.reduce((sum, c) => sum + (c.balance > 0 ? c.balance : 0), 0);
  const debtorsCount = clients.filter((c) => c.balance > 0).length;

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Top Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-slate-900 dark:text-white tracking-tight">Clients & Créances</h1>
          <p className="text-xs sm:text-sm text-slate-500 dark:text-slate-400 mt-1">
            Gestion du répertoire clients et suivi des règlements de dettes
          </p>
        </div>
        <button
          onClick={handleOpenCreate}
          className="btn-primary"
        >
          <Plus className="w-4 h-4" />
          <span>Nouveau Client</span>
        </button>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
        <div className="card-toc card-hover p-5">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Total Créances Dues</p>
              <p className="text-2xl font-extrabold text-rose-600 dark:text-rose-400 mt-1">{formatFCFA(totalReceivables)}</p>
            </div>
            <div className="w-10 h-10 rounded-xl bg-rose-50 dark:bg-rose-950/40 text-rose-600 dark:text-rose-400 flex items-center justify-center border border-rose-100 dark:border-rose-900/50">
              <AlertCircle className="w-5 h-5" />
            </div>
          </div>
          <p className="text-xs text-slate-400 dark:text-slate-500 mt-3">{debtorsCount} client(s) avec un solde débiteur</p>
        </div>

        <div className="card-toc card-hover p-5">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Clients Débiteurs</p>
              <p className="text-2xl font-extrabold text-slate-900 dark:text-white mt-1">{debtorsCount}</p>
            </div>
            <div className="w-10 h-10 rounded-xl bg-amber-50 dark:bg-amber-950/40 text-amber-600 dark:text-amber-400 flex items-center justify-center border border-amber-100 dark:border-amber-900/50">
              <DollarSign className="w-5 h-5" />
            </div>
          </div>
          <p className="text-xs text-slate-400 dark:text-slate-500 mt-3">En attente de paiement</p>
        </div>

        <div className="card-toc card-hover p-5">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Total Répertoire</p>
              <p className="text-2xl font-extrabold text-slate-900 dark:text-white mt-1">{clients.length}</p>
            </div>
            <div className="w-10 h-10 rounded-xl bg-brand-50 dark:bg-brand-500/15 text-brand-600 dark:text-brand-400 flex items-center justify-center border border-brand-200 dark:border-brand-500/30">
              <Users className="w-5 h-5" />
            </div>
          </div>
          <p className="text-xs text-slate-400 dark:text-slate-500 mt-3">Comptes clients enregistrés</p>
        </div>
      </div>

      {/* Filter Bar */}
      <div className="card-toc p-4 flex flex-col sm:flex-row gap-4 items-center justify-between">
        <div className="relative w-full sm:w-80">
          <Search className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
          <input
            type="text"
            placeholder="Rechercher nom, téléphone, email..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="input-toc pl-10"
          />
        </div>

        <label className="flex items-center gap-2 cursor-pointer select-none text-xs font-semibold text-slate-600 dark:text-slate-300">
          <input
            type="checkbox"
            checked={onlyDebtors}
            onChange={(e) => setOnlyDebtors(e.target.checked)}
            className="rounded border-slate-300 dark:border-dark-600 text-brand-500 focus:ring-brand-500 h-4 w-4"
          />
          <span>Afficher uniquement les créances &gt; 0</span>
        </label>
      </div>

      {/* Clients Table with Density */}
      <div className="card-toc overflow-hidden">
        {isLoading ? (
          <div className="p-12 text-center text-slate-400 text-sm">Chargement des clients...</div>
        ) : clients.length === 0 ? (
          <div className="p-12 text-center text-slate-400 text-sm">
            Aucun client trouvé pour ces critères de recherche.
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left">
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
                {clients.map((c) => {
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
                          <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-bold bg-rose-50 dark:bg-rose-950/40 text-rose-700 dark:text-rose-400 border border-rose-200 dark:border-rose-900/50">
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
        )}
      </div>

      {/* Modal Création / Modification Client */}
      <Modal
        isOpen={isClientModalOpen}
        onClose={() => setIsClientModalOpen(false)}
        title={selectedClient ? 'Modifier le Client' : 'Nouveau Client'}
        subtitle="Renseignez les coordonnées et le solde éventuel"
        footer={
          <>
            <button
              type="button"
              onClick={() => setIsClientModalOpen(false)}
              className="btn-secondary"
            >
              Annuler
            </button>
            <button
              type="button"
              onClick={handleClientSubmit}
              disabled={createMutation.isPending || updateMutation.isPending}
              className="btn-primary"
            >
              {selectedClient ? 'Enregistrer' : 'Créer le client'}
            </button>
          </>
        }
      >
        <form onSubmit={handleClientSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Nom Complet / Raison Sociale *
            </label>
            <input
              type="text"
              required
              placeholder="Ex: Jean Dupont ou Boutique ABC"
              value={clientForm.name}
              onChange={(e) => setClientForm({ ...clientForm, name: e.target.value })}
              className="input-toc"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Téléphone
              </label>
              <input
                type="text"
                placeholder="+228 90 00 00 00"
                value={clientForm.phone}
                onChange={(e) => setClientForm({ ...clientForm, phone: e.target.value })}
                className="input-toc"
              />
            </div>
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Email
              </label>
              <input
                type="email"
                placeholder="client@mail.com"
                value={clientForm.email}
                onChange={(e) => setClientForm({ ...clientForm, email: e.target.value })}
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
              placeholder="Quartier, Ville"
              value={clientForm.address}
              onChange={(e) => setClientForm({ ...clientForm, address: e.target.value })}
              className="input-toc"
            />
          </div>

          {!selectedClient && (
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Solde Débiteur Initial (Créance antérieure)
              </label>
              <input
                type="number"
                min="0"
                step="100"
                placeholder="0"
                value={clientForm.balance}
                onChange={(e) => setClientForm({ ...clientForm, balance: parseFloat(e.target.value) || 0 })}
                className="input-toc font-mono font-bold"
              />
            </div>
          )}

          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Notes
            </label>
            <textarea
              rows={2}
              placeholder="Remarques particulières..."
              value={clientForm.notes}
              onChange={(e) => setClientForm({ ...clientForm, notes: e.target.value })}
              className="input-toc"
            ></textarea>
          </div>
        </form>
      </Modal>

      {/* Modal Règlement Créance */}
      <Modal
        isOpen={isPaymentModalOpen && !!paymentClient}
        onClose={() => setIsPaymentModalOpen(false)}
        title={
          <div className="flex items-center gap-2 text-emerald-600 dark:text-emerald-400">
            <CreditCard className="w-5 h-5" />
            <span>Règlement de Créance</span>
          </div>
        }
        subtitle="Enregistrez un encaissement pour solder la dette du client"
        footer={
          <>
            <button
              type="button"
              onClick={() => setIsPaymentModalOpen(false)}
              className="btn-secondary"
            >
              Annuler
            </button>
            <button
              type="button"
              onClick={handlePaymentSubmit}
              disabled={paymentMutation.isPending || paymentForm.amount <= 0}
              className="inline-flex items-center justify-center gap-2 px-4 py-2.5 bg-emerald-600 hover:bg-emerald-700 active:scale-[0.99] text-white rounded-xl text-sm font-bold shadow-sm transition disabled:opacity-50"
            >
              Valider le règlement
            </button>
          </>
        }
      >
        {paymentClient && (
          <form onSubmit={handlePaymentSubmit} className="space-y-4">
            <div className="bg-[#F5FAFD] dark:bg-dark-700/60 p-3.5 rounded-2xl border border-[#E8EFF5] dark:border-dark-600">
              <div className="text-xs text-slate-400 font-medium">Client</div>
              <div className="font-bold text-slate-900 dark:text-white text-base">{paymentClient.name}</div>
              <div className="flex justify-between items-center mt-2 pt-2 border-t border-[#E8EFF5] dark:border-dark-600 text-xs">
                <span className="text-slate-500 dark:text-slate-400">Créance totale due :</span>
                <span className="font-extrabold text-rose-600 dark:text-rose-400 font-mono">{formatFCFA(paymentClient.balance)}</span>
              </div>
            </div>

            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Montant réglé *
              </label>
              <div className="relative">
                <input
                  type="number"
                  required
                  min="1"
                  max={paymentClient.balance}
                  value={paymentForm.amount}
                  onChange={(e) => setPaymentForm({ ...paymentForm, amount: parseFloat(e.target.value) || 0 })}
                  className="input-toc pr-20 font-mono font-bold"
                />
                <button
                  type="button"
                  onClick={() => setPaymentForm({ ...paymentForm, amount: paymentClient.balance })}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-xs font-bold text-brand-600 dark:text-brand-400 hover:underline"
                >
                  Totalité
                </button>
              </div>
              <div className="text-xs text-slate-500 dark:text-slate-400 mt-1.5 flex justify-between">
                <span>Nouveau solde après règlement :</span>
                <span className="font-bold text-slate-700 dark:text-slate-200 font-mono">
                  {formatFCFA(Math.max(0, paymentClient.balance - paymentForm.amount))}
                </span>
              </div>
            </div>

            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Moyen de paiement *
              </label>
              <select
                value={paymentForm.payment_method}
                onChange={(e) => setPaymentForm({ ...paymentForm, payment_method: e.target.value })}
                className="input-toc bg-white dark:bg-dark-700"
              >
                <option value="Espèces">Espèces</option>
                <option value="Mobile Money">Mobile Money (T-Money / Moov Money)</option>
                <option value="Virement">Virement bancaire</option>
                <option value="Chèque">Chèque</option>
              </select>
            </div>

            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Référence / Notes
              </label>
              <input
                type="text"
                value={paymentForm.notes}
                onChange={(e) => setPaymentForm({ ...paymentForm, notes: e.target.value })}
                placeholder="Ex: Réf reçu ou transaction..."
                className="input-toc"
              />
            </div>
          </form>
        )}
      </Modal>
    </div>
  );
};
