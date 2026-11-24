import React, { useState } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import { Lock, CheckCircle2, AlertCircle } from 'lucide-react';
import { authApi } from '../../lib/api';

export const ResetPasswordPage: React.FC = () => {
  const [params] = useSearchParams();
  const token = params.get('token') || '';
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [loading, setLoading] = useState(false);
  const [doneMsg, setDoneMsg] = useState<string | null>(null);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg(null);
    if (!token) {
      setErrorMsg('Jeton de reinitialisation manquant.');
      return;
    }
    if (password.length < 8) {
      setErrorMsg('Le nouveau mot de passe doit contenir au moins 8 caracteres.');
      return;
    }
    if (password !== confirm) {
      setErrorMsg('Les mots de passe ne correspondent pas.');
      return;
    }
    setLoading(true);
    try {
      const res = await authApi.resetPassword(token, password);
      setDoneMsg(res.message);
    } catch (err: unknown) {
      const detail = (err as { response?: { data?: { detail?: string } } })?.response?.data?.detail;
      setErrorMsg(detail || 'Jeton invalide ou expire.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#F5FAFD] dark:bg-dark-900 flex items-center justify-center p-6">
      <div className="w-full max-w-md bg-white dark:bg-dark-800 rounded-3xl shadow-soft p-8 border border-[#E8EFF5] dark:border-dark-600 space-y-6">
        <div className="text-center space-y-2">
          <div className="w-14 h-14 mx-auto rounded-2xl bg-[#E8F5FD] text-[#29ABE2] flex items-center justify-center">
            <Lock className="w-7 h-7" />
          </div>
          <h1 className="text-xl font-extrabold text-[#1C2B3A] dark:text-white">Nouveau mot de passe</h1>
        </div>

        {errorMsg && (
          <div className="p-3 bg-[#FDEBE9] text-[#E74C3C] rounded-xl text-xs flex items-center gap-2 font-medium">
            <AlertCircle className="w-4 h-4 shrink-0" />
            <span>{errorMsg}</span>
          </div>
        )}

        {doneMsg ? (
          <div className="space-y-4">
            <div className="p-4 rounded-2xl bg-[#E8F8F0] text-[#27AE60] text-xs font-medium flex items-center gap-2">
              <CheckCircle2 className="w-4 h-4 shrink-0" />
              <span>{doneMsg}</span>
            </div>
            <Link to="/login" className="block w-full py-3 btn-primary text-center text-sm rounded-xl font-bold">
              Se connecter
            </Link>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-[#1C2B3A] dark:text-slate-300 mb-1.5">
                Nouveau mot de passe (min 8 car.)
              </label>
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full px-4 py-2.5 input-toc text-sm"
              />
            </div>
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-[#1C2B3A] dark:text-slate-300 mb-1.5">
                Confirmer le mot de passe
              </label>
              <input
                type="password"
                required
                value={confirm}
                onChange={(e) => setConfirm(e.target.value)}
                className="w-full px-4 py-2.5 input-toc text-sm"
              />
            </div>
            <button type="submit" disabled={loading} className="w-full py-3 btn-primary text-sm rounded-xl font-bold">
              {loading ? 'Validation...' : 'Reinitialiser le mot de passe'}
            </button>
          </form>
        )}
      </div>
    </div>
  );
};
