import { create } from 'zustand';
import { UserBrief, AuthResponse } from '../types';

interface AuthState {
  user: UserBrief | null;
  token: string | null;
  isAuthenticated: boolean;
  setAuth: (data: AuthResponse) => void;
  logout: () => void;
  initFromStorage: () => void;
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  token: null,
  isAuthenticated: false,

  setAuth: (data: AuthResponse) => {
    localStorage.setItem('toc_access_token', data.access_token);
    localStorage.setItem('toc_refresh_token', data.refresh_token);
    localStorage.setItem('toc_user', JSON.stringify(data.user));
    set({
      user: data.user,
      token: data.access_token,
      isAuthenticated: true,
    });
  },

  logout: () => {
    localStorage.removeItem('toc_access_token');
    localStorage.removeItem('toc_refresh_token');
    localStorage.removeItem('toc_user');
    set({
      user: null,
      token: null,
      isAuthenticated: false,
    });
  },

  initFromStorage: () => {
    const token = localStorage.getItem('toc_access_token');
    const userJson = localStorage.getItem('toc_user');
    if (token && userJson) {
      try {
        const user = JSON.parse(userJson) as UserBrief;
        set({
          user,
          token,
          isAuthenticated: true,
        });
      } catch {
        localStorage.clear();
      }
    }
  },
}));
