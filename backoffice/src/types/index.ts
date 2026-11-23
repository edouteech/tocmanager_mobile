export interface UserBrief {
  id: string;
  username: string;
  email?: string | null;
  full_name?: string | null;
  role: 'superadmin' | 'owner' | 'merchant' | 'store_admin' | 'admin' | 'manager' | 'cashier' | string;
  permissions: string[];
  has_pin: boolean;
  is_active?: boolean;
  assigned_magasin_ids?: string[];
}

export interface VenteItemCreate {
  product_sync_id: string;
  quantity: number;
  unit_price?: number;
  cost_price?: number;
  product_name?: string;
}

export interface VenteCreate {
  magasin_id?: string | null;
  client_sync_id?: string | null;
  client_name?: string | null;
  items: VenteItemCreate[];
  discount_amount?: number;
  paid_amount: number;
  payment_method: string;
  notes?: string | null;
}

export interface AuthResponse {
  access_token: string;
  refresh_token: string;
  token_type: string;
  user: UserBrief;
}

export interface DashboardStats {
  total_sales_amount: number;
  total_sales_count: number;
  today_sales_amount: number;
  today_sales_count: number;
  total_receivables: number;
  total_expenses: number;
  products_count: number;
  low_stock_count: number;
  categories_count?: number;
  stock_value?: number;
  stock_cost?: number;
}

export interface VenteItem {
  sync_id?: string;
  product_sync_id?: string;
  product_name: string;
  quantity: number;
  unit_price: number;
  cost_price: number;
  total: number;
}

export interface Vente {
  sync_id: string;
  magasin_id?: string | null;
  ticket_number: string;
  client_sync_id?: string | null;
  client_name?: string | null;
  user_id?: string | null;
  user_name?: string | null;
  total_amount: number;
  paid_amount: number;
  discount_amount: number;
  payment_method: string;
  status?: string;
  notes?: string | null;
  created_at: string;
  updated_at?: string;
  items: VenteItem[];
}

export interface Product {
  sync_id: string;
  name: string;
  category_sync_id?: string | null;
  price: number;
  cost_price: number;
  average_cost_price?: number;
  stock: number;
  min_stock: number;
  barcode?: string | null;
  unit?: string;
  image_path?: string | null;
  is_active: boolean;
  updated_at: string;
  deleted_at?: string | null;
  custom_price?: number | null;
  is_available?: boolean;
  magasin_id?: string | null;
}

export interface ProductMagasinItem {
  magasin_id: string;
  magasin_name: string;
  magasin_code?: string | null;
  is_warehouse: boolean;
  is_active: boolean;
  is_available: boolean;
  custom_price?: number | null;
  effective_price: number;
  quantity: number;
  min_stock: number;
}

export interface StockTransferItem {
  id: string;
  product_sync_id: string;
  product_name: string;
  quantity_sent: number;
  quantity_received?: number | null;
  unit_cost: number;
}

export interface StockTransfer {
  id: string;
  reference: string;
  from_magasin_id: string;
  from_magasin_name?: string | null;
  to_magasin_id: string;
  to_magasin_name?: string | null;
  status: 'draft' | 'in_transit' | 'received' | 'canceled' | string;
  notes?: string | null;
  created_by_user_id?: string | null;
  created_by_name?: string | null;
  shipped_at?: string | null;
  received_at?: string | null;
  received_by_name?: string | null;
  canceled_at?: string | null;
  created_at: string;
  items: StockTransferItem[];
}

export interface StockMovement {
  id: string;
  magasin_id: string;
  magasin_name?: string | null;
  product_sync_id: string;
  product_name?: string | null;
  movement_type: string;
  quantity_delta: number;
  balance_before: number;
  balance_after: number;
  reference_type?: string | null;
  reference_id?: string | null;
  reason?: string | null;
  user_id?: string | null;
  user_name?: string | null;
  created_at: string;
}

export interface Category {
  sync_id: string;
  name: string;
  description?: string | null;
  color?: string | null;
  icon?: string | null;
  created_at: string;
  updated_at?: string | null;
  products_count?: number;
}

export interface Client {
  sync_id: string;
  name: string;
  phone?: string | null;
  email?: string | null;
  address?: string | null;
  balance: number;
  notes?: string | null;
  user_id?: string | null;
  user_name?: string | null;
  created_at: string;
  updated_at?: string | null;
}

export interface Supplier {
  sync_id: string;
  name: string;
  contact_person?: string | null;
  phone?: string | null;
  email?: string | null;
  address?: string | null;
  balance: number;
  notes?: string | null;
  user_id?: string | null;
  user_name?: string | null;
  created_at: string;
  updated_at?: string | null;
}

export interface Approvisionnement {
  sync_id: string;
  magasin_id?: string | null;
  supplier_sync_id?: string | null;
  supplier_name?: string | null;
  product_sync_id?: string | null;
  product_name: string;
  quantity: number;
  unit_cost: number;
  total_cost: number;
  payment_status: string;
  date: string;
  notes?: string | null;
  user_id?: string | null;
  user_name?: string | null;
  created_at: string;
}

export interface Decaissement {
  sync_id: string;
  magasin_id?: string | null;
  title: string;
  amount: number;
  category?: string | null;
  beneficiary?: string | null;
  payment_method: string;
  date: string;
  notes?: string | null;
  user_id?: string | null;
  user_name?: string | null;
  created_at: string;
}

export interface CashRegisterSession {
  id: string;
  magasin_id: string;
  magasin_name?: string | null;
  opened_by_user_id: string;
  opened_by_name?: string | null;
  opened_at: string;
  opening_balance: number;
  status: 'open' | 'closed' | string;
  expected_cash?: number | null;
  expected_mobile_money?: number | null;
  expected_card?: number | null;
  declared_cash?: number | null;
  discrepancy?: number | null;
  closed_by_name?: string | null;
  closed_at?: string | null;
  notes?: string | null;
}

export interface PaymentLedgerItem {
  id: string;
  magasin_id?: string | null;
  client_sync_id?: string | null;
  supplier_sync_id?: string | null;
  amount: number;
  payment_method: string;
  previous_balance: number;
  new_balance: number;
  notes?: string | null;
  user_id?: string | null;
  user_name?: string | null;
  created_at: string;
}

export interface StoreSettings {
  store_name: string;
  currency: string;
  phone?: string | null;
  email?: string | null;
  address?: string | null;
  tax_rate: number;
  low_stock_threshold: number;
  rccm?: string | null;
  nif?: string | null;
}

export interface FinancialKPIs {
  gross_sales: number;
  discount_amount: number;
  net_sales: number;
  cogs: number;
  gross_margin: number;
  gross_margin_rate: number;
  total_expenses: number;
  net_profit: number;
  net_margin_rate: number;
  net_cashflow?: number;
}

export interface TopProductItem {
  product_name: string;
  quantity_sold: number;
  total_revenue: number;
  total_profit: number;
}

export interface ExpenseCategoryItem {
  category: string;
  total_amount: number;
  percentage: number;
}

export interface MonthlyTrendItem {
  period: string;
  sales: number;
  expenses: number;
  profit: number;
}

export interface FinancialReport {
  start_date: string;
  end_date: string;
  kpis: FinancialKPIs;
  top_products: TopProductItem[];
  expenses_by_category: ExpenseCategoryItem[];
  monthly_trend: MonthlyTrendItem[];
}


// SaaS & Multi-Tenant Types
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
  features: Record<string, any>;
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

export interface PlatformKPIs {
  mrr: number;
  arr: number;
  total_boutiques: number;
  active_boutiques: number;
  total_magasins: number;
  trialing_subscriptions: number;
  active_subscriptions: number;
  total_gmv: number;
  currency: string;
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
