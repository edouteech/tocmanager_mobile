import { useTenantStore } from '../stores/tenantStore';

export interface QuotaStatus {
  used: number;
  limit: number;
  isUnlimited: boolean;
  reached: boolean;
}

export function useEntitlement() {
  const { currentPlan, openUpgradeModal } = useTenantStore();

  const hasFeature = (featureCode: string): boolean => {
    if (!currentPlan) return false;
    return Boolean(currentPlan.features?.[featureCode]);
  };

  const getQuota = (quotaCode: string): QuotaStatus => {
    const rawLimit = currentPlan?.features?.[quotaCode];
    const limit = typeof rawLimit === 'number' ? rawLimit : 0;
    const usageMap: Record<string, number> = {
      max_boutiques: currentPlan?.boutiques_used ?? 1,
      max_magasins: currentPlan?.magasins_used ?? 1,
      max_products: currentPlan?.products_used ?? 0,
      max_users: currentPlan?.users_used ?? 1,
      max_clients: currentPlan?.clients_used ?? 0,
      max_suppliers: currentPlan?.suppliers_used ?? 0,
    };
    const used = usageMap[quotaCode] ?? 0;
    const isUnlimited = limit === -1;
    const reached = !isUnlimited && used >= limit;
    return { used, limit, isUnlimited, reached };
  };

  const recommendedUpgradePlan = (): string => {
    return currentPlan?.plan_code === 'pro' ? 'enterprise' : 'pro';
  };

  const openUpgradeForFeature = (
    featureCode: string,
    title?: string,
    message?: string,
  ) => {
    openUpgradeModal({
      featureCode,
      title: title || 'Fonctionnalite reservee aux forfaits superieurs',
      message:
        message ||
        'Cette option n est pas incluse dans votre forfait actuel. Passez au forfait superieur pour la debloquer.',
      recommendedPlan: recommendedUpgradePlan(),
    });
  };

  return {
    currentPlan,
    hasFeature,
    getQuota,
    recommendedUpgradePlan,
    openUpgradeForFeature,
  };
}
