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
  X,
  CreditCard,
  Edit2,
  Trash2,
} from 'lucide-react';
import { clientsApi } from '../../lib/api';
import { formatFCFA, formatDateTime } from '../../lib/formatters';
import { Client } from '../../types';

export const ClientsPage: React.FC = () => {
  const queryClient = useQueryClient();
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
    <div className="space-y-6">
      {/* Top Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Clients & Créances</h1>
          <p className="text-sm text-slate-500">
            Gestion du répertoire clients et suivi des règlements de dettes
          </p>
        </div>
        <button
          onClick={handleOpenCreate}
          className="inline-flex items-center gap-2 px-4 py-2.5 bg-indigo-600 text-white rounded-lg text-sm font-medium hover:bg-indigo-700 transition shadow-sm"
        >
          <Plus className="w-4 h-4" />
          <span>Nouveau Client</span>
        </button>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-medium text-slate-500 uppercase tracking-wider">Total Créances Dues</p>
              <p className="text-2xl font-bold text-rose-600 mt-1">{formatFCFA(totalReceivables)}</p>
            </div>
            <div className="w-10 h-10 rounded-lg bg-rose-50 text-rose-600 flex items-center justify-center">
              <AlertCircle className="w-5 h-5" />
            </div>
          </div>
          <p className="text-xs text-slate-400 mt-3">{debtorsCount} client(s) avec un solde débiteur</p>
        </div>

        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-medium text-slate-500 uppercase tracking-wider">Clients Débiteurs</p>
              <p className="text-2xl font-bold text-slate-900 mt-1">{debtorsCount}</p>
            </div>
            <div className="w-10 h-10 rounded-lg bg-amber-50 text-amber-600 flex items-center justify-center">
              <DollarSign className="w-5 h-5" />
            </div>
          </div>
          <p className="text-xs text-slate-400 mt-3">En attente de paiement</p>
        </div>

        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-medium text-slate-500 uppercase tracking-wider">Total Répertoire</p>
              <p className="text-2xl font-bold text-slate-900 mt-1">{clients.length}</p>
            </div>
            <div className="w-10 h-10 rounded-lg bg-indigo-50 text-indigo-600 flex items-center justify-center">
              <Users className="w-5 h-5" />
            </div>
          </div>
          <p className="text-xs text-slate-400 mt-3">Comptes clients enregistrés</p>
        </div>
      </div>

      {/* Filter Bar */}
      <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm flex flex-col sm:flex-row gap-4 items-center justify-between">
        <div className="relative w-full sm:w-80">
          <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
          <input
            type="text"
            placeholder="Rechercher nom, téléphone, email..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-9 pr-4 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500"
          />
        </div>

        <label className="flex items-center gap-2 cursor-pointer select-none text-sm text-slate-600">
          <input
            type="checkbox"
            checked={onlyDebtors}
            onChange={(e) => setOnlyDebtors(e.target.checked)}
            className="rounded border-slate-300 text-indigo-600 focus:ring-indigo-500 h-4 w-4"
          />
          <span className="font-medium">Afficher uniquement les créances &gt; 0</span>
        </label>
      </div>

      {/* Clients Table */}
      <div className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
        {isLoading ? (
          <div className="p-12 text-center text-slate-400 text-sm">Chargement des clients...</div>
        ) : clients.length === 0 ? (
          <div className="p-12 text-center text-slate-400 text-sm">
            Aucun client trouvé pour ces critères de recherche.
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead className="bg-slate-50 border-b border-slate-200 text-xs font-semibold uppercase text-slate-500">
                <tr>
                  <th className="px-6 py-3.5">Client</th>
                  <th className="px-6 py-3.5">Contact</th>
                  <th className="px-6 py-3.5">Adresse / Notes</th>
                  <th className="px-6 py-3.5 text-right">Solde Dû</th>
                  <th className="px-6 py-3.5 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {clients.map((c) => {
                  const hasDebt = c.balance > 0;
                  return (
                    <tr key={c.sync_id} className="hover:bg-slate-50/80 transition-colors">
                      <td className="px-6 py-4">
                        <div className="font-semibold text-slate-900">{c.name}</div>
                        <div className="text-xs text-slate-400 mt-0.5">
                          Enregistré le {formatDateTime(c.created_at)}
                        </div>
                      </td>
                      <td className="px-6 py-4 text-slate-600">
                        {c.phone ? (
                          <div className="flex items-center gap-1.5">
                            <Phone className="w-3.5 h-3.5 text-slate-400" />
                            <span>{c.phone}</span>
                          </div>
                        ) : (
                          <span className="text-slate-400 text-xs">Aucun tél.</span>
                        )}
                        {c.email && <div className="text-xs text-slate-500 mt-0.5">{c.email}</div>}
                      </td>
                      <td className="px-6 py-4 text-slate-600">
                        {c.address && (
                          <div className="flex items-center gap-1.5 text-xs text-slate-600">
                            <MapPin className="w-3 h-3 text-slate-400" />
                            <span>{c.address}</span>
                          </div>
                        )}
                        {c.notes && <div className="text-xs text-slate-400 italic mt-0.5">{c.notes}</div>}
                        {!c.address && !c.notes && <span className="text-slate-400 text-xs">-</span>}
                      </td>
                      <td className="px-6 py-4 text-right">
                        {hasDebt ? (
                          <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold bg-rose-50 text-rose-700 border border-rose-200">
                            <AlertCircle className="w-3 h-3" />
                            {formatFCFA(c.balance)}
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-emerald-50 text-emerald-700">
                            <CheckCircle2 className="w-3 h-3" />
                            À jour (0 F)
                          </span>
                        )}
                      </td>
                      <td className="px-6 py-4 text-right">
                        <div className="flex items-center justify-end gap-2">
                          {hasDebt && (
                            <button
                              onClick={() => handleOpenPayment(c)}
                              className="px-2.5 py-1 bg-emerald-600 hover:bg-emerald-700 text-white rounded text-xs font-medium transition shadow-xs"
                              title="Enregistrer un règlement"
                            >
                              Régler
                            </button>
                          )}
                          <button
                            onClick={() => handleOpenEdit(c)}
                            className="p-1.5 text-slate-500 hover:text-indigo-600 hover:bg-indigo-50 rounded transition"
                            title="Modifier"
                          >
                            <Edit2 className="w-4 h-4" />
                          </button>
                          <button
                            onClick={() => handleDelete(c)}
                            className="p-1.5 text-slate-400 hover:text-rose-600 hover:bg-rose-50 rounded transition"
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
      {isClientModalOpen && (
        <div className="fixed inset-0 z-50 bg-slate-900/40 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-xl shadow-xl border border-slate-200 w-full max-w-md overflow-hidden animate-in fade-in zoom-in-95 duration-150">
            <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between">
              <h2 className="text-base font-bold text-slate-900">
                {selectedClient ? 'Modifier le Client' : 'Nouveau Client'}
              </h2>
              <button
                onClick={() => setIsClientModalOpen(false)}
                className="text-slate-400 hover:text-slate-600"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleClientSubmit} className="p-6 space-y-4">
              <div>
                <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">
                  Nom Complet / Raison Sociale *
                </label>
                <input
                  type="text"
                  required
                  placeholder="Ex: Jean Dupont ou Boutique ABC"
                  value={clientForm.name}
                  onChange={(e) => setClientForm({ ...clientForm, name: e.target.value })}
                  className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">
                    Téléphone
                  </label>
                  <input
                    type="text"
                    placeholder="+228 90 00 00 00"
                    value={clientForm.phone}
                    onChange={(e) => setClientForm({ ...clientForm, phone: e.target.value })}
                    className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">
                    Email
                  </label>
                  <input
                    type="email"
                    placeholder="client@mail.com"
                    value={clientForm.email}
                    onChange={(e) => setClientForm({ ...clientForm, email: e.target.value })}
                    className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">
                  Adresse physique
                </label>
                <input
                  type="text"
                  placeholder="Quartier, Ville"
                  value={clientForm.address}
                  onChange={(e) => setClientForm({ ...clientForm, address: e.target.value })}
                  className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500"
                />
              </div>

              {!selectedClient && (
                <div>
                  <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">
                    Solde Débiteur Initial (Créance antérieure)
                  </label>
                  <input
                    type="number"
                    min="0"
                    step="100"
                    placeholder="0"
                    value={clientForm.balance}
                    onChange={(e) => setClientForm({ ...clientForm, balance: parseFloat(e.target.value) || 0 })}
                    className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500"
                  />
                </div>
              )}

              <div>
                <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">
                  Notes
                </label>
                <textarea
                  rows={2}
                  placeholder="Remarques particulières..."
                  value={clientForm.notes}
                  onChange={(e) => setClientForm({ ...clientForm, notes: e.target.value })}
                  className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500"
                ></textarea>
              </div>

              <div className="pt-2 flex justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setIsClientModalOpen(false)}
                  className="px-4 py-2 border border-slate-200 rounded-lg text-sm font-medium text-slate-600 hover:bg-slate-50 transition"
                >
                  Annuler
                </button>
                <button
                  type="submit"
                  disabled={createMutation.isPending || updateMutation.isPending}
                  className="px-4 py-2 bg-indigo-600 text-white rounded-lg text-sm font-medium hover:bg-indigo-700 transition disabled:opacity-50"
                >
                  {selectedClient ? 'Enregistrer' : 'Créer le client'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal Règlement Créance */}
      {isPaymentModalOpen && paymentClient && (
        <div className="fixed inset-0 z-50 bg-slate-900/40 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-xl shadow-xl border border-slate-200 w-full max-w-md overflow-hidden animate-in fade-in zoom-in-95 duration-150">
            <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between">
              <div className="flex items-center gap-2 text-emerald-600 font-bold">
                <CreditCard className="w-5 h-5" />
                <h2 className="text-base text-slate-900">Règlement de Créance</h2>
              </div>
              <button
                onClick={() => setIsPaymentModalOpen(false)}
                className="text-slate-400 hover:text-slate-600"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handlePaymentSubmit} className="p-6 space-y-4">
              <div className="bg-slate-50 p-3.5 rounded-lg border border-slate-100">
                <div className="text-xs text-slate-500 font-medium">Client</div>
                <div className="font-bold text-slate-900 text-base">{paymentClient.name}</div>
                <div className="flex justify-between items-center mt-2 pt-2 border-t border-slate-200 text-xs">
                  <span className="text-slate-500">Créance totale due :</span>
                  <span className="font-bold text-rose-600">{formatFCFA(paymentClient.balance)}</span>
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">
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
                    className="w-full pl-3 pr-16 py-2 border border-slate-200 rounded-lg text-sm font-semibold text-slate-900 focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                  />
                  <button
                    type="button"
                    onClick={() => setPaymentForm({ ...paymentForm, amount: paymentClient.balance })}
                    className="absolute right-2 top-1/2 -translate-y-1/2 text-xs font-semibold text-indigo-600 hover:text-indigo-800"
                  >
                    Totalité
                  </button>
                </div>
                <div className="text-xs text-slate-500 mt-1 flex justify-between">
                  <span>Nouveau solde après règlement :</span>
                  <span className="font-bold text-slate-700">
                    {formatFCFA(Math.max(0, paymentClient.balance - paymentForm.amount))}
                  </span>
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">
                  Moyen de paiement *
                </label>
                <select
                  value={paymentForm.payment_method}
                  onChange={(e) => setPaymentForm({ ...paymentForm, payment_method: e.target.value })}
                  className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500 bg-white"
                >
                  <option value="Espèces">Espèces</option>
                  <option value="Mobile Money">Mobile Money (T-Money / Moov Money)</option>
                  <option value="Virement">Virement bancaire</option>
                  <option value="Chèque">Chèque</option>
                </select>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">
                  Référence / Notes
                </label>
                <input
                  type="text"
                  value={paymentForm.notes}
                  onChange={(e) => setPaymentForm({ ...paymentForm, notes: e.target.value })}
                  placeholder="Ex: Réf reçu ou transaction..."
                  className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500/20 focus:border-emerald-500"
                />
              </div>

              <div className="pt-2 flex justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setIsPaymentModalOpen(false)}
                  className="px-4 py-2 border border-slate-200 rounded-lg text-sm font-medium text-slate-600 hover:bg-slate-50 transition"
                >
                  Annuler
                </button>
                <button
                  type="submit"
                  disabled={paymentMutation.isPending || paymentForm.amount <= 0}
                  className="px-4 py-2 bg-emerald-600 text-white rounded-lg text-sm font-medium hover:bg-emerald-700 transition disabled:opacity-50"
                >
                  Valider le règlement
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
