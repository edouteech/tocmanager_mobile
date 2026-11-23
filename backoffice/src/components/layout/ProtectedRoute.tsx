import React, { useEffect } from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { useAuthStore } from '../../stores/authStore';
import { authApi } from '../../lib/api';

interface Props {
  children: React.ReactNode;
  allowedRoles?: string[];
}

export const ProtectedRoute: React.FC<Props> = ({ children, allowedRoles }) => {
  const { isAuthenticated, user, token, updateUser } = useAuthStore();
  const location = useLocation();
  const hasStoredToken = Boolean(token || localStorage.getItem('toc_access_token'));

  const { data: serverUser, isLoading: isVerifyingRole } = useQuery({
    queryKey: ['auth-me', token || localStorage.getItem('toc_access_token') || 'anon'],
    queryFn: () => authApi.me(),
    enabled: Boolean(isAuthenticated && hasStoredToken),
    staleTime: 60_000,
    retry: false,
  });

  useEffect(() => {
    if (serverUser) {
      updateUser(serverUser);
    }
  }, [serverUser, updateUser]);

  if (!isAuthenticated || !hasStoredToken) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  const effectiveUser = serverUser || user;
  if (allowedRoles && !serverUser && isVerifyingRole && !user) {
    return (
      <div className="min-h-[200px] flex items-center justify-center text-xs text-[#5A7184]">
        Vérification des droits...
      </div>
    );
  }

  if (effectiveUser) {
    const isSuperAdmin = effectiveUser.role === 'superadmin';

    if (allowedRoles && allowedRoles.includes('superadmin')) {
      if (!isSuperAdmin) {
        return <Navigate to="/" replace />;
      }
      return <>{children}</>;
    }

    if (isSuperAdmin) {
      return <Navigate to="/admin" replace />;
    }

    if (allowedRoles && allowedRoles.length > 0) {
      const normalizedUserRole =
        effectiveUser.role === 'merchant'
          ? 'owner'
          : effectiveUser.role === 'admin'
            ? 'store_admin'
            : effectiveUser.role;
      const hasAllowedRole = allowedRoles.some(
        (r) =>
          r === effectiveUser.role ||
          r === normalizedUserRole ||
          (normalizedUserRole === 'owner' && r === 'store_admin')
      );
      if (!hasAllowedRole) {
        return <Navigate to="/" replace />;
      }
    }
  }

  return <>{children}</>;
};
