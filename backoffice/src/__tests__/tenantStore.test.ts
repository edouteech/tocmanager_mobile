import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { tenantApi } from '../lib/api';
import { useTenantStore } from '../stores/tenantStore';
import { Boutique, Magasin } from '../types';

const MAGASINS: Magasin[] = [
  { id: 'mag-1', boutique_id: 'btq-1', name: 'Magasin Centre', is_warehouse: false, is_active: true },
  { id: 'mag-2', boutique_id: 'btq-1', name: 'Annexe Nord', is_warehouse: false, is_active: true },
];

const BOUTIQUE_1: Boutique = {
  id: 'btq-1',
  slug: 'boutique-alpha',
  name: 'Boutique Alpha',
  currency: 'XOF',
  country: 'Sénégal',
  owner_user_id: 'u1',
  is_active: true,
  magasins: MAGASINS,
  assigned_magasin_ids: [],
};

const BOUTIQUE_2: Boutique = {
  id: 'btq-2',
  slug: 'boutique-beta',
  name: 'Boutique Beta',
  currency: 'XOF',
  country: 'Sénégal',
  owner_user_id: 'u1',
  is_active: true,
  magasins: [MAGASINS[0]],
  assigned_magasin_ids: [],
};

describe('tenantStore', () => {
  beforeEach(() => {
    localStorage.clear();
    sessionStorage.clear();
    useTenantStore.getState().resetTenant();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it('defaults owners with multiple magasins into consolidated view', async () => {
    localStorage.setItem('toc_user', JSON.stringify({ id: 'u1', role: 'owner' }));
    useTenantStore.setState({ currentBoutique: BOUTIQUE_1 });
    vi.spyOn(tenantApi, 'getMagasins').mockResolvedValue(MAGASINS);

    await useTenantStore.getState().fetchMagasins();

    const state = useTenantStore.getState();
    expect(state.isConsolidatedView).toBe(true);
    expect(state.currentMagasin).toBeNull();
    expect(state.showMagasinPrompt).toBe(true);
    expect(localStorage.getItem('toc_current_magasin_id')).toBe('consolidated');
  });

  it('prevents consolidated view for cashiers and selects first magasin', async () => {
    localStorage.setItem('toc_user', JSON.stringify({ id: 'u2', role: 'cashier' }));
    useTenantStore.setState({ currentBoutique: BOUTIQUE_1 });
    vi.spyOn(tenantApi, 'getMagasins').mockResolvedValue(MAGASINS);

    await useTenantStore.getState().fetchMagasins();

    const state = useTenantStore.getState();
    expect(state.isConsolidatedView).toBe(false);
    expect(state.currentMagasin?.id).toBe('mag-1');

    useTenantStore.getState().selectMagasin(null);
    expect(useTenantStore.getState().isConsolidatedView).toBe(false);
    expect(useTenantStore.getState().currentMagasin?.id).toBe('mag-1');
  });

  it('switches boutique, clears magasin cache and dispatches tenant context event', async () => {
    localStorage.setItem('toc_user', JSON.stringify({ id: 'u1', role: 'owner' }));
    localStorage.setItem('toc_current_magasin_id', 'mag-1');
    const eventListener = vi.fn();
    window.addEventListener('toc:tenant-context-changed', eventListener);

    vi.spyOn(tenantApi, 'getMagasins').mockResolvedValue([MAGASINS[0]]);
    vi.spyOn(tenantApi, 'getCurrentPlan').mockResolvedValue({
      plan_id: 'plan-pro',
      plan_code: 'pro',
      plan_name: 'Pro',
      status: 'active',
      trial_active: false,
      trial_days_left: 0,
      billing_cycle: 'monthly',
      current_period_end: null,
      has_used_trial: false,
      features: {},
      can_access_stock_transfers: true,
      can_access_pnl_reports: true,
      can_access_data_exports: true,
      magasins_used: 1,
      magasins_limit: 5,
    });

    await useTenantStore.getState().selectBoutique(BOUTIQUE_2);

    const state = useTenantStore.getState();
    expect(state.currentBoutique?.id).toBe('btq-2');
    expect(state.currentMagasin?.id).toBe('mag-1');
    expect(localStorage.getItem('toc_current_boutique_id')).toBe('btq-2');
    expect(eventListener).toHaveBeenCalledTimes(1);

    window.removeEventListener('toc:tenant-context-changed', eventListener);
  });

  it('resets tenant and upgrade modal state completely on resetTenant', () => {
    useTenantStore.setState({
      boutiques: [BOUTIQUE_1],
      currentBoutique: BOUTIQUE_1,
      magasins: MAGASINS,
      currentMagasin: MAGASINS[0],
      isConsolidatedView: true,
      upgradeModalOpen: true,
    });

    useTenantStore.getState().resetTenant();

    const state = useTenantStore.getState();
    expect(state.boutiques).toEqual([]);
    expect(state.currentBoutique).toBeNull();
    expect(state.magasins).toEqual([]);
    expect(state.currentMagasin).toBeNull();
    expect(state.isConsolidatedView).toBe(false);
    expect(state.upgradeModalOpen).toBe(false);
  });
});
