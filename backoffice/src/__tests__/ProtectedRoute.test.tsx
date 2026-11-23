import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter, Route, Routes } from 'react-router-dom';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { ProtectedRoute } from '../components/layout/ProtectedRoute';
import { authApi } from '../lib/api';
import { useAuthStore } from '../stores/authStore';
import { UserBrief } from '../types';

const makeUser = (role: string): UserBrief => ({
  id: 'u1',
  username: 'tester',
  full_name: 'Test User',
  email: 'test@tocmanager.com',
  role,
  permissions: [],
  has_pin: false,
  is_active: true,
});

const renderWithRoute = (allowedRoles?: string[]) => {
  const client = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });
  return render(
    <QueryClientProvider client={client}>
      <MemoryRouter initialEntries={['/protected']}>
        <Routes>
          <Route path="/login" element={<div>Login Page</div>} />
          <Route path="/admin" element={<div>Admin Console</div>} />
          <Route path="/" element={<div>Dashboard Home</div>} />
          <Route
            path="/protected"
            element={
              <ProtectedRoute allowedRoles={allowedRoles}>
                <div>Secret Content</div>
              </ProtectedRoute>
            }
          />
        </Routes>
      </MemoryRouter>
    </QueryClientProvider>
  );
};

describe('ProtectedRoute', () => {
  beforeEach(() => {
    localStorage.clear();
    useAuthStore.setState({ user: null, token: null, isAuthenticated: false, isPinLocked: false });
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('redirects unauthenticated visitors to /login', () => {
    renderWithRoute();
    expect(screen.getByText('Login Page')).toBeInTheDocument();
  });

  it('redirects superadmin away from merchant routes to /admin', async () => {
    const superUser = makeUser('superadmin');
    localStorage.setItem('toc_access_token', 'tok-super');
    useAuthStore.setState({ user: superUser, token: 'tok-super', isAuthenticated: true });
    vi.spyOn(authApi, 'me').mockResolvedValue(superUser);

    renderWithRoute(['owner']);
    await waitFor(() => {
      expect(screen.getByText('Admin Console')).toBeInTheDocument();
    });
  });

  it('blocks non-superadmin users from superadmin routes', async () => {
    const ownerUser = makeUser('owner');
    localStorage.setItem('toc_access_token', 'tok-owner');
    useAuthStore.setState({ user: ownerUser, token: 'tok-owner', isAuthenticated: true });
    vi.spyOn(authApi, 'me').mockResolvedValue(ownerUser);

    renderWithRoute(['superadmin']);
    await waitFor(() => {
      expect(screen.getByText('Dashboard Home')).toBeInTheDocument();
    });
  });

  it('blocks cashier from store_admin-only routes', async () => {
    const cashier = makeUser('cashier');
    localStorage.setItem('toc_access_token', 'tok-cashier');
    useAuthStore.setState({ user: cashier, token: 'tok-cashier', isAuthenticated: true });
    vi.spyOn(authApi, 'me').mockResolvedValue(cashier);

    renderWithRoute(['owner', 'store_admin']);
    await waitFor(() => {
      expect(screen.getByText('Dashboard Home')).toBeInTheDocument();
    });
  });

  it('normalizes legacy merchant role as owner and allows store_admin routes', async () => {
    const merchant = makeUser('merchant');
    localStorage.setItem('toc_access_token', 'tok-merchant');
    useAuthStore.setState({ user: merchant, token: 'tok-merchant', isAuthenticated: true });
    vi.spyOn(authApi, 'me').mockResolvedValue(merchant);

    renderWithRoute(['store_admin']);
    await waitFor(() => {
      expect(screen.getByText('Secret Content')).toBeInTheDocument();
    });
  });
});
