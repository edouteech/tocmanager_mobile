import React from 'react';
import { NavLink } from 'react-router-dom';
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
} from 'lucide-react';
import { useAuthStore } from '../../stores/authStore';

interface NavItem {
  to: string;
  label: string;
  icon: React.ComponentType<{ className?: string }>;
  roles?: ('admin' | 'manager' | 'cashier')[];
}

export const Sidebar: React.FC = () => {
  const user = useAuthStore((s) => s.user);

  // Group 1: Navigation principale (ordre identique à l'AppDrawer Mobile)
  const mainNavItems: NavItem[] = [
    { to: '/', label: 'Accueil', icon: Home },
    { to: '/produits', label: 'Produits', icon: Package },
    { to: '/categories', label: 'Catégories', icon: LayoutGrid },
    { to: '/clients', label: 'Clients', icon: Users },
    { to: '/fournisseurs', label: 'Fournisseurs', icon: Building2, roles: ['admin', 'manager'] },
  ];

  // Group 2: Opérations & Flux
  const operationNavItems: NavItem[] = [
    { to: '/approvisionnements', label: 'Approvisionnements', icon: ArrowDownToLine, roles: ['admin', 'manager'] },
    { to: '/ventes', label: 'Ventes', icon: ShoppingCart },
    { to: '/depenses', label: 'Décaissements', icon: Wallet },
    { to: '/rapports', label: 'Rapports & Analytique', icon: BarChart3, roles: ['admin', 'manager'] },
  ];

  // Group 3: Paramètres & Administration
  const adminNavItems: NavItem[] = [
    { to: '/parametres', label: 'Paramètres', icon: Settings, roles: ['admin'] },
    { to: '/utilisateurs', label: 'Utilisateurs & Rôles', icon: UserCheck, roles: ['admin'] },
    { to: '/audit', label: "Journal d'Audit", icon: ShieldCheck, roles: ['admin'] },
  ];

  const renderNavList = (items: NavItem[]) => {
    return items
      .filter((item) => !item.roles || (user && item.roles.includes(user.role)))
      .map((item) => {
        const Icon = item.icon;
        return (
          <NavLink
            key={item.to}
            to={item.to}
            end={item.to === '/'}
            className={({ isActive }) =>
              `flex items-center gap-3.5 px-3.5 py-2.5 rounded-xl text-[13px] font-medium transition-all duration-150 ${
                isActive
                  ? 'bg-[#E8F5FD] dark:bg-[#29ABE2]/15 text-[#29ABE2] font-semibold shadow-none'
                  : 'text-[#5A7184] dark:text-slate-400 hover:bg-[#F0F9FE] dark:hover:bg-dark-700/60 hover:text-[#1C2B3A] dark:hover:text-white'
              }`
            }
          >
            {({ isActive }) => (
              <>
                <Icon
                  className={`w-[18px] h-[18px] shrink-0 transition-colors ${
                    isActive ? 'text-[#29ABE2]' : 'text-[#5A7184] dark:text-slate-400'
                  }`}
                />
                <span className="truncate">{item.label}</span>
              </>
            )}
          </NavLink>
        );
      });
  };

  return (
    <aside className="w-64 bg-white dark:bg-dark-800 text-[#1C2B3A] dark:text-slate-300 flex flex-col shrink-0 border-r border-[#E8EFF5] dark:border-dark-600 select-none shadow-soft transition-colors duration-200">
      {/* Drawer Header signature Mobile (Dégradé #1A8FBF -> #29ABE2) */}
      <div className="bg-gradient-to-br from-[#1A8FBF] to-[#29ABE2] px-5 py-5 flex items-center gap-3.5 text-white">
        <div className="p-2.5 bg-white/20 backdrop-blur-xs rounded-2xl flex items-center justify-center shrink-0">
          <img
            src="/assets/icon.png"
            alt="TocManager Icon"
            className="w-8 h-8 object-contain"
            onError={(e) => {
              (e.target as HTMLImageElement).src = '/assets/logo.png';
            }}
          />
        </div>
        <div className="min-w-0">
          <h1 className="text-lg font-bold tracking-tight text-white leading-tight truncate">
            tocmanager
          </h1>
          <p className="text-xs text-white/80 font-normal">
            Gestion simplifiée
          </p>
        </div>
      </div>

      {/* Navigation Links calqués sur le mobile */}
      <nav className="flex-1 px-3 py-4 space-y-1 overflow-y-auto">
        {renderNavList(mainNavItems)}

        <div className="py-2 px-2">
          <div className="border-t border-[#E8EFF5] dark:border-dark-600" />
        </div>

        {renderNavList(operationNavItems)}

        <div className="py-2 px-2">
          <div className="border-t border-[#E8EFF5] dark:border-dark-600" />
        </div>

        {renderNavList(adminNavItems)}
      </nav>

      {/* Footer Version & Status Mobile */}
      <div className="p-3 border-t border-[#E8EFF5] dark:border-dark-600 bg-[#F5FAFD]/60 dark:bg-dark-700/30">
        <div className="flex items-center justify-between px-2 py-1 text-xs text-[#5A7184] dark:text-slate-400">
          <div className="flex items-center gap-2">
            <span className="relative flex h-2 w-2">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-[#27AE60] opacity-75"></span>
              <span className="relative inline-flex rounded-full h-2 w-2 bg-[#27AE60]"></span>
            </span>
            <span className="font-medium text-[11px]">En ligne</span>
          </div>
          <span className="text-[11px] font-medium text-[#9FB3C8]">tocmanager v1.0.0</span>
        </div>
      </div>
    </aside>
  );
};
