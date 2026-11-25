import fs from 'node:fs';
import path from 'node:path';
import { render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { BrandLogo } from '../components/common/BrandLogo';
import { AdminLayout } from '../components/layout/AdminLayout';
import { Sidebar } from '../components/layout/Sidebar';
import { PublicFooter } from '../components/public/PublicFooter';
import { PublicMobileMenu } from '../components/public/PublicMobileMenu';
import { PublicNavbar } from '../components/public/PublicNavbar';
import { DensityProvider } from '../context/DensityContext';
import { SidebarProvider } from '../context/SidebarContext';
import { ThemeProvider } from '../context/ThemeContext';
import { LoginPage } from '../features/auth/LoginPage';
import { RegisterPage } from '../features/landing/RegisterPage';
import { saasApi } from '../lib/api';
import { useAuthStore } from '../stores/authStore';
import { useTenantStore } from '../stores/tenantStore';

const BACKOFFICE_ROOT = path.resolve(__dirname, '../..');
const REPO_ROOT = path.resolve(BACKOFFICE_ROOT, '..');

const BRAND_COMPONENT_FILES = [
  'src/components/public/PublicNavbar.tsx',
  'src/components/public/PublicFooter.tsx',
  'src/components/public/PublicMobileMenu.tsx',
  'src/features/landing/RegisterPage.tsx',
  'src/features/auth/LoginPage.tsx',
  'src/components/layout/Sidebar.tsx',
  'src/components/layout/AdminLayout.tsx',
];

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

describe('BrandLogo & official mobile brand assets', () => {
  beforeEach(() => {
    localStorage.clear();
    localStorage.setItem('toc_theme', 'light');
    mockMatchMedia();
    useAuthStore.setState({
      user: null,
      token: null,
      isAuthenticated: false,
      isPinLocked: false,
    });
    useTenantStore.setState({ currentPlan: null });
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('ships byte-identical logo.png and icon.png copied from mobile/assets', () => {
    for (const filename of ['logo.png', 'icon.png']) {
      const mobileAsset = path.join(REPO_ROOT, 'mobile/assets', filename);
      const webAsset = path.join(BACKOFFICE_ROOT, 'public/assets', filename);

      expect(fs.existsSync(mobileAsset)).toBe(true);
      expect(fs.existsSync(webAsset)).toBe(true);

      const mobileBytes = fs.readFileSync(mobileAsset);
      const webBytes = fs.readFileSync(webAsset);
      expect(webBytes.equals(mobileBytes)).toBe(true);
    }
  });

  it('configures favicon, apple-touch-icon, and og:image in index.html', () => {
    const html = fs.readFileSync(path.join(BACKOFFICE_ROOT, 'index.html'), 'utf-8');

    expect(html).toContain('<link rel="icon" type="image/png" href="/assets/icon.png" />');
    expect(html).toContain('<link rel="apple-touch-icon" href="/assets/icon.png" />');
    expect(html).toContain('<meta property="og:image" content="/assets/icon.png" />');
  });

  it('renders full logo and icon variants with expected intrinsic attributes', () => {
    const { rerender } = render(<BrandLogo />);
    const fullImg = screen.getByRole('img', { name: 'TocManager' });
    expect(fullImg).toHaveAttribute('src', '/assets/logo.png');
    expect(fullImg).toHaveAttribute('width', '500');
    expect(fullImg).toHaveAttribute('height', '85');
    expect(fullImg).toHaveAttribute('loading', 'lazy');

    rerender(<BrandLogo variant="icon" size="md" priority />);
    const iconImg = screen.getByRole('img', { name: 'TocManager' });
    expect(iconImg).toHaveAttribute('src', '/assets/icon.png');
    expect(iconImg).toHaveAttribute('width', '499');
    expect(iconImg).toHaveAttribute('height', '499');
    expect(iconImg).toHaveAttribute('loading', 'eager');
  });

  it('removes legacy split HTML brand placeholders from all 7 web brand components', () => {
    for (const relPath of BRAND_COMPONENT_FILES) {
      const content = fs.readFileSync(path.join(BACKOFFICE_ROOT, relPath), 'utf-8');
      expect(content).toContain('BrandLogo');
      expect(content).not.toContain('Toc<span');
    }
  });

  it('renders the real logo image across public navigation, auth pages, and app sidebars', async () => {
    const plansSpy = vi.spyOn(saasApi, 'getPlans').mockResolvedValue([]);

    const assertions: Array<{ name: string; ui: React.ReactElement }> = [
      { name: 'PublicNavbar', ui: <PublicNavbar /> },
      { name: 'PublicFooter', ui: <PublicFooter /> },
      {
        name: 'PublicMobileMenu',
        ui: (
          <PublicMobileMenu
            isOpen
            onClose={vi.fn()}
            navLinks={[]}
            theme="light"
            onToggleTheme={vi.fn()}
            isAuthenticated={false}
            workspacePath="/"
          />
        ),
      },
      { name: 'LoginPage', ui: <LoginPage /> },
      { name: 'RegisterPage', ui: <RegisterPage /> },
      { name: 'Sidebar', ui: <Sidebar /> },
      { name: 'AdminLayout', ui: <AdminLayout /> },
    ];

    for (const { name, ui } of assertions) {
      useAuthStore.setState({
        user: {
          id: 'u-1',
          username: 'admin',
          full_name: 'Admin',
          role: name === 'AdminLayout' ? 'superadmin' : 'owner',
          permissions: ['*'],
          has_pin: false,
          is_active: true,
        },
        token: 'jwt',
        isAuthenticated: true,
        isPinLocked: false,
      });

      const { unmount } = render(
        <ThemeProvider>
          <DensityProvider>
            <SidebarProvider>
              <MemoryRouter>{ui}</MemoryRouter>
            </SidebarProvider>
          </DensityProvider>
        </ThemeProvider>
      );

      if (name === 'RegisterPage') {
        await waitFor(() => expect(plansSpy).toHaveBeenCalled());
      }

      const logos = screen.getAllByRole('img', { name: 'TocManager' });
      expect(logos.length, `${name} should render BrandLogo image`).toBeGreaterThanOrEqual(1);
      for (const logo of logos) {
        expect(logo).toHaveAttribute('src', '/assets/logo.png');
      }
      expect(screen.queryByText(/^TM$/)).not.toBeInTheDocument();

      unmount();
    }
  });
});
