import React from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { AlertTriangle, RefreshCw, Store, ChevronRight } from 'lucide-react';
import { categoriesApi, reportsApi, ventesApi } from '../../lib/api';
import { Category, DashboardStats, Vente } from '../../types';
import { useTheme } from '../../context/ThemeContext';
import { useAuthStore } from '../../stores/authStore';
import { useTenantContextKey } from '../../stores/tenantStore';
import { CashierDashboardView } from './CashierDashboardView';
import { WelcomeBanner } from './WelcomeBanner';
import { DashboardKpiCards } from './DashboardKpiCards';
import { DashboardActivitySection } from './DashboardActivitySection';

export const DashboardPage: React.FC = () => {
  const navigate = useNavigate();
  const { theme } = useTheme();
  const user = useAuthStore((s) => s.user);
  const [boutiqueKey, magasinKey] = useTenantContextKey();
  const isCashier = user?.role === 'cashier';

  const {
    data: stats,
    isLoading: statsLoading,
    refetch: refetchStats,
    isFetching: statsFetching,
  } = useQuery<DashboardStats>({
    queryKey: ['dashboard-stats', boutiqueKey, magasinKey],
    queryFn: () => reportsApi.getDashboard(),
    enabled: !isCashier,
    refetchInterval: isCashier ? false : 15000,
  });

  const { data: categories = [] } = useQuery<Category[]>({
    queryKey: ['categories', boutiqueKey, magasinKey],
    queryFn: () => categoriesApi.getAll(),
    enabled: !isCashier,
  });

  const { data: recentVentes, isLoading: ventesLoading } = useQuery<Vente[]>({
    queryKey: ['recent-ventes', boutiqueKey, magasinKey],
    queryFn: () => ventesApi.getAll({ limit: 7 }),
    enabled: !isCashier,
    refetchInterval: isCashier ? false : 15000,
  });

  if (isCashier) {
    return (
      <div className="space-y-6">
        <WelcomeBanner />
        <CashierDashboardView />
      </div>
    );
  }

  const hour = new Date().getHours();
  const greeting = hour < 12 ? 'Bonjour' : hour < 18 ? 'Bon après-midi' : 'Bonsoir';
  const rawDate = new Intl.DateTimeFormat('fr-FR', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  }).format(new Date());
  const dateStr = rawDate.charAt(0).toUpperCase() + rawDate.slice(1);
  const lowStockCount = stats?.low_stock_count || 0;

  return (
    <div className="space-y-6 max-w-7xl mx-auto select-none">
      <WelcomeBanner />

      <div className="relative overflow-hidden rounded-3xl bg-gradient-to-br from-[#1A8FBF] to-[#29ABE2] p-6 sm:p-8 text-white shadow-soft">
        <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-6">
          <div className="space-y-2">
            <h1 className="text-2xl sm:text-3xl font-extrabold tracking-tight text-white leading-tight">
              {greeting} !
            </h1>
            <p className="text-xs sm:text-sm text-white/80 font-medium">{dateStr}</p>
            <div className="pt-2">
              <span className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-white/20 text-xs font-semibold text-white">
                <span>{stats?.products_count ?? 0} produits</span>
                <span className="opacity-60">•</span>
                <span>{stats?.categories_count ?? categories.length} catégories</span>
              </span>
            </div>
          </div>

          <div className="flex items-center gap-4">
            <button
              onClick={() => refetchStats()}
              className="inline-flex items-center gap-2 px-4 py-2 bg-white/15 hover:bg-white/25 active:scale-95 text-white rounded-xl text-xs font-semibold border border-white/20 transition-all"
              title="Actualiser les données"
            >
              <RefreshCw className={`w-3.5 h-3.5 ${statsFetching ? 'animate-spin' : ''}`} />
              <span className="hidden sm:inline">Actualiser</span>
            </button>

            <div className="p-3.5 bg-white/20 rounded-2xl hidden sm:flex items-center justify-center border border-white/20">
              <Store className="w-8 h-8 text-white" />
            </div>
          </div>
        </div>
        <div className="absolute -right-8 -bottom-10 w-48 h-48 bg-white/10 rounded-full blur-2xl pointer-events-none" />
      </div>

      {lowStockCount > 0 && (
        <div
          onClick={() => navigate('/produits')}
          className="cursor-pointer p-4 rounded-2xl bg-[#FDEBE9] dark:bg-[#E74C3C]/15 border border-[#E74C3C]/30 flex items-center justify-between gap-4 transition-all hover:bg-[#fbdad7] dark:hover:bg-[#E74C3C]/20"
        >
          <div className="flex items-center gap-3.5">
            <div className="w-10 h-10 rounded-xl bg-[#E74C3C] text-white flex items-center justify-center shrink-0 shadow-sm">
              <AlertTriangle className="w-5 h-5" />
            </div>
            <div>
              <h4 className="text-sm font-bold text-[#1C2B3A] dark:text-white">
                {lowStockCount} article{lowStockCount > 1 ? 's' : ''} en rupture ou stock critique
              </h4>
              <p className="text-xs text-[#E74C3C] font-semibold mt-0.5">
                Cliquez pour voir les articles et planifier un approvisionnement
              </p>
            </div>
          </div>

          <div className="flex items-center gap-1 text-xs font-bold text-[#E74C3C] shrink-0">
            <span className="hidden sm:inline">Gérer le stock</span>
            <ChevronRight className="w-4 h-4" />
          </div>
        </div>
      )}

      <DashboardKpiCards
        stats={stats}
        statsLoading={statsLoading}
        categoriesCount={categories.length}
        lowStockCount={lowStockCount}
      />

      <DashboardActivitySection
        recentVentes={recentVentes}
        ventesLoading={ventesLoading}
        theme={theme}
      />
    </div>
  );
};
