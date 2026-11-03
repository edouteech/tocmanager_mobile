import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Receipt,
  Plus,
  DollarSign,
  Calendar,
  CreditCard,
  Trash2,
  TrendingDown,
  UserCheck,
} from 'lucide-react';
import { decaissementsApi } from '../../lib/api';
import { formatFCFA, formatDateTime } from '../../lib/formatters';
import { Decaissement } from '../../types';
import { Modal } from '../../components/common/Modal';
import { useDensity } from '../../context/DensityContext';

const CATEGORIES = [
  'Loyer & Charges',
  'Salaires & Rémunérations',
  'Transport & Livraison',
  'Énergie & Eau (CIE/CEET)',
  'Maintenance & Réparations',
  'Fournitures & Emballages',
  'Marketing & Communication',
  'Divers & Imprévus',
];

export const ExpensesPage: React.FC = () => {
  const queryClient = useQueryClient();
  const { tableClasses } = useDensity();
  const [selectedCategory, setSelectedCategory] = useState<string>('');
  const [isModalOpen, setIsModalOpen] = useState(false);

  // Form state
  const [form, setForm] = useState({
    title: '',
    amount: 0,
    category: 'Loyer & Charges',
    beneficiary: '',
    payment_method: 'Espèces',
    notes: '',
  });

  // Query
  const { data: expenses = [], isLoading } = useQuery({
    queryKey: ['decaissements', selectedCategory],
    queryFn: () => decaissementsApi.getAll({ category: selectedCategory || undefined }),
  });

  // Mutations
  const createMutation = useMutation({
    mutationFn: decaissementsApi.create,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['decaissements'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard-stats'] });
      setIsModalOpen(false);
      resetForm();
    },
  });

  const deleteMutation = useMutation({
    mutationFn: decaissementsApi.delete,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['decaissements'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard-stats'] });
    },
  });

  const resetForm = () => {
    setForm({
      title: '',
      amount: 0,
      category: 'Loyer & Charges',
      beneficiary: '',
      payment_method: 'Espèces',
      notes: '',
    });
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.title.trim() || form.amount <= 0) return;

    createMutation.mutate({
      title: form.title.trim(),
      amount: form.amount,
      category: form.category,
      beneficiary: form.beneficiary.trim() || undefined,
      payment_method: form.payment_method,
      notes: form.notes.trim() || undefined,
    });
  };

  const handleDelete = (d: Decaissement) => {
    if (window.confirm(`Confirmer l'annulation de la dépense "${d.title}" (${formatFCFA(d.amount)}) ?`)) {
      deleteMutation.mutate(d.sync_id);
    }
  };

  // KPIs
  const totalExpenses = expenses.reduce((sum, d) => sum + d.amount, 0);
  const avgExpense = expenses.length > 0 ? Math.round(totalExpenses / expenses.length) : 0;

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Top Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-slate-900 dark:text-white tracking-tight">Dépenses & Décaissements</h1>
          <p className="text-xs sm:text-sm text-slate-500 dark:text-slate-400 mt-1">
            Suivi des charges d'exploitation et sorties de caisse de l'établissement
          </p>
        </div>
        <button
          onClick={() => {
            resetForm();
            setIsModalOpen(true);
          }}
          className="inline-flex items-center justify-center gap-2 px-4 py-2.5 bg-rose-600 hover:bg-rose-700 active:scale-[0.99] text-white rounded-xl text-sm font-semibold shadow-sm transition"
        >
          <Plus className="w-4 h-4" />
          <span>Nouveau Décaissement</span>
        </button>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
        <div className="card-toc card-hover p-5">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Total Décaissements</p>
              <p className="text-2xl font-extrabold text-rose-600 dark:text-rose-400 mt-1">{formatFCFA(totalExpenses)}</p>
            </div>
            <div className="w-10 h-10 rounded-xl bg-rose-50 dark:bg-rose-950/40 text-rose-600 dark:text-rose-400 flex items-center justify-center border border-rose-100 dark:border-rose-900/50">
              <TrendingDown className="w-5 h-5" />
            </div>
          </div>
          <p className="text-xs text-slate-400 dark:text-slate-500 mt-3">{expenses.length} dépenses enregistrées</p>
        </div>

        <div className="card-toc card-hover p-5">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Dépense Moyenne</p>
              <p className="text-2xl font-extrabold text-slate-900 dark:text-white mt-1">{formatFCFA(avgExpense)}</p>
            </div>
            <div className="w-10 h-10 rounded-xl bg-amber-50 dark:bg-amber-950/40 text-amber-600 dark:text-amber-400 flex items-center justify-center border border-amber-100 dark:border-amber-900/50">
              <DollarSign className="w-5 h-5" />
            </div>
          </div>
          <p className="text-xs text-slate-400 dark:text-slate-500 mt-3">Montant unitaire moyen</p>
        </div>

        <div className="card-toc card-hover p-5">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Catégorie la plus active</p>
              <p className="text-base font-extrabold text-slate-900 dark:text-white mt-2 truncate">
                {selectedCategory || 'Toutes catégories'}
              </p>
            </div>
            <div className="w-10 h-10 rounded-xl bg-brand-50 dark:bg-brand-500/15 text-brand-600 dark:text-brand-400 flex items-center justify-center border border-brand-200 dark:border-brand-500/30">
              <Receipt className="w-5 h-5" />
            </div>
          </div>
          <p className="text-xs text-slate-400 dark:text-slate-500 mt-3">Filtre d'affichage actuel</p>
        </div>
      </div>

      {/* Category Filter Pills */}
      <div className="flex items-center gap-2 overflow-x-auto pb-1">
        <button
          onClick={() => setSelectedCategory('')}
          className={`px-3.5 py-1.5 rounded-full text-xs font-bold transition whitespace-nowrap ${
            selectedCategory === ''
              ? 'bg-brand-500 text-white shadow-sm'
              : 'bg-white dark:bg-dark-800 text-slate-600 dark:text-slate-400 border border-[#E8EFF5] dark:border-dark-600 hover:bg-slate-50 dark:hover:bg-dark-700'
          }`}
        >
          Toutes ({expenses.length})
        </button>
        {CATEGORIES.map((cat) => (
          <button
            key={cat}
            onClick={() => setSelectedCategory(cat)}
            className={`px-3.5 py-1.5 rounded-full text-xs font-semibold transition whitespace-nowrap ${
              selectedCategory === cat
                ? 'bg-brand-500 text-white shadow-sm font-bold'
                : 'bg-white dark:bg-dark-800 text-slate-600 dark:text-slate-400 border border-[#E8EFF5] dark:border-dark-600 hover:bg-slate-50 dark:hover:bg-dark-700'
            }`}
          >
            {cat}
          </button>
        ))}
      </div>

      {/* Expenses Table with Density */}
      <div className="card-toc overflow-hidden">
        {isLoading ? (
          <div className="p-12 text-center text-slate-400 text-sm">Chargement des dépenses...</div>
        ) : expenses.length === 0 ? (
          <div className="p-12 text-center text-slate-400 text-sm">
            Aucun décaissement enregistré pour ces critères.
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left">
              <thead className="bg-[#F5FAFD] dark:bg-dark-700/50 border-b border-[#E8EFF5] dark:border-dark-600">
                <tr>
                  <th className={tableClasses.th}>Date & Heure</th>
                  <th className={tableClasses.th}>Motif de la Dépense</th>
                  <th className={tableClasses.th}>Catégorie</th>
                  <th className={tableClasses.th}>Bénéficiaire</th>
                  <th className={tableClasses.th}>Moyen</th>
                  <th className={`${tableClasses.th} text-right`}>Montant</th>
                  <th className={tableClasses.th}>Opérateur</th>
                  <th className={`${tableClasses.th} text-right`}>Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#E8EFF5] dark:divide-dark-600/60">
                {expenses.map((d) => (
                  <tr key={d.sync_id} className="hover:bg-brand-50/30 dark:hover:bg-dark-700/40 transition-colors">
                    <td className={tableClasses.td}>
                      <div className="flex items-center gap-1.5 font-medium text-slate-900 dark:text-white">
                        <Calendar className="w-3.5 h-3.5 text-brand-500" />
                        <span>{formatDateTime(d.date || d.created_at)}</span>
                      </div>
                    </td>
                    <td className={`${tableClasses.td} font-bold text-slate-900 dark:text-white`}>
                      {d.title}
                      {d.notes && <div className="text-xs text-slate-400 italic font-normal mt-0.5">{d.notes}</div>}
                    </td>
                    <td className={tableClasses.td}>
                      <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-rose-50 dark:bg-rose-950/40 text-rose-700 dark:text-rose-400 border border-rose-100 dark:border-rose-900/50">
                        {d.category}
                      </span>
                    </td>
                    <td className={`${tableClasses.td} text-slate-700 dark:text-slate-200`}>
                      {d.beneficiary || '-'}
                    </td>
                    <td className={tableClasses.td}>
                      <span className="inline-flex items-center gap-1 text-xs text-slate-600 dark:text-slate-300">
                        <CreditCard className="w-3.5 h-3.5 text-slate-400" />
                        {d.payment_method}
                      </span>
                    </td>
                    <td className={`${tableClasses.td} text-right font-extrabold text-rose-600 dark:text-rose-400 font-mono`}>
                      - {formatFCFA(d.amount)}
                    </td>
                    <td className={tableClasses.td}>
                      <div className="flex items-center gap-1 text-xs text-slate-500 dark:text-slate-400">
                        <UserCheck className="w-3.5 h-3.5 text-slate-400" />
                        <span>{d.user_name || 'Système'}</span>
                      </div>
                    </td>
                    <td className={`${tableClasses.td} text-right`}>
                      <button
                        onClick={() => handleDelete(d)}
                        className="p-1.5 text-slate-400 hover:text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-950/30 rounded-xl transition"
                        title="Annuler le décaissement"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Modal Nouveau Décaissement */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title="Enregistrer un Décaissement"
        subtitle="Sortie de caisse justifiée pour charges d'exploitation"
        footer={
          <>
            <button
              type="button"
              onClick={() => setIsModalOpen(false)}
              className="btn-secondary"
            >
              Annuler
            </button>
            <button
              type="button"
              onClick={handleSubmit}
              disabled={createMutation.isPending || !form.title.trim() || form.amount <= 0}
              className="inline-flex items-center justify-center gap-2 px-4 py-2.5 bg-rose-600 hover:bg-rose-700 active:scale-[0.99] text-white rounded-xl text-sm font-bold shadow-sm transition disabled:opacity-50"
            >
              {createMutation.isPending ? 'Enregistrement...' : 'Valider la Dépense'}
            </button>
          </>
        }
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Motif du décaissement *
            </label>
            <input
              type="text"
              required
              placeholder="Ex: Facture électricité agence, Frais de livraison..."
              value={form.title}
              onChange={(e) => setForm({ ...form, title: e.target.value })}
              className="input-toc"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Montant décaissé (F CFA) *
              </label>
              <input
                type="number"
                min="1"
                step="100"
                required
                value={form.amount}
                onChange={(e) => setForm({ ...form, amount: parseFloat(e.target.value) || 0 })}
                className="input-toc font-mono font-bold"
              />
            </div>
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Catégorie comptable *
              </label>
              <select
                value={form.category}
                onChange={(e) => setForm({ ...form, category: e.target.value })}
                className="input-toc bg-white dark:bg-dark-700"
              >
                {CATEGORIES.map((cat) => (
                  <option key={cat} value={cat}>
                    {cat}
                  </option>
                ))}
              </select>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Bénéficiaire / Prestataire
              </label>
              <input
                type="text"
                placeholder="Ex: CEET, Livreur Paul..."
                value={form.beneficiary}
                onChange={(e) => setForm({ ...form, beneficiary: e.target.value })}
                className="input-toc"
              />
            </div>
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Mode de règlement
              </label>
              <select
                value={form.payment_method}
                onChange={(e) => setForm({ ...form, payment_method: e.target.value })}
                className="input-toc bg-white dark:bg-dark-700"
              >
                <option value="Espèces">Espèces de Caisse</option>
                <option value="Mobile Money">Mobile Money (T-Money/Flooz)</option>
                <option value="Virement">Virement bancaire</option>
                <option value="Chèque">Chèque</option>
              </select>
            </div>
          </div>

          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Justificatif / Numéro de reçu / Notes
            </label>
            <textarea
              rows={2}
              placeholder="Réf ticket, n° facture, remarques..."
              value={form.notes}
              onChange={(e) => setForm({ ...form, notes: e.target.value })}
              className="input-toc"
            ></textarea>
          </div>
        </form>
      </Modal>
    </div>
  );
};
