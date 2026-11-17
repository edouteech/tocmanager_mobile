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

  if (allowedRoles && user) {
    if (user.role === 'superadmin') {
      return <>{children}</>;
    }
    if (
      !allowedRoles.includes(user.role) &&
      user.role !== 'admin' &&
      !(user.role === 'merchant' && allowedRoles.includes('manager'))
    ) {
      return <Navigate to="/" replace />;
    }
  }

  return <>{children}</>;
};
