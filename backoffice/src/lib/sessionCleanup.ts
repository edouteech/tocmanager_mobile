import axios from 'axios';
import { queryClient } from './queryClient';
import { clearTocStorage } from './sessionStorageKeys';
import { useTenantStore } from '../stores/tenantStore';

const API_BASE_URL = import.meta.env.VITE_API_URL || '/api/v1';

export const clearAllSessionState = () => {
  clearTocStorage();
  useTenantStore.getState().resetTenant();
  queryClient.clear();
};

export const revokeSessionBestEffort = (
  accessToken: string | null,
  refreshToken: string | null
) => {
  if (!accessToken && !refreshToken) return;
  axios
    .post(
      `${API_BASE_URL}/auth/logout`,
      { refresh_token: refreshToken || undefined },
      {
        headers: accessToken ? { Authorization: `Bearer ${accessToken}` } : undefined,
        timeout: 2500,
      }
    )
    .catch(() => {
      // Best-effort revocation; local session purge proceeds unconditionally
    });
};
