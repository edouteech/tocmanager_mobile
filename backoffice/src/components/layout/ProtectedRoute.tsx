import React from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { useAuthStore } from '../../stores/authStore';

interface Props {
  children: React.ReactNode;
  allowedRoles?: string[];
}

export const ProtectedRoute: React.FC<Props> = ({ children, allowedRoles }) => {
  const { isAuthenticated, user, initFromStorage } = useAuthStore();
  const location = useLocation();

  if (!isAuthenticated) {
    // Failsafe: Check localStorage synchronously before redirecting to /login
    const token = localStorage.getItem('toc_access_token');
    const userJson = localStorage.getItem('toc_user');
    if (token && userJson) {
      initFromStorage();
      return <>{children}</>;
    }
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  if (user) {
    const isSuperAdmin = user.role === 'superadmin';

    // Règle 1: Route Super-Admin plateforme
    if (allowedRoles && allowedRoles.includes('superadmin')) {
      if (!isSuperAdmin) {
        // Un client / employé n'a aucun accès à l'administration de la plateforme SaaS
        return <Navigate to="/" replace />;
      }
      return <>{children}</>;
    }

    // Règle 2: Route Back-office Client
    // Un administrateur de plateforme ne doit pas voir les données privées d'une boutique client en tant que tel
    if (isSuperAdmin) {
      return <Navigate to="/admin" replace />;
    }

    // Règle 3: Vérification des rôles au sein de la boutique (commerçant, caissier, gérant)
    if (allowedRoles && allowedRoles.length > 0) {
      const normalizedUserRole =
        user.role === 'merchant'
          ? 'owner'
          : user.role === 'admin'
            ? 'store_admin'
            : user.role;
      const hasAllowedRole = allowedRoles.some(
        (r) =>
          r === user.role ||
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
