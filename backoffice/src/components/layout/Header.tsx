import React from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import {
  LogOut,
  User as UserIcon,
  Shield,
  Calendar,
  Sun,
  Moon,
  AlignJustify,
  Rows,
  Bell,
} from 'lucide-react';
import { useAuthStore } from '../../stores/authStore';
import { useTheme } from '../../context/ThemeContext';
import { useDensity } from '../../context/DensityContext';
import { api } from '../../lib/api';
import { DashboardStats } from '../../types';

export const Header: React.FC = () => {
  const navigate = useNavigate();
  const { user, logout } = useAuthStore();
  const { theme, toggleTheme } = useTheme();
  const { density, toggleDensity } = useDensity();

  // Query stats for stock alert notifications (same as mobile HomeScreen)
  const { data: stats } = useQuery<DashboardStats>({
    queryKey: ['header-stock-alerts'],
    queryFn: async () => {
      const res = await api.get('/reports/dashboard');
      return res.data;
    },
    refetchInterval: 30000,
  });

  const lowStockCount = stats?.low_stock_count || 0;

  const roleLabel =
    user?.role === 'admin'
      ? 'Administrateur'
      : user?.role === 'manager'
      ? 'Gérant'
      : 'Caissier';

  // Format today's date in French (matches mobile date header)
  const todayFormatted = new Intl.DateTimeFormat('fr-FR', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  }).format(new Date());

  const capitalizedDate = todayFormatted.charAt(0).toUpperCase() + todayFormatted.slice(1);

  return (
    <header className="h-16 bg-white dark:bg-dark-800 border-b border-[#E8EFF5] dark:border-dark-600 px-6 sm:px-8 flex items-center justify-between sticky top-0 z-20 shadow-none transition-colors duration-200">
      {/* Date & Context (Mobile-like clean pill) */}
      <div className="flex items-center gap-3">
        <div className="hidden sm:flex items-center gap-2 text-xs font-semibold text-[#5A7184] dark:text-slate-400 bg-[#F0F9FE] dark:bg-dark-700/60 px-3.5 py-1.5 rounded-xl border border-[#E8EFF5] dark:border-dark-600">
          <Calendar className="w-3.5 h-3.5 text-[#29ABE2]" />
          <span>{capitalizedDate}</span>
        </div>
      </div>

      {/* Right controls: Notifications, Density, Dark Mode, Profile & Logout */}
      <div className="flex items-center gap-2 sm:gap-3.5">
        {/* Stock Alert Notification Bell (Exact replica of mobile notification bell) */}
        <button
          onClick={() => navigate('/produits')}
          className="relative p-2 text-[#5A7184] dark:text-slate-300 hover:text-[#29ABE2] hover:bg-[#F0F9FE] dark:hover:bg-dark-700 rounded-xl transition-all"
          title={
            lowStockCount > 0
              ? `${lowStockCount} produit(s) en alerte de stock`
              : 'Aucune alerte de rupture'
          }
        >
          <Bell className="w-4 h-4" />
          {lowStockCount > 0 && (
            <span className="absolute top-1 right-1 flex items-center justify-center min-w-[16px] h-4 px-1 text-[9px] font-bold text-white bg-[#E74C3C] rounded-full animate-pulse-subtle">
              {lowStockCount > 9 ? '9+' : lowStockCount}
            </span>
          )}
        </button>

        {/* Density Toggle Button */}
        <button
          onClick={toggleDensity}
          className="flex items-center gap-1.5 px-2.5 py-1.5 text-xs font-semibold text-[#5A7184] dark:text-slate-300 bg-[#F0F9FE] hover:bg-[#E8F5FD] dark:bg-dark-700 dark:hover:bg-dark-600 rounded-xl border border-[#E8EFF5] dark:border-dark-600 transition-all"
          title={`Densité : ${density === 'comfortable' ? 'Aérée' : 'Compacte'} (Cliquer pour basculer)`}
        >
          {density === 'comfortable' ? (
            <>
              <Rows className="w-3.5 h-3.5 text-[#29ABE2]" />
              <span className="hidden md:inline">Aérée</span>
            </>
          ) : (
            <>
              <AlignJustify className="w-3.5 h-3.5 text-[#29ABE2]" />
              <span className="hidden md:inline">Compacte</span>
            </>
          )}
        </button>

        {/* Theme Toggle (Light / Dark) */}
        <button
          onClick={toggleTheme}
          className="p-2 text-[#5A7184] dark:text-slate-300 hover:text-[#29ABE2] dark:hover:text-[#29ABE2] bg-[#F0F9FE] dark:bg-dark-700 hover:bg-[#E8F5FD] dark:hover:bg-dark-600 rounded-xl border border-[#E8EFF5] dark:border-dark-600 transition-all"
          title={theme === 'dark' ? 'Passer au mode Clair' : 'Passer au mode Sombre'}
          aria-label="Changer de thème"
        >
          {theme === 'dark' ? (
            <Sun className="w-4 h-4 text-amber-400 animate-fade-in" />
          ) : (
            <Moon className="w-4 h-4 text-[#1C2B3A] animate-fade-in" />
          )}
        </button>

        {/* User profile summary */}
        <div className="flex items-center gap-2.5 pl-3 border-l border-[#E8EFF5] dark:border-dark-600">
          <div className="w-8 h-8 rounded-xl bg-[#E8F5FD] dark:bg-[#29ABE2]/15 flex items-center justify-center text-[#29ABE2] border border-[#BAE3F9] dark:border-[#29ABE2]/30 font-bold shrink-0">
            <UserIcon className="w-4 h-4" />
          </div>
          <div className="hidden sm:block">
            <div className="text-xs font-bold text-[#1C2B3A] dark:text-white leading-tight">
              {user?.full_name || user?.username}
            </div>
            <div className="text-[11px] text-[#5A7184] dark:text-slate-400 flex items-center gap-1 mt-0.5">
              <Shield className="w-2.5 h-2.5 text-[#29ABE2]" />
              <span className="font-semibold text-[#29ABE2]">{roleLabel}</span>
            </div>
          </div>
        </div>

        {/* Logout button */}
        <button
          onClick={logout}
          className="inline-flex items-center gap-1.5 px-2.5 py-1.5 text-xs font-semibold text-[#5A7184] dark:text-slate-400 hover:text-[#E74C3C] dark:hover:text-[#E74C3C] hover:bg-[#FDEBE9] dark:hover:bg-rose-950/30 rounded-xl transition-all border border-transparent hover:border-[#E74C3C]/20"
          title="Se déconnecter"
        >
          <LogOut className="w-4 h-4" />
          <span className="hidden sm:inline">Déconnexion</span>
        </button>
      </div>
    </header>
  );
};
