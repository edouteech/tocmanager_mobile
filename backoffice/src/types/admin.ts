import type { PaymentCountry } from './saas';

export interface PlatformKPIs {
  mrr: number;
  arr: number;
  mrr_by_currency?: Record<string, number>;
  gmv_by_currency?: Record<string, number>;
  conversion_rate?: number;
  churn_rate?: number;
  total_boutiques: number;
  active_boutiques: number;
  total_magasins: number;
  trialing_subscriptions: number;
  active_subscriptions: number;
  total_gmv: number;
  currency: string;
  plan_distribution?: { name: string; count: number }[];
  monthly_signups?: { month: string; signups: number }[];
}

export interface AdminBoutiqueItem {
  id: string;
  slug: string;
  name: string;
  company_name?: string | null;
  currency: string;
  country: string;
  phone?: string | null;
  is_active: boolean;
  created_at?: string | null;
  owner_name: string;
  owner_email: string;
  magasin_count: number;
  subscription: {
    status: string;
    plan_name: string;
    plan_code: string;
    billing_cycle?: string;
    trial_ends_at?: string | null;
    current_period_end?: string | null;
  };
}

export interface AdminBoutiqueDetail {
  id: string;
  slug: string;
  name: string;
  company_name?: string | null;
  currency: string;
  country: string;
  phone?: string | null;
  email?: string | null;
  address?: string | null;
  is_active: boolean;
  created_at?: string | null;
  owner: { id: string | null; username: string | null; email: string; full_name: string };
  subscription: AdminBoutiqueItem['subscription'];
  magasins: { id: string; name: string; code?: string | null; is_warehouse: boolean; is_active: boolean }[];
  members: { id: string; username: string; full_name?: string | null; role: string; is_active: boolean }[];
  transactions: {
    id: string;
    reference: string;
    amount: number;
    currency: string;
    network: string;
    status: string;
    created_at: string;
  }[];
  invoices: {
    id: string;
    invoice_number: string;
    plan_name: string;
    amount: number;
    currency: string;
    issued_at: string;
  }[];
}

export interface AdminPaymentProvider {
  id: string;
  code: string;
  name: string;
  is_active: boolean;
  mode: 'sandbox' | 'live';
  base_url: string;
  countries: PaymentCountry[];
  networks: string[];
  sandbox: { api_key_masked: string; has_api_key: boolean; api_id: string };
  live: { api_key_masked: string; has_api_key: boolean; api_id: string };
  updated_at?: string | null;
}

export interface AdminSubscriptionsResponse {
  items: {
    id: string;
    boutique_id: string;
    boutique_name: string;
    plan_name: string;
    plan_code: string;
    status: string;
    billing_cycle: string;
    trial_ends_at?: string | null;
    current_period_end?: string | null;
  }[];
  total: number;
  transactions: {
    id: string;
    reference: string;
    external_reference?: string | null;
    boutique_id: string;
    boutique_name: string;
    plan_name: string;
    billing_cycle: string;
    amount: number;
    currency: string;
    phone: string;
    network: string;
    flow_type: string;
    status: string;
    created_at: string;
  }[];
  transactions_total: number;
  page: number;
  limit: number;
}

export interface PlatformAuditItem {
  id: string;
  admin_user_id?: string | null;
  admin_username?: string | null;
  action: string;
  target_entity?: string | null;
  target_id?: string | null;
  details?: Record<string, unknown> | null;
  created_at: string;
}
