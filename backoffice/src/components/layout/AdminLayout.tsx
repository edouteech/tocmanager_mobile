import React from 'react';
import { Outlet, NavLink, Link, useNavigate } from 'react-router-dom';
import { LayoutDashboard, Layers, Store, ShieldAlert, LogOut, ExternalLink, Sun, Moon } from 'lucide-react';
import { useAuthStore } from '../../stores/authStore';
import { useTheme } from '../../context/ThemeContext';

export const AdminLayout: React.FC = () => {
  const { user, logout } = useAuthStore();
  const { theme, toggleTheme } = useTheme();
  const navigate = useNavigate();

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <div className="min-h-screen bg-slate-50 dark:bg-slate-950 text-slate-800 dark:text-slate-100 flex font-sans">
      {/* Sidebar Super-Admin */}
      <aside className="w-64 bg-slate-900 text-white flex flex-col justify-between shrink-0 border-r border-slate-800">
        <div>
          {/* Logo / Header */}
          <div className="h-16 flex items-center gap-3 px-6 border-b border-slate-800">
            <div className="w-8 h-8 rounded-lg bg-gradient-to-tr from-amber-500 to-indigo-600 flex items-center justify-center font-black text-white text-sm">
              SA
            </div>
            <div>
              <div className="font-extrabold text-sm tracking-wide">TocManager</div>
              <div className="text-[10px] text-amber-400 font-semibold uppercase tracking-wider">Super-Admin</div>
            </div>
          </div>

          {/* Navigation Links */}
          <nav className="p-4 space-y-1.5 text-xs font-medium">
            <NavLink
              to="/admin"
              end
              className={({ isActive }) =>
                `flex items-center gap-3 px-3.5 py-2.5 rounded-xl transition ${
                  isActive ? 'bg-indigo-600 text-white font-bold shadow-md' : 'text-slate-300 hover:bg-slate-800 hover:text-white'
                }`
              }
            >
              <LayoutDashboard className="w-4 h-4" />
              <span>KPIs & Plateforme</span>
            </NavLink>

            <NavLink
              to="/admin/plans"
              className={({ isActive }) =>
                `flex items-center gap-3 px-3.5 py-2.5 rounded-xl transition ${
                  isActive ? 'bg-indigo-600 text-white font-bold shadow-md' : 'text-slate-300 hover:bg-slate-800 hover:text-white'
                }`
              }
            >
              <Layers className="w-4 h-4" />
              <span>Forfaits & Pricing</span>
            </NavLink>

            <NavLink
              to="/admin/boutiques"
              className={({ isActive }) =>
                `flex items-center gap-3 px-3.5 py-2.5 rounded-xl transition ${
                  isActive ? 'bg-indigo-600 text-white font-bold shadow-md' : 'text-slate-300 hover:bg-slate-800 hover:text-white'
                }`
              }
            >
              <Store className="w-4 h-4" />
              <span>Boutiques Clientes</span>
            </NavLink>
          </nav>
        </div>

        {/* Footer Sidebar */}
        <div className="p-4 border-t border-slate-800 space-y-3">
          <Link
            to="/landing"
            className="flex items-center justify-between px-3 py-2 text-xs font-semibold rounded-lg bg-slate-800/80 hover:bg-slate-800 text-indigo-300 transition"
          >
            <span>Site Public</span>
            <ExternalLink className="w-3.5 h-3.5" />
          </Link>

          <div className="flex items-center justify-between pt-2">
            <div className="flex items-center gap-2">
              <div className="w-7 h-7 rounded-full bg-slate-700 flex items-center justify-center font-bold text-xs">
                {user?.username?.slice(0, 2).toUpperCase() || 'AD'}
              </div>
              <div className="text-[11px] leading-tight">
                <div className="font-bold text-slate-200">{user?.username}</div>
                <div className="text-slate-400 text-[10px]">{user?.role}</div>
              </div>
            </div>

            <button
              onClick={handleLogout}
              title="Déconnexion"
              className="p-1.5 rounded-lg text-slate-400 hover:text-rose-400 hover:bg-slate-800 transition"
            >
              <LogOut className="w-4 h-4" />
            </button>
          </div>
        </div>
      </aside>

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col min-w-0 overflow-y-auto">
        <header className="h-16 bg-white dark:bg-slate-900 border-b border-slate-200 dark:border-slate-800 flex items-center justify-between px-6 sticky top-0 z-30">
          <div className="text-sm font-bold text-slate-700 dark:text-slate-200">
            Console d'Administration Globale TocManager
          </div>
          <button
            onClick={toggleTheme}
            className="p-2 rounded-xl text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800 transition"
          >
            {theme === 'dark' ? <Sun className="w-4 h-4 text-amber-400" /> : <Moon className="w-4 h-4" />}
          </button>
        </header>

        <main className="p-6 md:p-8 flex-1">
          <Outlet />
        </main>
      </div>
    </div>
  );
};
