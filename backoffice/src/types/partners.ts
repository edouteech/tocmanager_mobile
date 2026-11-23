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
