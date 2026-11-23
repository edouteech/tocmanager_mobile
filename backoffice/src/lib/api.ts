import axios from 'axios';
import {
  AuthResponse,
  DashboardStats,
  Vente,
  VenteCreate,
  Product,
  Category,
  Client,
  Supplier,
  Approvisionnement,
  Decaissement,
  StoreSettings,
  FinancialReport,
  UserBrief,
  SaasPlan,
  Boutique,
  Magasin,
  CurrentPlanStatus,
  PlatformKPIs,
  FeatureCatalogItem,
  PaymentProviderPublic,
  CheckoutResponse,
  TransactionStatusResponse,
  SaasInvoice,
} from '../types';

const API_BASE_URL = import.meta.env.VITE_API_URL || '/api/v1';

export const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor to attach Bearer token and active Tenant context
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('toc_access_token');
  if (token && config.headers) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  const boutiqueId = localStorage.getItem('toc_current_boutique_id');
  if (boutiqueId && config.headers) {
    config.headers['X-Boutique-Id'] = boutiqueId;
  }
  const magasinId = localStorage.getItem('toc_current_magasin_id');
  if (magasinId && config.headers) {
    config.headers['X-Magasin-Id'] = magasinId;
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
        } catch (refreshErr) {
          localStorage.removeItem('toc_access_token');
          localStorage.removeItem('toc_refresh_token');
          window.location.href = '/login';
          return Promise.reject(refreshErr);
        }
      } else {
        localStorage.removeItem('toc_access_token');
        window.location.href = '/login';
      }
    }
    if (error.response?.status === 403) {
      const detail = error.response?.data?.detail;
      if (
        detail &&
        typeof detail === 'object' &&
        (detail.error === 'PLAN_FEATURE_LOCKED' || detail.error === 'PLAN_QUOTA_EXCEEDED')
      ) {
        window.dispatchEvent(new CustomEvent('toc:plan-upgrade-required', { detail }));
      }
    }
    return Promise.reject(error);
  }
);

export const dashboardApi = {
  getStats: (params?: { start_date?: string; end_date?: string; magasin_id?: string }) =>
    api.get<DashboardStats>('/reports/dashboard', { params }).then((r) => r.data),
};

export const productsApi = {
  getAll: (params?: { q?: string; category_id?: string; magasin_id?: string }) =>
    api.get<Product[]>('/products', { params }).then((r) => r.data),
  create: (data: Partial<Product>) => api.post<Product>('/products', data).then((r) => r.data),
  update: (id: string, data: Partial<Product>) => api.put<Product>(`/products/${id}`, data).then((r) => r.data),
  delete: (id: string) => api.delete(`/products/${id}`).then((r) => r.data),
};

export const categoriesApi = {
  getAll: () => api.get<Category[]>('/categories').then((r) => r.data),
  create: (data: Partial<Category>) => api.post<Category>('/categories', data).then((r) => r.data),
  update: (id: string, data: Partial<Category>) => api.put<Category>(`/categories/${id}`, data).then((r) => r.data),
  delete: (id: string) => api.delete(`/categories/${id}`).then((r) => r.data),
};

export const clientsApi = {
  getAll: (params?: { q?: string; only_debtors?: boolean }) =>
    api.get<Client[]>('/clients', { params }).then((r) => r.data),
  getById: (id: string) => api.get<Client>(`/clients/${id}`).then((r) => r.data),
  create: (data: Partial<Client>) => api.post<Client>('/clients', data).then((r) => r.data),
  update: (id: string, data: Partial<Client>) => api.put<Client>(`/clients/${id}`, data).then((r) => r.data),
  delete: (id: string) => api.delete(`/clients/${id}`).then((r) => r.data),
  recordPayment: (id: string, payment: { amount: number; payment_method: string; notes?: string }) =>
    api.post<Client>(`/clients/${id}/payments`, payment).then((r) => r.data),
};

export const suppliersApi = {
  getAll: (params?: { q?: string; only_creditors?: boolean }) =>
    api.get<Supplier[]>('/suppliers', { params }).then((r) => r.data),
  getById: (id: string) => api.get<Supplier>(`/suppliers/${id}`).then((r) => r.data),
  create: (data: Partial<Supplier>) => api.post<Supplier>('/suppliers', data).then((r) => r.data),
  update: (id: string, data: Partial<Supplier>) => api.put<Supplier>(`/suppliers/${id}`, data).then((r) => r.data),
  delete: (id: string) => api.delete(`/suppliers/${id}`).then((r) => r.data),
  recordPayment: (id: string, payment: { amount: number; payment_method: string; notes?: string }) =>
    api.post<Supplier>(`/suppliers/${id}/payments`, payment).then((r) => r.data),
};

export const approvisionnementsApi = {
  getAll: () => api.get<Approvisionnement[]>('/approvisionnements').then((r) => r.data),
  create: (data: Partial<Approvisionnement>) =>
    api.post<Approvisionnement>('/approvisionnements', data).then((r) => r.data),
};
export const suppliesApi = approvisionnementsApi;

export const decaissementsApi = {
  getAll: (params?: any) => api.get<Decaissement[]>('/decaissements', { params }).then((r) => r.data),
  getCategories: (params?: { include_defaults?: boolean }) =>
    api.get<string[]>('/decaissements/categories', { params }).then((r) => r.data),
  create: (data: Partial<Decaissement>) => api.post<Decaissement>('/decaissements', data).then((r) => r.data),
  delete: (id: string) => api.delete(`/decaissements/${id}`).then((r) => r.data),
};
export const expensesApi = decaissementsApi;

export const reportsApi = {
  getDashboard: () => api.get<DashboardStats>('/reports/dashboard').then((r) => r.data),
  getFinancial: (params?: { preset?: string; start_date?: string; end_date?: string; magasin_id?: string }) =>
    api.get<FinancialReport>('/reports/financial', { params }).then((r) => r.data),
};

export const settingsApi = {
  getSettings: () => api.get<StoreSettings>('/settings').then((r) => r.data),
  updateSettings: (data: StoreSettings) => api.put<StoreSettings>('/settings', data).then((r) => r.data),
};

export const authApi = {
  verifyPin: (pin: string) => api.post<UserBrief>('/auth/verify-pin', { pin }).then((r) => r.data),
};

export const ventesApi = {
  getAll: (params?: { limit?: number; skip?: number; start_date?: string; end_date?: string; magasin_id?: string }) =>
    api.get<Vente[]>('/ventes', { params }).then((r) => r.data),
  getById: (id: string) => api.get<Vente>(`/ventes/${id}`).then((r) => r.data),
  create: (data: VenteCreate) => api.post<Vente>('/ventes', data).then((r) => r.data),
};

export const usersApi = {
  getAll: () => api.get<UserBrief[]>('/users').then((r) => r.data),
  create: (data: {
    username: string;
    password: string;
    full_name?: string | null;
    email?: string | null;
    role: string;
    pin?: string | null;
    assigned_magasin_ids?: string[];
  }) => api.post<UserBrief>('/users', data).then((r) => r.data),
  update: (
    id: string,
    data: Partial<{
      full_name: string | null;
      email: string | null;
      role: string;
      password?: string;
      pin?: string | null;
      is_active: boolean;
      assigned_magasin_ids?: string[];
    }>
  ) => api.put<UserBrief>(`/users/${id}`, data).then((r) => r.data),
  delete: (id: string) => api.delete(`/users/${id}`),
};

// SaaS Public & Inscription API
export const saasApi = {
  getPlans: () => api.get<SaasPlan[]>('/saas/plans').then((r) => r.data),
  getFeaturesCatalog: () => api.get<FeatureCatalogItem[]>('/saas/features-catalog').then((r) => r.data),
  registerCredentials: (data: { full_name: string; username_or_email: string; password: string; phone?: string }) =>
    api.post('/saas/auth/register-credentials', data).then((r) => r.data),
  provisionTenant: (data: {
    boutique_name: string;
    company_name?: string;
    currency?: string;
    country?: string;
    phone?: string;
    magasin_name?: string;
    plan_code?: string;
  }) => api.post('/saas/tenant/provision', data).then((r) => r.data),
};

export const billingApi = {
  getPaymentMethods: () =>
    api.get<{ providers: PaymentProviderPublic[] }>('/billing/payment-methods').then((r) => r.data),
  checkout: (data: { plan_code: string; billing_cycle: 'monthly' | 'yearly'; network: string; phone: string }) =>
    api.post<CheckoutResponse>('/billing/checkout', data).then((r) => r.data),
  getStatus: (reference: string) =>
    api.get<TransactionStatusResponse>(`/billing/status/${reference}`).then((r) => r.data),
  getInvoices: () => api.get<SaasInvoice[]>('/billing/invoices').then((r) => r.data),
  downloadInvoicePdf: (invoiceId: string) =>
    api.get<Blob>(`/billing/invoices/${invoiceId}/pdf`, { responseType: 'blob' }).then((r) => r.data),
};

// Tenant & Multi-Magasins API
export const tenantApi = {
  getBoutiques: () => api.get<Boutique[]>('/tenant/boutiques').then((r) => r.data),
  createBoutique: (data: { name: string; currency?: string; country?: string; initial_magasin_name?: string }) =>
    api.post<Boutique>('/tenant/boutiques', data).then((r) => r.data),
  getMagasins: () => api.get<Magasin[]>('/tenant/magasins').then((r) => r.data),
  createMagasin: (data: { name: string; code?: string; address?: string; phone?: string; is_warehouse?: boolean }) =>
    api.post<Magasin>('/tenant/magasins', data).then((r) => r.data),
  updateMagasin: (id: string, data: Partial<Magasin>) =>
    api.put<Magasin>(`/tenant/magasins/${id}`, data).then((r) => r.data),
  getCurrentPlan: () => api.get<CurrentPlanStatus>('/tenant/current-plan').then((r) => r.data),
  upgradePlan: (plan_code: string) => api.post('/tenant/upgrade-plan', { plan_code }).then((r) => r.data),
};

// Super-Admin Console API
export const adminApi = {
  getKpis: () => api.get<PlatformKPIs>('/admin/kpis').then((r) => r.data),
  getPlans: () => api.get<SaasPlan[]>('/admin/plans').then((r) => r.data),
  createPlan: (data: Partial<SaasPlan>) => api.post<SaasPlan>('/admin/plans', data).then((r) => r.data),
  updatePlan: (id: string, data: Partial<SaasPlan>) => api.put<SaasPlan>(`/admin/plans/${id}`, data).then((r) => r.data),
  getBoutiques: () => api.get<any[]>('/admin/boutiques').then((r) => r.data),
  toggleBoutiqueStatus: (id: string, is_active: boolean) =>
    api.put(`/admin/boutiques/${id}/status`, { is_active }).then((r) => r.data),
  extendTrial: (id: string, days: number = 14) =>
    api.post(`/admin/boutiques/${id}/extend-trial`, { days }).then((r) => r.data),
};
