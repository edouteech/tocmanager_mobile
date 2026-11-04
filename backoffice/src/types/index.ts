export interface UserBrief {
  id: string;
  username: string;
  email?: string | null;
  full_name?: string | null;
  role: 'admin' | 'manager' | 'cashier';
  permissions: string[];
  has_pin: boolean;
  is_active?: boolean;
}

export interface VenteItemCreate {
  product_sync_id: string;
  quantity: number;
  unit_price: number;
  cost_price?: number;
  product_name?: string;
}

export interface VenteCreate {
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
  ticket_number: string;
  client_sync_id?: string | null;
  client_name?: string | null;
  user_id?: string | null;
  user_name?: string | null;
  total_amount: number;
  paid_amount: number;
  discount_amount: number;
  payment_method: string;
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
