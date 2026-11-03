import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Lock, User, AlertCircle, ArrowRight, Sun, Moon } from 'lucide-react';
import { api } from '../../lib/api';
import { useAuthStore } from '../../stores/authStore';
import { useTheme } from '../../context/ThemeContext';

export const LoginPage: React.FC = () => {
  const navigate = useNavigate();
  const setAuth = useAuthStore((s) => s.setAuth);
  const { theme, toggleTheme } = useTheme();

  const [usernameOrEmail, setUsernameOrEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!usernameOrEmail || !password) return;

    setIsLoading(true);
    setErrorMessage(null);

    try {
      const response = await api.post('/auth/login', {
        username_or_email: usernameOrEmail,
        password: password,
      });

      setAuth(response.data);
      navigate('/');
    } catch (err: any) {
      const msg =
        err.response?.data?.detail ||
        "Identifiants incorrects ou serveur indisponible.";
      setErrorMessage(msg);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#F5FAFD] via-[#E8F5FD] to-[#DDF1FB] dark:from-dark-900 dark:via-dark-800 dark:to-dark-900 flex items-center justify-center p-6 select-none transition-colors duration-300 relative">
      {/* Top right theme toggle */}
      <div className="absolute top-6 right-6">
        <button
          onClick={toggleTheme}
          className="p-2.5 rounded-xl bg-white/80 dark:bg-dark-800/80 border border-slate-200 dark:border-dark-600 text-slate-600 dark:text-slate-300 shadow-soft hover:shadow-soft-md transition"
          title={theme === 'dark' ? 'Mode Clair' : 'Mode Sombre'}
        >
          {theme === 'dark' ? (
            <Sun className="w-4 h-4 text-amber-400" />
          ) : (
            <Moon className="w-4 h-4 text-slate-700" />
          )}
        </button>
      </div>

      <div className="w-full max-w-md bg-white dark:bg-dark-800 rounded-3xl shadow-soft-lg p-8 sm:p-10 border border-[#E8EFF5] dark:border-dark-600 animate-fade-in transition-colors duration-200">
        {/* Brand header with real logo */}
        <div className="text-center mb-8">
          <div className="flex justify-center mb-4">
            <img
              src="/assets/logo.png"
              alt="TocManager"
              className="h-12 w-auto max-w-[200px] object-contain drop-shadow-sm"
              onError={(e) => {
                (e.target as HTMLImageElement).src = '/assets/icon.png';
              }}
            />
          </div>
          <p className="text-xs font-semibold text-brand-600 dark:text-brand-400 uppercase tracking-wider">
            Portail d'Administration Central
          </p>
        </div>

        {/* Error Alert */}
        {errorMessage && (
          <div className="mb-6 p-3.5 bg-rose-50 dark:bg-rose-950/40 border border-rose-200 dark:border-rose-900/50 rounded-2xl flex items-start gap-3 text-rose-700 dark:text-rose-300 text-sm animate-fade-in">
            <AlertCircle className="w-5 h-5 shrink-0 mt-0.5 text-rose-600 dark:text-rose-400" />
            <span className="font-medium text-xs">{errorMessage}</span>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-5">
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Identifiant ou Email
            </label>
            <div className="relative">
              <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-slate-400">
                <User className="w-4 h-4" />
              </div>
              <input
                type="text"
                required
                value={usernameOrEmail}
                onChange={(e) => setUsernameOrEmail(e.target.value)}
                placeholder="Ex: admin ou caissier1"
                className="w-full pl-10 pr-4 py-2.5 input-toc text-sm font-medium"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Mot de passe
            </label>
            <div className="relative">
              <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-slate-400">
                <Lock className="w-4 h-4" />
              </div>
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full pl-10 pr-4 py-2.5 input-toc text-sm font-medium"
              />
            </div>
          </div>

          <button
            type="submit"
            disabled={isLoading}
            className="w-full mt-3 py-3 px-4 btn-primary font-bold text-sm rounded-xl shadow-md transition flex items-center justify-center gap-2 disabled:opacity-50"
          >
            {isLoading ? (
              <span className="inline-flex items-center gap-2">
                <span className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin"></span>
                <span>Connexion en cours...</span>
              </span>
            ) : (
              <>
                <span>Se connecter</span>
                <ArrowRight className="w-4 h-4" />
              </>
            )}
          </button>
        </form>

        <div className="mt-8 pt-6 border-t border-[#E8EFF5] dark:border-dark-600 text-center text-xs text-slate-400 dark:text-slate-500 font-medium">
          Plateforme synchronisée pour caisses tactiles et terminaux mobiles
        </div>
      </div>
    </div>
  );
};
