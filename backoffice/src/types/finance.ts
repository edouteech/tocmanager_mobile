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

export interface AuditLogItem {
  id: string;
  user_id?: string | null;
  user_name?: string | null;
  action: string;
  entity_type?: string | null;
  entity_id?: string | null;
  details?: Record<string, unknown> | null;
  created_at: string;
}
