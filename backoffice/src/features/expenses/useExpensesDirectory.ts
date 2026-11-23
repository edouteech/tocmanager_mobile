import React, { useEffect, useMemo, useState } from 'react';
import { keepPreviousData, useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { decaissementsApi } from '../../lib/api';
import { exportToExcel } from '../../lib/exportUtils';
import { formatDateTime } from '../../lib/formatters';
import { Decaissement } from '../../types';
import { ExpenseFormValues } from './ExpenseFormModal';
import { ViewMode } from '../../components/common/ViewToggle';
import { useAuthStore } from '../../stores/authStore';
import { useTenantContextKey, useTenantStore } from '../../stores/tenantStore';

const DEFAULT_CATEGORIES = [
  'Transport', 'Télécoms', 'Entretien', 'Consommables',
  'Énergie', 'Loyer', 'Salaires', 'Fournisseur', 'Divers',
];

export const useExpensesDirectory = () => {
  const queryClient = useQueryClient();
  const [boutiqueKey, magasinKey] = useTenantContextKey();
  const { magasins, currentMagasin, isConsolidatedView } = useTenantStore();
  const user = useAuthStore((s) => s.user);
  const canDeleteExpense = user?.role !== 'cashier';

  const [targetMagasinId, setTargetMagasinId] = useState<string>('');
  const [selectedCategory, setSelectedCategory] = useState<string>('');
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [confirmDelete, setConfirmDelete] = useState<Decaissement | null>(null);
  const [viewMode, setViewMode] = useState<ViewMode>('cards');
  const [page, setPage] = useState(1);
  const [limit, setLimit] = useState(50);
  const [form, setForm] = useState<ExpenseFormValues>({
    title: '', amount: 0, category: 'Transport', customCategory: '', beneficiary: '', payment_method: 'Espèces', notes: '',
  });
  const [formError, setFormError] = useState<string | null>(null);

  useEffect(() => {
    setPage(1);
  }, [boutiqueKey, magasinKey, selectedCategory, searchTerm]);

  const { data: expensesPage, isLoading, isFetching } = useQuery({
    queryKey: ['decaissements', boutiqueKey, magasinKey, page, limit, selectedCategory, searchTerm],
    queryFn: () =>
      decaissementsApi.getPaginated({ page, limit, q: searchTerm || undefined, category: selectedCategory || undefined }),
    placeholderData: keepPreviousData,
  });

  const allExpenses = useMemo(() => expensesPage?.items ?? [], [expensesPage?.items]);
  const expenseSummary = expensesPage?.summary;

  const { data: serverCategories = [] } = useQuery({
    queryKey: ['decaissement-categories', boutiqueKey, magasinKey],
    queryFn: () => decaissementsApi.getCategories({ include_defaults: true }),
  });

  const filterCategories = useMemo(() => {
    const set = new Set<string>(serverCategories.filter((c) => Boolean(c && c.trim())).map((c) => c.trim()));
    allExpenses.forEach((d) => { if (d.category?.trim()) set.add(d.category.trim()); });
    return Array.from(set).sort((a, b) => a.localeCompare(b, 'fr', { sensitivity: 'base' }));
  }, [allExpenses, serverCategories]);

  const formCategories = useMemo(() => {
    const set = new Set<string>(DEFAULT_CATEGORIES);
    allExpenses.forEach((d) => { if (d.category?.trim()) set.add(d.category.trim()); });
    serverCategories.forEach((c) => { if (c?.trim()) set.add(c.trim()); });
    return Array.from(set).sort((a, b) => a.localeCompare(b, 'fr', { sensitivity: 'base' }));
  }, [allExpenses, serverCategories]);

  const resetForm = () => {
    setForm({ title: '', amount: 0, category: formCategories[0] || 'Transport', customCategory: '', beneficiary: '', payment_method: 'Espèces', notes: '' });
    setFormError(null);
  };

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
      setConfirmDelete(null);
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);
    if (!form.title.trim()) return setFormError('Le motif du décaissement est obligatoire.');
    if (form.amount <= 0) return setFormError('Le montant doit être supérieur à 0.');
    if (form.category === '__custom__' && !form.customCategory.trim()) {
      return setFormError('Veuillez saisir le nom de la catégorie personnalisée.');
    }
    if (isConsolidatedView && magasins.length > 1 && !targetMagasinId) {
      return setFormError('Veuillez sélectionner un magasin.');
    }
    createMutation.mutate({
      magasin_id: isConsolidatedView && magasins.length > 1 ? targetMagasinId || undefined : currentMagasin?.id,
      title: form.title.trim(),
      amount: form.amount,
      category: form.category === '__custom__' ? form.customCategory.trim() : form.category,
      beneficiary: form.beneficiary.trim() || undefined,
      payment_method: form.payment_method,
      notes: form.notes.trim() || undefined,
    });
  };

  const totalCount = expenseSummary?.total_count ?? allExpenses.length;
  const totalExpenses = expenseSummary?.total_amount ?? allExpenses.reduce((sum, d) => sum + d.amount, 0);
  const avgExpense = totalCount > 0 ? Math.round(totalExpenses / totalCount) : 0;
  const filteredTotal = expenseSummary?.filtered_amount ?? allExpenses.reduce((sum, d) => sum + d.amount, 0);

  const handleExportExcel = () => {
    exportToExcel(
      allExpenses.map((d) => ({
        'Date & Heure': formatDateTime(d.date || d.created_at),
        Motif: d.title,
        Catégorie: d.category || 'Général',
        'Montant (FCFA)': d.amount,
        Bénéficiaire: d.beneficiary || '',
        'Mode Paiement': d.payment_method || 'Espèces',
        Opérateur: d.user_name || '',
        Notes: d.notes || '',
      })),
      `decaissements_${new Date().toISOString().slice(0, 10)}.xlsx`,
      'Décaissements'
    );
  };

  return {
    canDeleteExpense, magasins, showMagasinSelector: isConsolidatedView && magasins.length > 1,
    targetMagasinId, setTargetMagasinId, selectedCategory, setSelectedCategory,
    searchTerm, setSearchTerm, isModalOpen, setIsModalOpen, confirmDelete, setConfirmDelete,
    viewMode, setViewMode, page, setPage, limit, setLimit, form, setForm, formError,
    expensesPage, allExpenses, filterCategories, formCategories,
    totalCount, totalExpenses, avgExpense, filteredTotal,
    isLoading, isFetching, isSubmitting: createMutation.isPending, isDeleting: deleteMutation.isPending,
    confirmDeleteExpense: () => confirmDelete && deleteMutation.mutate(confirmDelete.sync_id),
    openCreateModal: () => { resetForm(); setIsModalOpen(true); },
    handleSubmit, handleExportExcel,
  };
};
