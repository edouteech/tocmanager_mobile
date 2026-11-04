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
  CreditCard,
  Edit2,
  Trash2,
} from 'lucide-react';
import { suppliersApi } from '../../lib/api';
import { formatFCFA, formatDateTime } from '../../lib/formatters';
import { Supplier } from '../../types';
import { Modal } from '../../components/common/Modal';
import { useDensity } from '../../context/DensityContext';

export const SuppliersPage: React.FC = () => {
  const queryClient = useQueryClient();
  const { tableClasses } = useDensity();
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
      notes: `Règlement facture fournisseur ${s.name}`,
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
  const totalDebts = suppliers.reduce((sum, s) => sum + (s.balance > 0 ? s.balance : 0), 0);
  const creditorsCount = suppliers.filter((s) => s.balance > 0).length;

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Top Header */}
      <div className="flex flex-col sm:flex-row justify-between items-stretch sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">Fournisseurs</h1>
          <p className="text-xs sm:text-sm text-[#5A7184] dark:text-slate-400 mt-1">
            Gestion des approvisionneurs partenaires et suivi des factures impayées
          </p>
        </div>
        <button
          onClick={handleOpenCreate}
          className="btn-primary w-full sm:w-auto justify-center"
        >
          <Plus className="w-4 h-4" />
          <span>Nouveau Fournisseur</span>
        </button>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4 sm:gap-5">
        <div className="card-toc card-hover p-5">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Dettes Fournisseurs</p>
              <p className="text-2xl font-extrabold text-rose-600 dark:text-rose-400 mt-1">{formatFCFA(totalDebts)}</p>
            </div>
            <div className="w-10 h-10 rounded-xl bg-rose-50 dark:bg-rose-950/40 text-rose-600 dark:text-rose-400 flex items-center justify-center border border-rose-100 dark:border-rose-900/50">
              <AlertCircle className="w-5 h-5" />
            </div>
          </div>
          <p className="text-xs text-slate-400 dark:text-slate-500 mt-3">{creditorsCount} fournisseur(s) en attente de paiement</p>
        </div>

        <div className="card-toc card-hover p-5">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Factures en Instance</p>
              <p className="text-2xl font-extrabold text-slate-900 dark:text-white mt-1">{creditorsCount}</p>
            </div>
            <div className="w-10 h-10 rounded-xl bg-amber-50 dark:bg-amber-950/40 text-amber-600 dark:text-amber-400 flex items-center justify-center border border-amber-100 dark:border-amber-900/50">
              <DollarSign className="w-5 h-5" />
            </div>
          </div>
          <p className="text-xs text-slate-400 dark:text-slate-500 mt-3">Soldes créditeurs ouverts</p>
        </div>

        <div className="card-toc card-hover p-5">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Total Partenaires</p>
              <p className="text-2xl font-extrabold text-slate-900 dark:text-white mt-1">{suppliers.length}</p>
            </div>
            <div className="w-10 h-10 rounded-xl bg-brand-50 dark:bg-brand-500/15 text-brand-600 dark:text-brand-400 flex items-center justify-center border border-brand-200 dark:border-brand-500/30">
              <Truck className="w-5 h-5" />
            </div>
          </div>
          <p className="text-xs text-slate-400 dark:text-slate-500 mt-3">Fournisseurs enregistrés</p>
        </div>
      </div>

      {/* Filter Bar */}
      <div className="card-toc p-4 flex flex-col sm:flex-row gap-4 items-stretch sm:items-center justify-between">
        <div className="relative w-full sm:w-72">
          <Search className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
          <input
            type="text"
            placeholder="Rechercher nom, contact, tél..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="input-toc pl-10"
          />
        </div>

        <label className="flex items-center gap-2 cursor-pointer select-none text-xs font-semibold text-slate-600 dark:text-slate-300">
          <input
            type="checkbox"
            checked={onlyCreditors}
            onChange={(e) => setOnlyCreditors(e.target.checked)}
            className="rounded border-slate-300 dark:border-dark-600 text-brand-500 focus:ring-brand-500 h-4 w-4"
          />
          <span>Afficher uniquement les dettes &gt; 0</span>
        </label>
      </div>

      {/* Suppliers Table with Density */}
      <div className="card-toc overflow-hidden">
        {isLoading ? (
          <div className="p-12 text-center text-slate-400 text-sm">Chargement des fournisseurs...</div>
        ) : suppliers.length === 0 ? (
          <div className="p-12 text-center text-slate-400 text-sm">
            Aucun fournisseur trouvé pour ces critères de recherche.
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left min-w-[650px]">
              <thead className="bg-[#F5FAFD] dark:bg-dark-700/50 border-b border-[#E8EFF5] dark:border-dark-600">
                <tr>
                  <th className={tableClasses.th}>Fournisseur</th>
                  <th className={tableClasses.th}>Contact Direct</th>
                  <th className={tableClasses.th}>Coordonnées</th>
                  <th className={`${tableClasses.th} text-right`}>Dette Restante</th>
                  <th className={`${tableClasses.th} text-right`}>Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#E8EFF5] dark:divide-dark-600/60">
                {suppliers.map((s) => {
                  const hasDebt = s.balance > 0;
                  return (
                    <tr key={s.sync_id} className="hover:bg-brand-50/30 dark:hover:bg-dark-700/40 transition-colors">
                      <td className={tableClasses.td}>
                        <div className="font-bold text-slate-900 dark:text-white">{s.name}</div>
                        <div className="text-xs text-slate-400 mt-0.5">
                          Inscrit le {formatDateTime(s.created_at)}
                        </div>
                      </td>
                      <td className={tableClasses.td}>
                        <div className="font-medium text-slate-700 dark:text-slate-200">{s.contact_person || '-'}</div>
                      </td>
                      <td className={tableClasses.td}>
                        {s.phone ? (
                          <div className="flex items-center gap-1.5 text-xs text-slate-600 dark:text-slate-300">
                            <Phone className="w-3.5 h-3.5 text-brand-500" />
                            <span>{s.phone}</span>
                          </div>
                        ) : null}
                        {s.email && (
                          <div className="flex items-center gap-1.5 text-xs text-slate-400 mt-0.5">
                            <Mail className="w-3 h-3 text-slate-400" />
                            <span>{s.email}</span>
                          </div>
                        )}
                        {!s.phone && !s.email && <span className="text-slate-400 text-xs">-</span>}
                      </td>
                      <td className={`${tableClasses.td} text-right font-mono`}>
                        {hasDebt ? (
                          <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-bold bg-rose-50 dark:bg-rose-950/40 text-rose-700 dark:text-rose-400 border border-rose-200 dark:border-rose-900/50">
                            <AlertCircle className="w-3 h-3" />
                            {formatFCFA(s.balance)}
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-400 border border-emerald-100 dark:border-emerald-900/50">
                            <CheckCircle2 className="w-3 h-3" />
                            Soldé (0 F)
                          </span>
                        )}
                      </td>
                      <td className={`${tableClasses.td} text-right`}>
                        <div className="flex items-center justify-end gap-2">
                          {hasDebt && (
                            <button
                              onClick={() => handleOpenPayment(s)}
                              className="px-2.5 py-1 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl text-xs font-bold transition shadow-xs"
                              title="Régler la dette"
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
        )}
      </div>

      {/* Modal Création / Modification Fournisseur */}
      <Modal
        isOpen={isSupplierModalOpen}
        onClose={() => setIsSupplierModalOpen(false)}
        title={selectedSupplier ? 'Modifier le Fournisseur' : 'Nouveau Fournisseur'}
        subtitle="Renseignez les détails du contact et les coordonnées"
        footer={
          <>
            <button
              type="button"
              onClick={() => setIsSupplierModalOpen(false)}
              className="btn-secondary"
            >
              Annuler
            </button>
            <button
              type="button"
              onClick={handleSupplierSubmit}
              disabled={createMutation.isPending || updateMutation.isPending}
              className="btn-primary"
            >
              {selectedSupplier ? 'Enregistrer' : 'Créer le fournisseur'}
            </button>
          </>
        }
      >
        <form onSubmit={handleSupplierSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Raison Sociale / Nom Entreprise *
            </label>
            <input
              type="text"
              required
              placeholder="Ex: Brasserie BB Lomé, Grossiste XYZ..."
              value={supplierForm.name}
              onChange={(e) => setSupplierForm({ ...supplierForm, name: e.target.value })}
              className="input-toc"
            />
          </div>

          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Nom du Commercial / Interlocuteur
            </label>
            <input
              type="text"
              placeholder="Ex: M. Koffi"
              value={supplierForm.contact_person}
              onChange={(e) => setSupplierForm({ ...supplierForm, contact_person: e.target.value })}
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
                value={supplierForm.phone}
                onChange={(e) => setSupplierForm({ ...supplierForm, phone: e.target.value })}
                className="input-toc"
              />
            </div>
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Email
              </label>
              <input
                type="email"
                placeholder="contact@fournisseur.com"
                value={supplierForm.email}
                onChange={(e) => setSupplierForm({ ...supplierForm, email: e.target.value })}
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
              placeholder="Zone industrielle, Rue, Ville..."
              value={supplierForm.address}
              onChange={(e) => setSupplierForm({ ...supplierForm, address: e.target.value })}
              className="input-toc"
            />
          </div>

          {!selectedSupplier && (
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Dette Initiale envers ce fournisseur
              </label>
              <input
                type="number"
                min="0"
                step="100"
                placeholder="0"
                value={supplierForm.balance}
                onChange={(e) => setSupplierForm({ ...supplierForm, balance: parseFloat(e.target.value) || 0 })}
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
              placeholder="Conditions de livraison, délais de paiement..."
              value={supplierForm.notes}
              onChange={(e) => setSupplierForm({ ...supplierForm, notes: e.target.value })}
              className="input-toc"
            ></textarea>
          </div>
        </form>
      </Modal>

      {/* Modal Règlement Dette Fournisseur */}
      <Modal
        isOpen={isPaymentModalOpen && !!paymentSupplier}
        onClose={() => setIsPaymentModalOpen(false)}
        title={
          <div className="flex items-center gap-2 text-emerald-600 dark:text-emerald-400">
            <CreditCard className="w-5 h-5" />
            <span>Paiement Fournisseur</span>
          </div>
        }
        subtitle="Enregistrez un décaissement pour solder la facture du fournisseur"
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
              Valider le paiement
            </button>
          </>
        }
      >
        {paymentSupplier && (
          <form onSubmit={handlePaymentSubmit} className="space-y-4">
            <div className="bg-[#F5FAFD] dark:bg-dark-700/60 p-3.5 rounded-2xl border border-[#E8EFF5] dark:border-dark-600">
              <div className="text-xs text-slate-400 font-medium">Fournisseur</div>
              <div className="font-bold text-slate-900 dark:text-white text-base">{paymentSupplier.name}</div>
              <div className="flex justify-between items-center mt-2 pt-2 border-t border-[#E8EFF5] dark:border-dark-600 text-xs">
                <span className="text-slate-500 dark:text-slate-400">Dette totale en cours :</span>
                <span className="font-extrabold text-rose-600 dark:text-rose-400 font-mono">{formatFCFA(paymentSupplier.balance)}</span>
              </div>
            </div>

            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
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
                  className="input-toc pr-20 font-mono font-bold"
                />
                <button
                  type="button"
                  onClick={() => setPaymentForm({ ...paymentForm, amount: paymentSupplier.balance })}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-xs font-bold text-brand-600 dark:text-brand-400 hover:underline"
                >
                  Totalité
                </button>
              </div>
              <div className="text-xs text-slate-500 dark:text-slate-400 mt-1.5 flex justify-between">
                <span>Solde restant après paiement :</span>
                <span className="font-bold text-slate-700 dark:text-slate-200 font-mono">
                  {formatFCFA(Math.max(0, paymentSupplier.balance - paymentForm.amount))}
                </span>
              </div>
            </div>

            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Moyen de décaissement *
              </label>
              <select
                value={paymentForm.payment_method}
                onChange={(e) => setPaymentForm({ ...paymentForm, payment_method: e.target.value })}
                className="input-toc bg-white dark:bg-dark-700"
              >
                <option value="Espèces">Espèces de Caisse</option>
                <option value="Chèque">Chèque bancaire</option>
                <option value="Virement">Virement bancaire</option>
                <option value="Mobile Money">Mobile Money Pro</option>
              </select>
            </div>

            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Référence / Numéro Chèque ou Reçu
              </label>
              <input
                type="text"
                value={paymentForm.notes}
                onChange={(e) => setPaymentForm({ ...paymentForm, notes: e.target.value })}
                placeholder="Ex: Chèque n°49204..."
                className="input-toc"
              />
            </div>
          </form>
        )}
      </Modal>
    </div>
  );
};
