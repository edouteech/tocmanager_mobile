import { api } from './client';
import type { Boutique, CurrentPlanStatus, Magasin } from '../../types';

export const tenantApi = {
  getBoutiques: () => api.get<Boutique[]>('/tenant/boutiques').then((r) => r.data),
  createBoutique: (data: {
    name: string;
    company_name?: string;
    currency?: string;
    country?: string;
    initial_magasin_name?: string;
  }) => api.post<Boutique>('/tenant/boutiques', data).then((r) => r.data),
  getMagasins: () => api.get<Magasin[]>('/tenant/magasins').then((r) => r.data),
  createMagasin: (data: {
    name: string;
    code?: string;
    address?: string;
    phone?: string;
    is_warehouse?: boolean;
  }) => api.post<Magasin>('/tenant/magasins', data).then((r) => r.data),
  updateMagasin: (id: string, data: Partial<Magasin>) =>
    api.put<Magasin>(`/tenant/magasins/${id}`, data).then((r) => r.data),
  getCurrentPlan: () => api.get<CurrentPlanStatus>('/tenant/current-plan').then((r) => r.data),
  upgradePlan: (plan_code: string) =>
    api.post('/tenant/upgrade-plan', { plan_code }).then((r) => r.data),
};
