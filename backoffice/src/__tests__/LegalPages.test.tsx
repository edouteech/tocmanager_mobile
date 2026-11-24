import { render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { ThemeProvider } from '../context/ThemeContext';
import { TermsPage } from '../features/landing/TermsPage';
import { PrivacyPage } from '../features/landing/PrivacyPage';

describe('LegalPages', () => {
  beforeEach(() => {
    localStorage.clear();
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
  });

  it('renders complete TermsPage (/cgu) with navigation and sibling privacy link', () => {
    render(
      <ThemeProvider>
        <MemoryRouter initialEntries={['/cgu']}>
          <TermsPage />
        </MemoryRouter>
      </ThemeProvider>
    );

    expect(
      screen.getByRole('heading', { name: /Conditions Générales d'Utilisation \(CGU\)/i })
    ).toBeInTheDocument();
    expect(
      screen.getByRole('heading', { name: /4\. Offres, essai gratuit et facturation Mobile Money/i })
    ).toBeInTheDocument();
    expect(
      screen.getByRole('link', { name: /Consulter la Politique de Confidentialité/i })
    ).toHaveAttribute('href', '/confidentialite');
  });

  it('renders complete PrivacyPage (/confidentialite) with security details and sibling terms link', () => {
    render(
      <ThemeProvider>
        <MemoryRouter initialEntries={['/confidentialite']}>
          <PrivacyPage />
        </MemoryRouter>
      </ThemeProvider>
    );

    expect(
      screen.getByRole('heading', { name: /Politique de Confidentialité/i })
    ).toBeInTheDocument();
    expect(
      screen.getByRole('heading', { name: /4\. Isolation multi-tenant et sécurité technique/i })
    ).toBeInTheDocument();
    expect(
      screen.getByRole('link', { name: /Consulter les Conditions Générales d'Utilisation/i })
    ).toHaveAttribute('href', '/cgu');
  });
});
