import React from 'react';
import { NavLink } from 'react-router-dom';
import {
  LayoutDashboard,
  ShoppingCart,
  Users,
  Package,
  Tag,
  PackagePlus,
  Receipt,
  Truck,
  TrendingUp,
  UserCheck,
  ShieldCheck,
  Settings,
} from 'lucide-react';
import { useAuthStore } from '../../stores/authStore';

interface NavSection {
  title: string;
  items: {
    to: string;
    label: string;
    icon: React.ComponentType<{ className?: string }>;
    roles?: ('admin' | 'manager' | 'cashier')[];
  }[];
}

export const Sidebar: React.FC = () => {
  const user = useAuthStore((s) => s.user);

  const sections: NavSection[] = [
    {
      title: 'VENTES & COMMERCE',
      items: [
        { to: '/', label: 'Tableau de bord', icon: LayoutDashboard },
        { to: '/ventes', label: 'Journal des Ventes', icon: ShoppingCart },
        { to: '/clients', label: 'Clients & Créances', icon: Users },
      ],
    },
    {
      title: 'CATALOGUE & STOCKS',
      items: [
        { to: '/produits', label: 'Stocks & Articles', icon: Package },
        { to: '/categories', label: 'Catégories', icon: Tag },
        { to: '/approvisionnements', label: 'Approvisionnements', icon: PackagePlus, roles: ['admin', 'manager'] },
      ],
    },
    {
      title: 'FINANCES & DÉPENSES',
      items: [
        { to: '/depenses', label: 'Dépenses de Caisse', icon: Receipt },
        { to: '/fournisseurs', label: 'Fournisseurs & Dettes', icon: Truck, roles: ['admin', 'manager'] },
      ],
    },
    {
      title: 'ANALYTIQUE & PILOTAGE',
      items: [
        { to: '/rapports', label: 'Rapports & Rentabilité', icon: TrendingUp, roles: ['admin', 'manager'] },
      ],
    },
    {
      title: 'ADMINISTRATION',
      items: [
        { to: '/utilisateurs', label: 'Utilisateurs & Rôles', icon: UserCheck, roles: ['admin'] },
        { to: '/audit', label: "Journal d'Audit", icon: ShieldCheck, roles: ['admin'] },
        { to: '/parametres', label: 'Paramètres Boutique', icon: Settings, roles: ['admin'] },
      ],
    },
  ];

  return (
    <aside className="w-64 bg-white dark:bg-dark-800 text-slate-700 dark:text-slate-300 flex flex-col shrink-0 border-r border-[#E8EFF5] dark:border-dark-600 select-none shadow-soft transition-colors duration-200">
      {/* Brand logo & title */}
      <div className="h-16 flex items-center px-6 gap-3 border-b border-[#E8EFF5] dark:border-dark-600 bg-white/50 dark:bg-dark-800/50 backdrop-blur-sm">
        <img
          src="/assets/logo.png"
          alt="TocManager Logo"
          className="h-9 w-auto max-w-[140px] object-contain drop-shadow-sm"
          onError={(e) => {
            // Fallback to icon if logo fails
            (e.target as HTMLImageElement).src = '/assets/icon.png';
          }}
        />
        <span className="sr-only">TocManager Backoffice</span>
      </div>

      {/* Navigation links grouped by sections */}
      <nav className="flex-1 px-3 py-4 space-y-5 overflow-y-auto">
        {sections.map((sec) => {
          const filteredItems = sec.items.filter((item) => {
            if (!item.roles) return true;
            return user && item.roles.includes(user.role);
          });

          if (filteredItems.length === 0) return null;

          return (
            <div key={sec.title} className="space-y-1">
              <p className="px-3 text-[10px] font-bold text-slate-400 dark:text-slate-500 uppercase tracking-wider mb-1.5">
                {sec.title}
              </p>
              {filteredItems.map((item) => {
                const Icon = item.icon;
                return (
                  <NavLink
                    key={item.to}
                    to={item.to}
                    end={item.to === '/'}
                    className={({ isActive }) =>
                      `flex items-center gap-3 px-3 py-2.5 rounded-xl text-xs font-semibold transition-all duration-150 ${
                        isActive
                          ? 'bg-brand-50 dark:bg-brand-500/15 text-brand-600 dark:text-brand-400 font-bold border-l-4 border-brand-500 pl-2 shadow-xs'
                          : 'text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-dark-700/60 hover:text-slate-900 dark:hover:text-white'
                      }`
                    }
                  >
                    <Icon className="w-4 h-4 shrink-0" />
                    <span className="truncate">{item.label}</span>
                  </NavLink>
                );
              })}
            </div>
          );
        })}
      </nav>

      {/* Footer API status */}
      <div className="p-3 border-t border-[#E8EFF5] dark:border-dark-600 bg-slate-50/50 dark:bg-dark-700/30">
        <div className="flex items-center justify-between px-2 py-1.5 text-[11px] text-slate-500 dark:text-slate-400">
          <div className="flex items-center gap-2">
            <span className="relative flex h-2 w-2">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
              <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
            </span>
            <span className="font-medium">Serveur Connecté</span>
          </div>
          <span className="text-[10px] font-mono opacity-70">v1.2.0</span>
        </div>
      </div>
    </aside>
  );
};
