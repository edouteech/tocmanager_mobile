import axios, { AxiosRequestConfig } from 'axios';
import { queryClient } from '../queryClient';
import { clearTocStorage } from '../sessionStorageKeys';
import type { AuthResponse } from '../../types';

const API_BASE_URL = import.meta.env.VITE_API_URL || '/api/v1';

export const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

const PUBLIC_AUTH_PATHS = ['/auth/login', '/auth/refresh', '/saas/auth/register-credentials'];

const isPublicAuthEndpoint = (url?: string): boolean => {
  if (!url) return false;
  return PUBLIC_AUTH_PATHS.some((path) => url.includes(path));
};

type QueuedRequest = {
  resolve: (token: string) => void;
  reject: (err: unknown) => void;
};

let isRefreshing = false;
let failedQueue: QueuedRequest[] = [];

const processQueue = (error: unknown, token: string | null) => {
  failedQueue.forEach((prom) => {
    if (error || !token) {
      prom.reject(error);
    } else {
      prom.resolve(token);
    }
  });
  failedQueue = [];
};

const clearAuthStorageAndRedirect = () => {
  clearTocStorage();
  queryClient.clear();
  window.dispatchEvent(new CustomEvent('toc:session-cleared'));
  if (window.location.pathname !== '/login') {
    window.location.href = '/login';
  }
};

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('toc_access_token');
  if (token && config.headers) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  const boutiqueId = localStorage.getItem('toc_current_boutique_id');
  if (boutiqueId && config.headers) {
    config.headers['X-Boutique-Id'] = boutiqueId;
  }
  const magasinId = localStorage.getItem('toc_current_magasin_id');
  if (
    magasinId &&
    magasinId !== 'consolidated' &&
    magasinId !== 'all' &&
    config.headers
  ) {
    config.headers['X-Magasin-Id'] = magasinId;
  }
  return config;
});

api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config as (AxiosRequestConfig & { _retry?: boolean }) | undefined;
    if (
      error.response?.status === 401 &&
      originalRequest &&
      !originalRequest._retry &&
      !isPublicAuthEndpoint(originalRequest.url)
    ) {
      if (isRefreshing) {
        return new Promise<string>((resolve, reject) => {
          failedQueue.push({ resolve, reject });
        }).then((newToken) => {
          originalRequest.headers = originalRequest.headers || {};
          originalRequest.headers.Authorization = `Bearer ${newToken}`;
          return api(originalRequest);
        });
      }

      originalRequest._retry = true;
      isRefreshing = true;

      const refreshToken = localStorage.getItem('toc_refresh_token');
      if (!refreshToken) {
        isRefreshing = false;
        processQueue(error, null);
        clearAuthStorageAndRedirect();
        return Promise.reject(error);
      }

      try {
        const res = await axios.post<AuthResponse>(`${API_BASE_URL}/auth/refresh`, {
          refresh_token: refreshToken,
        });
        const { access_token, refresh_token: newRefresh, user } = res.data;
        localStorage.setItem('toc_access_token', access_token);
        if (newRefresh) {
          localStorage.setItem('toc_refresh_token', newRefresh);
        }
        if (user) {
          localStorage.setItem('toc_user', JSON.stringify(user));
        }
        processQueue(null, access_token);
        originalRequest.headers = originalRequest.headers || {};
        originalRequest.headers.Authorization = `Bearer ${access_token}`;
        return api(originalRequest);
      } catch (refreshErr) {
        processQueue(refreshErr, null);
        clearAuthStorageAndRedirect();
        return Promise.reject(refreshErr);
      } finally {
        isRefreshing = false;
      }
    }

    if (error.response?.status === 403) {
      const detail = error.response?.data?.detail;
      if (
        detail &&
        typeof detail === 'object' &&
        (detail.error === 'PLAN_FEATURE_LOCKED' || detail.error === 'PLAN_QUOTA_EXCEEDED')
      ) {
        window.dispatchEvent(new CustomEvent('toc:plan-upgrade-required', { detail }));
      }
    }
    return Promise.reject(error);
  }
);
