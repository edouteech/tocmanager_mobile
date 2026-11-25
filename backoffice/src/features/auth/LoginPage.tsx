import React, { useState, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { Lock, User, AlertCircle, ArrowRight, Sun, Moon } from 'lucide-react';
import { authApi } from '../../lib/api';
import { AppSurface, TargetSurface, resolveAppSurface } from '../../lib/domainRouting';
import { useAuthStore } from '../../stores/authStore';
import { useTheme } from '../../context/ThemeContext';
import { BrandLogo } from '../../components/common/BrandLogo';
import { IconInput } from '../../components/common/IconInput';
import { SurfaceLink } from '../../components/common/SurfaceLink';
import { TwoFactorChallengeForm } from './TwoFactorChallengeForm';

interface SurfaceMismatchInfo {
  message: string;
  label: string;
  target: TargetSurface;
}

function getSurfaceMismatch(activeSurface: AppSurface, role: string): SurfaceMismatchInfo | null {
  if (activeSurface === 'admin' && role !== 'superadmin') {
    return {
      message: "Cet espace est réservé aux super-administrateurs. Connectez-vous sur l'espace client.",
      label: "Aller à l'espace client",
      target: 'app',
    };
  }
  if (activeSurface === 'app' && role === 'superadmin') {
    return {
      message: 'Un compte super-administrateur doit se connecter via la console dédiée.',
      label: 'Aller à la console Super-Admin',
      target: 'admin',
    };
  }
  return null;
}

export const LoginPage: React.FC<{ surface?: AppSurface }> = ({ surface }) => {
  const activeSurface = surface ?? resolveAppSurface();
  const navigate = useNavigate();
  const setAuth = useAuthStore((s) => s.setAuth);
  const { isAuthenticated, user } = useAuthStore();
  const { theme, toggleTheme } = useTheme();

  useEffect(() => {
    if (isAuthenticated && user && !getSurfaceMismatch(activeSurface, user.role)) {
      navigate(user.role === 'superadmin' ? '/admin' : '/', { replace: true });
    }
  }, [isAuthenticated, user, navigate, activeSurface]);

  const [usernameOrEmail, setUsernameOrEmail] = useState('');
  const [password, setPassword] = useState('');
  const [challengeToken, setChallengeToken] = useState<string | null>(null);
  const [challengeUser, setChallengeUser] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [mismatchLink, setMismatchLink] = useState<{ label: string; target: TargetSurface } | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!usernameOrEmail || !password) return;

    setIsLoading(true);
    setErrorMessage(null);
    setMismatchLink(null);

    try {
      const authData = await authApi.login({
        username_or_email: usernameOrEmail,
        password,
      });

      const mismatch = getSurfaceMismatch(activeSurface, authData.user.role);
      if (mismatch) {
        setMismatchLink({ label: mismatch.label, target: mismatch.target });
        setErrorMessage(mismatch.message);
        return;
      }

      if (authData.requires_2fa && authData.challenge_token) {
        setChallengeToken(authData.challenge_token);
        setChallengeUser(authData.user.username);
        return;
      }

      setAuth(authData);
      navigate(authData.user.role === 'superadmin' ? '/admin' : '/', { replace: true });
    } catch (err: unknown) {
      const detail = (err as { response?: { data?: { detail?: string } } })?.response?.data?.detail;
      setErrorMessage(detail || 'Identifiants incorrects ou serveur indisponible.');
    } finally {
      setIsLoading(false);
    }
  };

  const handleVerify2fa = async (code: string) => {
    if (!challengeToken) return;
    setIsLoading(true);
    setErrorMessage(null);
    setMismatchLink(null);
    try {
      const authData = await authApi.verify2faChallenge(challengeToken, code);
      const mismatch = getSurfaceMismatch(activeSurface, authData.user.role);
      if (mismatch) {
        setMismatchLink({ label: mismatch.label, target: mismatch.target });
        setErrorMessage(mismatch.message);
        setChallengeToken(null);
        return;
      }
      setAuth(authData);
      navigate(authData.user.role === 'superadmin' ? '/admin' : '/', { replace: true });
    } catch (err: unknown) {
      const detail = (err as { response?: { data?: { detail?: string } } })?.response?.data?.detail;
      setErrorMessage(detail || 'Code TOTP invalide ou expire.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#F5FAFD] dark:bg-dark-900 flex items-center justify-center p-6 select-none transition-colors duration-300 relative">
      <div className="absolute top-6 right-6">
        <button
          onClick={toggleTheme}
          className="p-2.5 rounded-xl bg-white dark:bg-dark-800 border border-[#E8EFF5] dark:border-dark-600 text-[#5A7184] dark:text-slate-300 shadow-soft hover:shadow-soft-md transition"
          title={theme === 'dark' ? 'Mode Clair' : 'Mode Sombre'}
        >
          {theme === 'dark' ? <Sun className="w-4 h-4 text-amber-400" /> : <Moon className="w-4 h-4 text-[#1C2B3A]" />}
        </button>
      </div>

      <div className="w-full max-w-md bg-white dark:bg-dark-800 rounded-3xl shadow-soft p-8 sm:p-10 border border-[#E8EFF5] dark:border-dark-600 animate-fade-in transition-colors duration-200">
        <div className="text-center mb-8">
          <div className="flex justify-center mb-3">
            <BrandLogo variant="full" size="lg" priority />
          </div>
          <h1 className="sr-only">TocManager</h1>
          <p className="text-xs text-[#5A7184] dark:text-slate-400 mt-1">
            {activeSurface === 'admin' ? 'Console Super-Administration' : "Portail d'Administration Central"}
          </p>
        </div>

        {errorMessage && (
          <div className="mb-6 p-3.5 bg-[#FDEBE9] dark:bg-[#E74C3C]/20 border border-[#E74C3C]/30 rounded-2xl flex items-start gap-3 text-[#E74C3C] text-xs animate-fade-in font-medium">
            <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
            <div className="space-y-1">
              <div>{errorMessage}</div>
              {mismatchLink && (
                <SurfaceLink
                  surface={mismatchLink.target}
                  to="/login"
                  className="inline-block font-bold underline"
                >
                  {mismatchLink.label}
                </SurfaceLink>
              )}
            </div>
          </div>
        )}

        {challengeToken ? (
          <TwoFactorChallengeForm
            username={challengeUser}
            isLoading={isLoading}
            onVerify={handleVerify2fa}
            onCancel={() => {
              setChallengeToken(null);
              setErrorMessage(null);
              setMismatchLink(null);
            }}
          />
        ) : (
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-[#1C2B3A] dark:text-slate-300 mb-1.5">
                Identifiant ou Email
              </label>
              <IconInput
                icon={<User className="w-4 h-4" />}
                type="text"
                required
                value={usernameOrEmail}
                onChange={(e) => setUsernameOrEmail(e.target.value)}
                placeholder="Ex: admin ou caissier1"
                className="text-sm font-medium"
              />
            </div>

            <div>
              <div className="flex items-center justify-between mb-1.5">
                <label className="block text-xs font-bold uppercase tracking-wider text-[#1C2B3A] dark:text-slate-300">
                  Mot de passe
                </label>
                <Link to="/forgot-password" className="text-xs font-semibold text-[#29ABE2] hover:underline">
                  Mot de passe oublie ?
                </Link>
              </div>
              <IconInput
                icon={<Lock className="w-4 h-4" />}
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="********"
                className="text-sm font-medium"
              />
            </div>

            <button
              type="submit"
              disabled={isLoading}
              className="w-full mt-3 py-3 px-4 btn-primary font-bold text-sm rounded-xl transition flex items-center justify-center gap-2"
            >
              {isLoading ? (
                <span>Connexion en cours...</span>
              ) : (
                <>
                  <span>Se connecter</span>
                  <ArrowRight className="w-4 h-4" />
                </>
              )}
            </button>
          </form>
        )}

        <div className="mt-8 pt-5 border-t border-[#E8EFF5] dark:border-dark-600 text-center text-[11px] text-[#9FB3C8] font-medium">
          tocmanager v1.0.0
        </div>
      </div>
    </div>
  );
};
