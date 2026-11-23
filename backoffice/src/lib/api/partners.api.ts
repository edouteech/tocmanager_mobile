import { api } from './client';
import type { Client, PaginatedResponse, PaymentLedgerItem, Supplier } from '../../types';

export const clientsApi = {
  getAll: (params?: { q?: string; only_debtors?: boolean }) =>
    api.get<Client[]>('/clients', { params }).then((r) => r.data),
  getPaginated: (params?: {
    page?: number;
    limit?: number;
    q?: string;
    only_debtors?: boolean;
    sort?: string;
  }) =>
    api
      .get<
        PaginatedResponse<
          Client,
          { total_clients: number; debtors_count: number; settled_count: number; total_debt: number }
        >
      >('/clients', {
        params: {
          paginated: true,
          page: params?.page ?? 1,
          limit: params?.limit ?? 50,
          q: params?.q || undefined,
          only_debtors: params?.only_debtors || undefined,
          sort: params?.sort || undefined,
        },
      })
      .then((r) => r.data),
  getById: (id: string) => api.get<Client>(`/clients/${id}`).then((r) => r.data),
  create: (data: Partial<Client>) => api.post<Client>('/clients', data).then((r) => r.data),
  update: (id: string, data: Partial<Client>) =>
    api.put<Client>(`/clients/${id}`, data).then((r) => r.data),
  delete: (id: string) => api.delete(`/clients/${id}`).then((r) => r.data),
  getPayments: (id: string) =>
    api.get<PaymentLedgerItem[]>(`/clients/${id}/payments`).then((r) => r.data),
  recordPayment: (
    id: string,
    payment: { amount: number; payment_method: string; notes?: string }
  ) => api.post<Client>(`/clients/${id}/payments`, payment).then((r) => r.data),
};

export const suppliersApi = {
  getAll: (params?: { q?: string; only_creditors?: boolean }) =>
    api.get<Supplier[]>('/suppliers', { params }).then((r) => r.data),
  getPaginated: (params?: {
    page?: number;
    limit?: number;
    q?: string;
    only_creditors?: boolean;
    sort?: string;
  }) =>
    api
      .get<
        PaginatedResponse<
          Supplier,
          {
            total_suppliers: number;
            creditors_count: number;
            settled_count: number;
            total_debt: number;
          }
        >
      >('/suppliers', {
        params: {
          paginated: true,
          page: params?.page ?? 1,
          limit: params?.limit ?? 50,
          q: params?.q || undefined,
          only_creditors: params?.only_creditors || undefined,
          sort: params?.sort || undefined,
        },
      })
      .then((r) => r.data),
  getById: (id: string) => api.get<Supplier>(`/suppliers/${id}`).then((r) => r.data),
  create: (data: Partial<Supplier>) => api.post<Supplier>('/suppliers', data).then((r) => r.data),
  update: (id: string, data: Partial<Supplier>) =>
    api.put<Supplier>(`/suppliers/${id}`, data).then((r) => r.data),
  delete: (id: string) => api.delete(`/suppliers/${id}`).then((r) => r.data),
  getPayments: (id: string) =>
    api.get<PaymentLedgerItem[]>(`/suppliers/${id}/payments`).then((r) => r.data),
  recordPayment: (
    id: string,
    payment: { amount: number; payment_method: string; notes?: string }
  ) => api.post<Supplier>(`/suppliers/${id}/payments`, payment).then((r) => r.data),
};
