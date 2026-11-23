import { api } from './client';
import type {
  AuditLogItem,
  DashboardStats,
  Decaissement,
  FinancialReport,
  PaginatedResponse,
  StoreSettings,
} from '../../types';

export const decaissementsApi = {
  getAll: (params?: Record<string, unknown>) =>
    api.get<Decaissement[]>('/decaissements', { params }).then((r) => r.data),
  getPaginated: (params?: {
    page?: number;
    limit?: number;
    q?: string;
    category?: string;
    start_date?: string;
    end_date?: string;
  }) =>
    api
      .get<
        PaginatedResponse<
          Decaissement,
          { total_count: number; total_amount: number; today_amount: number; filtered_amount: number }
        >
      >('/decaissements', {
        params: {
          paginated: true,
          page: params?.page ?? 1,
          limit: params?.limit ?? 50,
          q: params?.q || undefined,
          category: params?.category && params.category !== 'all' ? params.category : undefined,
          start_date: params?.start_date || undefined,
          end_date: params?.end_date || undefined,
        },
      })
      .then((r) => r.data),
  getCategories: (params?: { include_defaults?: boolean }) =>
    api.get<string[]>('/decaissements/categories', { params }).then((r) => r.data),
  create: (data: Partial<Decaissement>) =>
    api.post<Decaissement>('/decaissements', data).then((r) => r.data),
  delete: (id: string) => api.delete(`/decaissements/${id}`).then((r) => r.data),
};

export const reportsApi = {
  getDashboard: () => api.get<DashboardStats>('/reports/dashboard').then((r) => r.data),
  getFinancial: (params?: {
    preset?: string;
    start_date?: string;
    end_date?: string;
    magasin_id?: string;
  }) => api.get<FinancialReport>('/reports/financial', { params }).then((r) => r.data),
};

export const settingsApi = {
  getSettings: () => api.get<StoreSettings>('/settings').then((r) => r.data),
  updateSettings: (data: StoreSettings) =>
    api.put<StoreSettings>('/settings', data).then((r) => r.data),
};

export const auditApi = {
  getLogs: (params?: {
    page?: number;
    limit?: number;
    q?: string;
    action?: string;
    user_id?: string;
    entity_type?: string;
  }) =>
    api
      .get<{ total: number; items: AuditLogItem[]; page: number; pages: number; limit: number }>(
        '/audit/logs',
        {
          params: {
            page: params?.page ?? 1,
            limit: params?.limit ?? 50,
            q: params?.q || undefined,
            action: params?.action || undefined,
            user_id: params?.user_id || undefined,
            entity_type: params?.entity_type || undefined,
          },
        }
      )
      .then((r) => r.data),
};
