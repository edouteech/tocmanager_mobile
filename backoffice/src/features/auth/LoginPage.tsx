import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Lock, User, AlertCircle, ArrowRight, Sun, Moon, Store } from 'lucide-react';
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
    <div className="min-h-screen bg-[#F5FAFD] dark:bg-dark-900 flex items-center justify-center p-6 select-none transition-colors duration-300 relative">
      {/* Top right theme toggle */}
      <div className="absolute top-6 right-6">
        <button
          onClick={toggleTheme}
          className="p-2.5 rounded-xl bg-white dark:bg-dark-800 border border-[#E8EFF5] dark:border-dark-600 text-[#5A7184] dark:text-slate-300 shadow-soft hover:shadow-soft-md transition"
          title={theme === 'dark' ? 'Mode Clair' : 'Mode Sombre'}
        >
          {theme === 'dark' ? (
            <Sun className="w-4 h-4 text-amber-400" />
          ) : (
            <Moon className="w-4 h-4 text-[#1C2B3A]" />
          )}
        </button>
      </div>

      <div className="w-full max-w-md bg-white dark:bg-dark-800 rounded-3xl shadow-soft p-8 sm:p-10 border border-[#E8EFF5] dark:border-dark-600 animate-fade-in transition-colors duration-200">
        {/* Brand header calqué sur LoginScreen mobile */}
        <div className="text-center mb-8">
          <div className="flex justify-center mb-3">
            <div className="w-16 h-16 rounded-2xl bg-[#E8F5FD] dark:bg-[#29ABE2]/20 flex items-center justify-center text-[#29ABE2]">
              <Store className="w-8 h-8" />
            </div>
          </div>
          <h2 className="text-xl sm:text-2xl font-bold text-[#1C2B3A] dark:text-white tracking-tight">
            TocManager
          </h2>
          <p className="text-xs text-[#5A7184] dark:text-slate-400 mt-1">
            Portail d'Administration Central
          </p>
        </div>

        {/* Error Alert */}
        {errorMessage && (
          <div className="mb-6 p-3.5 bg-[#FDEBE9] dark:bg-[#E74C3C]/20 border border-[#E74C3C]/30 rounded-2xl flex items-start gap-3 text-[#E74C3C] text-xs animate-fade-in font-medium">
            <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
            <span>{errorMessage}</span>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-[#1C2B3A] dark:text-slate-300 mb-1.5">
              Identifiant ou Email
            </label>
            <div className="relative">
              <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-[#9FB3C8]">
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
            <label className="block text-xs font-bold uppercase tracking-wider text-[#1C2B3A] dark:text-slate-300 mb-1.5">
              Mot de passe
            </label>
            <div className="relative">
              <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-[#9FB3C8]">
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
            className="w-full mt-3 py-3 px-4 btn-primary font-bold text-sm rounded-xl transition flex items-center justify-center gap-2"
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

        <div className="mt-8 pt-5 border-t border-[#E8EFF5] dark:border-dark-600 text-center text-[11px] text-[#9FB3C8] font-medium">
          tocmanager v1.0.0
        </div>
      </div>
    </div>
  );
};
