import { create } from 'zustand';
import { UserBrief, AuthResponse } from '../types';

interface AuthState {
  user: UserBrief | null;
  token: string | null;
  isAuthenticated: boolean;
  isPinLocked: boolean;
  setAuth: (data: AuthResponse) => void;
  logout: () => void;
  lockSession: () => void;
  unlockSession: () => void;
  initFromStorage: () => void;
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  token: null,
  isAuthenticated: false,
  isPinLocked: false,

  setAuth: (data: AuthResponse) => {
    localStorage.setItem('toc_access_token', data.access_token);
    localStorage.setItem('toc_refresh_token', data.refresh_token);
    localStorage.setItem('toc_user', JSON.stringify(data.user));
    localStorage.removeItem('toc_pin_locked');
    set({
      user: data.user,
      token: data.access_token,
      isAuthenticated: true,
      isPinLocked: false,
    });
  },

  logout: () => {
    localStorage.removeItem('toc_access_token');
    localStorage.removeItem('toc_refresh_token');
    localStorage.removeItem('toc_user');
    localStorage.removeItem('toc_pin_locked');
    set({
      user: null,
      token: null,
      isAuthenticated: false,
      isPinLocked: false,
    });
  },

  lockSession: () => {
    localStorage.setItem('toc_pin_locked', 'true');
    set({ isPinLocked: true });
  },

  unlockSession: () => {
    localStorage.removeItem('toc_pin_locked');
    set({ isPinLocked: false });
  },

  initFromStorage: () => {
    const token = localStorage.getItem('toc_access_token');
    const userJson = localStorage.getItem('toc_user');
    const isLocked = localStorage.getItem('toc_pin_locked') === 'true';
    if (token && userJson) {
      try {
        const user = JSON.parse(userJson) as UserBrief;
        set({
          user,
          token,
          isAuthenticated: true,
          isPinLocked: isLocked,
        });
      } catch {
        localStorage.clear();
      }
    }
  },
}));
