import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { ThemeProvider } from '../context/ThemeContext';
import { useAuthStore } from '../stores/authStore';
import { saasApi } from '../lib/api';
import { LandingPage } from '../features/landing/LandingPage';
import { FALLBACK_PLANS } from '../features/landing/data/fallbackPlans';

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

const renderLandingPage = () => {
  const queryClient = new QueryClient({
    defaultOptions: { queries: { retry: false } },
  });

  return render(
    <QueryClientProvider client={queryClient}>
      <ThemeProvider>
        <MemoryRouter initialEntries={['/']}>
          <LandingPage />
        </MemoryRouter>
      </ThemeProvider>
    </QueryClientProvider>
  );
};

describe('LandingPage', () => {
  beforeEach(() => {
    localStorage.clear();
    mockMatchMedia();
    useAuthStore.setState({
      user: null,
      token: null,
      isAuthenticated: false,
      isPinLocked: false,
    });
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('renders all major SaaS sections and toggles interactive offline demo', async () => {
    vi.spyOn(saasApi, 'getPlans').mockResolvedValue(FALLBACK_PLANS);
    renderLandingPage();

    expect(
      screen.getByRole('heading', { name: /Pilotez vos points de vente/i })
    ).toBeInTheDocument();
    expect(screen.getByText(/Application Android incluse dans votre espace/i)).toBeInTheDocument();
    expect(screen.getByText(/En ligne • Synchronisé/i)).toBeInTheDocument();

    fireEvent.click(screen.getByRole('button', { name: /Simuler coupure internet/i }));
    expect(screen.getByText(/Hors-ligne • 3 UUID en file/i)).toBeInTheDocument();

    fireEvent.click(screen.getByRole('button', { name: /Reconnecter & sync/i }));
    expect(screen.getByText(/En ligne • Synchronisé/i)).toBeInTheDocument();
  });

  it('supports keyboard navigation on Product Tour tabs and store switcher', async () => {
    vi.spyOn(saasApi, 'getPlans').mockResolvedValue(FALLBACK_PLANS);
    renderLandingPage();

    const posTab = screen.getByRole('tab', { name: /Caisse POS Offline/i });
    expect(posTab).toHaveAttribute('aria-selected', 'true');

    fireEvent.keyDown(posTab, { key: 'ArrowRight' });
    const multiTab = screen.getByRole('tab', { name: /Multi-Magasins/i });
    expect(multiTab).toHaveAttribute('aria-selected', 'true');
    expect(screen.getByText(/Transferts & Cloisonnement Stocks/i)).toBeInTheDocument();

    fireEvent.click(screen.getByRole('button', { name: /Point de Vente Plateau/i }));
    expect(screen.getByText(/142 ventes aujourd’hui/i)).toBeInTheDocument();
  });

  it('filters screenshots gallery and opens/closes lightbox with Escape', async () => {
    vi.spyOn(saasApi, 'getPlans').mockResolvedValue(FALLBACK_PLANS);
    renderLandingPage();

    fireEvent.click(screen.getByRole('button', { name: /^Application Mobile$/i }));
    expect(screen.queryByText(/Tableau de bord Web consolidé/i)).not.toBeInTheDocument();
    expect(screen.getByText(/Caisse POS Mobile Offline-First/i)).toBeInTheDocument();

    fireEvent.click(
      screen.getByRole('button', { name: /Agrandir la capture : Caisse POS Mobile Offline-First/i })
    );
    expect(screen.getByRole('dialog', { name: /Aperçu agrandi/i })).toBeInTheDocument();

    fireEvent.keyDown(window, { key: 'Escape' });
    expect(screen.queryByRole('dialog')).not.toBeInTheDocument();
  });

  it('falls back gracefully to default plans when API fails and toggles yearly prices', async () => {
    vi.spyOn(saasApi, 'getPlans').mockRejectedValue(new Error('Network error'));
    renderLandingPage();

    await waitFor(() => {
      expect(screen.getByRole('heading', { name: 'Plan Gratuit' })).toBeInTheDocument();
    });
    expect(screen.getByRole('heading', { name: 'Plan Pro' })).toBeInTheDocument();
    expect(screen.getByRole('heading', { name: 'Plan Entreprise' })).toBeInTheDocument();
    expect(screen.getByText(/15[\s\u00a0\u202f]000 FCFA/)).toBeInTheDocument();

    const switchBtn = screen.getByRole('switch', { name: /Basculer entre facturation/i });
    fireEvent.click(switchBtn);
    expect(switchBtn).toHaveAttribute('aria-checked', 'true');
    expect(screen.getByText(/150[\s\u00a0\u202f]000 FCFA/)).toBeInTheDocument();
  });

  it('toggles FAQ accordion items and adapts navbar CTA for authenticated roles', async () => {
    vi.spyOn(saasApi, 'getPlans').mockResolvedValue(FALLBACK_PLANS);
    const { rerender } = renderLandingPage();

    const firstFaq = screen.getByRole('button', { name: /connexion internet est coupée/i });
    expect(firstFaq).toHaveAttribute('aria-expanded', 'true');
    fireEvent.click(firstFaq);
    expect(firstFaq).toHaveAttribute('aria-expanded', 'false');

    expect(screen.getByRole('link', { name: /^Connexion$/i })).toBeInTheDocument();

    fireEvent.click(screen.getByRole('button', { name: /Ouvrir le menu/i }));
    expect(screen.getByRole('dialog', { name: /Navigation mobile/i })).toBeInTheDocument();
    fireEvent.keyDown(window, { key: 'Escape' });
    expect(screen.queryByRole('dialog', { name: /Navigation mobile/i })).not.toBeInTheDocument();

    useAuthStore.setState({
      isAuthenticated: true,
      token: 'jwt-merchant',
      user: {
        id: 'u-1',
        username: 'awa',
        full_name: 'Awa Diop',
        role: 'merchant',
        permissions: [],
        has_pin: true,
        is_active: true,
      },
    });
    const queryClient = new QueryClient({ defaultOptions: { queries: { retry: false } } });
    rerender(
      <QueryClientProvider client={queryClient}>
        <ThemeProvider>
          <MemoryRouter initialEntries={['/landing']}>
            <LandingPage />
          </MemoryRouter>
        </ThemeProvider>
      </QueryClientProvider>
    );
    expect(screen.getByRole('link', { name: /Accéder à mon espace/i })).toHaveAttribute('href', '/');

    useAuthStore.setState({
      isAuthenticated: true,
      token: 'jwt-admin',
      user: {
        id: 'u-sa',
        username: 'superadmin',
        full_name: 'Super Admin',
        role: 'superadmin',
        permissions: [],
        has_pin: false,
        is_active: true,
      },
    });
    rerender(
      <QueryClientProvider client={queryClient}>
        <ThemeProvider>
          <MemoryRouter initialEntries={['/landing']}>
            <LandingPage />
          </MemoryRouter>
        </ThemeProvider>
      </QueryClientProvider>
    );
    expect(screen.getByRole('link', { name: /Accéder à mon espace/i })).toHaveAttribute('href', '/admin');
  });
});
