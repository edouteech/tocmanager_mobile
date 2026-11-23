import { api } from './client';
import type { AuthResponse, UserBrief } from '../../types';

export const authApi = {
  login: (credentials: { username_or_email: string; password: string }) =>
    api.post<AuthResponse>('/auth/login', credentials).then((r) => r.data),
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
