import axios from 'axios';
import {
  AuthResponse,
  DashboardStats,
  Vente,
  Product,
  Category,
  Client,
  Supplier,
  Approvisionnement,
  Decaissement,
  StoreSettings,
  FinancialReport,
} from '../types';

const API_BASE_URL = import.meta.env.VITE_API_URL || '/api/v1';

export const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor to attach Bearer token
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('toc_access_token');
  if (token && config.headers) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Response interceptor to handle token expiration & automatic refresh
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;
      const refreshToken = localStorage.getItem('toc_refresh_token');
      if (refreshToken) {
        try {
          const res = await axios.post(`${API_BASE_URL}/auth/refresh`, {
            refresh_token: refreshToken,
          });
          const { access_token, refresh_token: newRefresh } = res.data;
          localStorage.setItem('toc_access_token', access_token);
          if (newRefresh) {
            localStorage.setItem('toc_refresh_token', newRefresh);
          }
          originalRequest.headers.Authorization = `Bearer ${access_token}`;
          return api(originalRequest);
        } catch {
          localStorage.removeItem('toc_access_token');
          localStorage.removeItem('toc_refresh_token');
          localStorage.removeItem('toc_user');
          window.location.href = '/login';
        }
      } else {
        localStorage.removeItem('toc_access_token');
        localStorage.removeItem('toc_refresh_token');
        localStorage.removeItem('toc_user');
        window.location.href = '/login';
      }
    }
    return Promise.reject(error);
  }
);

// --- API Services ---

export const clientsApi = {
  getAll: (params?: { q?: string; only_debtors?: boolean }) =>
    api.get<Client[]>('/clients', { params }).then((r) => r.data),
  getById: (id: string) => api.get<Client>(`/clients/${id}`).then((r) => r.data),
  create: (data: Partial<Client>) => api.post<Client>('/clients', data).then((r) => r.data),
  update: (id: string, data: Partial<Client>) => api.put<Client>(`/clients/${id}`, data).then((r) => r.data),
  delete: (id: string) => api.delete(`/clients/${id}`),
  recordPayment: (id: string, payment: { amount: number; payment_method: string; notes?: string }) =>
    api.post<Client>(`/clients/${id}/payments`, payment).then((r) => r.data),
};

export const suppliersApi = {
  getAll: (params?: { q?: string; only_creditors?: boolean }) =>
    api.get<Supplier[]>('/suppliers', { params }).then((r) => r.data),
  getById: (id: string) => api.get<Supplier>(`/suppliers/${id}`).then((r) => r.data),
  create: (data: Partial<Supplier>) => api.post<Supplier>('/suppliers', data).then((r) => r.data),
  update: (id: string, data: Partial<Supplier>) => api.put<Supplier>(`/suppliers/${id}`, data).then((r) => r.data),
  delete: (id: string) => api.delete(`/suppliers/${id}`),
  recordPayment: (id: string, payment: { amount: number; payment_method: string; notes?: string }) =>
    api.post<Supplier>(`/suppliers/${id}/payments`, payment).then((r) => r.data),
};

export const approvisionnementsApi = {
  getAll: (params?: { product_sync_id?: string; supplier_sync_id?: string }) =>
    api.get<Approvisionnement[]>('/approvisionnements', { params }).then((r) => r.data),
  create: (data: {
    product_sync_id: string;
    product_name?: string;
    supplier_sync_id?: string;
    supplier_name?: string;
    quantity: number;
    unit_cost: number;
    payment_status: string;
    notes?: string;
    date?: string;
  }) => api.post<Approvisionnement>('/approvisionnements', data).then((r) => r.data),
};

export const decaissementsApi = {
  getAll: (params?: { category?: string; start_date?: string; end_date?: string }) =>
    api.get<Decaissement[]>('/decaissements', { params }).then((r) => r.data),
  getCategories: (params?: { include_defaults?: boolean }) =>
    api.get<string[]>('/decaissements/categories', { params }).then((r) => r.data),
  create: (data: {
    title: string;
    amount: number;
    category?: string;
    beneficiary?: string;
    payment_method: string;
    notes?: string;
    date?: string;
  }) => api.post<Decaissement>('/decaissements', data).then((r) => r.data),
  delete: (id: string) => api.delete(`/decaissements/${id}`),
};

export const categoriesApi = {
  getAll: () => api.get<Category[]>('/categories').then((r) => r.data),
  create: (data: Partial<Category>) => api.post<Category>('/categories', data).then((r) => r.data),
  update: (id: string, data: Partial<Category>) => api.put<Category>(`/categories/${id}`, data).then((r) => r.data),
  delete: (id: string) => api.delete(`/categories/${id}`),
};

export const productsApi = {
  getAll: (params?: { q?: string; category_id?: string }) =>
    api.get<Product[]>('/products', { params }).then((r) => r.data),
  create: (data: Partial<Product>) => api.post<Product>('/products', data).then((r) => r.data),
  update: (id: string, data: Partial<Product>) => api.put<Product>(`/products/${id}`, data).then((r) => r.data),
  delete: (id: string) => api.delete(`/products/${id}`),
};

export const reportsApi = {
  getDashboard: () => api.get<DashboardStats>('/reports/dashboard').then((r) => r.data),
  getFinancial: (params?: { start_date?: string; end_date?: string }) =>
    api.get<FinancialReport>('/reports/financial', { params }).then((r) => r.data),
};

export const settingsApi = {
  getSettings: () => api.get<StoreSettings>('/settings').then((r) => r.data),
  updateSettings: (data: StoreSettings) => api.put<StoreSettings>('/settings', data).then((r) => r.data),
};
