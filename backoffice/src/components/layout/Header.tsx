import React from 'react';
import {
  LogOut,
  User as UserIcon,
  Shield,
  Calendar,
  Sun,
  Moon,
  AlignJustify,
  Rows,
} from 'lucide-react';
import { useAuthStore } from '../../stores/authStore';
import { useTheme } from '../../context/ThemeContext';
import { useDensity } from '../../context/DensityContext';

export const Header: React.FC = () => {
  const { user, logout } = useAuthStore();
  const { theme, toggleTheme } = useTheme();
  const { density, toggleDensity } = useDensity();

  const roleLabel =
    user?.role === 'admin'
      ? 'Administrateur'
      : user?.role === 'manager'
      ? 'Gérant'
      : 'Caissier';

  // Format today's date in French
  const todayFormatted = new Intl.DateTimeFormat('fr-FR', {
    weekday: 'long',
    day: 'numeric',
    month: 'long',
    year: 'numeric',
  }).format(new Date());

  const capitalizedDate = todayFormatted.charAt(0).toUpperCase() + todayFormatted.slice(1);

  return (
    <header className="h-16 bg-white dark:bg-dark-800 border-b border-[#E8EFF5] dark:border-dark-600 px-6 sm:px-8 flex items-center justify-between sticky top-0 z-20 shadow-soft transition-colors duration-200">
      {/* Date & Context */}
      <div className="flex items-center gap-3">
        <div className="hidden sm:flex items-center gap-2 text-xs font-semibold text-slate-500 dark:text-slate-400 bg-[#F5FAFD] dark:bg-dark-700/60 px-3 py-1.5 rounded-xl border border-[#E8EFF5] dark:border-dark-600">
          <Calendar className="w-3.5 h-3.5 text-brand-500" />
          <span>{capitalizedDate}</span>
        </div>
      </div>

      {/* Right controls: Density, Dark Mode, Profile & Logout */}
      <div className="flex items-center gap-2 sm:gap-4">
        {/* Density Toggle Button */}
        <button
          onClick={toggleDensity}
          className="flex items-center gap-1.5 px-2.5 py-1.5 text-xs font-semibold text-slate-600 dark:text-slate-300 bg-slate-100 hover:bg-slate-200 dark:bg-dark-700 dark:hover:bg-dark-600 rounded-xl transition-all"
          title={`Densité actuelle : ${density === 'comfortable' ? 'Aérée' : 'Compacte'} (Cliquer pour basculer)`}
        >
          {density === 'comfortable' ? (
            <>
              <Rows className="w-3.5 h-3.5 text-brand-500" />
              <span className="hidden md:inline">Vue Aérée</span>
            </>
          ) : (
            <>
              <AlignJustify className="w-3.5 h-3.5 text-brand-500" />
              <span className="hidden md:inline">Vue Compacte</span>
            </>
          )}
        </button>

        {/* Theme Toggle (Light / Dark) */}
        <button
          onClick={toggleTheme}
          className="p-2 text-slate-600 dark:text-slate-300 hover:text-brand-500 dark:hover:text-brand-400 bg-slate-100 dark:bg-dark-700 hover:bg-slate-200 dark:hover:bg-dark-600 rounded-xl transition-all"
          title={theme === 'dark' ? 'Passer au mode Clair' : 'Passer au mode Sombre'}
          aria-label="Changer de thème"
        >
          {theme === 'dark' ? (
            <Sun className="w-4 h-4 text-amber-400 animate-fade-in" />
          ) : (
            <Moon className="w-4 h-4 text-slate-700 animate-fade-in" />
          )}
        </button>

        {/* User profile summary */}
        <div className="flex items-center gap-3 pl-3 pr-1 border-l border-[#E8EFF5] dark:border-dark-600">
          <div className="w-9 h-9 rounded-xl bg-brand-50 dark:bg-brand-500/15 flex items-center justify-center text-brand-600 dark:text-brand-400 border border-brand-200 dark:border-brand-500/30 font-bold">
            <UserIcon className="w-4 h-4" />
          </div>
          <div className="hidden sm:block">
            <div className="text-sm font-bold text-slate-900 dark:text-white leading-tight">
              {user?.full_name || user?.username}
            </div>
            <div className="text-xs text-slate-500 dark:text-slate-400 flex items-center gap-1 mt-0.5">
              <Shield className="w-3 h-3 text-brand-500" />
              <span className="font-medium text-brand-600 dark:text-brand-400">{roleLabel}</span>
            </div>
          </div>
        </div>

        {/* Logout button */}
        <button
          onClick={logout}
          className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-semibold text-slate-500 dark:text-slate-400 hover:text-rose-600 dark:hover:text-rose-400 hover:bg-rose-50 dark:hover:bg-rose-950/30 rounded-xl transition-all border border-transparent hover:border-rose-100 dark:hover:border-rose-900/50"
          title="Se déconnecter"
        >
          <LogOut className="w-4 h-4" />
          <span className="hidden sm:inline">Déconnexion</span>
        </button>
      </div>
    </header>
  );
};
