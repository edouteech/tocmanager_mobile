import fs from 'node:fs';
import path from 'node:path';
import { createRef } from 'react';
import { fireEvent, render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { Lock, User } from 'lucide-react';
import { IconInput } from '../components/common/IconInput';
import { ThemeProvider } from '../context/ThemeContext';
import { useAuthStore } from '../stores/authStore';
import { LoginPage } from '../features/auth/LoginPage';
import { ContactPage } from '../features/landing/ContactPage';
import { RegisterStep1Form } from '../features/landing/RegisterStep1Form';
import { RegisterStep2Form } from '../features/landing/RegisterStep2Form';
import { StoreProfileForm } from '../features/settings/StoreProfileForm';
import type { StoreSettings } from '../types';

const extractLayerBlock = (css: string, layerHeader: string): string => {
  const startIdx = css.indexOf(layerHeader);
  if (startIdx === -1) return '';
  const openBrace = css.indexOf('{', startIdx);
  if (openBrace === -1) return '';
  let depth = 1;
  let i = openBrace + 1;
  while (i < css.length && depth > 0) {
    if (css[i] === '{') depth += 1;
    else if (css[i] === '}') depth -= 1;
    i += 1;
  }
  return css.slice(openBrace + 1, i - 1);
};

const ensureMatchMedia = () => {
  if (typeof window.matchMedia !== 'function') {
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
  }
};

const assertAlignedInput = (placeholder: string, expectRightSlot = false) => {
  const input = screen.getByPlaceholderText(placeholder);
  expect(input).toHaveClass('input-toc', 'pl-10');
  expect(input).not.toHaveClass('pl-9');
  if (expectRightSlot) {
    expect(input).toHaveClass('pr-20');
  } else {
    expect(input).not.toHaveClass('pr-20');
  }
  const iconWrapper = input.parentElement?.querySelector('span[aria-hidden="true"]');
  expect(iconWrapper).not.toBeNull();
  expect(iconWrapper).toHaveClass('pointer-events-none', 'inset-y-0', 'left-0', 'flex', 'items-center', 'pl-3.5');
};

describe('CSS cascade layer and IconInput alignment', () => {
  beforeEach(() => {
    localStorage.clear();
    ensureMatchMedia();
    useAuthStore.setState({ user: null, token: null, isAuthenticated: false, isPinLocked: false });
  });

  it('declares .input-toc and related component classes inside @layer components only', () => {
    const indexCss = fs.readFileSync(path.resolve(__dirname, '../index.css'), 'utf-8');
    const componentsLayer = extractLayerBlock(indexCss, '@layer components');
    expect(componentsLayer).not.toBe('');
    for (const selector of ['.toc-gradient', '.btn-primary', '.btn-secondary', '.card-toc', '.input-toc', '.badge-toc-primary']) {
      expect(componentsLayer).toContain(selector);
    }
    const outsideComponents = indexCss.replace(componentsLayer, '');
    expect(outsideComponents).not.toContain('.input-toc');
  });

  it('renders IconInput with centered icon, pointer-events-none, ref forwarding, and conditional right slot spacing', () => {
    const ref = createRef<HTMLInputElement>();
    const onChange = vi.fn();
    render(
      <>
        <IconInput
          ref={ref}
          icon={<User data-testid="left-user-icon" className="w-4 h-4" />}
          placeholder="Identifiant"
          onChange={onChange}
        />
        <IconInput
          icon={<Lock className="w-4 h-4" />}
          placeholder="Mot de passe"
          rightSlot={<button type="button">Afficher</button>}
        />
      </>
    );

    assertAlignedInput('Identifiant', false);
    assertAlignedInput('Mot de passe', true);

    const identifiant = screen.getByPlaceholderText('Identifiant') as HTMLInputElement;
    expect(ref.current).toBe(identifiant);
    fireEvent.change(identifiant, { target: { value: 'amadou' } });
    expect(onChange).toHaveBeenCalledTimes(1);

    const rightSlotBtn = screen.getByRole('button', { name: 'Afficher' });
    expect(rightSlotBtn.parentElement).toHaveClass('absolute', 'inset-y-0', 'right-0', 'flex', 'items-center', 'pr-3');
  });

  it('aligns all icons and password toggle in RegisterStep1Form', () => {
    render(
      <MemoryRouter>
        <RegisterStep1Form
          fullName=""
          setFullName={vi.fn()}
          identifier=""
          setIdentifier={vi.fn()}
          phone=""
          setPhone={vi.fn()}
          password="Secret123"
          setPassword={vi.fn()}
          acceptTerms={false}
          setAcceptTerms={vi.fn()}
          loading={false}
          onSubmit={vi.fn()}
        />
      </MemoryRouter>
    );

    assertAlignedInput('Ex: Amadou Diallo');
    assertAlignedInput('amadou@boutique.com');
    assertAlignedInput('+221 77 000 00 00');
    assertAlignedInput('Minimum 6 caractères', true);

    const pwdInput = screen.getByPlaceholderText('Minimum 6 caractères');
    expect(pwdInput).toHaveAttribute('type', 'password');
    fireEvent.click(screen.getByRole('button', { name: 'Afficher' }));
    expect(pwdInput).toHaveAttribute('type', 'text');
    expect(screen.getByRole('button', { name: 'Masquer' })).toBeInTheDocument();
  });

  it('aligns icon inputs across RegisterStep2Form, ContactPage, LoginPage, and StoreProfileForm', () => {
    const storeForm: StoreSettings = {
      store_name: 'Ma Boutique',
      currency: 'XOF',
      phone: '',
      email: '',
      address: '',
      rccm: '',
      nif: '',
      tax_rate: 0,
      low_stock_threshold: 5,
    };

    const { unmount } = render(
      <>
        <RegisterStep2Form
          boutiqueName=""
          setBoutiqueName={vi.fn()}
          companyName=""
          setCompanyName={vi.fn()}
          currency="XOF"
          setCurrency={vi.fn()}
          country="Sénégal"
          setCountry={vi.fn()}
          magasinName=""
          setMagasinName={vi.fn()}
          selectedPlan="pro"
          setSelectedPlan={vi.fn()}
          billingCycle="monthly"
          setBillingCycle={vi.fn()}
          plans={[]}
          plansLoading={false}
          loading={false}
          onBack={vi.fn()}
          onSubmit={vi.fn()}
        />
        <StoreProfileForm form={storeForm} onChange={vi.fn()} onSubmit={vi.fn()} isSubmitting={false} />
      </>
    );

    assertAlignedInput('Ex: Boutique Élégance Dakar');
    assertAlignedInput('Ex: Élégance SARL (optionnel)');
    assertAlignedInput('+228 90 00 00 00');
    assertAlignedInput('contact@boutique.com');
    assertAlignedInput('Rue, Quartier, Ville, Pays');
    unmount();

    const { unmount: unmountContact } = render(
      <ThemeProvider>
        <MemoryRouter>
          <ContactPage />
        </MemoryRouter>
      </ThemeProvider>
    );
    assertAlignedInput('Ex: Awa Diop');
    assertAlignedInput('awa@entreprise.com');
    assertAlignedInput('Ex: Diop Distribution');
    assertAlignedInput('+221 77 000 00 00');
    unmountContact();

    render(
      <ThemeProvider>
        <MemoryRouter>
          <LoginPage />
        </MemoryRouter>
      </ThemeProvider>
    );
    assertAlignedInput('Ex: admin ou caissier1');
    assertAlignedInput('********');
  });
});
