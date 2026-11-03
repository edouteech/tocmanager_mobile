import React, { useEffect } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ThemeProvider } from './context/ThemeContext';
import { DensityProvider } from './context/DensityContext';
import { useAuthStore } from './stores/authStore';
import { MainLayout } from './components/layout/MainLayout';
import { ProtectedRoute } from './components/layout/ProtectedRoute';
import { LoginPage } from './features/auth/LoginPage';
import { DashboardPage } from './features/dashboard/DashboardPage';
import { SalesPage } from './features/sales/SalesPage';
import { ProductsPage } from './features/inventory/ProductsPage';
import { CategoriesPage } from './features/inventory/CategoriesPage';
import { ClientsPage } from './features/clients/ClientsPage';
import { SuppliersPage } from './features/suppliers/SuppliersPage';
import { SuppliesPage } from './features/supplies/SuppliesPage';
import { ExpensesPage } from './features/expenses/ExpensesPage';
import { ReportsPage } from './features/reports/ReportsPage';
import { UsersPage } from './features/users/UsersPage';
import { AuditLogsPage } from './features/audit/AuditLogsPage';
import { SettingsPage } from './features/settings/SettingsPage';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      refetchOnWindowFocus: false,
    },
  },
});

export const App: React.FC = () => {
  const initFromStorage = useAuthStore((s) => s.initFromStorage);

  useEffect(() => {
    initFromStorage();
  }, [initFromStorage]);

  return (
    <QueryClientProvider client={queryClient}>
      <ThemeProvider>
        <DensityProvider>
          <BrowserRouter>
            <Routes>
              {/* Public login route */}
              <Route path="/login" element={<LoginPage />} />

              {/* Protected routes inside MainLayout */}
              <Route
                path="/"
                element={
                  <ProtectedRoute>
                    <MainLayout />
                  </ProtectedRoute>
                }
              >
                {/* Ventes & Commerce */}
                <Route index element={<DashboardPage />} />
                <Route path="ventes" element={<SalesPage />} />
                <Route path="clients" element={<ClientsPage />} />

                {/* Catalogue & Stocks */}
                <Route path="produits" element={<ProductsPage />} />
                <Route path="categories" element={<CategoriesPage />} />
                <Route
                  path="approvisionnements"
                  element={
                    <ProtectedRoute allowedRoles={['admin', 'manager']}>
                      <SuppliesPage />
                    </ProtectedRoute>
                  }
                />

                {/* Finances & Dépenses */}
                <Route path="depenses" element={<ExpensesPage />} />
                <Route
                  path="fournisseurs"
                  element={
                    <ProtectedRoute allowedRoles={['admin', 'manager']}>
                      <SuppliersPage />
                    </ProtectedRoute>
                  }
                />

                {/* Analytique & Pilotage */}
                <Route
                  path="rapports"
                  element={
                    <ProtectedRoute allowedRoles={['admin', 'manager']}>
                      <ReportsPage />
                    </ProtectedRoute>
                  }
                />

                {/* Administration */}
                <Route
                  path="utilisateurs"
                  element={
                    <ProtectedRoute allowedRoles={['admin']}>
                      <UsersPage />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="audit"
                  element={
                    <ProtectedRoute allowedRoles={['admin']}>
                      <AuditLogsPage />
                    </ProtectedRoute>
                  }
                />
                <Route
                  path="parametres"
                  element={
                    <ProtectedRoute allowedRoles={['admin']}>
                      <SettingsPage />
                    </ProtectedRoute>
                  }
                />
              </Route>

              {/* Fallback */}
              <Route path="*" element={<Navigate to="/" replace />} />
            </Routes>
          </BrowserRouter>
        </DensityProvider>
      </ThemeProvider>
    </QueryClientProvider>
  );
};

export default App;
