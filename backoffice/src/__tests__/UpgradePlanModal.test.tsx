import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { UpgradePlanModal } from '../components/common/UpgradePlanModal';
import { saasApi, tenantApi } from '../lib/api';
import { useAuthStore } from '../stores/authStore';
import { useTenantStore } from '../stores/tenantStore';
import { CurrentPlanStatus, SaasPlan } from '../types';

vi.mock('../features/subscription/FeexPayCheckoutWidget', () => ({
  FeexPayCheckoutWidget: ({ plan }: { plan: SaasPlan }) => (
    <div data-testid="feexpay-checkout">Checkout {plan.code}</div>
  ),
}));

const PRO_PLAN: SaasPlan = {
  id: 'plan-pro',
  code: 'pro',
  name: 'Pro',
  price_monthly: 15000,
  price_yearly: 150000,
  currency: 'XOF',
  trial_period_days: 14,
  is_active: true,
  features: [
    {
      id: 'feat-1',
      feature_code: 'module_credit_sales',
      feature_name: 'Ventes a credit',
      value_type: 'boolean',
      boolean_value: true,
      int_limit: 0,
      show_on_pricing: true,
    },
    {
      id: 'feat-2',
      feature_code: 'max_magasins',
      feature_name: 'Magasins',
      value_type: 'limit_number',
      boolean_value: false,
      int_limit: 5,
      show_on_pricing: true,
    },
  ],
};

const makePlanStatus = (hasUsedTrial: boolean): CurrentPlanStatus => ({
  plan_id: 'plan-free',
  plan_code: 'free',
  plan_name: 'Starter',
  status: 'active',
  trial_active: false,
  trial_days_left: 0,
  billing_cycle: 'monthly',
  current_period_end: null,
  has_used_trial: hasUsedTrial,
  features: {},
  can_access_stock_transfers: false,
  can_access_pnl_reports: false,
  can_access_data_exports: false,
  magasins_used: 1,
  magasins_limit: 1,
});

const renderModal = () => {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  return render(
    <QueryClientProvider client={client}>
      <MemoryRouter>
        <UpgradePlanModal />
      </MemoryRouter>
    </QueryClientProvider>
  );
};

describe('UpgradePlanModal', () => {
  beforeEach(() => {
    vi.spyOn(saasApi, 'getPlans').mockResolvedValue([PRO_PLAN]);
    useTenantStore.getState().resetTenant();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('renders nothing when closed', () => {
    const { container } = renderModal();
    expect(container.firstChild).toBeNull();
  });

  it('shows free trial activation button for owner who has not used trial and triggers upgrade', async () => {
    useAuthStore.setState({
      user: {
        id: 'u1',
        username: 'owner',
        full_name: 'Owner',
        role: 'owner',
        permissions: [],
        has_pin: false,
        is_active: true,
      },
      token: 'tok',
      isAuthenticated: true,
    });
    const upgradeSpy = vi
      .spyOn(tenantApi, 'upgradePlan')
      .mockResolvedValue({ message: 'Essai Pro active.' });
    useTenantStore.setState({
      currentPlan: makePlanStatus(false),
      upgradeModalOpen: true,
      upgradeModalData: { title: 'Module verrouille', recommendedPlan: 'pro' },
      fetchPlanStatus: vi.fn().mockResolvedValue(undefined),
    });

    renderModal();
    const trialBtn = await screen.findByRole('button', { name: /Activer l essai gratuit \(14j\)/i });
    expect(screen.getByText(/Ventes a credit/i)).toBeInTheDocument();
    expect(screen.getByText(/Magasins \(5\)/i)).toBeInTheDocument();

    fireEvent.click(trialBtn);
    await waitFor(() => {
      expect(upgradeSpy).toHaveBeenCalledWith('pro');
    });
  });

  it('hides upgrade controls and warns non-owner staff', async () => {
    useAuthStore.setState({
      user: {
        id: 'u2',
        username: 'cashier',
        full_name: 'Cashier',
        role: 'cashier',
        permissions: [],
        has_pin: false,
        is_active: true,
      },
      token: 'tok',
      isAuthenticated: true,
    });
    useTenantStore.setState({
      currentPlan: makePlanStatus(false),
      upgradeModalOpen: true,
      upgradeModalData: { recommendedPlan: 'pro' },
    });

    renderModal();
    expect(
      await screen.findByText(/Seul le proprietaire de la boutique peut modifier l abonnement/i)
    ).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: /Activer l essai/i })).not.toBeInTheDocument();
  });

  it('shows FeexPay checkout widget when trial was already used', async () => {
    useAuthStore.setState({
      user: {
        id: 'u1',
        username: 'owner',
        full_name: 'Owner',
        role: 'owner',
        permissions: [],
        has_pin: false,
        is_active: true,
      },
      token: 'tok',
      isAuthenticated: true,
    });
    useTenantStore.setState({
      currentPlan: makePlanStatus(true),
      upgradeModalOpen: true,
      upgradeModalData: { recommendedPlan: 'pro' },
    });

    renderModal();
    expect(await screen.findByTestId('feexpay-checkout')).toHaveTextContent('Checkout pro');
  });
});
