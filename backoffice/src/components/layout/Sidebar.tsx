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
  Layers,
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
    <aside className="w-64 bg-slate-900 text-slate-300 flex flex-col shrink-0 border-r border-slate-800">
      {/* Brand logo & title */}
      <div className="h-16 flex items-center px-6 gap-3 border-b border-slate-800">
        <div className="w-9 h-9 rounded-lg bg-indigo-600 flex items-center justify-center text-white font-bold shadow-md">
          <Layers className="w-5 h-5" />
        </div>
        <div>
          <span className="font-bold text-white text-base tracking-wide">TocManager</span>
          <span className="block text-[10px] text-slate-400 font-medium uppercase tracking-wider">
            Backoffice Central
          </span>
        </div>
      </div>

      {/* Navigation links grouped by sections */}
      <nav className="flex-1 px-4 py-4 space-y-5 overflow-y-auto">
        {sections.map((sec) => {
          // Filter items based on user role
          const filteredItems = sec.items.filter((item) => {
            if (!item.roles) return true;
            return user && item.roles.includes(user.role);
          });

          if (filteredItems.length === 0) return null;

          return (
            <div key={sec.title} className="space-y-1">
              <p className="px-3 text-[10px] font-bold text-slate-500 uppercase tracking-wider mb-1.5">
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
                      `flex items-center gap-3 px-3 py-2 rounded-lg text-xs font-medium transition-colors ${
                        isActive
                          ? 'bg-indigo-600 text-white shadow-xs'
                          : 'text-slate-400 hover:text-white hover:bg-slate-800/60'
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

      {/* Footer Info */}
      <div className="p-4 border-t border-slate-800 text-xs text-slate-500 flex items-center justify-between">
        <span className="text-[11px]">v1.0.0</span>
        <span className="inline-flex items-center gap-1.5 text-[11px]">
          <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
          <span>API Active</span>
        </span>
      </div>
    </aside>
  );
};
