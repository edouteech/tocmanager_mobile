import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Package,
  Plus,
  Search,
  AlertTriangle,
  Edit2,
  Trash2,
  CheckCircle,
  Tag,
} from 'lucide-react';
import { api } from '../../lib/api';
import { formatFCFA } from '../../lib/formatters';
import { Product, Category } from '../../types';
import { Drawer } from '../../components/common/Drawer';
import { useDensity } from '../../context/DensityContext';

export const ProductsPage: React.FC = () => {
  const queryClient = useQueryClient();
  const { tableClasses } = useDensity();
  const [searchTerm, setSearchTerm] = useState('');
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);

  // Form states
  const [name, setName] = useState('');
  const [categoryId, setCategoryId] = useState('');
  const [price, setPrice] = useState<number>(0);
  const [costPrice, setCostPrice] = useState<number>(0);
  const [stock, setStock] = useState<number>(0);
  const [minStock, setMinStock] = useState<number>(5);
  const [unit, setUnit] = useState('pièce');

  // Query products
  const { data: products, isLoading } = useQuery<Product[]>({
    queryKey: ['products'],
    queryFn: async () => {
      const res = await api.get('/products');
      return res.data;
    },
  });

  // Query categories
  const { data: categories } = useQuery<Category[]>({
    queryKey: ['categories'],
    queryFn: async () => {
      const res = await api.get('/categories');
      return res.data;
    },
  });

  // Create mutation
  const createMutation = useMutation({
    mutationFn: async (payload: any) => {
      return api.post('/products', payload);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['products'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard-stats'] });
      closeDrawer();
    },
  });

  // Update mutation
  const updateMutation = useMutation({
    mutationFn: async ({ id, payload }: { id: string; payload: any }) => {
      return api.put(`/products/${id}`, payload);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['products'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard-stats'] });
      closeDrawer();
    },
  });

  // Delete mutation
  const deleteMutation = useMutation({
    mutationFn: async (id: string) => {
      return api.delete(`/products/${id}`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['products'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard-stats'] });
    },
  });

  const openCreateDrawer = () => {
    setEditingProduct(null);
    setName('');
    setCategoryId(categories && categories.length > 0 ? categories[0].sync_id : '');
    setPrice(0);
    setCostPrice(0);
    setStock(0);
    setMinStock(5);
    setUnit('pièce');
    setIsDrawerOpen(true);
  };

  const openEditDrawer = (p: Product) => {
    setEditingProduct(p);
    setName(p.name);
    setCategoryId(p.category_sync_id || '');
    setPrice(p.price);
    setCostPrice(p.cost_price);
    setStock(p.stock);
    setMinStock(p.min_stock);
    setUnit(p.unit || 'pièce');
    setIsDrawerOpen(true);
  };

  const closeDrawer = () => {
    setIsDrawerOpen(false);
    setEditingProduct(null);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const payload = {
      name,
      category_sync_id: categoryId || null,
      price: Number(price),
      cost_price: Number(costPrice),
      stock: Number(stock),
      min_stock: Number(minStock),
      unit,
    };

    if (editingProduct) {
      updateMutation.mutate({ id: editingProduct.sync_id, payload });
    } else {
      createMutation.mutate(payload);
    }
  };

  const filteredProducts = (products || []).filter((p) =>
    p.name.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Title & Actions */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">
            Produits
          </h1>
          <p className="text-xs sm:text-sm text-[#5A7184] dark:text-slate-400 mt-1">
            Catalogue des articles, prix de vente et gestion des stocks
          </p>
        </div>

        <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3 w-full sm:w-auto">
          <div className="relative w-full sm:w-64">
            <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-slate-400">
              <Search className="w-4 h-4" />
            </div>
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Rechercher un article..."
              className="input-toc pl-10"
            />
          </div>

          <button
            onClick={openCreateDrawer}
            className="btn-primary w-full sm:w-auto justify-center"
          >
            <Plus className="w-4 h-4" />
            <span>Nouvel Article</span>
          </button>
        </div>
      </div>

      {/* Products Table with Density */}
      <div className="card-toc overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left min-w-[700px]">
            <thead className="bg-[#F5FAFD] dark:bg-dark-700/50 border-b border-[#E8EFF5] dark:border-dark-600">
              <tr>
                <th className={tableClasses.th}>Désignation</th>
                <th className={tableClasses.th}>Catégorie</th>
                <th className={`${tableClasses.th} text-right`}>Prix Vente</th>
                <th className={`${tableClasses.th} text-right`}>Coût Achat</th>
                <th className={`${tableClasses.th} text-center`}>Stock Actuel</th>
                <th className={`${tableClasses.th} text-center`}>État Stock</th>
                <th className={`${tableClasses.th} text-right`}>Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#E8EFF5] dark:divide-dark-600/60">
              {isLoading ? (
                <tr>
                  <td colSpan={7} className="px-6 py-12 text-center text-slate-400">
                    Chargement des articles...
                  </td>
                </tr>
              ) : filteredProducts.length > 0 ? (
                filteredProducts.map((p) => {
                  const isLow = p.stock <= p.min_stock;
                  const cat = categories?.find((c) => c.sync_id === p.category_sync_id);

                  return (
                    <tr key={p.sync_id} className="hover:bg-brand-50/30 dark:hover:bg-dark-700/40 transition-colors">
                      <td className={`${tableClasses.td} font-bold text-slate-900 dark:text-white`}>
                        <div className="flex items-center gap-2.5">
                          <div className="w-8 h-8 rounded-xl bg-brand-50 dark:bg-brand-500/15 text-brand-600 dark:text-brand-400 flex items-center justify-center font-bold">
                            <Package className="w-4 h-4" />
                          </div>
                          <span>{p.name}</span>
                        </div>
                      </td>
                      <td className={tableClasses.td}>
                        {cat ? (
                          <span
                            className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-semibold"
                            style={{
                              backgroundColor: `${cat.color || '#29ABE2'}18`,
                              color: cat.color || '#29ABE2',
                            }}
                          >
                            <Tag className="w-3 h-3" />
                            {cat.name}
                          </span>
                        ) : (
                          <span className="text-xs text-slate-400">Non classé</span>
                        )}
                      </td>
                      <td className={`${tableClasses.td} text-right font-extrabold text-slate-900 dark:text-white font-mono`}>
                        {formatFCFA(p.price)}
                      </td>
                      <td className={`${tableClasses.td} text-right text-xs text-slate-500 dark:text-slate-400 font-mono`}>
                        {formatFCFA(p.cost_price)}
                      </td>
                      <td className={`${tableClasses.td} text-center font-bold text-slate-900 dark:text-white`}>
                        {p.stock} <span className="text-xs text-slate-400 font-normal">{p.unit || 'pce'}</span>
                      </td>
                      <td className={`${tableClasses.td} text-center`}>
                        {isLow ? (
                          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-bold bg-rose-50 dark:bg-rose-950/40 text-rose-700 dark:text-rose-400 border border-rose-200 dark:border-rose-900/50">
                            <AlertTriangle className="w-3.5 h-3.5 text-rose-600 dark:text-rose-400" />
                            <span>Stock Bas ({p.min_stock})</span>
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-400 border border-emerald-100 dark:border-emerald-900/50">
                            <CheckCircle className="w-3.5 h-3.5 text-emerald-600 dark:text-emerald-400" />
                            <span>Normal</span>
                          </span>
                        )}
                      </td>
                      <td className={`${tableClasses.td} text-right`}>
                        <div className="flex items-center justify-end gap-2">
                          <button
                            onClick={() => openEditDrawer(p)}
                            className="p-1.5 text-slate-400 hover:text-brand-600 hover:bg-brand-50 dark:hover:bg-dark-700 rounded-xl transition"
                            title="Modifier"
                          >
                            <Edit2 className="w-4 h-4" />
                          </button>
                          <button
                            onClick={() => {
                              if (window.confirm(`Confirmer la suppression de "${p.name}" ?`)) {
                                deleteMutation.mutate(p.sync_id);
                              }
                            }}
                            className="p-1.5 text-slate-400 hover:text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-950/30 rounded-xl transition"
                            title="Supprimer"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })
              ) : (
                <tr>
                  <td colSpan={7} className="px-6 py-12 text-center text-slate-400">
                    Aucun produit trouvé pour cette recherche.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Slide-over Drawer for Product Create / Edit */}
      <Drawer
        isOpen={isDrawerOpen}
        onClose={closeDrawer}
        title={editingProduct ? "Modifier l'Article" : "Ajouter un Nouvel Article"}
        subtitle="Renseignez les informations de prix et de stock"
        footer={
          <>
            <button
              type="button"
              onClick={closeDrawer}
              className="btn-secondary"
            >
              Annuler
            </button>
            <button
              type="button"
              onClick={handleSubmit}
              disabled={createMutation.isPending || updateMutation.isPending}
              className="btn-primary"
            >
              {createMutation.isPending || updateMutation.isPending
                ? 'Enregistrement...'
                : editingProduct
                ? 'Mettre à jour'
                : "Créer l'article"}
            </button>
          </>
        }
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Désignation / Nom de l'Article *
            </label>
            <input
              type="text"
              required
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Ex: Coca-Cola 33cl"
              className="input-toc"
            />
          </div>

          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Catégorie / Rayon
            </label>
            <select
              value={categoryId}
              onChange={(e) => setCategoryId(e.target.value)}
              className="input-toc bg-white dark:bg-dark-700"
            >
              <option value="">Sélectionner une catégorie (optionnel)...</option>
              {(categories || []).map((c) => (
                <option key={c.sync_id} value={c.sync_id}>
                  {c.name}
                </option>
              ))}
            </select>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Prix de Vente (F CFA) *
              </label>
              <input
                type="number"
                min="0"
                required
                value={price}
                onChange={(e) => setPrice(Number(e.target.value))}
                className="input-toc font-bold"
              />
            </div>
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Coût d'Achat Référence (F CFA)
              </label>
              <input
                type="number"
                min="0"
                value={costPrice}
                onChange={(e) => setCostPrice(Number(e.target.value))}
                className="input-toc font-bold"
              />
            </div>
          </div>

          <div className="grid grid-cols-3 gap-3">
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Stock Initial
              </label>
              <input
                type="number"
                min="0"
                value={stock}
                onChange={(e) => setStock(Number(e.target.value))}
                className="input-toc font-bold"
              />
            </div>
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Seuil Alerte
              </label>
              <input
                type="number"
                min="0"
                value={minStock}
                onChange={(e) => setMinStock(Number(e.target.value))}
                className="input-toc font-bold"
              />
            </div>
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Unité
              </label>
              <input
                type="text"
                value={unit}
                onChange={(e) => setUnit(e.target.value)}
                placeholder="pièce, kg, carton..."
                className="input-toc"
              />
            </div>
          </div>
        </form>
      </Drawer>
    </div>
  );
};
