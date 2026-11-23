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

export interface AuthResponse {
  access_token: string;
  refresh_token: string;
  token_type: string;
  user: UserBrief;
}
