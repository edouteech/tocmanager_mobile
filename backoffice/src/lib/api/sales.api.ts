import { api } from './client';
import type { CashRegisterSession, PaginatedResponse, Vente, VenteCreate } from '../../types';

export const ventesApi = {
  getAll: (params?: {
    limit?: number;
    skip?: number;
    start_date?: string;
    end_date?: string;
    magasin_id?: string;
  }) => api.get<Vente[]>('/ventes', { params }).then((r) => r.data),
  getPaginated: (params?: {
    page?: number;
    limit?: number;
    q?: string;
    only_credit?: boolean;
    start_date?: string;
    end_date?: string;
    magasin_id?: string;
  }) =>
    api
      .get<
        PaginatedResponse<
          Vente,
          {
            total_count: number;
            total_amount: number;
            filtered_amount: number;
            today_amount: number;
            total_credit: number;
          }
        >
      >('/ventes', {
        params: {
          paginated: true,
          page: params?.page ?? 1,
          limit: params?.limit ?? 50,
          q: params?.q || undefined,
          only_credit: params?.only_credit || undefined,
          start_date: params?.start_date || undefined,
          end_date: params?.end_date || undefined,
          magasin_id: params?.magasin_id || undefined,
        },
      })
      .then((r) => r.data),
  getById: (id: string) => api.get<Vente>(`/ventes/${id}`).then((r) => r.data),
  create: (data: VenteCreate) => api.post<Vente>('/ventes', data).then((r) => r.data),
  refund: (
    id: string,
    data: { items?: { vente_item_sync_id: string; quantity: number }[]; reason: string }
  ) => api.post<Vente>(`/ventes/${id}/refund`, data).then((r) => r.data),
};

export const cashSessionsApi = {
  getAll: () => api.get<CashRegisterSession[]>('/cash-sessions').then((r) => r.data),
  getCurrent: (magasinId?: string) =>
    api
      .get<CashRegisterSession | null>('/cash-sessions/current', {
        params: magasinId ? { magasin_id: magasinId } : undefined,
      })
      .then((r) => r.data),
  open: (data: { magasin_id?: string; opening_balance: number; notes?: string }) =>
    api.post<CashRegisterSession>('/cash-sessions/open', data).then((r) => r.data),
  close: (id: string, data: { declared_cash: number; notes?: string }) =>
    api.post<CashRegisterSession>(`/cash-sessions/${id}/close`, data).then((r) => r.data),
};
