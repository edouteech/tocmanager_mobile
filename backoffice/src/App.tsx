import React, { useEffect } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ThemeProvider } from './context/ThemeContext';
import { DensityProvider } from './context/DensityContext';
import { SidebarProvider } from './context/SidebarContext';
import { useAuthStore } from './stores/authStore';
import { MainLayout } from './components/layout/MainLayout';
import { AdminLayout } from './components/layout/AdminLayout';
import { ProtectedRoute } from './components/layout/ProtectedRoute';

// Landing & Public SaaS Pages
import { LandingPage } from './features/landing/LandingPage';
import { PricingPage } from './features/landing/PricingPage';
import { RegisterPage } from './features/landing/RegisterPage';
import { LoginPage } from './features/auth/LoginPage';

// Client Backoffice Pages
import { DashboardPage } from './features/dashboard/DashboardPage';
import { SalesPage } from './features/sales/SalesPage';
import { ProductsPage } from './features/inventory/ProductsPage';
import { CategoriesPage } from './features/inventory/CategoriesPage';
import { ClientsPage } from './features/clients/ClientsPage';
import { SuppliersPage } from './features/suppliers/SuppliersPage';
import { SuppliesPage } from './features/supplies/SuppliesPage';
import { ExpensesPage } from './features/expenses/ExpensesPage';
import { ReportsPage } from './features/reports/ReportsPage';
import { MagasinsPage } from './features/magasins/MagasinsPage';
import { UsersPage } from './features/users/UsersPage';
import { AuditLogsPage } from './features/audit/AuditLogsPage';
import { SettingsPage } from './features/settings/SettingsPage';

// Super-Admin Console Pages
import { AdminDashboardPage } from './features/admin/AdminDashboardPage';
import { AdminPlansPage } from './features/admin/AdminPlansPage';
import { AdminBoutiquesPage } from './features/admin/AdminBoutiquesPage';

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
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated);

  useEffect(() => {
    initFromStorage();
  }, [initFromStorage]);

  const hasStoredToken = Boolean(localStorage.getItem('toc_access_token'));
  const isUserLoggedIn = isAuthenticated || hasStoredToken;

  return (
    <QueryClientProvider client={queryClient}>
      <ThemeProvider>
        <DensityProvider>
          <SidebarProvider>
            <BrowserRouter>
              <Routes>
                {/* Public Marketing & Pricing Pages */}
                <Route path="/landing" element={<LandingPage />} />
                <Route path="/tarifs" element={<PricingPage />} />
                <Route path="/inscription" element={<RegisterPage />} />
                <Route path="/login" element={<LoginPage />} />

                {/* Super-Admin Platform Console */}
                <Route
                  path="/admin"
                  element={
                    <ProtectedRoute allowedRoles={['superadmin']}>
                      <AdminLayout />
                    </ProtectedRoute>
                  }
                >
                  <Route index element={<AdminDashboardPage />} />
                  <Route path="plans" element={<AdminPlansPage />} />
                  <Route path="boutiques" element={<AdminBoutiquesPage />} />
                </Route>

                {/* Client Backoffice (Protected Dashboard) */}
                {isUserLoggedIn ? (
                  <Route
                    path="/"
                    element={
                      <ProtectedRoute>
                        <MainLayout />
                      </ProtectedRoute>
                    }
                  >
                    {/* Commerce & Caisse */}
                    <Route index element={<DashboardPage />} />
                    <Route path="ventes" element={<SalesPage />} />
                    <Route path="clients" element={<ClientsPage />} />

                    {/* Catalogue, Stocks & Points de vente */}
                    <Route path="produits" element={<ProductsPage />} />
                    <Route path="categories" element={<CategoriesPage />} />
                    <Route path="magasins" element={<MagasinsPage />} />
                    <Route
                      path="approvisionnements"
                      element={
                        <ProtectedRoute allowedRoles={['owner', 'store_admin', 'manager', 'merchant']}>
                          <SuppliesPage />
                        </ProtectedRoute>
                      }
                    />

                    {/* Finances */}
                    <Route path="depenses" element={<ExpensesPage />} />
                    <Route
                      path="fournisseurs"
                      element={
                        <ProtectedRoute allowedRoles={['owner', 'store_admin', 'manager', 'merchant']}>
                          <SuppliersPage />
                        </ProtectedRoute>
                      }
                    />
                    <Route
                      path="rapports"
                      element={
                        <ProtectedRoute allowedRoles={['owner', 'store_admin', 'manager', 'merchant']}>
                          <ReportsPage />
                        </ProtectedRoute>
                      }
                    />

                    {/* Administration Boutique */}
                    <Route
                      path="utilisateurs"
                      element={
                        <ProtectedRoute allowedRoles={['owner', 'store_admin', 'merchant']}>
                          <UsersPage />
                        </ProtectedRoute>
                      }
                    />
                    <Route
                      path="audit"
                      element={
                        <ProtectedRoute allowedRoles={['owner', 'store_admin', 'merchant']}>
                          <AuditLogsPage />
                        </ProtectedRoute>
                      }
                    />
                    <Route
                      path="parametres"
                      element={
                        <ProtectedRoute allowedRoles={['owner', 'store_admin', 'merchant']}>
                          <SettingsPage />
                        </ProtectedRoute>
                      }
                    />
                  </Route>
                ) : (
                  /* Visiteur non connecté accédant à / -> Landing Page */
                  <Route path="/" element={<LandingPage />} />
                )}

                {/* Fallback */}
                <Route path="*" element={<Navigate to="/" replace />} />
              </Routes>
            </BrowserRouter>
          </SidebarProvider>
        </DensityProvider>
      </ThemeProvider>
    </QueryClientProvider>
  );
};

export default App;
