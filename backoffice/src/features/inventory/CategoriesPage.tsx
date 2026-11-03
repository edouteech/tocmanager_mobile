import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Tag,
  Plus,
  Layers,
  Edit2,
  Trash2,
  X,
  Package,
} from 'lucide-react';
import { categoriesApi } from '../../lib/api';
import { formatDateTime } from '../../lib/formatters';
import { Category } from '../../types';

const PRESET_COLORS = [
  '#4F46E5', // Indigo
  '#059669', // Emerald
  '#D97706', // Amber
  '#E11D48', // Rose
  '#0284C7', // Sky
  '#7C3AED', // Purple
  '#475569', // Slate
  '#EA580C', // Orange
];

export const CategoriesPage: React.FC = () => {
  const queryClient = useQueryClient();
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedCategory, setSelectedCategory] = useState<Category | null>(null);

  // Form state
  const [form, setForm] = useState({
    name: '',
    description: '',
    color: '#4F46E5',
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
      color: '#4F46E5',
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
      color: c.color || '#4F46E5',
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
    <div className="space-y-6">
      {/* Top Header */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Catégories de Produits</h1>
          <p className="text-sm text-slate-500">
            Organisation du catalogue d'articles et gestion des rayons
          </p>
        </div>
        <button
          onClick={handleOpenCreate}
          className="inline-flex items-center gap-2 px-4 py-2.5 bg-indigo-600 text-white rounded-lg text-sm font-medium hover:bg-indigo-700 transition shadow-sm"
        >
          <Plus className="w-4 h-4" />
          <span>Nouvelle Catégorie</span>
        </button>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-medium text-slate-500 uppercase tracking-wider">Total Catégories</p>
              <p className="text-2xl font-bold text-slate-900 mt-1">{categories.length}</p>
            </div>
            <div className="w-10 h-10 rounded-lg bg-indigo-50 text-indigo-600 flex items-center justify-center">
              <Tag className="w-5 h-5" />
            </div>
          </div>
          <p className="text-xs text-slate-400 mt-3">Familles de produits actives</p>
        </div>

        <div className="bg-white p-5 rounded-xl border border-slate-200 shadow-sm">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-medium text-slate-500 uppercase tracking-wider">Articles Classifiés</p>
              <p className="text-2xl font-bold text-slate-900 mt-1">{totalProducts}</p>
            </div>
            <div className="w-10 h-10 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center">
              <Layers className="w-5 h-5" />
            </div>
          </div>
          <p className="text-xs text-slate-400 mt-3">Produits rattachés à une catégorie</p>
        </div>
      </div>

      {/* Categories Grid */}
      {isLoading ? (
        <div className="bg-white p-12 text-center text-slate-400 text-sm rounded-xl border border-slate-200">
          Chargement des catégories...
        </div>
      ) : categories.length === 0 ? (
        <div className="bg-white p-12 text-center text-slate-400 text-sm rounded-xl border border-slate-200">
          Aucune catégorie enregistrée. Cliquez sur "Nouvelle Catégorie" pour en créer une.
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
          {categories.map((c) => (
            <div
              key={c.sync_id}
              className="bg-white rounded-xl border border-slate-200 p-5 shadow-sm hover:shadow-md transition flex flex-col justify-between"
            >
              <div>
                <div className="flex items-start justify-between gap-3">
                  <div className="flex items-center gap-3">
                    <div
                      className="w-10 h-10 rounded-lg flex items-center justify-center text-white font-bold shadow-xs"
                      style={{ backgroundColor: c.color || '#4F46E5' }}
                    >
                      <Tag className="w-5 h-5" />
                    </div>
                    <div>
                      <h3 className="font-bold text-slate-900 text-base">{c.name}</h3>
                      <span className="inline-flex items-center gap-1 text-xs font-medium text-slate-500 mt-0.5">
                        <Package className="w-3.5 h-3.5 text-slate-400" />
                        {c.products_count || 0} article(s)
                      </span>
                    </div>
                  </div>
                  <div className="flex items-center gap-1">
                    <button
                      onClick={() => handleOpenEdit(c)}
                      className="p-1.5 text-slate-400 hover:text-indigo-600 hover:bg-indigo-50 rounded transition"
                      title="Modifier"
                    >
                      <Edit2 className="w-4 h-4" />
                    </button>
                    <button
                      onClick={() => handleDelete(c)}
                      className="p-1.5 text-slate-400 hover:text-rose-600 hover:bg-rose-50 rounded transition"
                      title="Supprimer"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                </div>

                {c.description && (
                  <p className="text-xs text-slate-500 mt-3 line-clamp-2">{c.description}</p>
                )}
              </div>

              <div className="mt-4 pt-3 border-t border-slate-100 flex items-center justify-between text-[11px] text-slate-400">
                <span>Créée le {formatDateTime(c.created_at)}</span>
                <span
                  className="w-3 h-3 rounded-full border border-white shadow-xs"
                  style={{ backgroundColor: c.color || '#4F46E5' }}
                  title={`Couleur : ${c.color}`}
                ></span>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Modal Création / Modification */}
      {isModalOpen && (
        <div className="fixed inset-0 z-50 bg-slate-900/40 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-xl shadow-xl border border-slate-200 w-full max-w-md overflow-hidden animate-in fade-in zoom-in-95 duration-150">
            <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between">
              <h2 className="text-base font-bold text-slate-900">
                {selectedCategory ? 'Modifier la Catégorie' : 'Nouvelle Catégorie'}
              </h2>
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
                  Nom de la catégorie *
                </label>
                <input
                  type="text"
                  required
                  placeholder="Ex: Boissons, Alimentation, Cosmétiques..."
                  value={form.name}
                  onChange={(e) => setForm({ ...form, name: e.target.value })}
                  className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500"
                />
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-1">
                  Description
                </label>
                <textarea
                  rows={2}
                  placeholder="Courte description ou notes de rayon..."
                  value={form.description}
                  onChange={(e) => setForm({ ...form, description: e.target.value })}
                  className="w-full px-3 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500"
                ></textarea>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 uppercase tracking-wider mb-2">
                  Couleur d'identification
                </label>
                <div className="flex items-center gap-2 flex-wrap">
                  {PRESET_COLORS.map((c) => (
                    <button
                      key={c}
                      type="button"
                      onClick={() => setForm({ ...form, color: c })}
                      className={`w-7 h-7 rounded-full border-2 transition ${
                        form.color === c ? 'border-slate-900 scale-110 shadow-xs' : 'border-transparent hover:scale-105'
                      }`}
                      style={{ backgroundColor: c }}
                    />
                  ))}
                  <input
                    type="color"
                    value={form.color}
                    onChange={(e) => setForm({ ...form, color: e.target.value })}
                    className="w-8 h-8 rounded-full border border-slate-200 cursor-pointer p-0.5"
                    title="Choisir une couleur personnalisée"
                  />
                </div>
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
                  disabled={createMutation.isPending || updateMutation.isPending || !form.name.trim()}
                  className="px-4 py-2 bg-indigo-600 text-white rounded-lg text-sm font-medium hover:bg-indigo-700 transition disabled:opacity-50"
                >
                  {selectedCategory ? 'Enregistrer' : 'Créer la catégorie'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
