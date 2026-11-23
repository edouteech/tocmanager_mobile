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
