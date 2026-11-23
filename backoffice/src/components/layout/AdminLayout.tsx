import React, { useEffect } from 'react';
import { Outlet, NavLink, Link, useNavigate } from 'react-router-dom';
import {
  LayoutDashboard,
  Layers,
  Store,
  LogOut,
  ExternalLink,
  Sun,
  Moon,
  Menu,
  Rows,
  AlignJustify,
  CreditCard,
  ShieldAlert,
} from 'lucide-react';
import { useAuthStore } from '../../stores/authStore';
import { useTheme } from '../../context/ThemeContext';
import { useDensity } from '../../context/DensityContext';
import { useSidebar } from '../../context/SidebarContext';

interface AdminNavItem {
  to: string;
  label: string;
  icon: React.ComponentType<{ className?: string }>;
  end?: boolean;
}

const ADMIN_NAV: { group: string; items: AdminNavItem[] }[] = [
  {
    group: 'Pilotage',
    items: [{ to: '/admin', label: 'KPIs & Plateforme', icon: LayoutDashboard, end: true }],
  },
  {
    group: 'Monétisation',
    items: [
      { to: '/admin/plans', label: 'Forfaits & Pricing', icon: Layers },
      { to: '/admin/boutiques', label: 'Boutiques Clientes', icon: Store },
      { to: '/admin/subscriptions', label: 'Abonnements & FeexPay', icon: CreditCard },
    ],
  },
  {
    group: 'Système',
    items: [{ to: '/admin/audit', label: "Journal d'Audit", icon: ShieldAlert }],
  },
];

export const AdminLayout: React.FC = () => {
  const { user, logout } = useAuthStore();
  const { theme, toggleTheme } = useTheme();
  const { density, toggleDensity } = useDensity();
  const { isOpen, close, toggle } = useSidebar();
  const navigate = useNavigate();

  useEffect(() => {
    if (!isOpen) return;
    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') close();
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [isOpen, close]);

  const handleNavClick = () => {
    if (window.innerWidth < 1024) close();
  };

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <div className="min-h-screen bg-[#F5FAFD] dark:bg-dark-900 text-[#1C2B3A] dark:text-[#E2E8F0] flex font-sans transition-colors duration-200">
      {isOpen && (
        <div
          onClick={close}
          className="fixed inset-0 bg-[#1C2B3A]/50 z-40 lg:hidden backdrop-blur-xs animate-fade-in"
          aria-hidden="true"
        />
      )}

      <aside
        className={`fixed inset-y-0 left-0 z-50 w-64 transform transition-transform duration-200 lg:static lg:translate-x-0 ${
          isOpen ? 'translate-x-0' : '-translate-x-full'
        } bg-white dark:bg-dark-800 border-r border-[#E8EFF5] dark:border-dark-600 flex flex-col justify-between shrink-0`}
      >
        <div>
          <div className="h-16 flex items-center justify-between px-5 border-b border-[#E8EFF5] dark:border-dark-600">
            <Link to="/admin" onClick={handleNavClick} className="flex items-center gap-2.5">
              <div className="w-8 h-8 rounded-xl toc-gradient flex items-center justify-center font-black text-white text-xs shadow-sm">
                TM
              </div>
              <div className="leading-tight">
                <div className="font-bold text-sm text-[#1C2B3A] dark:text-white tracking-tight">
                  Toc<span className="text-[#29ABE2]">Manager</span>
                </div>
                <span className="badge-toc-primary text-[9px] px-1.5 py-0.5 mt-0.5">
                  Super-Admin
                </span>
              </div>
            </Link>
          </div>

          <div className="p-3.5 space-y-5">
            {ADMIN_NAV.map((section) => (
              <div key={section.group}>
                <div className="px-3.5 mb-1.5 text-[10px] font-bold tracking-wider text-[#9BB2C4] dark:text-slate-500 uppercase">
                  {section.group}
                </div>
                <nav className="space-y-0.5 text-[13px] font-medium">
                  {section.items.map((item) => {
                    const Icon = item.icon;
                    return (
                      <NavLink
                        key={item.to}
                        to={item.to}
                        end={item.end}
                        onClick={handleNavClick}
                        className={({ isActive }) =>
                          `flex items-center gap-3 px-3.5 py-2.5 rounded-xl transition ${
                            isActive
                              ? 'bg-[#E8F5FD] dark:bg-[#29ABE2]/15 text-[#29ABE2] font-semibold'
                              : 'text-[#5A7184] dark:text-slate-400 hover:bg-[#F0F9FE] dark:hover:bg-dark-700/60 hover:text-[#1C2B3A] dark:hover:text-white'
                          }`
                        }
                      >
                        <Icon className="w-4 h-4 shrink-0" />
                        <span>{item.label}</span>
                      </NavLink>
                    );
                  })}
                </nav>
              </div>
            ))}
          </div>
        </div>

        <div className="p-4 border-t border-[#E8EFF5] dark:border-dark-600 space-y-3">
          <Link
            to="/landing"
            onClick={handleNavClick}
            className="flex items-center justify-between px-3 py-2 text-xs font-semibold rounded-xl bg-[#F0F9FE] dark:bg-dark-700 hover:bg-[#E8F5FD] dark:hover:bg-dark-600 text-[#29ABE2] transition"
          >
            <span>Site Public</span>
            <ExternalLink className="w-3.5 h-3.5" />
          </Link>

          <div className="flex items-center justify-between pt-1">
            <div className="flex items-center gap-2.5 min-w-0">
              <div className="w-8 h-8 rounded-xl bg-[#E8F5FD] dark:bg-[#29ABE2]/15 text-[#29ABE2] flex items-center justify-center font-bold text-xs shrink-0">
                {user?.username?.slice(0, 2).toUpperCase() || 'SA'}
              </div>
              <div className="text-[11px] leading-tight min-w-0">
                <div className="font-bold text-[#1C2B3A] dark:text-white truncate">
                  {user?.username}
                </div>
                <div className="text-[#5A7184] dark:text-slate-400 text-[10px]">{user?.role}</div>
              </div>
            </div>

            <button
              type="button"
              onClick={handleLogout}
              title="Déconnexion"
              className="p-2 rounded-xl text-[#5A7184] hover:text-[#E74C3C] hover:bg-[#FDEBE9] dark:hover:bg-dark-700 transition"
            >
              <LogOut className="w-4 h-4" />
            </button>
          </div>
        </div>
      </aside>

      <div className="flex-1 flex flex-col min-w-0 overflow-y-auto">
        <header className="h-16 bg-white dark:bg-dark-800 border-b border-[#E8EFF5] dark:border-dark-600 flex items-center justify-between px-4 sm:px-6 lg:px-8 sticky top-0 z-30">
          <div className="flex items-center gap-3">
            <button
              type="button"
              onClick={toggle}
              className="lg:hidden p-2 text-[#5A7184] hover:text-[#29ABE2] hover:bg-[#F0F9FE] dark:hover:bg-dark-700 rounded-xl transition"
              aria-label="Ouvrir le menu d'administration"
            >
              <Menu className="w-5 h-5" />
            </button>
            <div className="text-sm font-bold text-[#1C2B3A] dark:text-white">
              Console Super-Admin TocManager
            </div>
          </div>

          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={toggleDensity}
              className="p-2 rounded-xl bg-[#F0F9FE] dark:bg-dark-700 border border-[#E8EFF5] dark:border-dark-600 text-[#5A7184] dark:text-slate-300 hover:text-[#29ABE2] transition"
              title={density === 'compact' ? 'Mode confortable' : 'Mode compact'}
              aria-label="Changer la densité d'affichage"
            >
              {density === 'compact' ? (
                <Rows className="w-4 h-4" />
              ) : (
                <AlignJustify className="w-4 h-4" />
              )}
            </button>

            <button
              type="button"
              onClick={toggleTheme}
              className="p-2 rounded-xl bg-[#F0F9FE] dark:bg-dark-700 border border-[#E8EFF5] dark:border-dark-600 text-[#5A7184] dark:text-slate-300 hover:text-[#29ABE2] transition"
              aria-label="Changer de thème"
            >
              {theme === 'dark' ? (
                <Sun className="w-4 h-4 text-amber-400" />
              ) : (
                <Moon className="w-4 h-4 text-[#1C2B3A]" />
              )}
            </button>
          </div>
        </header>

        <main className="p-4 sm:p-6 lg:p-8 flex-1">
          <Outlet />
        </main>
      </div>
    </div>
  );
};
