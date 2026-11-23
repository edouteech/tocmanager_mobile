import { create } from 'zustand';
import { Boutique, Magasin, CurrentPlanStatus } from '../types';
import { tenantApi } from '../lib/api';

const notifyContextChanged = () => {
  window.dispatchEvent(new CustomEvent('toc:tenant-context-changed'));
};

const getCanConsolidate = (boutique: Boutique | null): boolean => {
  const rawUser = localStorage.getItem('toc_user');
  if (!rawUser) return false;
  try {
    const u = JSON.parse(rawUser);
    const role = boutique?.user_role || u?.role || '';
    if (['owner', 'merchant', 'store_admin', 'admin'].includes(role)) return true;
    const assigned = u?.assigned_magasin_ids || [];
    return role === 'manager' && assigned.length === 0;
  } catch {
    return false;
  }
};

interface TenantState {
  boutiques: Boutique[];
  currentBoutique: Boutique | null;
  magasins: Magasin[];
  currentMagasin: Magasin | null;
  isConsolidatedView: boolean;
  showMagasinPrompt: boolean;
  currentPlan: CurrentPlanStatus | null;
  isLoading: boolean;

  upgradeModalOpen: boolean;
  upgradeModalData: {
    title?: string;
    message?: string;
    featureCode?: string;
    recommendedPlan?: string;
  } | null;

  initTenant: () => Promise<void>;
  fetchBoutiques: () => Promise<void>;
  selectBoutique: (boutique: Boutique) => Promise<void>;
  fetchMagasins: () => Promise<void>;
  selectMagasin: (magasin: Magasin | null) => void;
  dismissMagasinPrompt: () => void;
  fetchPlanStatus: () => Promise<void>;
  resetTenant: () => void;
  openUpgradeModal: (data?: {
    title?: string;
    message?: string;
    featureCode?: string;
    recommendedPlan?: string;
  }) => void;
  closeUpgradeModal: () => void;
}

export const useTenantStore = create<TenantState>((set, get) => ({
  boutiques: [],
  currentBoutique: null,
  magasins: [],
  currentMagasin: null,
  isConsolidatedView: false,
  showMagasinPrompt: false,
  currentPlan: null,
  isLoading: false,

  upgradeModalOpen: false,
  upgradeModalData: null,

  openUpgradeModal: (data) => {
    set({
      upgradeModalOpen: true,
      upgradeModalData: data || {
        title: 'Fonctionnalite Premium',
        message:
          'Cette fonctionnalite necessite un forfait superieur. Passez au forfait Pro pour debloquer tout le potentiel de votre commerce.',
        recommendedPlan: 'pro',
      },
    });
  },

  closeUpgradeModal: () => {
    set({ upgradeModalOpen: false, upgradeModalData: null });
  },

  initTenant: async () => {
    set({ isLoading: true });
    try {
      await get().fetchBoutiques();
      await get().fetchMagasins();
      await get().fetchPlanStatus();
    } catch (e) {
      console.error('Error initializing tenant:', e);
    } finally {
      set({ isLoading: false });
    }
  },

  fetchBoutiques: async () => {
    try {
      const boutiques = await tenantApi.getBoutiques();
      set({ boutiques });
      const savedBtqId = localStorage.getItem('toc_current_boutique_id');
      const active = boutiques.find((b) => b.id === savedBtqId) || boutiques[0] || null;
      if (active) {
        set({ currentBoutique: active });
        localStorage.setItem('toc_current_boutique_id', active.id);
      }
    } catch (e) {
      console.error('Error fetching boutiques:', e);
    }
  },

  selectBoutique: async (boutique: Boutique) => {
    set({
      currentBoutique: boutique,
      currentMagasin: null,
      isConsolidatedView: false,
      showMagasinPrompt: false,
    });
    localStorage.setItem('toc_current_boutique_id', boutique.id);
    localStorage.removeItem('toc_current_magasin_id');
    sessionStorage.removeItem('toc_magasin_prompt_dismissed');
    await get().fetchMagasins();
    await get().fetchPlanStatus();
    notifyContextChanged();
  },

  fetchMagasins: async () => {
    try {
      const magasins = await tenantApi.getMagasins();
      set({ magasins });
      const canConsolidate = getCanConsolidate(get().currentBoutique);
      const savedMagId = localStorage.getItem('toc_current_magasin_id');

      if (savedMagId === 'consolidated' && canConsolidate) {
        set({ currentMagasin: null, isConsolidatedView: true, showMagasinPrompt: false });
        return;
      }

      const matched = magasins.find((m) => m.id === savedMagId);
      if (matched) {
        set({ currentMagasin: matched, isConsolidatedView: false, showMagasinPrompt: false });
        return;
      }

      const promptDismissed = sessionStorage.getItem('toc_magasin_prompt_dismissed') === '1';
      if (magasins.length > 1 && canConsolidate) {
        set({
          currentMagasin: null,
          isConsolidatedView: true,
          showMagasinPrompt: !promptDismissed,
        });
        localStorage.setItem('toc_current_magasin_id', 'consolidated');
        return;
      }

      const first = magasins[0] || null;
      set({ currentMagasin: first, isConsolidatedView: false, showMagasinPrompt: false });
      if (first) {
        localStorage.setItem('toc_current_magasin_id', first.id);
      } else {
        localStorage.removeItem('toc_current_magasin_id');
      }
    } catch (e) {
      console.error('Error fetching magasins:', e);
    }
  },

  selectMagasin: (magasin: Magasin | null) => {
    sessionStorage.setItem('toc_magasin_prompt_dismissed', '1');
    if (magasin === null) {
      if (!getCanConsolidate(get().currentBoutique)) return;
      set({ currentMagasin: null, isConsolidatedView: true, showMagasinPrompt: false });
      localStorage.setItem('toc_current_magasin_id', 'consolidated');
    } else {
      set({ currentMagasin: magasin, isConsolidatedView: false, showMagasinPrompt: false });
      localStorage.setItem('toc_current_magasin_id', magasin.id);
    }
    notifyContextChanged();
  },

  dismissMagasinPrompt: () => {
    sessionStorage.setItem('toc_magasin_prompt_dismissed', '1');
    set({ showMagasinPrompt: false });
  },

  fetchPlanStatus: async () => {
    try {
      const status = await tenantApi.getCurrentPlan();
      set({ currentPlan: status });
    } catch (e) {
      console.error('Error fetching plan status:', e);
    }
  },

  resetTenant: () => {
    set({
      boutiques: [],
      currentBoutique: null,
      magasins: [],
      currentMagasin: null,
      isConsolidatedView: false,
      showMagasinPrompt: false,
      currentPlan: null,
      isLoading: false,
      upgradeModalOpen: false,
      upgradeModalData: null,
    });
  },
}));

export const useTenantContextKey = (): [string, string] => {
  const boutiqueId = useTenantStore((s) => s.currentBoutique?.id || 'default');
  const magasinId = useTenantStore((s) => s.currentMagasin?.id);
  const isConsolidated = useTenantStore((s) => s.isConsolidatedView);
  return [boutiqueId, isConsolidated ? 'consolidated' : magasinId || 'none'];
};
