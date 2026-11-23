import React, { useEffect } from 'react';
import { NavLink, Link, useNavigate } from 'react-router-dom';
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
  CreditCard,
  ArrowRightLeft,
  Calculator,
} from 'lucide-react';
import { useAuthStore } from '../../stores/authStore';
import { useTenantStore } from '../../stores/tenantStore';
import { useSidebar } from '../../context/SidebarContext';
import { useEntitlement } from '../../hooks/useEntitlement';

interface NavItem {
  to: string;
  label: string;
  icon: React.ComponentType<{ className?: string }>;
  roles?: string[];
  featureCode?: string;
}

export const Sidebar: React.FC = () => {
  const navigate = useNavigate();
  const user = useAuthStore((s) => s.user);
  const { currentPlan } = useTenantStore();
  const { hasFeature, openUpgradeForFeature } = useEntitlement();
  const { isOpen, close } = useSidebar();

  useEffect(() => {
    if (!isOpen) return;
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') close();
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [isOpen, close]);

  // Group 1: Navigation principale
  const mainNavItems: NavItem[] = [
    { to: '/', label: 'Accueil', icon: Home },
    { to: '/produits', label: 'Produits & Stocks', icon: Package },
    { to: '/categories', label: 'Catégories', icon: LayoutGrid },
    { to: '/clients', label: 'Clients & Créances', icon: Users },
    { to: '/fournisseurs', label: 'Fournisseurs', icon: Building2, roles: ['owner', 'store_admin', 'merchant', 'manager'], featureCode: 'module_suppliers' },
  ];

  // Group 2: Opérations & Flux
  const operationNavItems: NavItem[] = [
    { to: '/approvisionnements', label: 'Approvisionnements', icon: ArrowDownToLine, roles: ['owner', 'store_admin', 'merchant', 'manager'], featureCode: 'module_supplies' },
    { to: '/transferts', label: 'Transferts & Mouvements', icon: ArrowRightLeft, roles: ['owner', 'store_admin', 'merchant', 'manager'], featureCode: 'stock_transfers' },
    { to: '/ventes', label: 'Ventes & Caisse', icon: ShoppingCart },
    { to: '/caisse-z', label: 'Clôture de Caisse (Z)', icon: Calculator },
    { to: '/depenses', label: 'Décaissements', icon: Wallet },
    { to: '/rapports', label: 'Rapports & Analytique', icon: BarChart3, roles: ['owner', 'store_admin', 'merchant', 'manager'], featureCode: 'pnl_reports' },
  ];

  // Group 3: Paramètres & Administration
  const adminNavItems: NavItem[] = [
    { to: '/magasins', label: 'Magasins & Points de Vente', icon: Store, roles: ['owner', 'store_admin', 'merchant', 'manager'] },
    { to: '/parametres', label: 'Paramètres Boutique', icon: Settings, roles: ['owner', 'store_admin', 'merchant'] },
    { to: '/utilisateurs', label: 'Utilisateurs & Rôles', icon: UserCheck, roles: ['owner', 'store_admin', 'merchant'] },
    { to: '/audit', label: "Journal d'Audit", icon: ShieldCheck, roles: ['owner', 'store_admin', 'merchant'], featureCode: 'module_audit_logs' },
    { to: '/abonnement', label: 'Abonnement & Factures', icon: CreditCard, roles: ['owner', 'store_admin', 'merchant'] },
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
        if (user.role === 'owner' || user.role === 'store_admin' || user.role === 'admin' || user.role === 'merchant') return true;
        return item.roles.includes(user.role);
      })
      .map((item) => {
        const Icon = item.icon;
        const isLocked = Boolean(currentPlan && item.featureCode && !hasFeature(item.featureCode));
        return (
          <NavLink
            key={item.to}
            to={item.to}
            end={item.to === '/'}
            onClick={(e) => {
              if (isLocked && item.featureCode) {
                e.preventDefault();
                openUpgradeForFeature(item.featureCode, `${item.label} - Option Pro`);
                return;
              }
              handleNavClick();
            }}
            className={({ isActive }) =>
              `flex items-center justify-between gap-2 px-3.5 py-2.5 rounded-xl text-[13px] font-medium transition-all duration-150 ${
                isActive && !isLocked
                  ? 'bg-[#E8F5FD] dark:bg-[#29ABE2]/15 text-[#29ABE2] font-semibold shadow-none'
                  : 'text-[#5A7184] dark:text-slate-400 hover:bg-[#F0F9FE] dark:hover:bg-dark-700/60 hover:text-[#1C2B3A] dark:hover:text-white'
              }`
            }
          >
            <span className="flex items-center gap-3.5 min-w-0">
              <Icon className="w-4 h-4 shrink-0" />
              <span className="truncate">{item.label}</span>
            </span>
            {isLocked && (
              <span className="badge-toc-purple text-[9px] px-1.5 py-0.5 shrink-0">PRO</span>
            )}
          </NavLink>
        );
      });
  };

  return (
    <aside
      className={`fixed inset-y-0 left-0 z-50 w-64 transform transition-transform duration-200 lg:static lg:translate-x-0 ${
        isOpen ? 'translate-x-0' : '-translate-x-full'
      } flex flex-col h-full bg-white dark:bg-dark-800 border-r border-[#E8EFF5] dark:border-dark-600 shrink-0`}
    >
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

      {/* Plan Card at bottom */}
      <div className="p-3 border-t border-[#E8EFF5] dark:border-dark-600 space-y-2">
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
              onClick={() => {
                handleNavClick();
                navigate('/abonnement');
              }}
              className="w-full py-1.5 text-[11px] font-bold text-[#29ABE2] bg-[#E8F5FD] dark:bg-[#29ABE2]/15 hover:bg-[#BAE3F9]/40 rounded-lg transition"
            >
              Gerer l abonnement
            </button>
          </div>
        )}
      </div>
    </aside>
  );
};
