import { api } from './client';
import type {
  CheckoutResponse,
  FeatureCatalogItem,
  PaymentProviderPublic,
  ProvisionTenantResponse,
  PublicContactRequest,
  SaasInvoice,
  SaasPlan,
  TransactionStatusResponse,
} from '../../types';

export const saasApi = {
  getPlans: () => api.get<SaasPlan[]>('/saas/plans').then((r) => r.data),
  getFeaturesCatalog: () =>
    api.get<FeatureCatalogItem[]>('/saas/features-catalog').then((r) => r.data),
  registerCredentials: (data: {
    full_name: string;
    username_or_email: string;
    password: string;
    phone?: string;
  }) => api.post('/saas/auth/register-credentials', data).then((r) => r.data),
  provisionTenant: (data: {
    boutique_name: string;
    company_name?: string;
    currency?: string;
    country?: string;
    phone?: string;
    magasin_name?: string;
    plan_code?: string;
    billing_cycle?: 'monthly' | 'yearly';
  }) => api.post<ProvisionTenantResponse>('/saas/tenant/provision', data).then((r) => r.data),
  sendContact: (data: PublicContactRequest) =>
    api.post<{ success: boolean; message: string }>('/saas/contact', data).then((r) => r.data),
};

export const billingApi = {
  getPaymentMethods: () =>
    api.get<{ providers: PaymentProviderPublic[] }>('/billing/payment-methods').then((r) => r.data),
  checkout: (data: {
    plan_code: string;
    billing_cycle: 'monthly' | 'yearly';
    network: string;
    phone: string;
  }) => api.post<CheckoutResponse>('/billing/checkout', data).then((r) => r.data),
  getStatus: (reference: string) =>
    api.get<TransactionStatusResponse>(`/billing/status/${reference}`).then((r) => r.data),
  getInvoices: () => api.get<SaasInvoice[]>('/billing/invoices').then((r) => r.data),
  downloadInvoicePdf: (invoiceId: string) =>
    api
      .get<Blob>(`/billing/invoices/${invoiceId}/pdf`, { responseType: 'blob' })
      .then((r) => r.data),
};
