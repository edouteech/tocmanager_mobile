import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import {
  Menu,
  LogOut,
  User as UserIcon,
  Shield,
  Calendar,
  Sun,
  Moon,
  AlignJustify,
  Rows,
  Bell,
  Lock,
  Store,
  ChevronDown,
  Layers,
  Sparkles,
  Plus,
} from 'lucide-react';
import { useAuthStore } from '../../stores/authStore';
import { useTenantStore, useTenantContextKey } from '../../stores/tenantStore';
import { useTheme } from '../../context/ThemeContext';
import { useDensity } from '../../context/DensityContext';
import { useSidebar } from '../../context/SidebarContext';
import { api } from '../../lib/api';
import { DashboardStats } from '../../types';
import { CreateBoutiqueModal } from '../common/CreateBoutiqueModal';

export const Header: React.FC = () => {
  const navigate = useNavigate();
  const { user, logout, lockSession } = useAuthStore();
  const { theme, toggleTheme } = useTheme();
  const { density, toggleDensity } = useDensity();
  const { toggle: toggleSidebar } = useSidebar();
  const [boutiqueKey, magasinKey] = useTenantContextKey();

  const {
    boutiques,
    currentBoutique,
    selectBoutique,
    magasins,
    currentMagasin,
    selectMagasin,
    isConsolidatedView,
    currentPlan,
    openUpgradeModal,
  } = useTenantStore();

  const [boutiqueDropdownOpen, setBoutiqueDropdownOpen] = useState(false);
  const [magasinDropdownOpen, setMagasinDropdownOpen] = useState(false);
  const [createBoutiqueOpen, setCreateBoutiqueOpen] = useState(false);

  // Query stats for stock alert notifications
  const { data: stats } = useQuery<DashboardStats>({
    queryKey: ['header-stock-alerts', boutiqueKey, magasinKey],
    queryFn: async () => {
      const res = await api.get('/reports/dashboard');
      return res.data;
    },
    refetchInterval: 30000,
  });

  const lowStockCount = stats?.low_stock_count || 0;

  const isOwner =
    user?.role === 'owner' ||
    user?.role === 'merchant' ||
    user?.role === 'store_admin' ||
    user?.role === 'admin';

  return (
    <header className="h-16 bg-white dark:bg-dark-800 border-b border-[#E8EFF5] dark:border-dark-600 px-3 sm:px-6 lg:px-8 flex items-center justify-between sticky top-0 z-20 shadow-none transition-colors duration-200">
      {/* Left side: Hamburger button on mobile + Boutique & Magasin Selectors */}
      <div className="flex items-center gap-2 sm:gap-3">
        {/* Mobile Hamburger toggle */}
        <button
          onClick={toggleSidebar}
          className="lg:hidden p-2 text-[#5A7184] hover:text-[#29ABE2] hover:bg-[#F0F9FE] dark:hover:bg-dark-700 rounded-xl transition"
          aria-label="Ouvrir le menu de navigation"
        >
          <Menu className="w-5 h-5" />
        </button>

        {/* Sélecteur de Boutique */}
        <div className="relative">
          <button
            onClick={() => {
              setBoutiqueDropdownOpen(!boutiqueDropdownOpen);
              setMagasinDropdownOpen(false);
            }}
            className="flex items-center gap-2 px-3 py-1.5 rounded-xl text-xs font-bold text-slate-800 dark:text-white bg-[#F0F9FE] dark:bg-dark-700 hover:bg-[#E8F5FD] dark:hover:bg-dark-600 border border-[#E8EFF5] dark:border-dark-600 transition"
          >
            <Store className="w-3.5 h-3.5 text-indigo-600 dark:text-indigo-400" />
            <span className="truncate max-w-[120px] sm:max-w-[160px]">
              {currentBoutique?.name || 'Boutique Principale'}
            </span>
            <ChevronDown className="w-3 h-3 text-slate-400" />
          </button>

          {boutiqueDropdownOpen && (
            <div className="absolute top-full left-0 mt-1.5 w-60 bg-white dark:bg-slate-900 rounded-xl shadow-xl border border-slate-200 dark:border-slate-800 py-1.5 z-50 animate-fadeIn">
              <div className="px-3 py-1 text-[10px] font-bold text-slate-400 uppercase tracking-wider">
                Vos Boutiques
              </div>
              {boutiques.map((b) => (
                <button
                  key={b.id}
                  onClick={() => {
                    selectBoutique(b);
                    setBoutiqueDropdownOpen(false);
                  }}
                  className={`w-full text-left px-3 py-2 text-xs flex items-center justify-between hover:bg-slate-50 dark:hover:bg-slate-800 transition ${
                    b.id === currentBoutique?.id ? 'text-indigo-600 font-bold bg-indigo-50/50 dark:bg-indigo-950/40' : 'text-slate-700 dark:text-slate-200'
                  }`}
                >
                  <span className="truncate">{b.name}</span>
                  {b.id === currentBoutique?.id && <span className="text-[10px] text-indigo-600">Actif</span>}
                </button>
              ))}
              {isOwner && (
                <>
                  <div className="my-1 border-t border-slate-100 dark:border-slate-800" />
                  <button
                    type="button"
                    onClick={() => {
                      setBoutiqueDropdownOpen(false);
                      setCreateBoutiqueOpen(true);
                    }}
                    className="w-full text-left px-3 py-2 text-xs font-bold text-indigo-600 dark:text-indigo-400 flex items-center gap-1.5 hover:bg-indigo-50/70 dark:hover:bg-indigo-950/40 transition"
                  >
                    <Plus className="w-3.5 h-3.5" />
                    <span>Nouvelle Boutique</span>
                  </button>
                </>
              )}
            </div>
          )}
        </div>

        {/* Sélecteur de Magasin (Point de Vente) */}
        <div className="relative">
          <button
            onClick={() => {
              setMagasinDropdownOpen(!magasinDropdownOpen);
              setBoutiqueDropdownOpen(false);
            }}
            className={`flex items-center gap-2 px-3 py-1.5 rounded-xl text-xs font-bold transition border ${
              isConsolidatedView
                ? 'bg-amber-50 dark:bg-amber-950/40 text-amber-700 dark:text-amber-300 border-amber-200 dark:border-amber-800'
                : 'bg-white dark:bg-slate-800 text-slate-800 dark:text-slate-200 border-slate-200 dark:border-slate-700'
            }`}
          >
            <span className="truncate max-w-[110px] sm:max-w-[150px]">
              {isConsolidatedView ? 'Vue Consolidée' : currentMagasin?.name || 'Magasin'}
            </span>
            <ChevronDown className="w-3 h-3 text-slate-400" />
          </button>

          {magasinDropdownOpen && (
            <div className="absolute top-full left-0 mt-1.5 w-64 bg-white dark:bg-slate-900 rounded-xl shadow-xl border border-slate-200 dark:border-slate-800 py-1.5 z-50 animate-fadeIn">
              {isOwner && (
                <>
                  <div className="px-3 py-1 text-[10px] font-bold text-slate-400 uppercase tracking-wider">
                    Pilotage Global
                  </div>
                  <button
                    onClick={() => {
                      selectMagasin(null);
                      setMagasinDropdownOpen(false);
                    }}
                    className={`w-full text-left px-3 py-2 text-xs flex items-center justify-between hover:bg-slate-50 dark:hover:bg-slate-800 transition ${
                      isConsolidatedView ? 'text-amber-600 font-bold bg-amber-50/50 dark:bg-amber-950/40' : 'text-slate-700 dark:text-slate-200'
                    }`}
                  >
                    <span>Tous les Magasins (Vue Consolidée)</span>
                    {isConsolidatedView && <span className="text-[10px] text-amber-600">Actif</span>}
                  </button>
                  <div className="my-1 border-t border-slate-100 dark:border-slate-800" />
                </>
              )}

              <div className="px-3 py-1 text-[10px] font-bold text-slate-400 uppercase tracking-wider">
                Points de Vente
              </div>
              {magasins.map((m) => (
                <button
                  key={m.id}
                  onClick={() => {
                    selectMagasin(m);
                    setMagasinDropdownOpen(false);
                  }}
                  className={`w-full text-left px-3 py-2 text-xs flex items-center justify-between hover:bg-slate-50 dark:hover:bg-slate-800 transition ${
                    !isConsolidatedView && m.id === currentMagasin?.id
                      ? 'text-indigo-600 font-bold bg-indigo-50/50 dark:bg-indigo-950/40'
                      : 'text-slate-700 dark:text-slate-200'
                  }`}
                >
                  <span className="truncate">{m.name}</span>
                  {m.is_warehouse && <span className="text-[9px] text-slate-400">(Dépôt)</span>}
                  {!isConsolidatedView && m.id === currentMagasin?.id && (
                    <span className="text-[10px] text-indigo-600">●</span>
                  )}
                </button>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Right controls */}
      <div className="flex items-center gap-1.5 sm:gap-2.5">
        {/* Badge Plan & Upgrade CTA */}
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
            className="hidden md:inline-flex items-center gap-1.5 px-2.5 py-1 rounded-xl text-xs font-semibold bg-gradient-to-r from-indigo-50 to-purple-50 dark:from-indigo-950/40 dark:to-purple-950/40 border border-indigo-200 dark:border-indigo-800/60 text-indigo-700 dark:text-indigo-300 hover:shadow-sm transition"
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

        {/* Stock Alert Notification Bell */}
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

        {/* Theme Toggle */}
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

        {/* Lock Screen */}
        <button
          onClick={lockSession}
          className="p-2 text-[#5A7184] dark:text-slate-300 hover:text-amber-500 bg-[#F0F9FE] dark:bg-dark-700 rounded-xl border border-[#E8EFF5] dark:border-dark-600 transition"
          title="Verrouiller la session"
        >
          <Lock className="w-4 h-4" />
        </button>

        {/* User profile */}
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

        {/* Logout */}
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
