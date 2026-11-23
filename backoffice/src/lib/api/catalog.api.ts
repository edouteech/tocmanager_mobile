import { api } from './client';
import type {
  Approvisionnement,
  Category,
  PaginatedResponse,
  Product,
  ProductMagasinItem,
  StockMovement,
  StockTransfer,
} from '../../types';

export const productsApi = {
  getAll: (params?: {
    search?: string;
    category_id?: string;
    only_available?: boolean;
    magasin_id?: string;
    limit?: number;
  }) =>
    api
      .get<Product[]>('/products', {
        params: {
          search: params?.search,
          category_id: params?.category_id,
          only_available: params?.only_available,
          limit: params?.limit,
        },
        headers: params?.magasin_id ? { 'X-Magasin-Id': params.magasin_id } : undefined,
      })
      .then((r) => r.data),
  getPaginated: (params?: {
    page?: number;
    limit?: number;
    search?: string;
    category_id?: string;
    stock_status?: string;
    sort?: string;
    only_available?: boolean;
    magasin_id?: string;
  }) =>
    api
      .get<
        PaginatedResponse<
          Product,
          { total: number; in_stock: number; low_stock: number; out_of_stock: number }
        >
      >('/products', {
        params: {
          paginated: true,
          page: params?.page ?? 1,
          limit: params?.limit ?? 50,
          search: params?.search || undefined,
          category_id:
            params?.category_id && params.category_id !== 'all' ? params.category_id : undefined,
          stock_status:
            params?.stock_status && params.stock_status !== 'all'
              ? params.stock_status
              : undefined,
          sort: params?.sort || undefined,
          only_available: params?.only_available,
        },
        headers: params?.magasin_id ? { 'X-Magasin-Id': params.magasin_id } : undefined,
      })
      .then((r) => r.data),
  create: (data: Partial<Product>) => api.post<Product>('/products', data).then((r) => r.data),
  update: (id: string, data: Partial<Product>) =>
    api.put<Product>(`/products/${id}`, data).then((r) => r.data),
  delete: (id: string) => api.delete(`/products/${id}`).then((r) => r.data),
  getMagasins: (syncId: string) =>
    api.get<ProductMagasinItem[]>(`/products/${syncId}/magasins`).then((r) => r.data),
  updateMagasinConfig: (
    syncId: string,
    magasinId: string,
    payload: {
      is_available?: boolean;
      custom_price?: number | null;
      clear_custom_price?: boolean;
      min_stock?: number;
    }
  ) =>
    api
      .put<ProductMagasinItem>(`/products/${syncId}/magasins/${magasinId}`, payload)
      .then((r) => r.data),
};

export const categoriesApi = {
  getAll: () => api.get<Category[]>('/categories').then((r) => r.data),
  create: (data: Partial<Category>) => api.post<Category>('/categories', data).then((r) => r.data),
  update: (id: string, data: Partial<Category>) =>
    api.put<Category>(`/categories/${id}`, data).then((r) => r.data),
  delete: (id: string) => api.delete(`/categories/${id}`).then((r) => r.data),
};

export const approvisionnementsApi = {
  getAll: () => api.get<Approvisionnement[]>('/approvisionnements').then((r) => r.data),
  getPaginated: (params?: {
    page?: number;
    limit?: number;
    q?: string;
    product_sync_id?: string;
    supplier_sync_id?: string;
    start_date?: string;
    end_date?: string;
  }) =>
    api
      .get<
        PaginatedResponse<
          Approvisionnement,
          { total_count: number; total_cost: number; total_quantity: number; filtered_cost: number }
        >
      >('/approvisionnements', {
        params: {
          paginated: true,
          page: params?.page ?? 1,
          limit: params?.limit ?? 50,
          q: params?.q || undefined,
          product_sync_id: params?.product_sync_id || undefined,
          supplier_sync_id: params?.supplier_sync_id || undefined,
          start_date: params?.start_date || undefined,
          end_date: params?.end_date || undefined,
        },
      })
      .then((r) => r.data),
  create: (data: Partial<Approvisionnement>) =>
    api.post<Approvisionnement>('/approvisionnements', data).then((r) => r.data),
};

export const transfersApi = {
  getAll: (params?: { status?: string }) =>
    api.get<StockTransfer[]>('/transfers', { params }).then((r) => r.data),
  create: (data: {
    from_magasin_id: string;
    to_magasin_id: string;
    items: { product_sync_id: string; quantity_sent: number }[];
    notes?: string;
    ship_immediately?: boolean;
  }) => api.post<StockTransfer>('/transfers', data).then((r) => r.data),
  receive: (
    id: string,
    payload?: { items?: { product_sync_id: string; quantity_received: number }[]; notes?: string }
  ) => api.post<StockTransfer>(`/transfers/${id}/receive`, payload || {}).then((r) => r.data),
  cancel: (id: string) => api.post<StockTransfer>(`/transfers/${id}/cancel`).then((r) => r.data),
};

export const stockMovementsApi = {
  getAll: (params?: {
    product_sync_id?: string;
    magasin_id?: string;
    movement_type?: string;
  }) => api.get<StockMovement[]>('/stock-movements', { params }).then((r) => r.data),
  adjust: (data: {
    magasin_id?: string;
    product_sync_id: string;
    counted_quantity?: number;
    quantity_delta?: number;
    movement_type?: 'adjustment' | 'loss';
    reason: string;
  }) => api.post<StockMovement>('/stock-movements/adjust', data).then((r) => r.data),
};
