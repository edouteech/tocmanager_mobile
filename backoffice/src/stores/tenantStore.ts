import { create } from 'zustand';
import { Boutique, Magasin, CurrentPlanStatus } from '../types';
import { tenantApi } from '../lib/api';

interface TenantState {
  boutiques: Boutique[];
  currentBoutique: Boutique | null;
  magasins: Magasin[];
  currentMagasin: Magasin | null; // null = Consolidated View ("Tous les magasins")
  isConsolidatedView: boolean;
  currentPlan: CurrentPlanStatus | null;
  isLoading: boolean;

  // Paywall & Upsell Modal
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
  fetchPlanStatus: () => Promise<void>;
  openUpgradeModal: (data?: { title?: string; message?: string; featureCode?: string; recommendedPlan?: string }) => void;
  closeUpgradeModal: () => void;
}

export const useTenantStore = create<TenantState>((set, get) => ({
  boutiques: [],
  currentBoutique: null,
  magasins: [],
  currentMagasin: null,
  isConsolidatedView: false,
  currentPlan: null,
  isLoading: false,

  upgradeModalOpen: false,
  upgradeModalData: null,

  openUpgradeModal: (data) => {
    set({
      upgradeModalOpen: true,
      upgradeModalData: data || {
        title: 'Fonctionnalité Premium',
        message: 'Cette fonctionnalité nécessite un forfait supérieur. Passez à la formule Pro pour débloquer tout le potentiel de votre commerce.',
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
    set({ currentBoutique: boutique, currentMagasin: null, isConsolidatedView: false });
    localStorage.setItem('toc_current_boutique_id', boutique.id);
    localStorage.removeItem('toc_current_magasin_id');
    await get().fetchMagasins();
    await get().fetchPlanStatus();
    window.location.reload();
  },

  fetchMagasins: async () => {
    try {
      const magasins = await tenantApi.getMagasins();
      set({ magasins });
      const savedMagId = localStorage.getItem('toc_current_magasin_id');
      if (savedMagId === 'consolidated') {
        set({ currentMagasin: null, isConsolidatedView: true });
      } else {
        const active = magasins.find((m) => m.id === savedMagId) || magasins[0] || null;
        set({ currentMagasin: active, isConsolidatedView: false });
        if (active) {
          localStorage.setItem('toc_current_magasin_id', active.id);
        }
      }
    } catch (e) {
      console.error('Error fetching magasins:', e);
    }
  },

  selectMagasin: (magasin: Magasin | null) => {
    if (magasin === null) {
      // Consolidated view
      set({ currentMagasin: null, isConsolidatedView: true });
      localStorage.setItem('toc_current_magasin_id', 'consolidated');
    } else {
      set({ currentMagasin: magasin, isConsolidatedView: false });
      localStorage.setItem('toc_current_magasin_id', magasin.id);
    }
  },

  fetchPlanStatus: async () => {
    try {
      const status = await tenantApi.getCurrentPlan();
      set({ currentPlan: status });
    } catch (e) {
      console.error('Error fetching plan status:', e);
    }
  },
}));
