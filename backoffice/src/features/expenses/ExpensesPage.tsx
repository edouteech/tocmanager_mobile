import React, { useState, useMemo } from 'react';
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
  Tag,
  Search,
  FileSpreadsheet,
} from 'lucide-react';
import { decaissementsApi } from '../../lib/api';
import { formatFCFA, formatDateTime } from '../../lib/formatters';
import { Decaissement } from '../../types';
import { Modal } from '../../components/common/Modal';
import { useDensity } from '../../context/DensityContext';
import { exportToExcel } from '../../lib/exportUtils';
import { SummaryChipsRow, SummaryChipItem } from '../../components/common/SummaryChipsRow';
import { ViewToggle, ViewMode } from '../../components/common/ViewToggle';
import { ExpenseCard } from './ExpenseCard';

const getCategoryBadgeClass = (cat: string) => {
  switch (cat.toLowerCase().trim()) {
    case 'fournisseur':
      return 'bg-brand-50 text-brand-700 border-brand-200 dark:bg-brand-500/15 dark:text-brand-300 dark:border-brand-500/30';
    case 'loyer':
    case 'télécoms':
    case 'telecoms':
      return 'bg-purple-50 text-purple-700 border-purple-200 dark:bg-purple-950/40 dark:text-purple-300 dark:border-purple-800/40';
    case 'salaires':
      return 'bg-emerald-50 text-emerald-700 border-emerald-200 dark:bg-emerald-950/40 dark:text-emerald-300 dark:border-emerald-800/40';
    case 'transport':
      return 'bg-amber-50 text-amber-700 border-amber-200 dark:bg-amber-950/40 dark:text-amber-300 dark:border-amber-800/40';
    case 'énergie':
    case 'energie':
      return 'bg-sky-50 text-sky-700 border-sky-200 dark:bg-sky-950/40 dark:text-sky-300 dark:border-sky-800/40';
    case 'entretien':
    case 'maintenance':
      return 'bg-orange-50 text-orange-700 border-orange-200 dark:bg-orange-950/40 dark:text-orange-300 dark:border-orange-800/40';
    case 'consommables':
    case 'fournitures':
      return 'bg-indigo-50 text-indigo-700 border-indigo-200 dark:bg-indigo-950/40 dark:text-indigo-300 dark:border-indigo-800/40';
    default:
      return 'bg-slate-100 text-slate-700 border-slate-200 dark:bg-dark-700 dark:text-slate-300 dark:border-dark-600';
  }
};

export const ExpensesPage: React.FC = () => {
  const queryClient = useQueryClient();
  const { tableClasses } = useDensity();
  const [selectedCategory, setSelectedCategory] = useState<string>('');
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [viewMode, setViewMode] = useState<ViewMode>('cards');

  // Form state
  const [form, setForm] = useState({
    title: '',
    amount: 0,
    category: 'Transport',
    customCategory: '',
    beneficiary: '',
    payment_method: 'Espèces',
    notes: '',
  });

  // Query all expenses
  const { data: allExpenses = [], isLoading } = useQuery({
    queryKey: ['decaissements'],
    queryFn: () => decaissementsApi.getAll(),
  });

  // Query distinct server categories
  const { data: serverCategories = [] } = useQuery({
    queryKey: ['decaissement-categories'],
    queryFn: () => decaissementsApi.getCategories({ include_defaults: true }),
  });

  // Extract all distinct real categories present in current data for filtering
  const filterCategories = useMemo(() => {
    const set = new Set<string>();
    allExpenses.forEach((d) => {
      if (d.category && d.category.trim()) {
        set.add(d.category.trim());
      }
    });
    return Array.from(set).sort((a, b) => a.localeCompare(b, 'fr', { sensitivity: 'base' }));
  }, [allExpenses]);

  // Categories available in the creation form (defaults + all existing categories)
  const formCategories = useMemo(() => {
    const set = new Set<string>([
      'Transport',
      'Télécoms',
      'Entretien',
      'Consommables',
      'Énergie',
      'Loyer',
      'Salaires',
      'Fournisseur',
      'Divers',
    ]);
    allExpenses.forEach((d) => {
      if (d.category && d.category.trim()) set.add(d.category.trim());
    });
    serverCategories.forEach((c) => {
      if (c && c.trim()) set.add(c.trim());
    });
    return Array.from(set).sort((a, b) => a.localeCompare(b, 'fr', { sensitivity: 'base' }));
  }, [allExpenses, serverCategories]);

  // Compute count and amount per category
  const categoryStats = useMemo(() => {
    const stats: Record<string, { count: number; total: number }> = {};
    allExpenses.forEach((d) => {
      const cat = (d.category || 'Général').trim();
      if (!stats[cat]) stats[cat] = { count: 0, total: 0 };
      stats[cat].count += 1;
      stats[cat].total += d.amount;
    });
    return stats;
  }, [allExpenses]);

  // Filtered expenses for display
  const filteredExpenses = useMemo(() => {
    return allExpenses.filter((d) => {
      const matchCategory = !selectedCategory || (d.category || '').toLowerCase().trim() === selectedCategory.toLowerCase().trim();
      const matchSearch =
        !searchTerm ||
        d.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
        (d.beneficiary && d.beneficiary.toLowerCase().includes(searchTerm.toLowerCase())) ||
        (d.category && d.category.toLowerCase().includes(searchTerm.toLowerCase())) ||
        (d.payment_method && d.payment_method.toLowerCase().includes(searchTerm.toLowerCase()));
      return matchCategory && matchSearch;
    });
  }, [allExpenses, selectedCategory, searchTerm]);

  // Mutations
  const createMutation = useMutation({
    mutationFn: decaissementsApi.create,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['decaissements'] });
      queryClient.invalidateQueries({ queryKey: ['decaissement-categories'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard-stats'] });
      setIsModalOpen(false);
      resetForm();
    },
  });

  const deleteMutation = useMutation({
    mutationFn: decaissementsApi.delete,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['decaissements'] });
      queryClient.invalidateQueries({ queryKey: ['decaissement-categories'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard-stats'] });
    },
  });

  const resetForm = () => {
    setForm({
      title: '',
      amount: 0,
      category: formCategories[0] || 'Transport',
      customCategory: '',
      beneficiary: '',
      payment_method: 'Espèces',
      notes: '',
    });
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.title.trim() || form.amount <= 0) return;

    const finalCategory =
      form.category === '__custom__' && form.customCategory.trim()
        ? form.customCategory.trim()
        : form.category;

    createMutation.mutate({
      title: form.title.trim(),
      amount: form.amount,
      category: finalCategory,
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

  const handleExportExcel = () => {
    const exportData = filteredExpenses.map((d) => ({
      'Date & Heure': formatDateTime(d.date || d.created_at),
      'Motif': d.title,
      'Catégorie': d.category || 'Général',
      'Montant (FCFA)': d.amount,
      'Bénéficiaire': d.beneficiary || '',
      'Mode Paiement': d.payment_method || 'Espèces',
      'Opérateur': d.user_name || '',
      'Notes': d.notes || '',
    }));
    exportToExcel(exportData, `decaissements_${new Date().toISOString().slice(0, 10)}.xlsx`, 'Décaissements');
  };

  // KPIs
  const totalExpenses = allExpenses.reduce((sum, d) => sum + d.amount, 0);
  const avgExpense = allExpenses.length > 0 ? Math.round(totalExpenses / allExpenses.length) : 0;
  const filteredTotal = filteredExpenses.reduce((sum, d) => sum + d.amount, 0);

  // Summary Chips
  const summaryChips: SummaryChipItem[] = [
    {
      label: 'Total Décaissements',
      value: formatFCFA(totalExpenses),
      color: 'danger',
      icon: <TrendingDown className="w-4 h-4" />,
      subtext: `${allExpenses.length} dépenses au total`,
    },
    {
      label: 'Dépense Moyenne',
      value: formatFCFA(avgExpense),
      color: 'warning',
      icon: <DollarSign className="w-4 h-4" />,
      subtext: 'Montant unitaire moyen',
    },
    {
      label: selectedCategory ? `Total ${selectedCategory}` : 'Sélection Actuelle',
      value: formatFCFA(filteredTotal),
      color: 'purple',
      icon: <Receipt className="w-4 h-4" />,
      subtext: `${filteredExpenses.length} dépense(s) affichée(s)`,
    },
    {
      label: 'Catégories Actives',
      value: filterCategories.length,
      color: 'info',
      icon: <Tag className="w-4 h-4" />,
      subtext: 'Rayons de charges',
    },
  ];

  return (
    <div className="space-y-5 max-w-7xl mx-auto">
      {/* Top Header */}
      <div className="flex flex-col sm:flex-row justify-between items-stretch sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">
            Décaissements
          </h1>
          <p className="text-xs sm:text-sm text-[#5A7184] dark:text-slate-400 mt-0.5">
            Suivi des charges d'exploitation et sorties de caisse
          </p>
        </div>

        <div className="flex items-center gap-2 sm:gap-3 flex-wrap">
          <ViewToggle mode={viewMode} onChange={setViewMode} />

          <button
            onClick={handleExportExcel}
            className="btn-toc btn-outline flex items-center justify-center gap-2 py-2 px-3 text-xs font-bold"
            title="Exporter les décaissements vers Excel"
          >
            <FileSpreadsheet className="w-4 h-4 text-emerald-600" />
            <span className="hidden sm:inline">Excel</span>
          </button>

          <button
            onClick={() => {
              resetForm();
              setIsModalOpen(true);
            }}
            className="btn-toc btn-primary flex items-center gap-2 py-2 px-3.5 text-xs font-bold shadow-sm"
          >
            <Plus className="w-4 h-4" />
            <span>Nouveau Décaissement</span>
          </button>
        </div>
      </div>

      {/* Mobile-Style Summary Chips Row */}
      <SummaryChipsRow chips={summaryChips} />

      {/* Search & Category Filter Pills */}
      <div className="card-toc p-3.5 sm:p-4 space-y-3">
        {/* Search Input */}
        <div className="relative w-full">
          <Search className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
          <input
            type="text"
            placeholder="Rechercher motif, bénéficiaire, mode..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="input-toc pl-10 w-full text-xs sm:text-sm"
          />
        </div>

        {/* Dynamic Category Filter Pills */}
        <div className="flex items-center gap-1.5 overflow-x-auto no-scrollbar py-1 text-xs">
          <button
            type="button"
            onClick={() => setSelectedCategory('')}
            className={`px-3 py-1.5 rounded-xl font-bold whitespace-nowrap transition-all duration-150 shrink-0 ${
              selectedCategory === ''
                ? 'bg-brand-600 text-white shadow-xs'
                : 'bg-white dark:bg-dark-800 text-slate-600 dark:text-slate-300 border border-slate-200 dark:border-dark-600 hover:bg-slate-50 dark:hover:bg-dark-700'
            }`}
          >
            Toutes ({allExpenses.length})
          </button>

          {filterCategories.map((cat) => {
            const count = categoryStats[cat]?.count || 0;
            const isSelected = selectedCategory.toLowerCase().trim() === cat.toLowerCase().trim();
            return (
              <button
                key={cat}
                type="button"
                onClick={() => setSelectedCategory(isSelected ? '' : cat)}
                className={`px-3 py-1.5 rounded-xl font-bold whitespace-nowrap transition-all duration-150 flex items-center gap-1.5 shrink-0 ${
                  isSelected
                    ? 'bg-brand-600 text-white shadow-xs'
                    : 'bg-white dark:bg-dark-800 text-slate-600 dark:text-slate-300 border border-slate-200 dark:border-dark-600 hover:bg-slate-50 dark:hover:bg-dark-700'
                }`}
              >
                <span>{cat}</span>
                {count > 0 && (
                  <span
                    className={`text-[10px] px-1.5 py-0.2 rounded-full font-mono ${
                      isSelected
                        ? 'bg-white/20 text-white'
                        : 'bg-slate-100 dark:bg-dark-700 text-slate-600 dark:text-slate-400'
                    }`}
                  >
                    {count}
                  </span>
                )}
              </button>
            );
          })}
        </div>
      </div>

      {/* Content: Cards View (Mobile style) or Table View */}
      {isLoading ? (
        <div className="card-toc p-12 text-center text-slate-400">
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-4 border-brand-500 border-t-transparent mb-3" />
          <p className="text-sm">Chargement des dépenses...</p>
        </div>
      ) : filteredExpenses.length === 0 ? (
        <div className="card-toc p-12 text-center text-slate-400">
          <div className="w-16 h-16 bg-slate-100 dark:bg-dark-700 rounded-full flex items-center justify-center mx-auto mb-3">
            <Receipt className="w-8 h-8 text-slate-400" />
          </div>
          <h3 className="text-base font-bold text-slate-800 dark:text-slate-200">
            Aucun décaissement trouvé
          </h3>
          <p className="text-xs text-slate-400 mt-1 max-w-sm mx-auto">
            {searchTerm || selectedCategory
              ? 'Aucune dépense ne correspond aux critères de recherche.'
              : 'Enregistrez votre première sortie de caisse.'}
          </p>
        </div>
      ) : viewMode === 'cards' ? (
        /* Mobile Cards Grid */
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3.5">
          {filteredExpenses.map((d) => (
            <ExpenseCard
              key={d.sync_id}
              expense={d}
              onDelete={handleDelete}
              badgeClass={getCategoryBadgeClass(d.category || 'Général')}
            />
          ))}
        </div>
      ) : (
        /* Desktop Table View */
        <div className="card-toc overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left min-w-[750px]">
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
                {filteredExpenses.map((d) => (
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
                      <span
                        className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-bold border ${getCategoryBadgeClass(
                          d.category || 'Général'
                        )}`}
                      >
                        <Tag className="w-3 h-3" />
                        <span>{d.category || 'Général'}</span>
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
        </div>
      )}

      {/* Modal Nouveau Décaissement */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title="Enregistrer un Décaissement"
        subtitle="Sortie de caisse justifiée pour charges d'exploitation"
        footer={
          <div className="flex items-center justify-end gap-2 w-full">
            <button
              type="button"
              onClick={() => setIsModalOpen(false)}
              className="btn-toc btn-secondary text-xs"
            >
              Annuler
            </button>
            <button
              type="button"
              onClick={handleSubmit}
              disabled={createMutation.isPending || !form.title.trim() || form.amount <= 0}
              className="btn-toc btn-primary text-xs bg-rose-600 hover:bg-rose-700"
            >
              {createMutation.isPending ? 'Enregistrement...' : 'Valider la Dépense'}
            </button>
          </div>
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

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Montant décaissé (F CFA) *
              </label>
              <input
                type="number"
                min="1"
                step="100"
                required
                value={form.amount || ''}
                onChange={(e) => setForm({ ...form, amount: parseFloat(e.target.value) || 0 })}
                className="input-toc font-mono font-bold text-rose-600"
              />
            </div>
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Catégorie *
              </label>
              <select
                value={form.category}
                onChange={(e) => setForm({ ...form, category: e.target.value })}
                className="input-toc bg-white dark:bg-dark-700"
              >
                {formCategories.map((cat) => (
                  <option key={cat} value={cat}>
                    {cat}
                  </option>
                ))}
                <option value="__custom__">+ Nouvelle catégorie personnalisée...</option>
              </select>
            </div>
          </div>

          {form.category === '__custom__' && (
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Nom de la nouvelle catégorie *
              </label>
              <input
                type="text"
                required
                placeholder="Ex: Frais Bancaires, Sécurité..."
                value={form.customCategory}
                onChange={(e) => setForm({ ...form, customCategory: e.target.value })}
                className="input-toc"
              />
            </div>
          )}

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Bénéficiaire / Prestataire
              </label>
              <input
                type="text"
                placeholder="Ex: SBEE, Moov Africa, Chauffeur..."
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
                <option value="Mobile Money">Mobile Money (T-Money/Flooz/Moov)</option>
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
