import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  PackagePlus,
  Plus,
  DollarSign,
  Truck,
  Layers,
  X,
  Calendar,
  CheckCircle2,
  Clock,
  UserCheck,
} from 'lucide-react';
import { approvisionnementsApi, productsApi, suppliersApi } from '../../lib/api';
import { formatFCFA, formatDateTime } from '../../lib/formatters';
import { Approvisionnement } from '../../types';

export const SuppliesPage: React.FC = () => {
  const queryClient = useQueryClient();
  const [isModalOpen, setIsModalOpen] = useState(false);

  // Form state
  const [form, setForm] = useState({
    product_sync_id: '',
    supplier_sync_id: '',
    quantity: 1,
    unit_cost: 0,
    payment_status: 'Payé',
    notes: '',
  });

  // Queries
  const { data: supplies = [], isLoading } = useQuery({
    queryKey: ['approvisionnements'],
    queryFn: () => approvisionnementsApi.getAll(),
  });

  const { data: products = [] } = useQuery({
    queryKey: ['products'],
    queryFn: () => productsApi.getAll(),
  });

  const { data: suppliers = [] } = useQuery({
    queryKey: ['suppliers'],
    queryFn: () => suppliersApi.getAll(),
  });

  // Mutation
  const createMutation = useMutation({
    mutationFn: approvisionnementsApi.create,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['approvisionnements'] });
      queryClient.invalidateQueries({ queryKey: ['products'] });
      queryClient.invalidateQueries({ queryKey: ['suppliers'] });
      setIsModalOpen(false);
      resetForm();
    },
  });

  const resetForm = () => {
    setForm({
      product_sync_id: '',
      supplier_sync_id: '',
      quantity: 1,
      unit_cost: 0,
      payment_status: 'Payé',
      notes: '',
    });
  };

  const handleProductChange = (prodSyncId: string) => {
    const selectedProd = products.find((p) => p.sync_id === prodSyncId);
    setForm((prev) => ({
      ...prev,
      product_sync_id: prodSyncId,
      unit_cost: selectedProd?.cost_price || 0,
    }));
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.product_sync_id || form.quantity <= 0) return;

    const prod = products.find((p) => p.sync_id === form.product_sync_id);
    const sup = suppliers.find((s) => s.sync_id === form.supplier_sync_id);

    createMutation.mutate({
      product_sync_id: form.product_sync_id,
      product_name: prod?.name,
      supplier_sync_id: form.supplier_sync_id || undefined,
      supplier_name: sup?.name,
      quantity: form.quantity,
      unit_cost: form.unit_cost,
      payment_status: form.payment_status,
      notes: form.notes || undefined,
    });
  };

  // KPIs
  const totalSupplyCost = supplies.reduce((sum, s) => sum + s.total_cost, 0);
  const totalQuantity = supplies.reduce((sum, s) => sum + s.quantity, 0);

  return (
    <div className="space-y-6">
      {/* Top Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 tracking-tight">
            Approvisionnements & Stocks
          </h1>
          <p className="text-sm text-slate-500">
            Journal des réceptions de marchandises et réapprovisionnements du magasin
          </p>
        </div>
        <button
          onClick={() => {
            resetForm();
            setIsModalOpen(true);
          }}
          className="inline-flex items-center gap-2 px-4 py-2.5 bg-indigo-600 text-white rounded-lg text-sm font-medium hover:bg-indigo-700 transition shadow-sm"
        >
          <Plus className="w-4 h-4" />
          <span>Nouvelle Réception</span>
        </button>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-medium text-slate-500 uppercase tracking-wider">Valeur des Achats Reçus</p>
              <p className="text-2xl font-bold text-slate-900 mt-1">{formatFCFA(totalSupplyCost)}</p>
            </div>
            <div className="w-10 h-10 rounded-lg bg-indigo-50 text-indigo-600 flex items-center justify-center">
              <DollarSign className="w-5 h-5" />
            </div>
          </div>
          <p className="text-xs text-slate-400 mt-3">Investissement d'approvisionnement</p>
        </div>

        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-medium text-slate-500 uppercase tracking-wider">Quantités Totales Reçues</p>
              <p className="text-2xl font-bold text-slate-900 mt-1">{totalQuantity}</p>
            </div>
            <div className="w-10 h-10 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center">
              <Layers className="w-5 h-5" />
            </div>
          </div>
          <p className="text-xs text-slate-400 mt-3">Unités réceptionnées en stock</p>
        </div>

        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-medium text-slate-500 uppercase tracking-wider">Bons de Réception</p>
              <p className="text-2xl font-bold text-slate-900 mt-1">{supplies.length}</p>
            </div>
            <div className="w-10 h-10 rounded-lg bg-amber-50 text-amber-600 flex items-center justify-center">
              <PackagePlus className="w-5 h-5" />
            </div>
          </div>
          <p className="text-xs text-slate-400 mt-3">Opérations d'entrée répertoriées</p>
        </div>
      </div>

      {/* Table */}
      <div className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
        {isLoading ? (
          <div className="p-12 text-center text-slate-400 text-sm">Chargement des réceptions...</div>
        ) : supplies.length === 0 ? (
          <div className="p-12 text-center text-slate-400 text-sm">
            Aucun approvisionnement enregistré pour le moment.
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead className="bg-slate-50 border-b border-slate-200 text-xs font-semibold uppercase text-slate-500">
                <tr>
                  <th className="px-6 py-3.5">Date & Heure</th>
                  <th className="px-6 py-3.5">Article Réceptionné</th>
                  <th className="px-6 py-3.5">Fournisseur</th>
                  <th className="px-6 py-3.5 text-center">Quantité</th>
                  <th className="px-6 py-3.5 text-right">Coût Unitaire</th>
                  <th className="px-6 py-3.5 text-right">Total Achat</th>
                  <th className="px-6 py-3.5 text-center">Paiement</th>
                  <th className="px-6 py-3.5">Opérateur</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {supplies.map((s) => {
                  const isPaid = s.payment_status === 'Payé';
                  return (
                    <tr key={s.sync_id} className="hover:bg-slate-50/80 transition-colors">
                      <td className="px-6 py-4 text-slate-600 text-xs">
                        <div className="flex items-center gap-1.5 font-medium text-slate-900">
                          <Calendar className="w-3.5 h-3.5 text-slate-400" />
                          <span>{formatDateTime(s.date || s.created_at)}</span>
                        </div>
                        {s.notes && <div className="text-slate-400 italic mt-0.5">{s.notes}</div>}
                      </td>
                      <td className="px-6 py-4 font-semibold text-slate-900">
                        {s.product_name}
                      </td>
                      <td className="px-6 py-4 text-slate-600">
                        {s.supplier_name ? (
                          <div className="flex items-center gap-1.5">
                            <Truck className="w-3.5 h-3.5 text-slate-400" />
                            <span>{s.supplier_name}</span>
                          </div>
                        ) : (
                          <span className="text-slate-400 text-xs">Non spécifié</span>
                        )}
                      </td>
                      <td className="px-6 py-4 text-center">
                        <span className="inline-block px-2.5 py-0.5 rounded-full text-xs font-bold bg-indigo-50 text-indigo-700">
                          +{s.quantity}
                        </span>
                      </td>
                      <td className="px-6 py-4 text-right text-slate-600 font-mono">
                        {formatFCFA(s.unit_cost)}
                      </td>
                      <td className="px-6 py-4 text-right font-bold text-slate-900 font-mono">
                        {formatFCFA(s.total_cost)}
                      </td>
                      <td className="px-6 py-4 text-center">
                        {isPaid ? (
                          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-medium bg-emerald-50 text-emerald-700">
                            <CheckCircle2 className="w-3 h-3" />
                            Payé
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-amber-50 text-amber-700 border border-amber-200">
                            <Clock className="w-3 h-3" />
                            À crédit
                          </span>
                        )}
                      </td>
                      <td className="px-6 py-4 text-xs text-slate-500">
                        <div className="flex items-center gap-1">
                          <UserCheck className="w-3 h-3 text-slate-400" />
                          <span>{s.user_name || 'Système'}</span>
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

      {/* Modal Nouvelle Entrée de Stock */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 bg-slate-900/40 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-xl shadow-xl border border-slate-200 w-full max-w-lg overflow-hidden animate-in fade-in zoom-in-95 duration-150">
            <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between">
              <div className="flex items-center gap-2 text-indigo-600 font-bold">
                <PackagePlus className="w-5 h-5" />
                <h2 className="text-base text-slate-900">Enregistrer une Réception de Stock</h2>
              </div>
              <button
                onClick={() => setIsModalOpen(false)}
                className="text-slate-400 hover:text-slate-600"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSubmit} className="p-6 space-y-4">
              <div>
                <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">
                  Article / Produit à réapprovisionner *
                </label>
                <select
                  required
                  value={form.product_sync_id}
                  onChange={(e) => handleProductChange(e.target.value)}
                  className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 bg-white"
                >
                  <option value="">Sélectionner un produit...</option>
                  {products.map((p) => (
                    <option key={p.sync_id} value={p.sync_id}>
                      {p.name} (Stock actuel : {p.stock} {p.unit || 'pce'})
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">
                  Fournisseur partenaire
                </label>
                <select
                  value={form.supplier_sync_id}
                  onChange={(e) => setForm({ ...form, supplier_sync_id: e.target.value })}
                  className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 bg-white"
                >
                  <option value="">Sélectionner un fournisseur (optionnel)...</option>
                  {suppliers.map((s) => (
                    <option key={s.sync_id} value={s.sync_id}>
                      {s.name}
                    </option>
                  ))}
                </select>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">
                    Quantité reçue *
                  </label>
                  <input
                    type="number"
                    required
                    min="1"
                    step="1"
                    value={form.quantity}
                    onChange={(e) => setForm({ ...form, quantity: parseFloat(e.target.value) || 0 })}
                    className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">
                    Prix d'achat unitaire (F) *
                  </label>
                  <input
                    type="number"
                    required
                    min="0"
                    step="50"
                    value={form.unit_cost}
                    onChange={(e) => setForm({ ...form, unit_cost: parseFloat(e.target.value) || 0 })}
                    className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500"
                  />
                </div>
              </div>

              <div className="bg-slate-50 p-3 rounded-lg flex items-center justify-between text-sm">
                <span className="text-slate-600 font-medium">Montant total de la livraison :</span>
                <span className="font-bold text-indigo-700 text-base">
                  {formatFCFA(form.quantity * form.unit_cost)}
                </span>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">
                  Modalité de règlement *
                </label>
                <div className="grid grid-cols-2 gap-3">
                  <label
                    className={`flex items-center gap-2 p-3 border rounded-lg cursor-pointer text-sm font-medium transition ${
                      form.payment_status === 'Payé'
                        ? 'border-emerald-500 bg-emerald-50 text-emerald-800'
                        : 'border-slate-200 bg-white text-slate-600'
                    }`}
                  >
                    <input
                      type="radio"
                      name="payment_status"
                      value="Payé"
                      checked={form.payment_status === 'Payé'}
                      onChange={() => setForm({ ...form, payment_status: 'Payé' })}
                      className="sr-only"
                    />
                    <CheckCircle2 className="w-4 h-4 text-emerald-600" />
                    <span>Payé (Comptant)</span>
                  </label>

                  <label
                    className={`flex items-center gap-2 p-3 border rounded-lg cursor-pointer text-sm font-medium transition ${
                      form.payment_status === 'À crédit'
                        ? 'border-amber-500 bg-amber-50 text-amber-800'
                        : 'border-slate-200 bg-white text-slate-600'
                    }`}
                  >
                    <input
                      type="radio"
                      name="payment_status"
                      value="À crédit"
                      checked={form.payment_status === 'À crédit'}
                      onChange={() => setForm({ ...form, payment_status: 'À crédit' })}
                      className="sr-only"
                    />
                    <Clock className="w-4 h-4 text-amber-600" />
                    <span>À crédit (Différé)</span>
                  </label>
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">
                  Numéro Bon / Facture / Notes
                </label>
                <input
                  type="text"
                  placeholder="Ex: Facture N° BL-2026-89"
                  value={form.notes}
                  onChange={(e) => setForm({ ...form, notes: e.target.value })}
                  className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500"
                />
              </div>

              <div className="pt-2 flex justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="px-4 py-2 border border-slate-200 rounded-lg text-sm font-medium text-slate-600 hover:bg-slate-50 transition"
                >
                  Annuler
                </button>
                <button
                  type="submit"
                  disabled={createMutation.isPending || !form.product_sync_id}
                  className="px-4 py-2 bg-indigo-600 text-white rounded-lg text-sm font-medium hover:bg-indigo-700 transition disabled:opacity-50"
                >
                  Valider la réception
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
