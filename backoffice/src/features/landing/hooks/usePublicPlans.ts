import { useQuery } from '@tanstack/react-query';
import { saasApi } from '../../../lib/api';
import type { SaasPlan } from '../../../types';
import { FALLBACK_PLANS } from '../data/fallbackPlans';

export function usePublicPlans() {
  const { data, isLoading, isError } = useQuery<SaasPlan[]>({
    queryKey: ['public-saas-plans'],
    queryFn: () => saasApi.getPlans(),
    staleTime: 5 * 60 * 1000,
    retry: false,
  });

  const hasLivePlans = Boolean(data && data.length > 0);
  const plans = hasLivePlans ? (data as SaasPlan[]) : FALLBACK_PLANS;
  const isFallback = !isLoading && (isError || !hasLivePlans);

  return {
    plans,
    isLoading,
    isFallback,
  };
}
