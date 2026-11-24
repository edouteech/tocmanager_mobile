import { api } from './client';
import type { AuthResponse, TwoFactorSetupResponse, UserBrief } from '../../types';

export const authApi = {
  login: (credentials: { username_or_email: string; password: string }) =>
    api.post<AuthResponse>('/auth/login', credentials).then((r) => r.data),
  verify2faChallenge: (challengeToken: string, code: string) =>
    api
      .post<AuthResponse>('/auth/verify-2fa', { challenge_token: challengeToken, code })
      .then((r) => r.data),
  setup2fa: () => api.post<TwoFactorSetupResponse>('/auth/2fa/setup').then((r) => r.data),
  confirm2fa: (code: string) =>
    api.post<UserBrief>('/auth/2fa/confirm', { code }).then((r) => r.data),
  disable2fa: (password: string, code: string) =>
    api.post<UserBrief>('/auth/2fa/disable', { password, code }).then((r) => r.data),
  forgotPassword: (email: string) =>
    api.post<{ status: string; message: string }>('/auth/forgot-password', { email }).then((r) => r.data),
  resetPassword: (token: string, newPassword: string) =>
    api
      .post<{ status: string; message: string }>('/auth/reset-password', {
        token,
        new_password: newPassword,
      })
      .then((r) => r.data),
  requestEmailVerification: () =>
    api.post<{ status: string; channel: string }>('/auth/request-email-verification').then((r) => r.data),
  verifyEmail: (token: string) =>
    api.post<UserBrief>('/auth/verify-email', { token }).then((r) => r.data),
  me: () => api.get<UserBrief>('/auth/me').then((r) => r.data),
  setPin: (currentPassword: string, pin: string) =>
    api
      .post<UserBrief>('/auth/set-pin', { current_password: currentPassword, pin })
      .then((r) => r.data),
  verifyPin: (pin: string) => api.post<UserBrief>('/auth/verify-pin', { pin }).then((r) => r.data),
};

export const usersApi = {
  getAll: () => api.get<UserBrief[]>('/users').then((r) => r.data),
  create: (data: {
    username: string;
    password: string;
    full_name?: string | null;
    email?: string | null;
    role: string;
    pin?: string | null;
    assigned_magasin_ids?: string[];
  }) => api.post<UserBrief>('/users', data).then((r) => r.data),
  update: (
    id: string,
    data: Partial<{
      full_name: string | null;
      email: string | null;
      role: string;
      password?: string;
      pin?: string | null;
      is_active: boolean;
      assigned_magasin_ids?: string[];
    }>
  ) => api.put<UserBrief>(`/users/${id}`, data).then((r) => r.data),
  delete: (id: string) => api.delete(`/users/${id}`),
};
