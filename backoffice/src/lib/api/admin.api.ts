import { api } from './client';
import type {
  AdminBoutiqueDetail,
  AdminBoutiqueItem,
  AdminPaymentProvider,
  AdminSubscriptionsResponse,
  FeatureCatalogItem,
  PlatformAuditItem,
  PlatformKPIs,
  SaasPlan,
  SaasPlanPayload,
  UserBrief,
} from '../../types';

export const adminApi = {
  getKpis: () => api.get<PlatformKPIs>('/admin/kpis').then((r) => r.data),
  getFeaturesCatalog: () =>
    api.get<FeatureCatalogItem[]>('/admin/features-catalog').then((r) => r.data),
  getPlans: () => api.get<SaasPlan[]>('/admin/plans').then((r) => r.data),
  createPlan: (data: SaasPlanPayload) =>
    api.post<SaasPlan>('/admin/plans', data).then((r) => r.data),
  updatePlan: (id: string, data: Partial<SaasPlanPayload>) =>
    api.put<SaasPlan>(`/admin/plans/${id}`, data).then((r) => r.data),
  getBoutiques: (params?: {
    q?: string;
    status?: string;
    plan_code?: string;
    paginated?: boolean;
    page?: number;
    limit?: number;
  }) =>
    api
      .get<
        | AdminBoutiqueItem[]
        | { items: AdminBoutiqueItem[]; total: number; page: number; limit: number }
      >('/admin/boutiques', { params })
      .then((r) => r.data),
  getBoutiqueDetail: (id: string) =>
    api.get<AdminBoutiqueDetail>(`/admin/boutiques/${id}`).then((r) => r.data),
  toggleBoutiqueStatus: (id: string, is_active: boolean) =>
    api.put(`/admin/boutiques/${id}/status`, { is_active }).then((r) => r.data),
  assignBoutiquePlan: (
    id: string,
    payload: {
      plan_code: string;
      status: string;
      billing_cycle: 'monthly' | 'yearly';
      period_days: number;
      reason?: string;
    }
  ) => api.put(`/admin/boutiques/${id}/plan`, payload).then((r) => r.data),
  extendTrial: (id: string, days: number = 14) =>
    api.post(`/admin/boutiques/${id}/extend-trial`, { days }).then((r) => r.data),
  impersonateBoutique: (id: string) =>
    api
      .post<{
        access_token: string;
        token_type: string;
        expires_in_minutes: number;
        read_only: boolean;
        boutique_id: string;
        boutique_name: string;
        user: UserBrief;
      }>(`/admin/boutiques/${id}/impersonate`)
      .then((r) => r.data),
  getPaymentProviders: () =>
    api.get<AdminPaymentProvider[]>('/admin/payment-providers').then((r) => r.data),
  getPaymentProvider: (code: string) =>
    api.get<AdminPaymentProvider>(`/admin/payment-providers/${code}`).then((r) => r.data),
  updatePaymentProvider: (
    code: string,
    payload: {
      name?: string;
      is_active?: boolean;
      mode?: 'sandbox' | 'live';
      base_url?: string;
      networks?: string[];
      sandbox?: { api_key?: string; api_id?: string };
      live?: { api_key?: string; api_id?: string };
    }
  ) =>
    api.put<AdminPaymentProvider>(`/admin/payment-providers/${code}`, payload).then((r) => r.data),
  getSubscriptions: (params?: { status?: string; tx_status?: string; page?: number; limit?: number }) =>
    api.get<AdminSubscriptionsResponse>('/admin/subscriptions', { params }).then((r) => r.data),
  getAuditLogs: (params?: { action?: string; q?: string; page?: number; limit?: number }) =>
    api
      .get<{ items: PlatformAuditItem[]; total: number; page: number; limit: number }>(
        '/admin/audit',
        { params }
      )
      .then((r) => r.data),
};
