export interface UserBrief {
  id: string;
  username: string;
  email?: string | null;
  full_name?: string | null;
  role: 'superadmin' | 'owner' | 'merchant' | 'store_admin' | 'admin' | 'manager' | 'cashier' | string;
  permissions: string[];
  has_pin: boolean;
  is_active?: boolean;
  email_verified?: boolean;
  totp_enabled?: boolean;
  assigned_magasin_ids?: string[];
}

export interface AuthResponse {
  access_token: string;
  refresh_token: string;
  token_type: string;
  requires_2fa?: boolean;
  challenge_token?: string | null;
  user: UserBrief;
}

export interface TwoFactorSetupResponse {
  secret: string;
  otpauth_uri: string;
}
