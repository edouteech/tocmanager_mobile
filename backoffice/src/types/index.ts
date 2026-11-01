export interface UserBrief {
  id: string;
  username: string;
  email?: string | null;
  full_name?: string | null;
  role: 'admin' | 'manager' | 'cashier';
  permissions: string[];
  has_pin: boolean;
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
  updated_at: string;
  deleted_at?: string | null;
}

export interface Client {
  sync_id: string;
  name: string;
  phone?: string | null;
  email?: string | null;
  address?: string | null;
  balance: number;
  notes?: string | null;
  updated_at: string;
  deleted_at?: string | null;
}
