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
