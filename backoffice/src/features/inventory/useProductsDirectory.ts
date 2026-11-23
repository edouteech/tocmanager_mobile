import React, { useEffect, useMemo, useState } from 'react';
import { keepPreviousData, useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { categoriesApi, productsApi } from '../../lib/api';
import { exportToExcel } from '../../lib/exportUtils';
import { Category, Product } from '../../types';
import { ProductFormValues } from './ProductFormDrawer';
import { useAuthStore } from '../../stores/authStore';
import { useTenantContextKey } from '../../stores/tenantStore';
import { ViewMode } from '../../components/common/ViewToggle';

export const INITIAL_PRODUCT_FORM: ProductFormValues = {
  name: '',
  categoryId: '',
  price: 0,
  costPrice: 0,
  stock: 0,
  minStock: 5,
  unit: 'pièce',
  barcode: '',
  imagePath: null,
};

export const useProductsDirectory = () => {
  const queryClient = useQueryClient();
  const user = useAuthStore((s) => s.user);
  const canManageProducts = user?.role !== 'cashier';
  const [boutiqueKey, magasinKey] = useTenantContextKey();

  const [searchTerm, setSearchTerm] = useState('');
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);
  const [drawerTab, setDrawerTab] = useState<'info' | 'magasins'>('info');
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);
  const [confirmDelete, setConfirmDelete] = useState<Product | null>(null);
  const [stockFilter, setStockFilter] = useState<string>('all');
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [sortBy, setSortBy] = useState<string>('name_asc');
  const [viewMode, setViewMode] = useState<ViewMode>('cards');
  const [page, setPage] = useState(1);
  const [limit, setLimit] = useState(50);
  const [formValues, setFormValues] = useState<ProductFormValues>(INITIAL_PRODUCT_FORM);
  const [formError, setFormError] = useState<string | null>(null);

  useEffect(() => {
    setPage(1);
  }, [boutiqueKey, magasinKey, searchTerm, selectedCategory, stockFilter, sortBy]);

  const { data: productsPage, isLoading, isFetching } = useQuery({
    queryKey: ['products', boutiqueKey, magasinKey, page, limit, searchTerm, selectedCategory, stockFilter, sortBy],
    queryFn: () =>
      productsApi.getPaginated({
        page,
        limit,
        search: searchTerm || undefined,
        category_id: selectedCategory,
        stock_status: stockFilter,
        sort: sortBy,
      }),
    placeholderData: keepPreviousData,
  });

  const products = useMemo(() => productsPage?.items ?? [], [productsPage?.items]);
  const productSummary = productsPage?.summary;

  const { data: categories = [] } = useQuery<Category[]>({
    queryKey: ['categories', boutiqueKey, magasinKey],
    queryFn: () => categoriesApi.getAll(),
  });

  const categoriesMap = useMemo(
    () => new Map(categories.map((c) => [c.sync_id, c])),
    [categories]
  );

  const closeDrawer = () => {
    setIsDrawerOpen(false);
    setEditingProduct(null);
    setFormValues(INITIAL_PRODUCT_FORM);
    setFormError(null);
  };

  const createMutation = useMutation({
    mutationFn: (payload: Partial<Product>) => productsApi.create(payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['products'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard-stats'] });
      closeDrawer();
    },
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, payload }: { id: string; payload: Partial<Product> }) =>
      productsApi.update(id, payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['products'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard-stats'] });
      closeDrawer();
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => productsApi.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['products'] });
      queryClient.invalidateQueries({ queryKey: ['dashboard-stats'] });
      setConfirmDelete(null);
    },
  });

  const stats = useMemo(() => {
    if (productSummary) {
      return {
        total: productSummary.total,
        inStock: productSummary.in_stock,
        lowStock: productSummary.low_stock,
        outOfStock: productSummary.out_of_stock,
      };
    }
    let inStock = 0;
    let lowStock = 0;
    let outOfStock = 0;
    products.forEach((p) => {
      if (p.stock <= 0) outOfStock++;
      else if (p.stock <= (p.min_stock || 5)) lowStock++;
      else inStock++;
    });
    return { total: products.length, inStock, lowStock, outOfStock };
  }, [productSummary, products]);

  const openCreateDrawer = () => {
    setEditingProduct(null);
    setDrawerTab('info');
    setFormValues({ ...INITIAL_PRODUCT_FORM, categoryId: categories.length > 0 ? categories[0].sync_id : '' });
    setFormError(null);
    setIsDrawerOpen(true);
  };

  const openEditDrawer = (p: Product) => {
    setEditingProduct(p);
    setDrawerTab('info');
    setFormValues({
      name: p.name,
      categoryId: p.category_sync_id || '',
      price: p.price,
      costPrice: p.cost_price,
      stock: p.stock,
      minStock: p.min_stock,
      unit: p.unit || 'pièce',
      barcode: p.barcode || '',
      imagePath: p.image_path || null,
    });
    setFormError(null);
    setIsDrawerOpen(true);
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);
    if (!formValues.name.trim()) return setFormError("Le nom de l'article est obligatoire.");
    if (Number(formValues.price) < 0 || Number(formValues.costPrice) < 0 || Number(formValues.stock) < 0) {
      return setFormError('Les prix et quantités ne peuvent pas être négatifs.');
    }
    const payload = {
      name: formValues.name.trim(),
      category_sync_id: formValues.categoryId || null,
      price: Number(formValues.price),
      cost_price: Number(formValues.costPrice),
      stock: Number(formValues.stock),
      min_stock: Number(formValues.minStock),
      unit: formValues.unit,
      barcode: formValues.barcode.trim() || null,
      image_path: formValues.imagePath,
    };
    if (editingProduct) updateMutation.mutate({ id: editingProduct.sync_id, payload });
    else createMutation.mutate(payload);
  };

  const handleExportExcel = () => {
    const exportData = products.map((p) => {
      const cat = p.category_sync_id ? categoriesMap.get(p.category_sync_id) : undefined;
      return {
        Désignation: p.name,
        Catégorie: cat?.name || 'Non classé',
        'Prix Vente (FCFA)': p.price,
        "Coût d'Achat (FCFA)": p.cost_price,
        'Stock Actuel': p.stock,
        'Seuil Alerte': p.min_stock,
        Unité: p.unit || 'pièce',
        'Code-barres': p.barcode || '',
      };
    });
    exportToExcel(exportData, `catalogue_produits_${new Date().toISOString().slice(0, 10)}.xlsx`, 'Produits & Stocks');
  };

  return {
    canManageProducts, searchTerm, setSearchTerm, isDrawerOpen, drawerTab, setDrawerTab,
    editingProduct, confirmDelete, setConfirmDelete, stockFilter, setStockFilter,
    selectedCategory, setSelectedCategory, sortBy, setSortBy, viewMode, setViewMode,
    page, setPage, limit, setLimit, formValues, setFormValues, formError,
    productsPage, products, categories, categoriesMap, stats, isLoading, isFetching,
    isSubmitting: createMutation.isPending || updateMutation.isPending,
    isDeleting: deleteMutation.isPending,
    confirmDeleteProduct: () => confirmDelete && deleteMutation.mutate(confirmDelete.sync_id),
    closeDrawer, openCreateDrawer, openEditDrawer, handleSubmit, handleExportExcel,
  };
};
