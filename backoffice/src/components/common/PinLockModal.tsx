import React, { useState, useEffect, useCallback } from 'react';
import {
  Lock,
  Delete,
  RotateCcw,
  LogOut,
  AlertCircle,
  KeyRound,
  ShieldCheck,
} from 'lucide-react';
import { useAuthStore } from '../../stores/authStore';
import { authApi } from '../../lib/api';

export const PinLockModal: React.FC = () => {
  const { user, isPinLocked, unlockSession, logout } = useAuthStore();
  const [pin, setPin] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [shake, setShake] = useState(false);

  const handleDigit = useCallback((digit: string) => {
    setError(null);
    setPin((prev) => (prev.length < 6 ? prev + digit : prev));
  }, []);

  const handleDelete = useCallback(() => {
    setError(null);
    setPin((prev) => prev.slice(0, -1));
  }, []);

  const handleClear = useCallback(() => {
    setError(null);
    setPin('');
  }, []);

  const handleUnlock = useCallback(async (pinToVerify: string) => {
    if (!pinToVerify || pinToVerify.length < 4) {
      setError('Veuillez saisir un code PIN d\'au moins 4 chiffres.');
      setShake(true);
      setTimeout(() => setShake(false), 500);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      await authApi.verifyPin(pinToVerify);
      setPin('');
      unlockSession();
    } catch (err: any) {
      const msg = err.response?.data?.detail || 'Code PIN incorrect. Veuillez réessayer.';
      setError(msg);
      setPin('');
      setShake(true);
      setTimeout(() => setShake(false), 500);
    } finally {
      setIsLoading(false);
    }
  }, [unlockSession]);

  // Keyboard support (typing numbers, Backspace, Escape)
  useEffect(() => {
    if (!isPinLocked) return;

    const handleKeyDown = (e: KeyboardEvent) => {
      if (/^[0-9]$/.test(e.key)) {
        handleDigit(e.key);
      } else if (e.key === 'Backspace') {
        handleDelete();
      } else if (e.key === 'Escape') {
        handleClear();
      } else if (e.key === 'Enter') {
        handleUnlock(pin);
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isPinLocked, pin, handleDigit, handleDelete, handleClear, handleUnlock]);

  // Automatically attempt unlock when 4 or 6 digits entered
  useEffect(() => {
    if (pin.length === 4 && (!user?.has_pin || pin.length === 4)) {
      // If 4 digits entered, try or wait
    }
  }, [pin, user]);

  if (!isPinLocked || !user) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-950/80 backdrop-blur-md animate-fade-in">
      <div
        className={`w-full max-w-sm bg-white dark:bg-dark-800 rounded-3xl shadow-2xl border border-slate-200 dark:border-dark-600 p-6 flex flex-col items-center space-y-5 transition-transform ${
          shake ? 'animate-bounce' : ''
        }`}
      >
        {/* Header Icon & User */}
        <div className="relative">
          <div className="w-16 h-16 rounded-2xl bg-brand-500/10 text-brand-600 dark:text-brand-400 flex items-center justify-center shadow-inner">
            <Lock className="w-8 h-8" />
          </div>
          <div className="absolute -bottom-1 -right-1 w-6 h-6 rounded-full bg-emerald-500 border-2 border-white dark:border-dark-800 flex items-center justify-center text-white">
            <ShieldCheck className="w-3.5 h-3.5" />
          </div>
        </div>

        <div className="text-center space-y-1">
          <h3 className="text-lg font-extrabold text-slate-900 dark:text-white">
            Session Caisse Verrouillée
          </h3>
          <p className="text-xs text-slate-500 dark:text-slate-400">
            Utilisateur actif : <span className="font-bold text-slate-700 dark:text-slate-200">{user.full_name || user.username}</span>
          </p>
        </div>

        {/* PIN Indicators */}
        <div className="flex items-center gap-3 py-2">
          {[0, 1, 2, 3, 4, 5].map((index) => (
            <div
              key={index}
              className={`w-4 h-4 rounded-full border-2 transition-all duration-150 ${
                index < pin.length
                  ? 'bg-brand-600 border-brand-600 scale-110 shadow-sm'
                  : 'bg-transparent border-slate-300 dark:border-dark-500'
              }`}
            />
          ))}
        </div>

        {/* Error message */}
        {error && (
          <div className="flex items-center gap-1.5 text-xs text-rose-600 dark:text-rose-400 font-semibold px-3 py-1.5 bg-rose-50 dark:bg-rose-950/30 rounded-xl border border-rose-200 dark:border-rose-900/40">
            <AlertCircle className="w-3.5 h-3.5 shrink-0" />
            <span>{error}</span>
          </div>
        )}

        {/* Virtual Keypad (0-9, Clear, Backspace) */}
        <div className="grid grid-cols-3 gap-2.5 w-full pt-1">
          {['1', '2', '3', '4', '5', '6', '7', '8', '9'].map((digit) => (
            <button
              key={digit}
              type="button"
              onClick={() => handleDigit(digit)}
              className="h-14 rounded-2xl bg-slate-100 hover:bg-slate-200 dark:bg-dark-700 dark:hover:bg-dark-600 text-slate-900 dark:text-white text-xl font-bold font-mono transition-all active:scale-95 shadow-xs"
            >
              {digit}
            </button>
          ))}
          <button
            type="button"
            onClick={handleClear}
            className="h-14 rounded-2xl bg-slate-100/70 hover:bg-slate-200 dark:bg-dark-700/60 dark:hover:bg-dark-600 text-slate-500 dark:text-slate-400 flex items-center justify-center transition-all active:scale-95 text-xs font-bold"
          >
            <RotateCcw className="w-5 h-5" />
          </button>
          <button
            type="button"
            onClick={() => handleDigit('0')}
            className="h-14 rounded-2xl bg-slate-100 hover:bg-slate-200 dark:bg-dark-700 dark:hover:bg-dark-600 text-slate-900 dark:text-white text-xl font-bold font-mono transition-all active:scale-95 shadow-xs"
          >
            0
          </button>
          <button
            type="button"
            onClick={handleDelete}
            className="h-14 rounded-2xl bg-slate-100/70 hover:bg-slate-200 dark:bg-dark-700/60 dark:hover:bg-dark-600 text-slate-500 dark:text-slate-400 flex items-center justify-center transition-all active:scale-95"
          >
            <Delete className="w-5 h-5" />
          </button>
        </div>

        {/* Action Button: Déverrouiller */}
        <button
          type="button"
          onClick={() => handleUnlock(pin)}
          disabled={pin.length < 4 || isLoading}
          className="w-full btn-toc btn-primary py-3 rounded-2xl text-sm font-bold flex items-center justify-center gap-2 shadow-md shadow-brand-500/20 disabled:opacity-50"
        >
          <KeyRound className="w-4 h-4" />
          <span>{isLoading ? 'Vérification...' : 'Déverrouiller la caisse'}</span>
        </button>

        {/* Change user / logout */}
        <button
          type="button"
          onClick={logout}
          className="text-xs text-slate-500 hover:text-rose-600 dark:text-slate-400 dark:hover:text-rose-400 flex items-center gap-1.5 transition-colors pt-1"
        >
          <LogOut className="w-3.5 h-3.5" />
          <span>Changer d'utilisateur / Se déconnecter</span>
        </button>
      </div>
    </div>
  );
};
