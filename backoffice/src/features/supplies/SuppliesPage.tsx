import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  PackagePlus,
  Plus,
  DollarSign,
  Truck,
  Layers,
  Calendar,
  CheckCircle2,
  Clock,
  UserCheck,
} from 'lucide-react';
import { approvisionnementsApi, productsApi, suppliersApi } from '../../lib/api';
import { formatFCFA, formatDateTime } from '../../lib/formatters';
import { Drawer } from '../../components/common/Drawer';
import { useDensity } from '../../context/DensityContext';

export const SuppliesPage: React.FC = () => {
  const queryClient = useQueryClient();
  const { tableClasses } = useDensity();
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);

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
      setIsDrawerOpen(false);
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

  const totalSupplyCost = supplies.reduce((sum, s) => sum + s.total_cost, 0);
  const totalQuantity = supplies.reduce((sum, s) => sum + s.quantity, 0);

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Top Header */}
      <div className="flex flex-col sm:flex-row justify-between items-stretch sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">
            Approvisionnements
          </h1>
          <p className="text-xs sm:text-sm text-[#5A7184] dark:text-slate-400 mt-1">
            Journal des réceptions de marchandises et réassort du magasin
          </p>
        </div>
        <button
          onClick={() => {
            resetForm();
            setIsDrawerOpen(true);
          }}
          className="btn-primary w-full sm:w-auto justify-center"
        >
          <Plus className="w-4 h-4" />
          <span>Nouvelle Réception</span>
        </button>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4 sm:gap-5">
        <div className="card-toc card-hover p-5">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Valeur des Achats Reçus</p>
              <p className="text-2xl font-extrabold text-slate-900 dark:text-white mt-1">{formatFCFA(totalSupplyCost)}</p>
            </div>
            <div className="w-10 h-10 rounded-xl bg-brand-50 dark:bg-brand-500/15 text-brand-600 dark:text-brand-400 flex items-center justify-center border border-brand-200 dark:border-brand-500/30">
              <DollarSign className="w-5 h-5" />
            </div>
          </div>
          <p className="text-xs text-slate-400 dark:text-slate-500 mt-3">Investissement d'approvisionnement</p>
        </div>

        <div className="card-toc card-hover p-5">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Quantités Totales Reçues</p>
              <p className="text-2xl font-extrabold text-slate-900 dark:text-white mt-1">{totalQuantity}</p>
            </div>
            <div className="w-10 h-10 rounded-xl bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 flex items-center justify-center border border-emerald-100 dark:border-emerald-800/40">
              <Layers className="w-5 h-5" />
            </div>
          </div>
          <p className="text-xs text-slate-400 dark:text-slate-500 mt-3">Unités réceptionnées en stock</p>
        </div>

        <div className="card-toc card-hover p-5">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Bons de Réception</p>
              <p className="text-2xl font-extrabold text-slate-900 dark:text-white mt-1">{supplies.length}</p>
            </div>
            <div className="w-10 h-10 rounded-xl bg-amber-50 dark:bg-amber-950/40 text-amber-600 dark:text-amber-400 flex items-center justify-center border border-amber-100 dark:border-amber-900/50">
              <PackagePlus className="w-5 h-5" />
            </div>
          </div>
          <p className="text-xs text-slate-400 dark:text-slate-500 mt-3">Opérations d'entrée répertoriées</p>
        </div>
      </div>

      {/* Table with Density */}
      <div className="card-toc overflow-hidden">
        {isLoading ? (
          <div className="p-12 text-center text-slate-400 text-sm">Chargement des réceptions...</div>
        ) : supplies.length === 0 ? (
          <div className="p-12 text-center text-slate-400 text-sm">
            Aucun approvisionnement enregistré pour le moment.
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left min-w-[750px]">
              <thead className="bg-[#F5FAFD] dark:bg-dark-700/50 border-b border-[#E8EFF5] dark:border-dark-600">
                <tr>
                  <th className={tableClasses.th}>Date & Heure</th>
                  <th className={tableClasses.th}>Article Réceptionné</th>
                  <th className={tableClasses.th}>Fournisseur</th>
                  <th className={`${tableClasses.th} text-center`}>Quantité</th>
                  <th className={`${tableClasses.th} text-right`}>Coût Unitaire</th>
                  <th className={`${tableClasses.th} text-right`}>Total Achat</th>
                  <th className={`${tableClasses.th} text-center`}>Paiement</th>
                  <th className={tableClasses.th}>Opérateur</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#E8EFF5] dark:divide-dark-600/60">
                {supplies.map((s) => {
                  const isPaid = s.payment_status === 'Payé';
                  return (
                    <tr key={s.sync_id} className="hover:bg-brand-50/30 dark:hover:bg-dark-700/40 transition-colors">
                      <td className={tableClasses.td}>
                        <div className="flex items-center gap-1.5 font-medium text-slate-900 dark:text-white">
                          <Calendar className="w-3.5 h-3.5 text-brand-500" />
                          <span>{formatDateTime(s.date || s.created_at)}</span>
                        </div>
                        {s.notes && <div className="text-slate-400 text-xs italic mt-0.5">{s.notes}</div>}
                      </td>
                      <td className={`${tableClasses.td} font-bold text-slate-900 dark:text-white`}>
                        {s.product_name}
                      </td>
                      <td className={tableClasses.td}>
                        {s.supplier_name ? (
                          <div className="flex items-center gap-1.5 text-xs text-slate-600 dark:text-slate-300">
                            <Truck className="w-3.5 h-3.5 text-slate-400" />
                            <span>{s.supplier_name}</span>
                          </div>
                        ) : (
                          <span className="text-slate-400 text-xs">Non spécifié</span>
                        )}
                      </td>
                      <td className={`${tableClasses.td} text-center`}>
                        <span className="inline-block px-2.5 py-0.5 rounded-full text-xs font-bold bg-brand-50 dark:bg-brand-500/15 text-brand-700 dark:text-brand-300 border border-brand-200 dark:border-brand-500/30">
                          +{s.quantity}
                        </span>
                      </td>
                      <td className={`${tableClasses.td} text-right text-slate-500 dark:text-slate-400 font-mono`}>
                        {formatFCFA(s.unit_cost)}
                      </td>
                      <td className={`${tableClasses.td} text-right font-extrabold text-slate-900 dark:text-white font-mono`}>
                        {formatFCFA(s.total_cost)}
                      </td>
                      <td className={`${tableClasses.td} text-center`}>
                        {isPaid ? (
                          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-400 border border-emerald-100 dark:border-emerald-900/50">
                            <CheckCircle2 className="w-3 h-3" />
                            Payé
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-bold bg-amber-50 dark:bg-amber-950/40 text-amber-700 dark:text-amber-400 border border-amber-200 dark:border-amber-900/50">
                            <Clock className="w-3 h-3" />
                            À crédit
                          </span>
                        )}
                      </td>
                      <td className={tableClasses.td}>
                        <div className="flex items-center gap-1 text-xs text-slate-500 dark:text-slate-400">
                          <UserCheck className="w-3.5 h-3.5 text-slate-400" />
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

      {/* Slide-over Drawer for Stock Reception */}
      <Drawer
        isOpen={isDrawerOpen}
        onClose={() => setIsDrawerOpen(false)}
        title="Réception de Marchandises"
        subtitle="Entrée en stock avec recalcul automatique du PAMP"
        footer={
          <>
            <button
              type="button"
              onClick={() => setIsDrawerOpen(false)}
              className="btn-secondary"
            >
              Annuler
            </button>
            <button
              type="button"
              onClick={handleSubmit}
              disabled={createMutation.isPending || !form.product_sync_id || form.quantity <= 0}
              className="btn-primary"
            >
              {createMutation.isPending ? 'Enregistrement...' : 'Valider la Réception'}
            </button>
          </>
        }
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Article réceptionné *
            </label>
            <select
              required
              value={form.product_sync_id}
              onChange={(e) => handleProductChange(e.target.value)}
              className="input-toc bg-white dark:bg-dark-700"
            >
              <option value="">Sélectionner un produit du catalogue...</option>
              {products.map((p) => (
                <option key={p.sync_id} value={p.sync_id}>
                  {p.name} (Stock actuel: {p.stock})
                </option>
              ))}
            </select>
          </div>

          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Fournisseur partenaire
            </label>
            <select
              value={form.supplier_sync_id}
              onChange={(e) => setForm({ ...form, supplier_sync_id: e.target.value })}
              className="input-toc bg-white dark:bg-dark-700"
            >
              <option value="">Sélectionner un fournisseur (optionnel)...</option>
              {suppliers.map((s) => (
                <option key={s.sync_id} value={s.sync_id}>
                  {s.name} (Solde dû: {formatFCFA(s.balance)})
                </option>
              ))}
            </select>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Quantité reçue *
              </label>
              <input
                type="number"
                min="1"
                required
                value={form.quantity}
                onChange={(e) => setForm({ ...form, quantity: parseInt(e.target.value) || 1 })}
                className="input-toc font-mono font-bold"
              />
            </div>
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Coût unitaire d'achat (F CFA) *
              </label>
              <input
                type="number"
                min="0"
                step="50"
                required
                value={form.unit_cost}
                onChange={(e) => setForm({ ...form, unit_cost: parseFloat(e.target.value) || 0 })}
                className="input-toc font-mono font-bold"
              />
            </div>
          </div>

          <div className="p-3.5 bg-brand-50/50 dark:bg-dark-700/60 rounded-2xl border border-brand-100 dark:border-dark-600 flex justify-between items-center text-xs">
            <span className="font-semibold text-slate-600 dark:text-slate-300">Montant Total de la Réception :</span>
            <span className="font-extrabold text-brand-600 dark:text-brand-400 text-sm font-mono">
              {formatFCFA(form.quantity * form.unit_cost)}
            </span>
          </div>

          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Modalité de règlement
            </label>
            <div className="grid grid-cols-2 gap-3">
              <label
                className={`flex items-center justify-center gap-2 p-3 rounded-xl border text-xs font-bold cursor-pointer transition ${
                  form.payment_status === 'Payé'
                    ? 'border-emerald-500 bg-emerald-50 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-300'
                    : 'border-slate-200 dark:border-dark-600 text-slate-600 dark:text-slate-400'
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
                className={`flex items-center justify-center gap-2 p-3 rounded-xl border text-xs font-bold cursor-pointer transition ${
                  form.payment_status === 'À crédit'
                    ? 'border-amber-500 bg-amber-50 text-amber-700 dark:bg-amber-950/40 dark:text-amber-300'
                    : 'border-slate-200 dark:border-dark-600 text-slate-600 dark:text-slate-400'
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
                <span>À Crédit (Dette)</span>
              </label>
            </div>
            {form.payment_status === 'À crédit' && form.supplier_sync_id && (
              <p className="text-[11px] text-amber-600 dark:text-amber-400 mt-1.5">
                Ce montant sera ajouté automatiquement au solde débiteur du fournisseur.
              </p>
            )}
          </div>

          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Numéro de bon / Facture / Notes
            </label>
            <textarea
              rows={2}
              placeholder="Ex: Facture BL-9042, date de livraison..."
              value={form.notes}
              onChange={(e) => setForm({ ...form, notes: e.target.value })}
              className="input-toc"
            ></textarea>
          </div>
        </form>
      </Drawer>
    </div>
  );
};
