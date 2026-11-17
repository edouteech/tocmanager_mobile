import React from 'react';
import { NavLink, Link } from 'react-router-dom';
import {
  Home,
  Package,
  LayoutGrid,
  Users,
  Building2,
  ArrowDownToLine,
  ShoppingCart,
  Wallet,
  BarChart3,
  Settings,
  UserCheck,
  ShieldCheck,
  Store,
  Sparkles,
  ExternalLink,
  ShieldAlert,
} from 'lucide-react';
import { useAuthStore } from '../../stores/authStore';
import { useTenantStore } from '../../stores/tenantStore';
import { useSidebar } from '../../context/SidebarContext';

interface NavItem {
  to: string;
  label: string;
  icon: React.ComponentType<{ className?: string }>;
  roles?: string[];
}

export const Sidebar: React.FC = () => {
  const user = useAuthStore((s) => s.user);
  const { currentPlan, openUpgradeModal } = useTenantStore();
  const { close } = useSidebar();

  // Group 1: Navigation principale
  const mainNavItems: NavItem[] = [
    { to: '/', label: 'Accueil', icon: Home },
    { to: '/produits', label: 'Produits & Stocks', icon: Package },
    { to: '/categories', label: 'Catégories', icon: LayoutGrid },
    { to: '/clients', label: 'Clients & Créances', icon: Users },
    { to: '/fournisseurs', label: 'Fournisseurs', icon: Building2, roles: ['superadmin', 'admin', 'merchant', 'manager'] },
  ];

  // Group 2: Opérations & Flux
  const operationNavItems: NavItem[] = [
    { to: '/approvisionnements', label: 'Approvisionnements', icon: ArrowDownToLine, roles: ['superadmin', 'admin', 'merchant', 'manager'] },
    { to: '/ventes', label: 'Ventes & Caisse', icon: ShoppingCart },
    { to: '/depenses', label: 'Décaissements', icon: Wallet },
    { to: '/rapports', label: 'Rapports & Analytique', icon: BarChart3, roles: ['superadmin', 'admin', 'merchant', 'manager'] },
  ];

  // Group 3: Paramètres & Administration
  const adminNavItems: NavItem[] = [
    { to: '/magasins', label: 'Magasins & Points de Vente', icon: Store, roles: ['superadmin', 'admin', 'merchant', 'manager'] },
    { to: '/parametres', label: 'Paramètres Boutique', icon: Settings, roles: ['superadmin', 'admin', 'merchant'] },
    { to: '/utilisateurs', label: 'Utilisateurs & Rôles', icon: UserCheck, roles: ['superadmin', 'admin', 'merchant'] },
    { to: '/audit', label: "Journal d'Audit", icon: ShieldCheck, roles: ['superadmin', 'admin', 'merchant'] },
  ];

  const handleNavClick = () => {
    if (window.innerWidth < 1024) {
      close();
    }
  };

  const renderNavList = (items: NavItem[]) => {
    return items
      .filter((item) => {
        if (!item.roles) return true;
        if (!user) return false;
        if (user.role === 'superadmin' || user.role === 'admin' || user.role === 'merchant') return true;
        return item.roles.includes(user.role);
      })
      .map((item) => {
        const Icon = item.icon;
        return (
          <NavLink
            key={item.to}
            to={item.to}
            end={item.to === '/'}
            onClick={handleNavClick}
            className={({ isActive }) =>
              `flex items-center gap-3.5 px-3.5 py-2.5 rounded-xl text-[13px] font-medium transition-all duration-150 ${
                isActive
                  ? 'bg-[#E8F5FD] dark:bg-[#29ABE2]/15 text-[#29ABE2] font-semibold shadow-none'
                  : 'text-[#5A7184] dark:text-slate-400 hover:bg-[#F0F9FE] dark:hover:bg-dark-700/60 hover:text-[#1C2B3A] dark:hover:text-white'
              }`
            }
          >
            <Icon className="w-4 h-4 shrink-0" />
            <span className="truncate">{item.label}</span>
          </NavLink>
        );
      });
  };

  return (
    <div className="flex flex-col h-full bg-white dark:bg-dark-800 border-r border-[#E8EFF5] dark:border-dark-600 transition-colors duration-200">
      {/* Brand logo header */}
      <div className="h-16 px-5 border-b border-[#E8EFF5] dark:border-dark-600 flex items-center justify-between shrink-0">
        <Link to="/" className="flex items-center gap-2.5">
          <div className="w-8 h-8 rounded-xl bg-gradient-to-tr from-indigo-600 to-indigo-800 flex items-center justify-center text-white shadow-sm font-black text-sm">
            TM
          </div>
          <span className="font-bold text-[#1C2B3A] dark:text-white text-base tracking-tight">
            Toc<span className="text-indigo-600">Manager</span>
          </span>
        </Link>
      </div>

      {/* Navigation scrollable container */}
      <div className="flex-1 overflow-y-auto px-3.5 py-4 space-y-6">
        <div>
          <div className="px-3.5 mb-2 text-[10px] font-bold tracking-wider text-[#9BB2C4] dark:text-slate-500 uppercase">
            Général
          </div>
          <nav className="space-y-0.5">{renderNavList(mainNavItems)}</nav>
        </div>

        <div>
          <div className="px-3.5 mb-2 text-[10px] font-bold tracking-wider text-[#9BB2C4] dark:text-slate-500 uppercase">
            Flux & Caisse
          </div>
          <nav className="space-y-0.5">{renderNavList(operationNavItems)}</nav>
        </div>

        <div>
          <div className="px-3.5 mb-2 text-[10px] font-bold tracking-wider text-[#9BB2C4] dark:text-slate-500 uppercase">
            Configuration
          </div>
          <nav className="space-y-0.5">{renderNavList(adminNavItems)}</nav>
        </div>
      </div>

      {/* Plan Card & Superadmin Link at bottom */}
      <div className="p-3 border-t border-[#E8EFF5] dark:border-dark-600 space-y-2">
        {user?.role === 'superadmin' && (
          <Link
            to="/admin"
            className="flex items-center justify-between px-3 py-2 rounded-xl text-xs font-bold bg-amber-50 dark:bg-amber-950/40 text-amber-800 dark:text-amber-300 border border-amber-200 dark:border-amber-800 transition"
          >
            <div className="flex items-center gap-2">
              <ShieldAlert className="w-3.5 h-3.5 text-amber-600" />
              <span>Console Super-Admin</span>
            </div>
            <ExternalLink className="w-3 h-3" />
          </Link>
        )}

        {currentPlan && (
          <div className="p-3 rounded-xl bg-slate-50 dark:bg-slate-900 border border-slate-200 dark:border-slate-800 text-xs space-y-2">
            <div className="flex items-center justify-between">
              <span className="font-bold text-slate-800 dark:text-slate-200 flex items-center gap-1">
                <Sparkles className="w-3 h-3 text-amber-500" />
                {currentPlan.plan_name}
              </span>
              {currentPlan.trial_active && (
                <span className="text-[10px] text-amber-600 font-bold bg-amber-100 dark:bg-amber-950 px-1.5 py-0.2 rounded">
                  Essai {currentPlan.trial_days_left}j
                </span>
              )}
            </div>
            <p className="text-[10px] text-slate-500 leading-tight">
              {currentPlan.magasins_limit === -1
                ? 'Magasins illimités'
                : `${currentPlan.magasins_used} / ${currentPlan.magasins_limit} magasins utilisés`}
            </p>
            <button
              onClick={() =>
                openUpgradeModal({
                  title: 'Mettre à niveau votre Formule',
                  message: 'Débloquez plus de magasins, les transferts de stock et les exports comptables en passant au forfait Pro.',
                })
              }
              className="w-full py-1 text-[11px] font-bold text-indigo-600 dark:text-indigo-400 bg-indigo-50 dark:bg-indigo-950/60 hover:bg-indigo-100 dark:hover:bg-indigo-900/60 rounded-lg transition"
            >
              Changer de forfait
            </button>
          </div>
        )}
      </div>
    </div>
  );
};
