import type { UserBrief } from './auth';

export interface SaasPlanFeature {
  id: string;
  feature_code: string;
  feature_name: string;
  category?: string;
  description?: string | null;
  display_order?: number;
  show_on_pricing?: boolean;
  value_type: 'boolean' | 'limit_number' | 'text';
  boolean_value: boolean;
  int_limit: number;
}

export interface FeatureCatalogItem {
  feature_code: string;
  feature_name: string;
  category: string;
  value_type: 'boolean' | 'limit_number';
  description: string;
  display_order: number;
  show_on_pricing: boolean;
  defaults: {
    free: boolean | number;
    pro: boolean | number;
    enterprise: boolean | number;
  };
}

export interface SaasPlan {
  id: string;
  name: string;
  code: string;
  description?: string | null;
  price_monthly: number;
  price_yearly: number;
  currency: string;
  trial_period_days: number;
  badge?: string | null;
  is_active: boolean;
  features: SaasPlanFeature[];
}

export interface SaasPlanPayload {
  name: string;
  code: string;
  description?: string | null;
  price_monthly: number;
  price_yearly: number;
  currency?: string;
  trial_period_days: number;
  badge?: string | null;
  is_active: boolean;
  features: {
    feature_code: string;
    feature_name?: string;
    boolean_value: boolean;
    int_limit: number;
    show_on_pricing: boolean;
  }[];
}

export interface Magasin {
  id: string;
  boutique_id?: string;
  name: string;
  code?: string;
  address?: string | null;
  phone?: string | null;
  is_warehouse: boolean;
  is_active: boolean;
  created_at?: string;
}

export interface Boutique {
  id: string;
  slug: string;
  name: string;
  company_name?: string | null;
  currency: string;
  country: string;
  phone?: string | null;
  email?: string | null;
  address?: string | null;
  logo_url?: string | null;
  owner_user_id: string;
  is_active: boolean;
  created_at?: string;
  magasins: Magasin[];
  user_role?: string;
  assigned_magasin_ids: string[];
}

export interface CurrentPlanStatus {
  plan_id: string;
  plan_name: string;
  plan_code: string;
  status: string;
  trial_active: boolean;
  trial_days_left: number;
  features: Record<string, unknown>;
  can_access_stock_transfers: boolean;
  can_access_pnl_reports: boolean;
  can_access_data_exports: boolean;
  boutiques_used?: number;
  boutiques_limit?: number;
  magasins_used: number;
  magasins_limit: number;
  products_used?: number;
  products_limit?: number;
  users_used?: number;
  users_limit?: number;
  clients_used?: number;
  clients_limit?: number;
  suppliers_used?: number;
  suppliers_limit?: number;
  audit_retention_days?: number;
  has_used_trial?: boolean;
  billing_cycle?: 'monthly' | 'yearly' | string;
  current_period_end?: string | null;
}

export interface PaymentCountry {
  code: string;
  name: string;
  dial_code: string;
  networks: string[];
}

export interface PaymentProviderPublic {
  code: string;
  name: string;
  is_active: boolean;
  mode: string;
  countries: PaymentCountry[];
}

export interface CheckoutResponse {
  transaction_id: string;
  reference: string;
  external_reference?: string | null;
  flow_type: 'ussd_push' | 'redirect' | string;
  status: string;
  payment_url?: string | null;
  amount: number;
  currency: string;
}

export interface TransactionStatusResponse {
  id: string;
  reference: string;
  external_reference?: string | null;
  provider_code: string;
  flow_type: string;
  status: string;
  payment_url?: string | null;
  amount: number;
  currency: string;
  network: string;
  paid_at?: string | null;
}

export interface SaasInvoice {
  id: string;
  invoice_number: string;
  transaction_id: string;
  boutique_id: string;
  plan_name: string;
  billing_cycle: string;
  amount: number;
  currency: string;
  period_start: string;
  period_end: string;
  issued_at: string;
}

export interface ProvisionTenantResponse {
  success: boolean;
  message: string;
  boutique_id: string;
  boutique_name: string;
  magasin_id: string;
  magasin_name: string;
  plan_name: string;
  trial_active: boolean;
  trial_days: number;
  access_token: string;
  refresh_token: string;
  token_type: string;
  user: UserBrief;
}

export interface PublicContactRequest {
  full_name: string;
  email: string;
  company?: string;
  phone?: string;
  message: string;
}
