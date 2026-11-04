import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Tag,
  Plus,
  Layers,
  Edit2,
  Trash2,
  Package,
} from 'lucide-react';
import { categoriesApi } from '../../lib/api';
import { formatDateTime } from '../../lib/formatters';
import { Category } from '../../types';
import { Modal } from '../../components/common/Modal';

const PRESET_COLORS = [
  '#29ABE2', // Brand Cyan TocManager
  '#27AE60', // Emerald
  '#F39C12', // Amber
  '#E74C3C', // Coral Danger
  '#8E44AD', // Purple
  '#1A8FBF', // Deep Cyan
  '#5A7184', // Slate
  '#E67E22', // Orange
];

export const CategoriesPage: React.FC = () => {
  const queryClient = useQueryClient();
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedCategory, setSelectedCategory] = useState<Category | null>(null);

  // Form state
  const [form, setForm] = useState({
    name: '',
    description: '',
    color: '#29ABE2',
    icon: 'Package',
  });

  // Query
  const { data: categories = [], isLoading } = useQuery({
    queryKey: ['categories'],
    queryFn: categoriesApi.getAll,
  });

  // Mutations
  const createMutation = useMutation({
    mutationFn: categoriesApi.create,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['categories'] });
      setIsModalOpen(false);
      resetForm();
    },
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: Partial<Category> }) => categoriesApi.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['categories'] });
      setIsModalOpen(false);
      setSelectedCategory(null);
      resetForm();
    },
  });

  const deleteMutation = useMutation({
    mutationFn: categoriesApi.delete,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['categories'] });
    },
  });

  const resetForm = () => {
    setForm({
      name: '',
      description: '',
      color: '#29ABE2',
      icon: 'Package',
    });
  };

  const handleOpenCreate = () => {
    setSelectedCategory(null);
    resetForm();
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
    setIsModalOpen(true);
  };

  const handleDelete = (c: Category) => {
    if (window.confirm(`Confirmer la suppression de la catégorie "${c.name}" ?`)) {
      deleteMutation.mutate(c.sync_id);
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!form.name.trim()) return;

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
      {/* Top Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">Catégories</h1>
          <p className="text-xs sm:text-sm text-[#5A7184] dark:text-slate-400 mt-1">
            Organisation du catalogue d'articles et gestion des rayons
          </p>
        </div>
        <button
          onClick={handleOpenCreate}
          className="btn-primary"
        >
          <Plus className="w-4 h-4" />
          <span>Nouvelle Catégorie</span>
        </button>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
        <div className="card-toc card-hover p-5">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Total Catégories</p>
              <p className="text-2xl font-extrabold text-slate-900 dark:text-white mt-1">{categories.length}</p>
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
              <p className="text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">Articles Classifiés</p>
              <p className="text-2xl font-extrabold text-slate-900 dark:text-white mt-1">{totalProducts}</p>
            </div>
            <div className="w-10 h-10 rounded-xl bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 flex items-center justify-center border border-emerald-100 dark:border-emerald-800/40">
              <Layers className="w-5 h-5" />
            </div>
          </div>
          <p className="text-xs text-slate-400 dark:text-slate-500 mt-3">Produits rattachés à une catégorie</p>
        </div>
      </div>

      {/* Categories Grid */}
      {isLoading ? (
        <div className="card-toc p-12 text-center text-slate-400 text-sm">
          Chargement des catégories...
        </div>
      ) : categories.length === 0 ? (
        <div className="card-toc p-12 text-center text-slate-400 text-sm">
          Aucune catégorie enregistrée. Cliquez sur "Nouvelle Catégorie" pour en créer une.
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
          {categories.map((c) => (
            <div
              key={c.sync_id}
              className="card-toc card-hover p-5 flex flex-col justify-between"
            >
              <div>
                <div className="flex items-start justify-between gap-3">
                  <div className="flex items-center gap-3">
                    <div
                      className="w-10 h-10 rounded-xl flex items-center justify-center text-white font-bold shadow-xs"
                      style={{ backgroundColor: c.color || '#29ABE2' }}
                    >
                      <Tag className="w-5 h-5" />
                    </div>
                    <div>
                      <h3 className="font-bold text-slate-900 dark:text-white text-base">{c.name}</h3>
                      <span className="inline-flex items-center gap-1 text-xs font-medium text-slate-500 dark:text-slate-400 mt-0.5">
                        <Package className="w-3.5 h-3.5 text-brand-500" />
                        {c.products_count || 0} article(s)
                      </span>
                    </div>
                  </div>
                  <div className="flex items-center gap-1">
                    <button
                      onClick={() => handleOpenEdit(c)}
                      className="p-1.5 text-slate-400 hover:text-brand-600 hover:bg-brand-50 dark:hover:bg-dark-700 rounded-xl transition"
                      title="Modifier"
                    >
                      <Edit2 className="w-4 h-4" />
                    </button>
                    <button
                      onClick={() => handleDelete(c)}
                      className="p-1.5 text-slate-400 hover:text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-950/30 rounded-xl transition"
                      title="Supprimer"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                </div>

                {c.description && (
                  <p className="text-xs text-slate-500 dark:text-slate-400 mt-3 line-clamp-2">{c.description}</p>
                )}
              </div>

              <div className="mt-4 pt-3 border-t border-[#E8EFF5] dark:border-dark-600 flex items-center justify-between text-[11px] text-slate-400">
                <span>Créée le {formatDateTime(c.created_at)}</span>
                <span
                  className="w-3.5 h-3.5 rounded-full border border-white dark:border-dark-700 shadow-xs"
                  style={{ backgroundColor: c.color || '#29ABE2' }}
                  title={`Couleur : ${c.color}`}
                ></span>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Modal Création / Modification */}
      <Modal
        isOpen={isModalOpen}
        onClose={() => setIsModalOpen(false)}
        title={selectedCategory ? 'Modifier la Catégorie' : 'Nouvelle Catégorie'}
        subtitle="Définissez le nom et la couleur d'identification"
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
              disabled={createMutation.isPending || updateMutation.isPending || !form.name.trim()}
              className="btn-primary"
            >
              {selectedCategory ? 'Enregistrer' : 'Créer la catégorie'}
            </button>
          </>
        }
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Nom de la catégorie *
            </label>
            <input
              type="text"
              required
              placeholder="Ex: Boissons, Alimentation, Cosmétiques..."
              value={form.name}
              onChange={(e) => setForm({ ...form, name: e.target.value })}
              className="input-toc"
            />
          </div>

          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Description
            </label>
            <textarea
              rows={2}
              placeholder="Courte description ou notes de rayon..."
              value={form.description}
              onChange={(e) => setForm({ ...form, description: e.target.value })}
              className="input-toc"
            ></textarea>
          </div>

          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-2">
              Couleur d'identification
            </label>
            <div className="flex items-center gap-2 flex-wrap">
              {PRESET_COLORS.map((c) => (
                <button
                  key={c}
                  type="button"
                  onClick={() => setForm({ ...form, color: c })}
                  className={`w-7 h-7 rounded-full border-2 transition ${
                    form.color === c ? 'border-brand-500 scale-110 shadow-md ring-2 ring-brand-500/30' : 'border-transparent hover:scale-105'
                  }`}
                  style={{ backgroundColor: c }}
                />
              ))}
              <input
                type="color"
                value={form.color}
                onChange={(e) => setForm({ ...form, color: e.target.value })}
                className="w-8 h-8 rounded-full border border-slate-200 dark:border-dark-600 cursor-pointer p-0.5 bg-transparent"
                title="Choisir une couleur personnalisée"
              />
            </div>
          </div>
        </form>
      </Modal>
    </div>
  );
};
