import React, { useState, useMemo } from 'react';
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
  FileSpreadsheet,
  Check,
} from 'lucide-react';
import { api } from '../../lib/api';
import { formatFCFA } from '../../lib/formatters';
import { Product, Category } from '../../types';
import { Drawer } from '../../components/common/Drawer';
import { useDensity } from '../../context/DensityContext';
import { exportToExcel } from '../../lib/exportUtils';
import { ImageUploadInput } from '../../components/common/ImageUploadInput';
import { SummaryChipsRow, SummaryChipItem } from '../../components/common/SummaryChipsRow';
import { FilterPeriodChips, FilterChipItem, SortOption } from '../../components/common/FilterPeriodChips';
import { ViewToggle, ViewMode } from '../../components/common/ViewToggle';
import { ProductCard } from './ProductCard';

export const ProductsPage: React.FC = () => {
  const queryClient = useQueryClient();
  const { tableClasses } = useDensity();
  const [searchTerm, setSearchTerm] = useState('');
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);
  const [stockFilter, setStockFilter] = useState<string>('all');
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [sortBy, setSortBy] = useState<string>('name_asc');
  const [viewMode, setViewMode] = useState<ViewMode>('cards');

  // Form states
  const [name, setName] = useState('');
  const [categoryId, setCategoryId] = useState('');
  const [price, setPrice] = useState<number>(0);
  const [costPrice, setCostPrice] = useState<number>(0);
  const [stock, setStock] = useState<number>(0);
  const [minStock, setMinStock] = useState<number>(5);
  const [unit, setUnit] = useState('pièce');
  const [imagePath, setImagePath] = useState<string | null>(null);

  // Query products
  const { data: products = [], isLoading } = useQuery<Product[]>({
    queryKey: ['products'],
    queryFn: async () => {
      const res = await api.get('/products');
      return res.data;
    },
  });

  // Query categories
  const { data: categories = [] } = useQuery<Category[]>({
    queryKey: ['categories'],
    queryFn: async () => {
      const res = await api.get('/categories');
      return res.data;
    },
  });

  // Mutations
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

  const deleteMutation = useMutation({
    mutationFn: async (id: string) => {
      return api.delete(`/products/${id}`);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['products'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard-stats'] });
    },
  });

  // Stats calculation
  const stats = useMemo(() => {
    let inStock = 0;
    let lowStock = 0;
    let outOfStock = 0;

    products.forEach((p) => {
      if (p.stock <= 0) {
        outOfStock++;
      } else if (p.stock <= (p.min_stock || 5)) {
        lowStock++;
      } else {
        inStock++;
      }
    });

    return { total: products.length, inStock, lowStock, outOfStock };
  }, [products]);

  // Summary chips
  const summaryChips: SummaryChipItem[] = [
    {
      label: 'Articles Référencés',
      value: stats.total,
      color: 'primary',
      icon: <Package className="w-4 h-4" />,
      subtext: 'Catalogue global',
    },
    {
      label: 'En Stock Normal',
      value: stats.inStock,
      color: 'success',
      icon: <CheckCircle className="w-4 h-4" />,
      subtext: 'Disponibilité garantie',
    },
    {
      label: 'Stock Faible',
      value: stats.lowStock,
      color: 'warning',
      icon: <AlertTriangle className="w-4 h-4" />,
      subtext: 'À réapprovisionner',
    },
    {
      label: 'En Rupture',
      value: stats.outOfStock,
      color: stats.outOfStock > 0 ? 'danger' : 'info',
      icon: <AlertTriangle className="w-4 h-4" />,
      subtext: 'Articles indisponibles',
    },
  ];

  // Stock filter chips
  const filterChips: FilterChipItem[] = [
    { id: 'all', label: 'Tous', count: stats.total },
    { id: 'normal', label: 'En Stock', count: stats.inStock },
    { id: 'low', label: 'Stock Faible', count: stats.lowStock },
    { id: 'rupture', label: 'En Rupture', count: stats.outOfStock },
  ];

  const sortOptions: SortOption[] = [
    { id: 'name_asc', label: 'Désignation (A - Z)' },
    { id: 'price_desc', label: 'Prix le plus élevé' },
    { id: 'price_asc', label: 'Prix croissant' },
    { id: 'stock_asc', label: 'Stock le plus faible' },
    { id: 'stock_desc', label: 'Stock le plus élevé' },
  ];

  // Filtered & Sorted products
  const filteredProducts = useMemo(() => {
    return products
      .filter((p) => {
        // Search
        const term = searchTerm.toLowerCase();
        const matchesSearch =
          p.name.toLowerCase().includes(term) ||
          (p.barcode && p.barcode.toLowerCase().includes(term));
        if (!matchesSearch) return false;

        // Category filter
        if (selectedCategory !== 'all' && p.category_sync_id !== selectedCategory) {
          return false;
        }

        // Stock filter
        const isOut = p.stock <= 0;
        const isLow = !isOut && p.stock <= (p.min_stock || 5);
        if (stockFilter === 'normal' && (isOut || isLow)) return false;
        if (stockFilter === 'low' && !isLow) return false;
        if (stockFilter === 'rupture' && !isOut) return false;

        return true;
      })
      .sort((a, b) => {
        if (sortBy === 'price_desc') return b.price - a.price;
        if (sortBy === 'price_asc') return a.price - b.price;
        if (sortBy === 'stock_asc') return a.stock - b.stock;
        if (sortBy === 'stock_desc') return b.stock - a.stock;
        return a.name.localeCompare(b.name);
      });
  }, [products, searchTerm, selectedCategory, stockFilter, sortBy]);

  const openCreateDrawer = () => {
    setEditingProduct(null);
    setName('');
    setCategoryId(categories.length > 0 ? categories[0].sync_id : '');
    setPrice(0);
    setCostPrice(0);
    setStock(0);
    setMinStock(5);
    setUnit('pièce');
    setImagePath(null);
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
    setImagePath(p.image_path || null);
    setIsDrawerOpen(true);
  };

  const closeDrawer = () => {
    setIsDrawerOpen(false);
    setEditingProduct(null);
    setImagePath(null);
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
      image_path: imagePath,
    };

    if (editingProduct) {
      updateMutation.mutate({ id: editingProduct.sync_id, payload });
    } else {
      createMutation.mutate(payload);
    }
  };

  const handleExportExcel = () => {
    const exportData = filteredProducts.map((p) => {
      const cat = categories.find((c) => c.sync_id === p.category_sync_id);
      return {
        'Désignation': p.name,
        'Catégorie': cat?.name || 'Non classé',
        'Prix Vente (FCFA)': p.price,
        'Coût d\'Achat (FCFA)': p.cost_price,
        'Stock Actuel': p.stock,
        'Seuil Alerte': p.min_stock,
        'Unité': p.unit || 'pièce',
        'Code-barres': p.barcode || '',
      };
    });
    exportToExcel(exportData, `catalogue_produits_${new Date().toISOString().slice(0, 10)}.xlsx`, 'Produits & Stocks');
  };

  return (
    <div className="space-y-5 max-w-7xl mx-auto">
      {/* Header: Title & Actions */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">
            Produits & Stocks
          </h1>
          <p className="text-xs sm:text-sm text-[#5A7184] dark:text-slate-400 mt-0.5">
            Catalogue des articles, prix de vente et alertes de réapprovisionnement
          </p>
        </div>

        <div className="flex items-center gap-2 sm:gap-3 flex-wrap">
          <ViewToggle mode={viewMode} onChange={setViewMode} />

          <button
            onClick={handleExportExcel}
            className="btn-toc btn-outline flex items-center justify-center gap-2 py-2 px-3 text-xs font-bold"
            title="Exporter l'inventaire en Excel"
          >
            <FileSpreadsheet className="w-4 h-4 text-emerald-600" />
            <span className="hidden sm:inline">Excel</span>
          </button>

          <button
            onClick={openCreateDrawer}
            className="btn-toc btn-primary flex items-center gap-2 py-2 px-3.5 text-xs font-bold shadow-sm"
          >
            <Plus className="w-4 h-4" />
            <span>Nouvel Article</span>
          </button>
        </div>
      </div>

      {/* Mobile-Style Summary Chips Row */}
      <SummaryChipsRow chips={summaryChips} />

      {/* Search & Stock Filter Bar */}
      <div className="card-toc p-3.5 sm:p-4 space-y-3">
        <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3">
          {/* Search Input */}
          <div className="relative flex-1">
            <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-slate-400">
              <Search className="w-4 h-4" />
            </div>
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Rechercher par nom, code-barres..."
              className="input-toc pl-10 w-full text-xs sm:text-sm"
            />
          </div>

          {/* Category Dropdown */}
          {categories.length > 0 && (
            <div className="w-full sm:w-56">
              <select
                value={selectedCategory}
                onChange={(e) => setSelectedCategory(e.target.value)}
                className="input-toc bg-white dark:bg-dark-800 text-xs sm:text-sm"
              >
                <option value="all">Toutes les catégories</option>
                {categories.map((c) => (
                  <option key={c.sync_id} value={c.sync_id}>
                    {c.name}
                  </option>
                ))}
              </select>
            </div>
          )}
        </div>

        {/* Stock status filter chips & Sort */}
        <FilterPeriodChips
          chips={filterChips}
          selectedChip={stockFilter}
          onSelectChip={setStockFilter}
          sortOptions={sortOptions}
          selectedSort={sortBy}
          onSelectSort={setSortBy}
        />
      </div>

      {/* Content: Cards View (Mobile style) or Table View */}
      {isLoading ? (
        <div className="card-toc p-12 text-center text-slate-400">
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-4 border-brand-500 border-t-transparent mb-3" />
          <p className="text-sm">Chargement des articles...</p>
        </div>
      ) : filteredProducts.length === 0 ? (
        <div className="card-toc p-12 text-center text-slate-400">
          <div className="w-16 h-16 bg-slate-100 dark:bg-dark-700 rounded-full flex items-center justify-center mx-auto mb-3">
            <Package className="w-8 h-8 text-slate-400" />
          </div>
          <h3 className="text-base font-bold text-slate-800 dark:text-slate-200">
            Aucun article trouvé
          </h3>
          <p className="text-xs text-slate-400 mt-1 max-w-sm mx-auto">
            {searchTerm || stockFilter !== 'all' || selectedCategory !== 'all'
              ? 'Aucun article ne correspond aux filtres appliqués.'
              : 'Commencez par ajouter votre premier article au catalogue.'}
          </p>
        </div>
      ) : viewMode === 'cards' ? (
        /* Mobile Cards Grid */
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-3.5">
          {filteredProducts.map((p) => {
            const cat = categories.find((c) => c.sync_id === p.category_sync_id);
            return (
              <ProductCard
                key={p.sync_id}
                product={p}
                categoryName={cat?.name}
                onEdit={openEditDrawer}
                onDelete={(prod) => {
                  if (window.confirm(`Confirmer la suppression de "${prod.name}" ?`)) {
                    deleteMutation.mutate(prod.sync_id);
                  }
                }}
              />
            );
          })}
        </div>
      ) : (
        /* Desktop Table View */
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
                {filteredProducts.map((p) => {
                  const isOut = p.stock <= 0;
                  const isLow = !isOut && p.stock <= (p.min_stock || 5);
                  const cat = categories.find((c) => c.sync_id === p.category_sync_id);

                  return (
                    <tr key={p.sync_id} className="hover:bg-brand-50/30 dark:hover:bg-dark-700/40 transition-colors">
                      <td className={`${tableClasses.td} font-bold text-slate-900 dark:text-white`}>
                        <div className="flex items-center gap-3">
                          {p.image_path ? (
                            <img
                              src={p.image_path}
                              alt={p.name}
                              className="w-9 h-9 rounded-xl object-cover border border-slate-200 dark:border-dark-600 shadow-xs shrink-0"
                            />
                          ) : (
                            <div className="w-9 h-9 rounded-xl bg-brand-50 dark:bg-brand-500/15 text-brand-600 dark:text-brand-400 flex items-center justify-center font-bold shrink-0">
                              <Package className="w-4 h-4" />
                            </div>
                          )}
                          <span className="truncate max-w-[220px]">{p.name}</span>
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
                        {isOut ? (
                          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-bold bg-rose-50 dark:bg-rose-950/40 text-rose-700 dark:text-rose-400 border border-rose-200 dark:border-rose-900/50">
                            <AlertTriangle className="w-3.5 h-3.5 text-rose-600 dark:text-rose-400" />
                            <span>Rupture</span>
                          </span>
                        ) : isLow ? (
                          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-bold bg-amber-50 dark:bg-amber-950/40 text-amber-700 dark:text-amber-400 border border-amber-200 dark:border-amber-900/50">
                            <AlertTriangle className="w-3.5 h-3.5 text-amber-600 dark:text-amber-400" />
                            <span>Faible ({p.stock})</span>
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
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Slide-over Drawer for Product Create / Edit */}
      <Drawer
        isOpen={isDrawerOpen}
        onClose={closeDrawer}
        title={editingProduct ? "Modifier l'Article" : "Ajouter un Nouvel Article"}
        subtitle="Renseignez les informations de prix et de stock"
        footer={
          <div className="flex items-center justify-end gap-2.5 w-full">
            <button
              type="button"
              onClick={closeDrawer}
              className="btn-toc btn-secondary text-xs"
            >
              Annuler
            </button>
            <button
              type="button"
              onClick={handleSubmit}
              disabled={createMutation.isPending || updateMutation.isPending}
              className="btn-toc btn-primary text-xs"
            >
              {createMutation.isPending || updateMutation.isPending
                ? 'Enregistrement...'
                : editingProduct
                ? 'Mettre à jour'
                : "Créer l'article"}
            </button>
          </div>
        }
      >
        <form onSubmit={handleSubmit} className="space-y-4">
          <ImageUploadInput
            value={imagePath}
            onChange={setImagePath}
            label="Photo de l'article"
          />

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
              {categories.map((c) => (
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
                className="input-toc font-bold font-mono"
              />
            </div>
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Coût d'Achat (F CFA)
              </label>
              <input
                type="number"
                min="0"
                value={costPrice}
                onChange={(e) => setCostPrice(Number(e.target.value))}
                className="input-toc font-bold font-mono"
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
                className="input-toc font-bold font-mono"
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
                className="input-toc font-bold font-mono"
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
