import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { Menu, LogOut, User as UserIcon, Sun, Moon, Bell, Lock, Sparkles } from 'lucide-react';
import { useAuthStore } from '../../stores/authStore';
import { useTenantStore, useTenantContextKey } from '../../stores/tenantStore';
import { useTheme } from '../../context/ThemeContext';
import { useSidebar } from '../../context/SidebarContext';
import { reportsApi } from '../../lib/api';
import { DashboardStats } from '../../types';
import { CreateBoutiqueModal } from '../common/CreateBoutiqueModal';
import { TenantContextSelectors } from './TenantContextSelectors';

export const Header: React.FC = () => {
  const navigate = useNavigate();
  const { user, logout, lockSession } = useAuthStore();
  const { theme, toggleTheme } = useTheme();
  const { toggle: toggleSidebar } = useSidebar();
  const [boutiqueKey, magasinKey] = useTenantContextKey();
  const { currentPlan, openUpgradeModal } = useTenantStore();
  const [createBoutiqueOpen, setCreateBoutiqueOpen] = useState(false);

  const isOwner =
    user?.role === 'owner' ||
    user?.role === 'merchant' ||
    user?.role === 'store_admin' ||
    user?.role === 'admin';
  const canPollDashboardStats = Boolean(
    user && user.role !== 'cashier' && user.role !== 'superadmin'
  );

  const { data: stats } = useQuery<DashboardStats>({
    queryKey: ['dashboard-stats', boutiqueKey, magasinKey],
    queryFn: () => reportsApi.getDashboard(),
    enabled: canPollDashboardStats,
    refetchInterval: canPollDashboardStats ? 30000 : false,
  });

  const lowStockCount = stats?.low_stock_count || 0;

  return (
    <header className="h-16 bg-white dark:bg-dark-800 border-b border-[#E8EFF5] dark:border-dark-600 px-3 sm:px-6 lg:px-8 flex items-center justify-between sticky top-0 z-20 shadow-none transition-colors duration-200">
      <div className="flex items-center gap-2 sm:gap-3">
        <button
          onClick={toggleSidebar}
          className="lg:hidden p-2 text-[#5A7184] hover:text-[#29ABE2] hover:bg-[#F0F9FE] dark:hover:bg-dark-700 rounded-xl transition"
          aria-label="Ouvrir le menu de navigation"
        >
          <Menu className="w-5 h-5" />
        </button>

        <TenantContextSelectors
          isOwner={isOwner}
          onOpenCreateBoutique={() => setCreateBoutiqueOpen(true)}
        />
      </div>

      <div className="flex items-center gap-1.5 sm:gap-2.5">
        {currentPlan && (
          <button
            onClick={() => {
              if (isOwner) {
                navigate('/abonnement');
              } else {
                openUpgradeModal({
                  title: 'Passer au Forfait Supérieur',
                  message: `Vous êtes actuellement sur le ${currentPlan.plan_name}. Passez au forfait Pro ou Entreprise pour étendre vos capacités.`,
                });
              }
            }}
            className="hidden md:inline-flex items-center gap-1.5 px-2.5 py-1 rounded-xl text-xs font-semibold bg-[#E8F5FD] dark:bg-[#29ABE2]/15 border border-[#BAE3F9] dark:border-[#29ABE2]/30 text-[#1A8FBF] dark:text-[#29ABE2] hover:shadow-sm transition"
          >
            <Sparkles className="w-3.5 h-3.5 text-amber-500" />
            <span>{currentPlan.plan_name}</span>
            {currentPlan.trial_active && (
              <span className="text-[10px] text-amber-600 dark:text-amber-400 font-bold">
                ({currentPlan.trial_days_left}j)
              </span>
            )}
          </button>
        )}

        <button
          onClick={() => navigate('/produits')}
          className="relative p-2 text-[#5A7184] dark:text-slate-300 hover:text-[#29ABE2] hover:bg-[#F0F9FE] dark:hover:bg-dark-700 rounded-xl transition"
          title={
            lowStockCount > 0
              ? `${lowStockCount} produit(s) en alerte de stock`
              : 'Aucune alerte de rupture'
          }
        >
          <Bell className="w-4 h-4" />
          {lowStockCount > 0 && (
            <span className="absolute top-1 right-1 flex items-center justify-center min-w-[16px] h-4 px-1 text-[9px] font-bold text-white bg-[#E74C3C] rounded-full">
              {lowStockCount > 9 ? '9+' : lowStockCount}
            </span>
          )}
        </button>

        <button
          onClick={toggleTheme}
          className="p-2 text-[#5A7184] dark:text-slate-300 hover:text-[#29ABE2] bg-[#F0F9FE] dark:bg-dark-700 rounded-xl border border-[#E8EFF5] dark:border-dark-600 transition"
          aria-label="Changer de thème"
        >
          {theme === 'dark' ? (
            <Sun className="w-4 h-4 text-amber-400" />
          ) : (
            <Moon className="w-4 h-4 text-[#1C2B3A]" />
          )}
        </button>

        {user?.has_pin ? (
          <button
            onClick={lockSession}
            className="p-2 text-[#5A7184] dark:text-slate-300 hover:text-amber-500 bg-[#F0F9FE] dark:bg-dark-700 rounded-xl border border-[#E8EFF5] dark:border-dark-600 transition"
            title="Verrouiller la session"
          >
            <Lock className="w-4 h-4" />
          </button>
        ) : isOwner ? (
          <button
            type="button"
            onClick={() => navigate('/parametres')}
            className="hidden sm:inline-flex items-center gap-1 px-2.5 py-1.5 text-[11px] font-semibold text-[#5A7184] dark:text-slate-300 hover:text-[#29ABE2] bg-[#F0F9FE] dark:bg-dark-700 rounded-xl border border-[#E8EFF5] dark:border-dark-600 transition"
            title="Configurer un code PIN caisse"
          >
            <Lock className="w-3.5 h-3.5" />
            <span>PIN</span>
          </button>
        ) : null}

        <div className="flex items-center gap-2 pl-1.5 sm:pl-2.5 border-l border-[#E8EFF5] dark:border-dark-600">
          <div className="w-8 h-8 rounded-xl bg-[#E8F5FD] dark:bg-[#29ABE2]/15 flex items-center justify-center text-[#29ABE2] border border-[#BAE3F9] dark:border-[#29ABE2]/30 font-bold shrink-0">
            <UserIcon className="w-4 h-4" />
          </div>
          <div className="hidden md:block">
            <div className="text-xs font-bold text-[#1C2B3A] dark:text-white leading-tight truncate max-w-[120px]">
              {user?.full_name || user?.username}
            </div>
            <div className="text-[11px] text-[#29ABE2] font-semibold">{user?.role}</div>
          </div>
        </div>

        <button
          onClick={logout}
          className="inline-flex items-center gap-1 px-2 sm:px-2.5 py-1.5 text-xs font-semibold text-[#5A7184] dark:text-slate-400 hover:text-[#E74C3C] rounded-xl transition"
        >
          <LogOut className="w-4 h-4" />
        </button>
      </div>

      <CreateBoutiqueModal
        isOpen={createBoutiqueOpen}
        onClose={() => setCreateBoutiqueOpen(false)}
      />
    </header>
  );
};
