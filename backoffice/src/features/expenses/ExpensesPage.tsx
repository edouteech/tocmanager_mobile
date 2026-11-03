import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Receipt,
  Plus,
  DollarSign,
  Tag,
  Calendar,
  X,
  CreditCard,
  Trash2,
  TrendingDown,
  UserCheck,
} from 'lucide-react';
import { decaissementsApi } from '../../lib/api';
import { formatFCFA, formatDateTime } from '../../lib/formatters';
import { Decaissement } from '../../types';

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
      setIsModalOpen(false);
      resetForm();
    },
  });

  const deleteMutation = useMutation({
    mutationFn: decaissementsApi.delete,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['decaissements'] });
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
    <div className="space-y-6">
      {/* Top Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Dépenses & Décaissements</h1>
          <p className="text-sm text-slate-500">
            Suivi des charges d'exploitation et sorties de caisse de l'établissement
          </p>
        </div>
        <button
          onClick={() => {
            resetForm();
            setIsModalOpen(true);
          }}
          className="inline-flex items-center gap-2 px-4 py-2.5 bg-rose-600 text-white rounded-lg text-sm font-medium hover:bg-rose-700 transition shadow-sm"
        >
          <Plus className="w-4 h-4" />
          <span>Nouvelle Dépense</span>
        </button>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-medium text-slate-500 uppercase tracking-wider">Total Décaissements</p>
              <p className="text-2xl font-bold text-rose-600 mt-1">{formatFCFA(totalExpenses)}</p>
            </div>
            <div className="w-10 h-10 rounded-lg bg-rose-50 text-rose-600 flex items-center justify-center">
              <TrendingDown className="w-5 h-5" />
            </div>
          </div>
          <p className="text-xs text-slate-400 mt-3">Charges cumulées enregistrées</p>
        </div>

        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-medium text-slate-500 uppercase tracking-wider">Moyenne par Dépense</p>
              <p className="text-2xl font-bold text-slate-900 mt-1">{formatFCFA(avgExpense)}</p>
            </div>
            <div className="w-10 h-10 rounded-lg bg-slate-100 text-slate-700 flex items-center justify-center">
              <DollarSign className="w-5 h-5" />
            </div>
          </div>
          <p className="text-xs text-slate-400 mt-3">Sur l'ensemble des opérations</p>
        </div>

        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-medium text-slate-500 uppercase tracking-wider">Nombre de Décaissements</p>
              <p className="text-2xl font-bold text-slate-900 mt-1">{expenses.length}</p>
            </div>
            <div className="w-10 h-10 rounded-lg bg-indigo-50 text-indigo-600 flex items-center justify-center">
              <Receipt className="w-5 h-5" />
            </div>
          </div>
          <p className="text-xs text-slate-400 mt-3">Opérations de sortie de caisse</p>
        </div>
      </div>

      {/* Category Tabs */}
      <div className="bg-white p-3 rounded-xl border border-slate-200 shadow-sm flex items-center gap-2 overflow-x-auto">
        <button
          onClick={() => setSelectedCategory('')}
          className={`px-3 py-1.5 rounded-lg text-xs font-semibold whitespace-nowrap transition ${
            selectedCategory === ''
              ? 'bg-slate-900 text-white'
              : 'text-slate-600 hover:bg-slate-100'
          }`}
        >
          Toutes les dépenses
        </button>
        {CATEGORIES.map((cat) => (
          <button
            key={cat}
            onClick={() => setSelectedCategory(cat)}
            className={`px-3 py-1.5 rounded-lg text-xs font-semibold whitespace-nowrap transition ${
              selectedCategory === cat
                ? 'bg-indigo-600 text-white'
                : 'text-slate-600 hover:bg-slate-100'
            }`}
          >
            {cat}
          </button>
        ))}
      </div>

      {/* Table */}
      <div className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
        {isLoading ? (
          <div className="p-12 text-center text-slate-400 text-sm">Chargement des dépenses...</div>
        ) : expenses.length === 0 ? (
          <div className="p-12 text-center text-slate-400 text-sm">
            Aucun décaissement enregistré dans cette catégorie.
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead className="bg-slate-50 border-b border-slate-200 text-xs font-semibold uppercase text-slate-500">
                <tr>
                  <th className="px-6 py-3.5">Date</th>
                  <th className="px-6 py-3.5">Motif / Intitulé</th>
                  <th className="px-6 py-3.5">Catégorie</th>
                  <th className="px-6 py-3.5">Bénéficiaire</th>
                  <th className="px-6 py-3.5">Moyen de paiement</th>
                  <th className="px-6 py-3.5 text-right">Montant</th>
                  <th className="px-6 py-3.5">Opérateur</th>
                  <th className="px-6 py-3.5 text-right">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {expenses.map((d) => (
                  <tr key={d.sync_id} className="hover:bg-slate-50/80 transition-colors">
                    <td className="px-6 py-4 text-slate-600 text-xs whitespace-nowrap">
                      <div className="flex items-center gap-1.5 font-medium text-slate-900">
                        <Calendar className="w-3.5 h-3.5 text-slate-400" />
                        <span>{formatDateTime(d.date || d.created_at)}</span>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="font-semibold text-slate-900">{d.title}</div>
                      {d.notes && <div className="text-xs text-slate-400 italic mt-0.5">{d.notes}</div>}
                    </td>
                    <td className="px-6 py-4">
                      <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-medium bg-slate-100 text-slate-700">
                        <Tag className="w-3 h-3 text-slate-400" />
                        {d.category || 'Général'}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-slate-600 text-xs">
                      {d.beneficiary || <span className="text-slate-400">-</span>}
                    </td>
                    <td className="px-6 py-4 text-slate-600 text-xs">
                      <div className="flex items-center gap-1.5">
                        <CreditCard className="w-3.5 h-3.5 text-slate-400" />
                        <span>{d.payment_method}</span>
                      </div>
                    </td>
                    <td className="px-6 py-4 text-right font-bold text-rose-600 font-mono">
                      -{formatFCFA(d.amount)}
                    </td>
                    <td className="px-6 py-4 text-xs text-slate-500 whitespace-nowrap">
                      <div className="flex items-center gap-1">
                        <UserCheck className="w-3 h-3 text-slate-400" />
                        <span>{d.user_name || 'Système'}</span>
                      </div>
                    </td>
                    <td className="px-6 py-4 text-right">
                      <button
                        onClick={() => handleDelete(d)}
                        className="p-1.5 text-slate-400 hover:text-rose-600 hover:bg-rose-50 rounded transition"
                        title="Annuler cette dépense"
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

      {/* Modal Saisie Dépense */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 bg-slate-900/40 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-xl shadow-xl border border-slate-200 w-full max-w-md overflow-hidden animate-in fade-in zoom-in-95 duration-150">
            <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between">
              <div className="flex items-center gap-2 text-rose-600 font-bold">
                <Receipt className="w-5 h-5" />
                <h2 className="text-base text-slate-900">Enregistrer une Dépense</h2>
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
                  Motif / Intitulé de la dépense *
                </label>
                <input
                  type="text"
                  required
                  placeholder="Ex: Facture électricité du mois, Achat carburant..."
                  value={form.title}
                  onChange={(e) => setForm({ ...form, title: e.target.value })}
                  className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-rose-500/20 focus:border-rose-500"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">
                    Montant (F CFA) *
                  </label>
                  <input
                    type="number"
                    required
                    min="1"
                    step="50"
                    placeholder="0"
                    value={form.amount || ''}
                    onChange={(e) => setForm({ ...form, amount: parseFloat(e.target.value) || 0 })}
                    className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm font-semibold text-rose-600 focus:outline-none focus:ring-2 focus:ring-rose-500/20 focus:border-rose-500"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">
                    Moyen de règlement *
                  </label>
                  <select
                    value={form.payment_method}
                    onChange={(e) => setForm({ ...form, payment_method: e.target.value })}
                    className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-rose-500/20 focus:border-rose-500 bg-white"
                  >
                    <option value="Espèces">Espèces</option>
                    <option value="Mobile Money">Mobile Money</option>
                    <option value="Virement">Virement bancaire</option>
                    <option value="Chèque">Chèque</option>
                  </select>
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">
                  Catégorie comptable *
                </label>
                <select
                  value={form.category}
                  onChange={(e) => setForm({ ...form, category: e.target.value })}
                  className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-rose-500/20 focus:border-rose-500 bg-white"
                >
                  {CATEGORIES.map((cat) => (
                    <option key={cat} value={cat}>
                      {cat}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">
                  Bénéficiaire / Prestataire
                </label>
                <input
                  type="text"
                  placeholder="Ex: Compagnie d'électricité, Livreur..."
                  value={form.beneficiary}
                  onChange={(e) => setForm({ ...form, beneficiary: e.target.value })}
                  className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-rose-500/20 focus:border-rose-500"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">
                  Justificatif / Numéro reçu / Notes
                </label>
                <textarea
                  rows={2}
                  placeholder="Remarques éventuelles..."
                  value={form.notes}
                  onChange={(e) => setForm({ ...form, notes: e.target.value })}
                  className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-rose-500/20 focus:border-rose-500"
                ></textarea>
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
                  disabled={createMutation.isPending || form.amount <= 0 || !form.title.trim()}
                  className="px-4 py-2 bg-rose-600 text-white rounded-lg text-sm font-medium hover:bg-rose-700 transition disabled:opacity-50"
                >
                  Enregistrer la dépense
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
