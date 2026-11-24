import React from 'react';
import { Package, Plus, Search, AlertTriangle, CheckCircle, FileSpreadsheet } from 'lucide-react';
import { ConfirmModal } from '../../components/common/ConfirmModal';
import { IconInput } from '../../components/common/IconInput';
import { PaginationControls } from '../../components/common/PaginationControls';
import { SummaryChipsRow, SummaryChipItem } from '../../components/common/SummaryChipsRow';
import { FilterPeriodChips, FilterChipItem, SortOption } from '../../components/common/FilterPeriodChips';
import { ViewToggle } from '../../components/common/ViewToggle';
import { ProductCard } from './ProductCard';
import { ProductsTable } from './ProductsTable';
import { ProductFormDrawer } from './ProductFormDrawer';
import { useProductsDirectory } from './useProductsDirectory';

const SORT_OPTIONS: SortOption[] = [
  { id: 'name_asc', label: 'Désignation (A - Z)' },
  { id: 'price_desc', label: 'Prix le plus élevé' },
  { id: 'price_asc', label: 'Prix croissant' },
  { id: 'stock_asc', label: 'Stock le plus faible' },
  { id: 'stock_desc', label: 'Stock le plus élevé' },
];

export const ProductsPage: React.FC = () => {
  const {
    canManageProducts, searchTerm, setSearchTerm, isDrawerOpen, drawerTab, setDrawerTab,
    editingProduct, confirmDelete, setConfirmDelete, stockFilter, setStockFilter,
    selectedCategory, setSelectedCategory, sortBy, setSortBy, viewMode, setViewMode,
    page, setPage, limit, setLimit, formValues, setFormValues, formError,
    productsPage, products, categories, categoriesMap, stats, isLoading, isFetching,
    isSubmitting, isDeleting, confirmDeleteProduct,
    closeDrawer, openCreateDrawer, openEditDrawer, handleSubmit, handleExportExcel,
  } = useProductsDirectory();

  const summaryChips: SummaryChipItem[] = [
    { label: 'Articles Référencés', value: stats.total, color: 'primary', icon: <Package className="w-4 h-4" />, subtext: 'Catalogue global' },
    { label: 'En Stock Normal', value: stats.inStock, color: 'success', icon: <CheckCircle className="w-4 h-4" />, subtext: 'Disponibilité garantie' },
    { label: 'Stock Faible', value: stats.lowStock, color: 'warning', icon: <AlertTriangle className="w-4 h-4" />, subtext: 'À réapprovisionner' },
    { label: 'En Rupture', value: stats.outOfStock, color: stats.outOfStock > 0 ? 'danger' : 'info', icon: <AlertTriangle className="w-4 h-4" />, subtext: 'Articles indisponibles' },
  ];

  const filterChips: FilterChipItem[] = [
    { id: 'all', label: 'Tous', count: stats.total },
    { id: 'normal', label: 'En Stock', count: stats.inStock },
    { id: 'low', label: 'Stock Faible', count: stats.lowStock },
    { id: 'rupture', label: 'En Rupture', count: stats.outOfStock },
  ];

  return (
    <div className="space-y-5 max-w-7xl mx-auto">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">Produits & Stocks</h1>
          <p className="text-xs sm:text-sm text-[#5A7184] dark:text-slate-400 mt-0.5">
            Catalogue des articles, prix de vente et alertes de réapprovisionnement
          </p>
        </div>

        <div className="flex items-center gap-2 sm:gap-3 flex-wrap">
          <ViewToggle mode={viewMode} onChange={setViewMode} />
          <button onClick={handleExportExcel} className="btn-secondary flex items-center justify-center gap-2 py-2 px-3 text-xs font-bold" title="Exporter l'inventaire en Excel">
            <FileSpreadsheet className="w-4 h-4 text-emerald-600" />
            <span className="hidden sm:inline">Excel</span>
          </button>
          {canManageProducts && (
            <button onClick={openCreateDrawer} className="btn-primary flex items-center gap-2 py-2 px-3.5 text-xs font-bold shadow-sm">
              <Plus className="w-4 h-4" />
              <span>Nouvel Article</span>
            </button>
          )}
        </div>
      </div>

      <SummaryChipsRow chips={summaryChips} />

      <div className="card-toc p-3.5 sm:p-4 space-y-3">
        <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3">
          <IconInput
            containerClassName="flex-1"
            icon={<Search className="w-4 h-4" />}
            iconClassName="text-slate-400"
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder="Rechercher par nom, code-barres..."
            className="text-xs sm:text-sm"
          />
          {categories.length > 0 && (
            <div className="w-full sm:w-56">
              <select value={selectedCategory} onChange={(e) => setSelectedCategory(e.target.value)} className="input-toc bg-white dark:bg-dark-800 text-xs sm:text-sm">
                <option value="all">Toutes les catégories</option>
                {categories.map((c) => (
                  <option key={c.sync_id} value={c.sync_id}>{c.name}</option>
                ))}
              </select>
            </div>
          )}
        </div>
        <FilterPeriodChips chips={filterChips} selectedChip={stockFilter} onSelectChip={setStockFilter} sortOptions={SORT_OPTIONS} selectedSort={sortBy} onSelectSort={setSortBy} />
      </div>

      {isLoading ? (
        <div className="card-toc p-12 text-center text-slate-400">
          <div className="inline-block animate-spin rounded-full h-8 w-8 border-4 border-brand-500 border-t-transparent mb-3" />
          <p className="text-sm">Chargement des articles...</p>
        </div>
      ) : products.length === 0 ? (
        <div className="card-toc p-12 text-center text-slate-400">
          <div className="w-16 h-16 bg-slate-100 dark:bg-dark-700 rounded-full flex items-center justify-center mx-auto mb-3">
            <Package className="w-8 h-8 text-slate-400" />
          </div>
          <h3 className="text-base font-bold text-slate-800 dark:text-slate-200">Aucun article trouvé</h3>
          <p className="text-xs text-slate-400 mt-1 max-w-sm mx-auto">
            {searchTerm || stockFilter !== 'all' || selectedCategory !== 'all'
              ? 'Aucun article ne correspond aux filtres appliqués.'
              : 'Commencez par ajouter votre premier article au catalogue.'}
          </p>
        </div>
      ) : viewMode === 'cards' ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-3.5">
          {products.map((p) => (
            <ProductCard
              key={p.sync_id}
              product={p}
              categoryName={p.category_sync_id ? categoriesMap.get(p.category_sync_id)?.name : undefined}
              canManage={canManageProducts}
              onEdit={openEditDrawer}
              onDelete={setConfirmDelete}
            />
          ))}
        </div>
      ) : (
        <ProductsTable products={products} categoriesMap={categoriesMap} canManage={canManageProducts} onEdit={openEditDrawer} onDelete={setConfirmDelete} />
      )}

      <PaginationControls
        page={productsPage?.page || page}
        pages={productsPage?.pages || 1}
        total={productsPage?.total || 0}
        limit={limit}
        onPageChange={setPage}
        onLimitChange={(nextLimit) => {
          setLimit(nextLimit);
          setPage(1);
        }}
        itemLabel="produits"
        isFetching={isFetching}
      />

      <ProductFormDrawer
        isOpen={isDrawerOpen}
        editingProduct={editingProduct}
        drawerTab={drawerTab}
        categories={categories}
        values={formValues}
        formError={formError}
        isSubmitting={isSubmitting}
        onClose={closeDrawer}
        onTabChange={setDrawerTab}
        onChange={setFormValues}
        onSubmit={handleSubmit}
      />

      <ConfirmModal
        isOpen={Boolean(confirmDelete)}
        onClose={() => setConfirmDelete(null)}
        onConfirm={confirmDeleteProduct}
        title="Supprimer l'article"
        message={confirmDelete ? `Confirmer la suppression de "${confirmDelete.name}" ?` : ''}
        confirmLabel="Supprimer"
        isPending={isDeleting}
      />
    </div>
  );
};
