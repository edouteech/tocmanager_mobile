import React, { Suspense, useEffect } from 'react';
import { Navigate, Route, Routes, useLocation } from 'react-router-dom';
import { MainLayout } from '../components/layout/MainLayout';
import { AdminLayout } from '../components/layout/AdminLayout';
import { ProtectedRoute } from '../components/layout/ProtectedRoute';
import { NotFoundPage } from '../components/common/NotFoundPage';
import { AppSurface, TargetSurface, buildSurfaceUrl, isExternalSurfaceUrl, resolveAppSurface } from '../lib/domainRouting';
import { useAuthStore } from '../stores/authStore';
import {
  AdminAuditPage,
  AdminBoutiquesPage,
  AdminDashboardPage,
  AdminPlansPage,
  AdminSubscriptionsPage,
  AuditLogsPage,
  CashSessionsPage,
  CategoriesPage,
  ClientsPage,
  ContactPage,
  DashboardPage,
  ExpensesPage,
  ForgotPasswordPage,
  LandingPage,
  LoginPage,
  MagasinsPage,
  PricingPage,
  PrivacyPage,
  ProductsPage,
  RegisterPage,
  ReportsPage,
  ResetPasswordPage,
  SalesPage,
  SettingsPage,
  SubscriptionPage,
  SuppliersPage,
  SuppliesPage,
  TermsPage,
  TransfersPage,
  UsersPage,
  VerifyEmailPage,
} from './lazyPages';

const MANAGER_ROLES = ['owner', 'store_admin', 'manager', 'merchant'];
const OWNER_ROLES = ['owner', 'store_admin', 'merchant'];

interface ClientSubRoute {
  path: string;
  Component: React.ComponentType;
  roles?: string[];
}

const CLIENT_SUB_ROUTES: ClientSubRoute[] = [
  { path: 'ventes', Component: SalesPage },
  { path: 'caisse-z', Component: CashSessionsPage },
  { path: 'clients', Component: ClientsPage },
  { path: 'produits', Component: ProductsPage },
  { path: 'categories', Component: CategoriesPage },
  { path: 'magasins', Component: MagasinsPage },
  { path: 'approvisionnements', Component: SuppliesPage, roles: MANAGER_ROLES },
  { path: 'transferts', Component: TransfersPage, roles: MANAGER_ROLES },
  { path: 'depenses', Component: ExpensesPage },
  { path: 'fournisseurs', Component: SuppliersPage, roles: MANAGER_ROLES },
  { path: 'rapports', Component: ReportsPage, roles: MANAGER_ROLES },
  { path: 'utilisateurs', Component: UsersPage, roles: OWNER_ROLES },
  { path: 'audit', Component: AuditLogsPage, roles: OWNER_ROLES },
  { path: 'parametres', Component: SettingsPage, roles: OWNER_ROLES },
  { path: 'abonnement', Component: SubscriptionPage, roles: OWNER_ROLES },
];

export const PageLoader: React.FC = () => (
  <div className="min-h-[50vh] flex flex-col items-center justify-center gap-3 text-slate-500 dark:text-slate-400">
    <div className="w-8 h-8 border-2 border-[#29ABE2] border-t-transparent rounded-full animate-spin" />
    <span className="text-xs font-medium">Chargement...</span>
  </div>
);

const ExternalSurfaceRedirect: React.FC<{ target: TargetSurface }> = ({ target }) => {
  const { pathname, search, hash } = useLocation();
  const destination = buildSurfaceUrl(target, `${pathname}${search}${hash}`);

  useEffect(() => {
    if (isExternalSurfaceUrl(destination)) {
      window.location.replace(destination);
    }
  }, [destination]);

  if (!isExternalSurfaceUrl(destination)) {
    return <Navigate to={destination} replace />;
  }
  return <PageLoader />;
};

const renderPublicPages = (includeLandingAlias: boolean) => (
  <>
    {includeLandingAlias && <Route path="/landing" element={<LandingPage />} />}
    <Route path="/tarifs" element={<PricingPage />} />
    <Route path="/contact" element={<ContactPage />} />
    <Route path="/cgu" element={<TermsPage />} />
    <Route path="/confidentialite" element={<PrivacyPage />} />
  </>
);

const renderAdminConsoleRoutes = (surface: AppSurface) => (
  <Route
    path="/admin"
    element={
      <ProtectedRoute allowedRoles={['superadmin']} surface={surface}>
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
);

const renderClientWorkspaceRoutes = (surface: AppSurface) => (
  <Route
    path="/"
    element={
      <ProtectedRoute surface={surface}>
        <MainLayout />
      </ProtectedRoute>
    }
  >
    <Route index element={<DashboardPage />} />
    {CLIENT_SUB_ROUTES.map(({ path, Component, roles }) => (
      <Route
        key={path}
        path={path}
        element={
          roles ? (
            <ProtectedRoute allowedRoles={roles} surface={surface}>
              <Component />
            </ProtectedRoute>
          ) : (
            <Component />
          )
        }
      />
    ))}
  </Route>
);

interface AppRoutesProps {
  surface?: AppSurface;
}

/**
 * Route table isolated per domain surface (public showcase, app.* client workspace, admin.* console).
 */
export const AppRoutes: React.FC<AppRoutesProps> = ({ surface }) => {
  const activeSurface = surface ?? resolveAppSurface();
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated);
  const hasStoredToken = Boolean(localStorage.getItem('toc_access_token'));
  const isUserLoggedIn = isAuthenticated || hasStoredToken;

  return (
    <Suspense fallback={<PageLoader />}>
      <Routes>
        {activeSurface === 'public' && (
          <>
            <Route path="/" element={<LandingPage />} />
            <Route path="/landing" element={<Navigate to="/" replace />} />
            {renderPublicPages(false)}
            <Route path="/login" element={<ExternalSurfaceRedirect target="app" />} />
            <Route path="/inscription" element={<ExternalSurfaceRedirect target="app" />} />
            <Route path="/forgot-password" element={<ExternalSurfaceRedirect target="app" />} />
            <Route path="/reset-password" element={<ExternalSurfaceRedirect target="app" />} />
            <Route path="/verify-email" element={<ExternalSurfaceRedirect target="app" />} />
            <Route path="*" element={<NotFoundPage />} />
          </>
        )}

        {activeSurface === 'app' && (
          <>
            <Route path="/login" element={<LoginPage surface="app" />} />
            <Route path="/inscription" element={<RegisterPage />} />
            <Route path="/forgot-password" element={<ForgotPasswordPage />} />
            <Route path="/reset-password" element={<ResetPasswordPage />} />
            <Route path="/verify-email" element={<VerifyEmailPage />} />
            {renderClientWorkspaceRoutes('app')}
            <Route path="/admin/*" element={<NotFoundPage />} />
            <Route path="*" element={<NotFoundPage />} />
          </>
        )}

        {activeSurface === 'admin' && (
          <>
            <Route path="/login" element={<LoginPage surface="admin" />} />
            <Route path="/forgot-password" element={<ForgotPasswordPage />} />
            <Route path="/reset-password" element={<ResetPasswordPage />} />
            <Route path="/" element={<Navigate to="/admin" replace />} />
            {renderAdminConsoleRoutes('admin')}
            <Route path="*" element={<NotFoundPage />} />
          </>
        )}

        {activeSurface === 'all' && (
          <>
            {renderPublicPages(true)}
            <Route path="/inscription" element={<RegisterPage />} />
            <Route path="/login" element={<LoginPage surface="all" />} />
            <Route path="/forgot-password" element={<ForgotPasswordPage />} />
            <Route path="/reset-password" element={<ResetPasswordPage />} />
            <Route path="/verify-email" element={<VerifyEmailPage />} />
            {renderAdminConsoleRoutes('all')}
            {isUserLoggedIn ? (
              renderClientWorkspaceRoutes('all')
            ) : (
              <Route path="/" element={<LandingPage />} />
            )}
            <Route path="*" element={<Navigate to="/" replace />} />
          </>
        )}
      </Routes>
    </Suspense>
  );
};
