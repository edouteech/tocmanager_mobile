import React from 'react';
import { useNavigate } from 'react-router-dom';
import { ShieldAlert, ArrowLeft } from 'lucide-react';
import { useAuthStore } from '../../stores/authStore';
import { useTenantStore } from '../../stores/tenantStore';
import { queryClient } from '../../lib/queryClient';
import { AuthResponse } from '../../types';

export const ImpersonationBanner: React.FC = () => {
  const navigate = useNavigate();
  const rawMeta = localStorage.getItem('toc_impersonation_meta');
  if (!rawMeta) return null;

  let meta: { boutique_name?: string; expires_in_minutes?: number } = {};
  try {
    meta = JSON.parse(rawMeta);
  } catch {
    return null;
  }

  const handleExitSupport = () => {
    const rawBackup = localStorage.getItem('toc_admin_backup_session');
    localStorage.removeItem('toc_impersonation_meta');
    localStorage.removeItem('toc_admin_backup_session');
    localStorage.removeItem('toc_current_boutique_id');
    localStorage.removeItem('toc_current_magasin_id');
    useTenantStore.getState().resetTenant();
    queryClient.clear();

    if (rawBackup) {
      try {
        const backup = JSON.parse(rawBackup) as {
          access_token: string;
          refresh_token?: string;
          user: AuthResponse['user'];
        };
        if (backup.access_token && backup.user) {
          useAuthStore.getState().setAuth({
            access_token: backup.access_token,
            refresh_token: backup.refresh_token || '',
            token_type: 'bearer',
            user: backup.user,
          });
          navigate('/admin/boutiques', { replace: true });
          return;
        }
      } catch {
        // Fallback below
      }
    }

    useAuthStore.getState().logout();
    navigate('/login', { replace: true });
  };

  return (
    <div className="bg-[#FEF5E7] dark:bg-[#F39C12]/20 border-b border-[#F39C12]/40 px-4 py-2 flex items-center justify-between gap-3 text-xs">
      <div className="flex items-center gap-2 font-semibold text-[#1C2B3A] dark:text-amber-200">
        <ShieldAlert className="w-4 h-4 text-[#F39C12] shrink-0" />
        <span>
          Mode support lecture seule actif — Boutique : {meta.boutique_name || 'Cliente'}
        </span>
      </div>
      <button
        type="button"
        onClick={handleExitSupport}
        className="inline-flex items-center gap-1.5 px-3 py-1 rounded-lg bg-[#F39C12] text-white font-bold hover:opacity-90 transition shrink-0"
      >
        <ArrowLeft className="w-3.5 h-3.5" />
        <span>Quitter le mode support</span>
      </button>
    </div>
  );
};
