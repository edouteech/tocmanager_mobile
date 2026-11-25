import React, { lazy } from 'react';

const lazyNamed = <T extends React.ComponentType<any>>(
  loader: () => Promise<Record<string, unknown>>,
  exportName: string
) =>
  lazy(() =>
    loader().then((module) => ({
      default: module[exportName] as T,
    }))
  );

// Public Showcase Pages
export const LandingPage = lazyNamed(() => import('../features/landing/LandingPage'), 'LandingPage');
export const PricingPage = lazyNamed(() => import('../features/landing/PricingPage'), 'PricingPage');
export const ContactPage = lazyNamed(() => import('../features/landing/ContactPage'), 'ContactPage');
export const TermsPage = lazyNamed(() => import('../features/landing/TermsPage'), 'TermsPage');
export const PrivacyPage = lazyNamed(() => import('../features/landing/PrivacyPage'), 'PrivacyPage');

// Onboarding & Auth Pages
export const RegisterPage = lazyNamed(() => import('../features/landing/RegisterPage'), 'RegisterPage');
export const LoginPage = lazyNamed(() => import('../features/auth/LoginPage'), 'LoginPage');
export const ForgotPasswordPage = lazyNamed(
  () => import('../features/auth/ForgotPasswordPage'),
  'ForgotPasswordPage'
);
export const ResetPasswordPage = lazyNamed(
  () => import('../features/auth/ResetPasswordPage'),
  'ResetPasswordPage'
);
export const VerifyEmailPage = lazyNamed(
  () => import('../features/auth/VerifyEmailPage'),
  'VerifyEmailPage'
);

// Client Backoffice Pages
export const DashboardPage = lazyNamed(() => import('../features/dashboard/DashboardPage'), 'DashboardPage');
export const SalesPage = lazyNamed(() => import('../features/sales/SalesPage'), 'SalesPage');
export const CashSessionsPage = lazyNamed(() => import('../features/cash/CashSessionsPage'), 'CashSessionsPage');
export const ProductsPage = lazyNamed(() => import('../features/inventory/ProductsPage'), 'ProductsPage');
export const CategoriesPage = lazyNamed(() => import('../features/inventory/CategoriesPage'), 'CategoriesPage');
export const ClientsPage = lazyNamed(() => import('../features/clients/ClientsPage'), 'ClientsPage');
export const SuppliersPage = lazyNamed(() => import('../features/suppliers/SuppliersPage'), 'SuppliersPage');
export const SuppliesPage = lazyNamed(() => import('../features/supplies/SuppliesPage'), 'SuppliesPage');
export const TransfersPage = lazyNamed(() => import('../features/transfers/TransfersPage'), 'TransfersPage');
export const ExpensesPage = lazyNamed(() => import('../features/expenses/ExpensesPage'), 'ExpensesPage');
export const ReportsPage = lazyNamed(() => import('../features/reports/ReportsPage'), 'ReportsPage');
export const MagasinsPage = lazyNamed(() => import('../features/magasins/MagasinsPage'), 'MagasinsPage');
export const UsersPage = lazyNamed(() => import('../features/users/UsersPage'), 'UsersPage');
export const AuditLogsPage = lazyNamed(() => import('../features/audit/AuditLogsPage'), 'AuditLogsPage');
export const SettingsPage = lazyNamed(() => import('../features/settings/SettingsPage'), 'SettingsPage');
export const SubscriptionPage = lazyNamed(
  () => import('../features/subscription/SubscriptionPage'),
  'SubscriptionPage'
);

// Super-Admin Console Pages
export const AdminDashboardPage = lazyNamed(
  () => import('../features/admin/AdminDashboardPage'),
  'AdminDashboardPage'
);
export const AdminPlansPage = lazyNamed(() => import('../features/admin/AdminPlansPage'), 'AdminPlansPage');
export const AdminBoutiquesPage = lazyNamed(
  () => import('../features/admin/AdminBoutiquesPage'),
  'AdminBoutiquesPage'
);
export const AdminSubscriptionsPage = lazyNamed(
  () => import('../features/admin/AdminSubscriptionsPage'),
  'AdminSubscriptionsPage'
);
export const AdminAuditPage = lazyNamed(() => import('../features/admin/AdminAuditPage'), 'AdminAuditPage');
