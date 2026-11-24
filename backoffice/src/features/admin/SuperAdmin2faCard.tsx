import React, { useState } from 'react';
import { KeyRound, ShieldCheck, ShieldOff } from 'lucide-react';
import { authApi } from '../../lib/api';
import { useAuthStore } from '../../stores/authStore';

export const SuperAdmin2faCard: React.FC = () => {
  const user = useAuthStore((s) => s.user);
  const updateUser = useAuthStore((s) => s.updateUser);
  const [setupSecret, setSetupSecret] = useState<string | null>(null);
  const [otpauthUri, setOtpauthUri] = useState<string | null>(null);
  const [code, setCode] = useState('');
  const [disablePassword, setDisablePassword] = useState('');
  const [feedback, setFeedback] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const handleInitSetup = async () => {
    setBusy(true);
    setFeedback(null);
    try {
      const res = await authApi.setup2fa();
      setSetupSecret(res.secret);
      setOtpauthUri(res.otpauth_uri);
    } catch {
      setFeedback('Erreur lors de la generation du secret TOTP.');
    } finally {
      setBusy(false);
    }
  };

  const handleConfirm = async (e: React.FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setFeedback(null);
    try {
      const updated = await authApi.confirm2fa(code);
      updateUser(updated);
      setSetupSecret(null);
      setOtpauthUri(null);
      setCode('');
      setFeedback('Authentification 2FA activee.');
    } catch {
      setFeedback('Code TOTP invalide.');
    } finally {
      setBusy(false);
    }
  };

  const handleDisable = async (e: React.FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setFeedback(null);
    try {
      const updated = await authApi.disable2fa(disablePassword, code);
      updateUser(updated);
      setDisablePassword('');
      setCode('');
      setFeedback('Authentification 2FA desactivee.');
    } catch {
      setFeedback('Mot de passe ou code TOTP incorrect.');
    } finally {
      setBusy(false);
    }
  };

  const enabled = Boolean(user?.totp_enabled);

  return (
    <div className="card-toc p-6 space-y-4">
      <div className="flex items-center justify-between gap-4">
        <div className="flex items-center gap-2.5">
          <div className={`p-2 rounded-xl ${enabled ? 'bg-[#E8F8F0] text-[#27AE60]' : 'bg-[#FEF5E7] text-[#F39C12]'}`}>
            <KeyRound className="w-5 h-5" />
          </div>
          <div>
            <h3 className="font-bold text-base text-[#1C2B3A] dark:text-white">
              Securite Super-Admin (2FA TOTP)
            </h3>
            <p className="text-xs text-[#5A7184] dark:text-slate-400">
              {enabled ? '2FA active sur votre compte plateforme.' : 'Protection TOTP non activee.'}
            </p>
          </div>
        </div>
        {!enabled && !setupSecret && (
          <button type="button" onClick={handleInitSetup} disabled={busy} className="btn-primary text-xs">
            <ShieldCheck className="w-4 h-4" />
            <span>Activer la 2FA</span>
          </button>
        )}
      </div>

      {setupSecret && (
        <form onSubmit={handleConfirm} className="p-4 rounded-2xl bg-[#F5FAFD] dark:bg-dark-700 space-y-3 border border-[#E8EFF5]">
          <p className="text-xs text-[#1C2B3A] dark:text-slate-200 font-semibold">
            Cle TOTP a ajouter dans Google Authenticator / 1Password : <code className="font-mono text-[#1A8FBF]">{setupSecret}</code>
          </p>
          {otpauthUri && (
            <p className="text-[11px] text-[#5A7184] break-all font-mono">{otpauthUri}</p>
          )}
          <div className="flex flex-wrap gap-2">
            <input
              type="text"
              maxLength={6}
              required
              value={code}
              onChange={(e) => setCode(e.target.value)}
              placeholder="Code a 6 chiffres"
              className="input-toc px-3 py-2 text-xs font-mono"
            />
            <button type="submit" disabled={busy} className="btn-primary text-xs">Confirmer l'activation</button>
          </div>
        </form>
      )}

      {enabled && (
        <form onSubmit={handleDisable} className="flex flex-wrap items-center gap-2">
          <input
            type="password"
            required
            value={disablePassword}
            onChange={(e) => setDisablePassword(e.target.value)}
            placeholder="Mot de passe actuel"
            className="input-toc px-3 py-2 text-xs"
          />
          <input
            type="text"
            maxLength={6}
            required
            value={code}
            onChange={(e) => setCode(e.target.value)}
            placeholder="Code TOTP"
            className="input-toc px-3 py-2 text-xs font-mono w-32"
          />
          <button type="submit" disabled={busy} className="px-3 py-2 rounded-xl bg-[#FDEBE9] text-[#E74C3C] text-xs font-bold inline-flex items-center gap-1">
            <ShieldOff className="w-3.5 h-3.5" />
            <span>Desactiver 2FA</span>
          </button>
        </form>
      )}

      {feedback && <p className="text-xs font-semibold text-[#1A8FBF]">{feedback}</p>}
    </div>
  );
};
