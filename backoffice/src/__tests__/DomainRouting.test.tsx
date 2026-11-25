import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { AppRoutes } from '../routes/AppRoutes';
import { LoginPage } from '../features/auth/LoginPage';
import { DensityProvider } from '../context/DensityContext';
import { SidebarProvider } from '../context/SidebarContext';
import { ThemeProvider } from '../context/ThemeContext';
import { ToastProvider } from '../context/ToastContext';
import { authApi, saasApi } from '../lib/api';
import { buildSurfaceUrl, resolveAppSurface } from '../lib/domainRouting';
import { decodeImpersonationPayload, encodeImpersonationPayload } from '../lib/impersonationTransfer';
import { useAuthStore } from '../stores/authStore';

const mockMatchMedia = () => {
  Object.defineProperty(window, 'matchMedia', {
    writable: true,
    value: vi.fn().mockImplementation((query: string) => ({
      matches: false,
      media: query,
      onchange: null,
      addListener: vi.fn(),
      removeListener: vi.fn(),
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
      dispatchEvent: vi.fn(),
    })),
  });
};

const renderAppAt = (surface: 'public' | 'app' | 'admin' | 'all', initialPath: string) => {
  const client = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });
  return render(
    <QueryClientProvider client={client}>
      <ThemeProvider>
        <DensityProvider>
          <SidebarProvider>
            <ToastProvider>
              <MemoryRouter initialEntries={[initialPath]}>
                <AppRoutes surface={surface} />
              </MemoryRouter>
            </ToastProvider>
          </SidebarProvider>
        </DensityProvider>
      </ThemeProvider>
    </QueryClientProvider>
  );
};

describe('Domain routing & 3-subdomain isolation', () => {
  beforeEach(() => {
    localStorage.clear();
    localStorage.setItem('toc_theme', 'light');
    mockMatchMedia();
    useAuthStore.setState({ user: null, token: null, isAuthenticated: false, isPinLocked: false });
    vi.spyOn(saasApi, 'getPlans').mockResolvedValue([]);
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('resolves hostnames and builds cross-subdomain URLs accurately', () => {
    expect(resolveAppSurface('tocmanager.locarapide.com')).toBe('public');
    expect(resolveAppSurface('www.tocmanager.locarapide.com')).toBe('public');
    expect(resolveAppSurface('app.tocmanager.locarapide.com')).toBe('app');
    expect(resolveAppSurface('admin.tocmanager.locarapide.com')).toBe('admin');
    expect(resolveAppSurface('localhost')).toBe('all');
    expect(resolveAppSurface('127.0.0.1')).toBe('all');

    const prodLoc = { protocol: 'https:', hostname: 'tocmanager.locarapide.com', port: '' };
    expect(buildSurfaceUrl('app', '/inscription?plan=pro', prodLoc)).toBe(
      'https://app.tocmanager.locarapide.com/inscription?plan=pro'
    );
    expect(buildSurfaceUrl('admin', '/admin', prodLoc)).toBe(
      'https://admin.tocmanager.locarapide.com/admin'
    );
    expect(
      buildSurfaceUrl('public', '/tarifs', {
        protocol: 'https:',
        hostname: 'admin.tocmanager.locarapide.com',
        port: '',
      })
    ).toBe('https://tocmanager.locarapide.com/tarifs');

    expect(
      buildSurfaceUrl('app', '/login', { protocol: 'http:', hostname: 'localhost', port: '5173' })
    ).toBe('/login');
  });

  it('serves only public pages on public surface and renders 404 for /admin and workspace routes', async () => {
    const first = renderAppAt('public', '/');
    expect(await screen.findByText(/Application Android incluse/i)).toBeInTheDocument();
    first.unmount();

    const adminHit = renderAppAt('public', '/admin/boutiques');
    expect(await screen.findByRole('heading', { name: /Page introuvable/i })).toBeInTheDocument();
    adminHit.unmount();

    renderAppAt('public', '/ventes');
    expect(await screen.findByRole('heading', { name: /Page introuvable/i })).toBeInTheDocument();
  });

  it('isolates app surface from /admin and public-only pages while routing auth/workspace', async () => {
    const adminAttempt = renderAppAt('app', '/admin');
    expect(await screen.findByRole('heading', { name: /Page introuvable/i })).toBeInTheDocument();
    adminAttempt.unmount();

    const pricingAttempt = renderAppAt('app', '/tarifs');
    expect(await screen.findByRole('heading', { name: /Page introuvable/i })).toBeInTheDocument();
    pricingAttempt.unmount();

    const loginAttempt = renderAppAt('app', '/login');
    expect(await screen.findByText(/Portail d'Administration Central/i)).toBeInTheDocument();
    loginAttempt.unmount();

    renderAppAt('app', '/');
    expect(await screen.findByText(/Portail d'Administration Central/i)).toBeInTheDocument();
  });

  it('isolates admin surface from public/client pages and directs root /admin to login', async () => {
    const regAttempt = renderAppAt('admin', '/inscription');
    expect(await screen.findByRole('heading', { name: /Page introuvable/i })).toBeInTheDocument();
    regAttempt.unmount();

    const salesAttempt = renderAppAt('admin', '/ventes');
    expect(await screen.findByRole('heading', { name: /Page introuvable/i })).toBeInTheDocument();
    salesAttempt.unmount();

    renderAppAt('admin', '/admin');
    expect(await screen.findByText(/Console Super-Administration/i)).toBeInTheDocument();
  });

  it('enforces strict role guards on LoginPage per surface without persisting mismatched auth', async () => {
    const merchantLoginSpy = vi.spyOn(authApi, 'login').mockResolvedValueOnce({
      access_token: 'merchant-jwt',
      refresh_token: 'merchant-rt',
      token_type: 'bearer',
      requires_2fa: false,
      user: {
        id: 'u-m',
        username: 'merchant1',
        full_name: 'Merchant User',
        role: 'merchant',
        permissions: ['*'],
        has_pin: false,
        is_active: true,
      },
    });

    const adminRender = render(
      <ThemeProvider>
        <MemoryRouter>
          <LoginPage surface="admin" />
        </MemoryRouter>
      </ThemeProvider>
    );
    fireEvent.change(screen.getByPlaceholderText('Ex: admin ou caissier1'), {
      target: { value: 'merchant1' },
    });
    fireEvent.change(screen.getByPlaceholderText('********'), {
      target: { value: 'Secret123!' },
    });
    fireEvent.click(screen.getByRole('button', { name: /Se connecter/i }));

    expect(
      await screen.findByText(/réservé aux super-administrateurs/i)
    ).toBeInTheDocument();
    await waitFor(() => expect(merchantLoginSpy).toHaveBeenCalledTimes(1));
    expect(localStorage.getItem('toc_access_token')).toBeNull();
    adminRender.unmount();

    vi.spyOn(authApi, 'login').mockResolvedValueOnce({
      access_token: 'super-jwt',
      refresh_token: 'super-rt',
      token_type: 'bearer',
      requires_2fa: false,
      user: {
        id: 'u-sa',
        username: 'superadmin',
        full_name: 'Super Admin',
        role: 'superadmin',
        permissions: ['*'],
        has_pin: false,
        is_active: true,
      },
    });

    render(
      <ThemeProvider>
        <MemoryRouter>
          <LoginPage surface="app" />
        </MemoryRouter>
      </ThemeProvider>
    );
    fireEvent.change(screen.getByPlaceholderText('Ex: admin ou caissier1'), {
      target: { value: 'superadmin' },
    });
    fireEvent.change(screen.getByPlaceholderText('********'), {
      target: { value: 'Secret123!' },
    });
    fireEvent.click(screen.getByRole('button', { name: /Se connecter/i }));

    expect(
      await screen.findByText(/super-administrateur doit se connecter via la console dédiée/i)
    ).toBeInTheDocument();
    expect(localStorage.getItem('toc_access_token')).toBeNull();
  });

  it('round-trips UTF-8 cross-domain support impersonation payloads cleanly', () => {
    const sample = {
      access_token: 'jwt-readonly',
      user: {
        id: 'u-sa',
        username: 'support',
        full_name: 'Support Équipe',
        role: 'owner',
        permissions: ['*'],
        has_pin: false,
        is_active: true,
      },
      boutique_id: 'btq-1',
      boutique_name: 'Boutique Élégance Dakar',
      expires_in_minutes: 30,
    };

    const encoded = encodeImpersonationPayload(sample);
    expect(encoded).not.toContain('=');
    const decoded = decodeImpersonationPayload(encoded);
    expect(decoded).toEqual(sample);
    expect(decodeImpersonationPayload('invalid-base64!')).toBeNull();
  });
});
