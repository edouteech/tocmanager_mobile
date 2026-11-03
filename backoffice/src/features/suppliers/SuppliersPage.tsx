import React, { useState } from 'react';
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
  X,
  CreditCard,
  Edit2,
  Trash2,
} from 'lucide-react';
import { suppliersApi } from '../../lib/api';
import { formatFCFA, formatDateTime } from '../../lib/formatters';
import { Supplier } from '../../types';

export const SuppliersPage: React.FC = () => {
  const queryClient = useQueryClient();
  const [search, setSearch] = useState('');
  const [onlyCreditors, setOnlyCreditors] = useState(false);

  // Modals state
  const [isSupplierModalOpen, setIsSupplierModalOpen] = useState(false);
  const [selectedSupplier, setSelectedSupplier] = useState<Supplier | null>(null);
  const [isPaymentModalOpen, setIsPaymentModalOpen] = useState(false);
  const [paymentSupplier, setPaymentSupplier] = useState<Supplier | null>(null);

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
    queryKey: ['suppliers', search, onlyCreditors],
    queryFn: () => suppliersApi.getAll({ q: search || undefined, only_creditors: onlyCreditors }),
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
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['suppliers'] });
      setIsPaymentModalOpen(false);
      setPaymentSupplier(null);
      setPaymentForm({ amount: 0, payment_method: 'Espèces', notes: '' });
    },
  });

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
      notes: `Paiement facture fournisseur ${s.name}`,
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

  // KPIs
  const totalPayables = suppliers.reduce((sum, s) => sum + (s.balance > 0 ? s.balance : 0), 0);
  const creditorsCount = suppliers.filter((s) => s.balance > 0).length;

  return (
    <div className="space-y-6">
      {/* Top Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Fournisseurs & Dettes</h1>
          <p className="text-sm text-slate-500">
            Gestion des partenaires d'approvisionnement et suivi des règlements fournisseurs
          </p>
        </div>
        <button
          onClick={handleOpenCreate}
          className="inline-flex items-center gap-2 px-4 py-2.5 bg-indigo-600 text-white rounded-lg text-sm font-medium hover:bg-indigo-700 transition shadow-sm"
        >
          <Plus className="w-4 h-4" />
          <span>Nouveau Fournisseur</span>
        </button>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-medium text-slate-500 uppercase tracking-wider">Total Dettes Fournisseurs</p>
              <p className="text-2xl font-bold text-amber-600 mt-1">{formatFCFA(totalPayables)}</p>
            </div>
            <div className="w-10 h-10 rounded-lg bg-amber-50 text-amber-600 flex items-center justify-center">
              <AlertCircle className="w-5 h-5" />
            </div>
          </div>
          <p className="text-xs text-slate-400 mt-3">{creditorsCount} fournisseur(s) en attente de paiement</p>
        </div>

        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-medium text-slate-500 uppercase tracking-wider">Factures en Instance</p>
              <p className="text-2xl font-bold text-slate-900 mt-1">{creditorsCount}</p>
            </div>
            <div className="w-10 h-10 rounded-lg bg-rose-50 text-rose-600 flex items-center justify-center">
              <DollarSign className="w-5 h-5" />
            </div>
          </div>
          <p className="text-xs text-slate-400 mt-3">À régler pour approvisionnements</p>
        </div>

        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-medium text-slate-500 uppercase tracking-wider">Total Fournisseurs</p>
              <p className="text-2xl font-bold text-slate-900 mt-1">{suppliers.length}</p>
            </div>
            <div className="w-10 h-10 rounded-lg bg-indigo-50 text-indigo-600 flex items-center justify-center">
              <Truck className="w-5 h-5" />
            </div>
          </div>
          <p className="text-xs text-slate-400 mt-3">Partenaires actifs</p>
        </div>
      </div>

      {/* Filter Bar */}
      <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm flex flex-col sm:flex-row gap-4 items-center justify-between">
        <div className="relative w-full sm:w-80">
          <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
          <input
            type="text"
            placeholder="Rechercher nom, contact, tél..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-9 pr-4 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500"
          />
        </div>

        <label className="flex items-center gap-2 cursor-pointer select-none text-sm text-slate-600">
          <input
            type="checkbox"
            checked={onlyCreditors}
            onChange={(e) => setOnlyCreditors(e.target.checked)}
            className="rounded border-slate-300 text-indigo-600 focus:ring-indigo-500 h-4 w-4"
          />
          <span className="font-medium">Afficher uniquement les dettes &gt; 0</span>
        </label>
      </div>

      {/* Table */}
      <div className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
        {isLoading ? (
          <div className="p-12 text-center text-slate-400 text-sm">Chargement des fournisseurs...</div>
        ) : suppliers.length === 0 ? (
          <div className="p-12 text-center text-slate-400 text-sm">
            Aucun fournisseur trouvé pour ces critères de recherche.
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead className="bg-slate-50 border-b border-slate-200 text-xs font-semibold uppercase text-slate-500">
                <tr>
                  <th className="px-6 py-3.5">Fournisseur</th>
                  <th className="px-6 py-3.5">Contact</th>
                  <th className="px-6 py-3.5">Adresse / Notes</th>
                  <th className="px-6 py-3.5 text-right">Dette à Payer</th>
                  <th className="px-6 py-3.5 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {suppliers.map((s) => {
                  const hasDebt = s.balance > 0;
                  return (
                    <tr key={s.sync_id} className="hover:bg-slate-50/80 transition-colors">
                      <td className="px-6 py-4">
                        <div className="font-semibold text-slate-900">{s.name}</div>
                        {s.contact_person && (
                          <div className="text-xs text-slate-500 mt-0.5">
                            Contact : {s.contact_person}
                          </div>
                        )}
                      </td>
                      <td className="px-6 py-4 text-slate-600">
                        {s.phone ? (
                          <div className="flex items-center gap-1.5">
                            <Phone className="w-3.5 h-3.5 text-slate-400" />
                            <span>{s.phone}</span>
                          </div>
                        ) : (
                          <span className="text-slate-400 text-xs">Aucun tél.</span>
                        )}
                        {s.email && (
                          <div className="flex items-center gap-1.5 text-xs text-slate-500 mt-0.5">
                            <Mail className="w-3 h-3 text-slate-400" />
                            <span>{s.email}</span>
                          </div>
                        )}
                      </td>
                      <td className="px-6 py-4 text-slate-600">
                        {s.address && (
                          <div className="flex items-center gap-1.5 text-xs text-slate-600">
                            <MapPin className="w-3 h-3 text-slate-400" />
                            <span>{s.address}</span>
                          </div>
                        )}
                        {s.notes && <div className="text-xs text-slate-400 italic mt-0.5">{s.notes}</div>}
                        {!s.address && !s.notes && <span className="text-slate-400 text-xs">-</span>}
                      </td>
                      <td className="px-6 py-4 text-right">
                        {hasDebt ? (
                          <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold bg-amber-50 text-amber-700 border border-amber-200">
                            <AlertCircle className="w-3 h-3" />
                            {formatFCFA(s.balance)}
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-medium bg-emerald-50 text-emerald-700">
                            <CheckCircle2 className="w-3 h-3" />
                            Soldé (0 F)
                          </span>
                        )}
                      </td>
                      <td className="px-6 py-4 text-right">
                        <div className="flex items-center justify-end gap-2">
                          {hasDebt && (
                            <button
                              onClick={() => handleOpenPayment(s)}
                              className="px-2.5 py-1 bg-amber-600 hover:bg-amber-700 text-white rounded text-xs font-medium transition shadow-xs"
                              title="Payer le fournisseur"
                            >
                              Payer
                            </button>
                          )}
                          <button
                            onClick={() => handleOpenEdit(s)}
                            className="p-1.5 text-slate-500 hover:text-indigo-600 hover:bg-indigo-50 rounded transition"
                            title="Modifier"
                          >
                            <Edit2 className="w-4 h-4" />
                          </button>
                          <button
                            onClick={() => handleDelete(s)}
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

      {/* Modal Création / Modification Fournisseur */}
      {isSupplierModalOpen && (
        <div className="fixed inset-0 z-50 bg-slate-900/40 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-xl shadow-xl border border-slate-200 w-full max-w-md overflow-hidden animate-in fade-in zoom-in-95 duration-150">
            <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between">
              <h2 className="text-base font-bold text-slate-900">
                {selectedSupplier ? 'Modifier le Fournisseur' : 'Nouveau Fournisseur'}
              </h2>
              <button
                onClick={() => setIsSupplierModalOpen(false)}
                className="text-slate-400 hover:text-slate-600"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSupplierSubmit} className="p-6 space-y-4">
              <div>
                <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">
                  Raison Sociale / Nom Entreprise *
                </label>
                <input
                  type="text"
                  required
                  placeholder="Ex: Distributeur Boissons SARL"
                  value={supplierForm.name}
                  onChange={(e) => setSupplierForm({ ...supplierForm, name: e.target.value })}
                  className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">
                  Personne de contact / Commercial
                </label>
                <input
                  type="text"
                  placeholder="Ex: M. Jean Directeur Commercial"
                  value={supplierForm.contact_person}
                  onChange={(e) => setSupplierForm({ ...supplierForm, contact_person: e.target.value })}
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
                    value={supplierForm.phone}
                    onChange={(e) => setSupplierForm({ ...supplierForm, phone: e.target.value })}
                    className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">
                    Email
                  </label>
                  <input
                    type="email"
                    placeholder="contact@fournisseur.com"
                    value={supplierForm.email}
                    onChange={(e) => setSupplierForm({ ...supplierForm, email: e.target.value })}
                    className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">
                  Adresse / Entrepôt
                </label>
                <input
                  type="text"
                  placeholder="Zone Industrielle, Ville"
                  value={supplierForm.address}
                  onChange={(e) => setSupplierForm({ ...supplierForm, address: e.target.value })}
                  className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500"
                />
              </div>

              {!selectedSupplier && (
                <div>
                  <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">
                    Dette initiale envers ce fournisseur
                  </label>
                  <input
                    type="number"
                    min="0"
                    step="100"
                    placeholder="0"
                    value={supplierForm.balance}
                    onChange={(e) => setSupplierForm({ ...supplierForm, balance: parseFloat(e.target.value) || 0 })}
                    className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500"
                  />
                </div>
              )}

              <div>
                <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">
                  Conditions / Notes
                </label>
                <textarea
                  rows={2}
                  placeholder="Délais de paiement, RIB, etc."
                  value={supplierForm.notes}
                  onChange={(e) => setSupplierForm({ ...supplierForm, notes: e.target.value })}
                  className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500"
                ></textarea>
              </div>

              <div className="pt-2 flex justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setIsSupplierModalOpen(false)}
                  className="px-4 py-2 border border-slate-200 rounded-lg text-sm font-medium text-slate-600 hover:bg-slate-50 transition"
                >
                  Annuler
                </button>
                <button
                  type="submit"
                  disabled={createMutation.isPending || updateMutation.isPending}
                  className="px-4 py-2 bg-indigo-600 text-white rounded-lg text-sm font-medium hover:bg-indigo-700 transition disabled:opacity-50"
                >
                  {selectedSupplier ? 'Enregistrer' : 'Créer le fournisseur'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Modal Paiement Fournisseur */}
      {isPaymentModalOpen && paymentSupplier && (
        <div className="fixed inset-0 z-50 bg-slate-900/40 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-xl shadow-xl border border-slate-200 w-full max-w-md overflow-hidden animate-in fade-in zoom-in-95 duration-150">
            <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between">
              <div className="flex items-center gap-2 text-amber-600 font-bold">
                <CreditCard className="w-5 h-5" />
                <h2 className="text-base text-slate-900">Règlement Facture Fournisseur</h2>
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
                <div className="text-xs text-slate-500 font-medium">Fournisseur</div>
                <div className="font-bold text-slate-900 text-base">{paymentSupplier.name}</div>
                <div className="flex justify-between items-center mt-2 pt-2 border-t border-slate-200 text-xs">
                  <span className="text-slate-500">Dette totale en cours :</span>
                  <span className="font-bold text-amber-600">{formatFCFA(paymentSupplier.balance)}</span>
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">
                  Montant payé *
                </label>
                <div className="relative">
                  <input
                    type="number"
                    required
                    min="1"
                    max={paymentSupplier.balance}
                    value={paymentForm.amount}
                    onChange={(e) => setPaymentForm({ ...paymentForm, amount: parseFloat(e.target.value) || 0 })}
                    className="w-full pl-3 pr-16 py-2 border border-slate-200 rounded-lg text-sm font-semibold text-slate-900 focus:outline-none focus:ring-2 focus:ring-amber-500/20 focus:border-amber-500"
                  />
                  <button
                    type="button"
                    onClick={() => setPaymentForm({ ...paymentForm, amount: paymentSupplier.balance })}
                    className="absolute right-2 top-1/2 -translate-y-1/2 text-xs font-semibold text-indigo-600 hover:text-indigo-800"
                  >
                    Totalité
                  </button>
                </div>
                <div className="text-xs text-slate-500 mt-1 flex justify-between">
                  <span>Reste dû après paiement :</span>
                  <span className="font-bold text-slate-700">
                    {formatFCFA(Math.max(0, paymentSupplier.balance - paymentForm.amount))}
                  </span>
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">
                  Moyen de règlement *
                </label>
                <select
                  value={paymentForm.payment_method}
                  onChange={(e) => setPaymentForm({ ...paymentForm, payment_method: e.target.value })}
                  className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-amber-500/20 focus:border-amber-500 bg-white"
                >
                  <option value="Espèces">Espèces</option>
                  <option value="Virement">Virement bancaire</option>
                  <option value="Chèque">Chèque</option>
                  <option value="Mobile Money">Mobile Money</option>
                </select>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">
                  Référence du paiement / Chèque / Virement
                </label>
                <input
                  type="text"
                  value={paymentForm.notes}
                  onChange={(e) => setPaymentForm({ ...paymentForm, notes: e.target.value })}
                  placeholder="Ex: Réf virement ou n° chèque..."
                  className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-amber-500/20 focus:border-amber-500"
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
                  className="px-4 py-2 bg-amber-600 text-white rounded-lg text-sm font-medium hover:bg-amber-700 transition disabled:opacity-50"
                >
                  Valider le paiement
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
