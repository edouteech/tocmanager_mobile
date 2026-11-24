import React, { Suspense, lazy, useEffect } from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClientProvider } from '@tanstack/react-query';
import { queryClient } from './lib/queryClient';
import { ThemeProvider } from './context/ThemeContext';
import { DensityProvider } from './context/DensityContext';
import { SidebarProvider } from './context/SidebarContext';
import { ToastProvider } from './context/ToastContext';
import { useAuthStore } from './stores/authStore';
import { MainLayout } from './components/layout/MainLayout';
import { AdminLayout } from './components/layout/AdminLayout';
import { ProtectedRoute } from './components/layout/ProtectedRoute';

const lazyNamed = <T extends React.ComponentType<any>>(
  loader: () => Promise<Record<string, unknown>>,
  exportName: string
) =>
  lazy(() =>
    loader().then((module) => ({
      default: module[exportName] as T,
    }))
  );

// Landing & Public SaaS Pages
const LandingPage = lazyNamed(() => import('./features/landing/LandingPage'), 'LandingPage');
const PricingPage = lazyNamed(() => import('./features/landing/PricingPage'), 'PricingPage');
const ContactPage = lazyNamed(() => import('./features/landing/ContactPage'), 'ContactPage');
const TermsPage = lazyNamed(() => import('./features/landing/TermsPage'), 'TermsPage');
const PrivacyPage = lazyNamed(() => import('./features/landing/PrivacyPage'), 'PrivacyPage');
const RegisterPage = lazyNamed(() => import('./features/landing/RegisterPage'), 'RegisterPage');
const LoginPage = lazyNamed(() => import('./features/auth/LoginPage'), 'LoginPage');
const ForgotPasswordPage = lazyNamed(
  () => import('./features/auth/ForgotPasswordPage'),
  'ForgotPasswordPage'
);
const ResetPasswordPage = lazyNamed(
  () => import('./features/auth/ResetPasswordPage'),
  'ResetPasswordPage'
);
const VerifyEmailPage = lazyNamed(
  () => import('./features/auth/VerifyEmailPage'),
  'VerifyEmailPage'
);

// Client Backoffice Pages
const DashboardPage = lazyNamed(() => import('./features/dashboard/DashboardPage'), 'DashboardPage');
const SalesPage = lazyNamed(() => import('./features/sales/SalesPage'), 'SalesPage');
const CashSessionsPage = lazyNamed(() => import('./features/cash/CashSessionsPage'), 'CashSessionsPage');
const ProductsPage = lazyNamed(() => import('./features/inventory/ProductsPage'), 'ProductsPage');
const CategoriesPage = lazyNamed(() => import('./features/inventory/CategoriesPage'), 'CategoriesPage');
const ClientsPage = lazyNamed(() => import('./features/clients/ClientsPage'), 'ClientsPage');
const SuppliersPage = lazyNamed(() => import('./features/suppliers/SuppliersPage'), 'SuppliersPage');
const SuppliesPage = lazyNamed(() => import('./features/supplies/SuppliesPage'), 'SuppliesPage');
const TransfersPage = lazyNamed(() => import('./features/transfers/TransfersPage'), 'TransfersPage');
const ExpensesPage = lazyNamed(() => import('./features/expenses/ExpensesPage'), 'ExpensesPage');
const ReportsPage = lazyNamed(() => import('./features/reports/ReportsPage'), 'ReportsPage');
const MagasinsPage = lazyNamed(() => import('./features/magasins/MagasinsPage'), 'MagasinsPage');
const UsersPage = lazyNamed(() => import('./features/users/UsersPage'), 'UsersPage');
const AuditLogsPage = lazyNamed(() => import('./features/audit/AuditLogsPage'), 'AuditLogsPage');
const SettingsPage = lazyNamed(() => import('./features/settings/SettingsPage'), 'SettingsPage');
const SubscriptionPage = lazyNamed(
  () => import('./features/subscription/SubscriptionPage'),
  'SubscriptionPage'
);

// Super-Admin Console Pages
const AdminDashboardPage = lazyNamed(
  () => import('./features/admin/AdminDashboardPage'),
  'AdminDashboardPage'
);
const AdminPlansPage = lazyNamed(() => import('./features/admin/AdminPlansPage'), 'AdminPlansPage');
const AdminBoutiquesPage = lazyNamed(
  () => import('./features/admin/AdminBoutiquesPage'),
  'AdminBoutiquesPage'
);
const AdminSubscriptionsPage = lazyNamed(
  () => import('./features/admin/AdminSubscriptionsPage'),
  'AdminSubscriptionsPage'
);
const AdminAuditPage = lazyNamed(() => import('./features/admin/AdminAuditPage'), 'AdminAuditPage');

const PageLoader: React.FC = () => (
  <div className="min-h-[50vh] flex flex-col items-center justify-center gap-3 text-slate-500 dark:text-slate-400">
    <div className="w-8 h-8 border-2 border-[#29ABE2] border-t-transparent rounded-full animate-spin" />
    <span className="text-xs font-medium">Chargement...</span>
  </div>
);

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
            <ToastProvider>
              <BrowserRouter>
              <Suspense fallback={<PageLoader />}>
                <Routes>
                  {/* Public Marketing & Pricing Pages */}
                  <Route path="/landing" element={<LandingPage />} />
                  <Route path="/tarifs" element={<PricingPage />} />
                  <Route path="/contact" element={<ContactPage />} />
                  <Route path="/cgu" element={<TermsPage />} />
                  <Route path="/confidentialite" element={<PrivacyPage />} />
                  <Route path="/inscription" element={<RegisterPage />} />
                  <Route path="/login" element={<LoginPage />} />
                  <Route path="/forgot-password" element={<ForgotPasswordPage />} />
                  <Route path="/reset-password" element={<ResetPasswordPage />} />
                  <Route path="/verify-email" element={<VerifyEmailPage />} />

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
                    <Route path="subscriptions" element={<AdminSubscriptionsPage />} />
                    <Route path="audit" element={<AdminAuditPage />} />
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
                      <Route path="caisse-z" element={<CashSessionsPage />} />
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
                      <Route
                        path="transferts"
                        element={
                          <ProtectedRoute allowedRoles={['owner', 'store_admin', 'manager', 'merchant']}>
                            <TransfersPage />
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
                      <Route
                        path="abonnement"
                        element={
                          <ProtectedRoute allowedRoles={['owner', 'store_admin', 'merchant']}>
                            <SubscriptionPage />
                          </ProtectedRoute>
                        }
                      />
                    </Route>
                  ) : (
                    <Route path="/" element={<LandingPage />} />
                  )}

                  {/* Fallback */}
                  <Route path="*" element={<Navigate to="/" replace />} />
                </Routes>
              </Suspense>
            </BrowserRouter>
            </ToastProvider>
          </SidebarProvider>
        </DensityProvider>
      </ThemeProvider>
    </QueryClientProvider>
  );
};

export default App;
