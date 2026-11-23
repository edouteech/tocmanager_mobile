import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Tag, Plus, Layers } from 'lucide-react';
import { categoriesApi } from '../../lib/api';
import { Category } from '../../types';
import { ConfirmModal } from '../../components/common/ConfirmModal';
import { useAuthStore } from '../../stores/authStore';
import { useTenantContextKey } from '../../stores/tenantStore';
import { CategoryFormModal, CategoryFormState } from './CategoryFormModal';
import { CategoryGrid } from './CategoryGrid';

const INITIAL_FORM: CategoryFormState = {
  name: '',
  description: '',
  color: '#29ABE2',
  icon: 'Package',
};

export const CategoriesPage: React.FC = () => {
  const queryClient = useQueryClient();
  const user = useAuthStore((s) => s.user);
  const canManageCategories = user?.role !== 'cashier';
  const [boutiqueKey, magasinKey] = useTenantContextKey();
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedCategory, setSelectedCategory] = useState<Category | null>(null);
  const [confirmDelete, setConfirmDelete] = useState<Category | null>(null);
  const [form, setForm] = useState<CategoryFormState>(INITIAL_FORM);
  const [formError, setFormError] = useState<string | null>(null);

  const { data: categories = [], isLoading } = useQuery({
    queryKey: ['categories', boutiqueKey, magasinKey],
    queryFn: categoriesApi.getAll,
  });

  const createMutation = useMutation({
    mutationFn: categoriesApi.create,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['categories'] });
      setIsModalOpen(false);
      setForm(INITIAL_FORM);
    },
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: Partial<Category> }) =>
      categoriesApi.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['categories'] });
      setIsModalOpen(false);
      setSelectedCategory(null);
      setForm(INITIAL_FORM);
    },
  });

  const deleteMutation = useMutation({
    mutationFn: categoriesApi.delete,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['categories'] });
      setConfirmDelete(null);
    },
  });

  const handleOpenCreate = () => {
    setSelectedCategory(null);
    setForm(INITIAL_FORM);
    setFormError(null);
    setIsModalOpen(true);
  };

  const handleOpenEdit = (c: Category) => {
    setSelectedCategory(c);
    setForm({
      name: c.name,
      description: c.description || '',
      color: c.color || '#29ABE2',
      icon: c.icon || 'Package',
    });
    setFormError(null);
    setIsModalOpen(true);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);
    if (!form.name.trim()) {
      setFormError('Le nom de la catégorie est obligatoire.');
      return;
    }

    if (selectedCategory) {
      updateMutation.mutate({
        id: selectedCategory.sync_id,
        data: {
          name: form.name.trim(),
          description: form.description.trim() || null,
          color: form.color,
          icon: form.icon,
        },
      });
    } else {
      createMutation.mutate({
        name: form.name.trim(),
        description: form.description.trim() || undefined,
        color: form.color,
        icon: form.icon,
      });
    }
  };

  const totalProducts = categories.reduce((sum, c) => sum + (c.products_count || 0), 0);

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">
            Catégories
          </h1>
          <p className="text-xs sm:text-sm text-[#5A7184] dark:text-slate-400 mt-1">
            Organisation du catalogue d'articles et gestion des rayons
          </p>
        </div>
        {canManageCategories && (
          <button onClick={handleOpenCreate} className="btn-primary">
            <Plus className="w-4 h-4" />
            <span>Nouvelle Catégorie</span>
          </button>
        )}
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
        <div className="card-toc card-hover p-5">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                Total Catégories
              </p>
              <p className="text-2xl font-extrabold text-slate-900 dark:text-white mt-1">
                {categories.length}
              </p>
            </div>
            <div className="w-10 h-10 rounded-xl bg-brand-50 dark:bg-brand-500/15 text-brand-600 dark:text-brand-400 flex items-center justify-center border border-brand-200 dark:border-brand-500/30">
              <Tag className="w-5 h-5" />
            </div>
          </div>
          <p className="text-xs text-slate-400 dark:text-slate-500 mt-3">Familles de produits actives</p>
        </div>

        <div className="card-toc card-hover p-5">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                Articles Classifiés
              </p>
              <p className="text-2xl font-extrabold text-slate-900 dark:text-white mt-1">
                {totalProducts}
              </p>
            </div>
            <div className="w-10 h-10 rounded-xl bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 flex items-center justify-center border border-emerald-100 dark:border-emerald-800/40">
              <Layers className="w-5 h-5" />
            </div>
          </div>
          <p className="text-xs text-slate-400 dark:text-slate-500 mt-3">
            Produits rattachés à une catégorie
          </p>
        </div>
      </div>

      {isLoading ? (
        <div className="card-toc p-12 text-center text-slate-400 text-sm">
          Chargement des catégories...
        </div>
      ) : categories.length === 0 ? (
        <div className="card-toc p-12 text-center text-slate-400 text-sm">
          Aucune catégorie enregistrée. Cliquez sur "Nouvelle Catégorie" pour en créer une.
        </div>
      ) : (
        <CategoryGrid
          categories={categories}
          canManage={canManageCategories}
          onEdit={handleOpenEdit}
          onDelete={setConfirmDelete}
        />
      )}

      <CategoryFormModal
        isOpen={isModalOpen}
        isEditing={Boolean(selectedCategory)}
        form={form}
        formError={formError}
        isPending={createMutation.isPending || updateMutation.isPending}
        onClose={() => setIsModalOpen(false)}
        onChange={setForm}
        onSubmit={handleSubmit}
      />

      <ConfirmModal
        isOpen={Boolean(confirmDelete)}
        onClose={() => setConfirmDelete(null)}
        onConfirm={() => {
          if (confirmDelete) {
            deleteMutation.mutate(confirmDelete.sync_id);
          }
        }}
        title="Supprimer la catégorie"
        message={
          confirmDelete
            ? `Confirmer la suppression de la catégorie "${confirmDelete.name}" ?`
            : ''
        }
        confirmLabel="Supprimer"
        isPending={deleteMutation.isPending}
      />
    </div>
  );
};
