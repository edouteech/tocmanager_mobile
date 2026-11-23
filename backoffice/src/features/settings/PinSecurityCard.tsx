import React, { useState } from 'react';
import { KeyRound, ShieldCheck, AlertCircle, CheckCircle2 } from 'lucide-react';
import { authApi } from '../../lib/api';
import { useAuthStore } from '../../stores/authStore';

export const PinSecurityCard: React.FC = () => {
  const { user, updateUser } = useAuthStore();
  const [currentPassword, setCurrentPassword] = useState('');
  const [pin, setPin] = useState('');
  const [confirmPin, setConfirmPin] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setSuccess(null);

    if (!currentPassword) {
      setError('Veuillez saisir votre mot de passe actuel.');
      return;
    }
    if (!/^\d{4}$|^\d{6}$/.test(pin)) {
      setError('Le code PIN doit contenir exactement 4 ou 6 chiffres.');
      return;
    }
    if (pin !== confirmPin) {
      setError('La confirmation du code PIN ne correspond pas.');
      return;
    }

    setLoading(true);
    try {
      const updatedUser = await authApi.setPin(currentPassword, pin);
      updateUser({ ...user, ...updatedUser, has_pin: true });
      setCurrentPassword('');
      setPin('');
      setConfirmPin('');
      setSuccess('Code PIN enregistré avec succès.');
    } catch (err: any) {
      setError(
        err.response?.data?.detail ||
          'Impossible de mettre à jour le code PIN. Vérifiez votre mot de passe.'
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <div id="security-pin" className="card-toc p-6 space-y-4">
      <div className="flex items-center justify-between pb-3 border-b border-[#E8EFF5] dark:border-dark-600">
        <div className="flex items-center gap-2.5 font-bold text-[#1C2B3A] dark:text-white text-base">
          <KeyRound className="w-5 h-5 text-[#29ABE2]" />
          <h2>Sécurité & Code PIN Caisse</h2>
        </div>
        <span className={user?.has_pin ? 'badge-toc-success' : 'badge-toc-warning'}>
          {user?.has_pin ? 'PIN configuré' : 'Non configuré'}
        </span>
      </div>

      <p className="text-xs text-[#5A7184] dark:text-slate-400">
        Définissez un code PIN à 4 ou 6 chiffres pour verrouiller rapidement l'écran de caisse. La modification du PIN révoque les anciens refresh tokens actifs.
      </p>

      {error && (
        <div className="p-3 rounded-xl bg-[#FDEBE9] dark:bg-[#E74C3C]/15 border border-[#E74C3C]/30 text-[#E74C3C] text-xs font-medium flex items-center gap-2">
          <AlertCircle className="w-4 h-4 shrink-0" />
          <span>{error}</span>
        </div>
      )}

      {success && (
        <div className="p-3 rounded-xl bg-[#E8F8F0] dark:bg-[#27AE60]/15 border border-[#27AE60]/30 text-[#27AE60] text-xs font-semibold flex items-center gap-2">
          <CheckCircle2 className="w-4 h-4 shrink-0" />
          <span>{success}</span>
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-4">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Mot de passe actuel *
            </label>
            <input
              type="password"
              required
              value={currentPassword}
              onChange={(e) => setCurrentPassword(e.target.value)}
              placeholder="Votre mot de passe"
              className="input-toc"
            />
          </div>
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Nouveau PIN (4 ou 6 chiffres) *
            </label>
            <input
              type="password"
              inputMode="numeric"
              maxLength={6}
              required
              value={pin}
              onChange={(e) => setPin(e.target.value.replace(/\D/g, ''))}
              placeholder="Ex: 1234"
              className="input-toc font-mono"
            />
          </div>
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Confirmer le PIN *
            </label>
            <input
              type="password"
              inputMode="numeric"
              maxLength={6}
              required
              value={confirmPin}
              onChange={(e) => setConfirmPin(e.target.value.replace(/\D/g, ''))}
              placeholder="Retapez le PIN"
              className="input-toc font-mono"
            />
          </div>
        </div>

        <div className="flex justify-end">
          <button type="submit" disabled={loading} className="btn-secondary text-xs">
            <ShieldCheck className="w-4 h-4 text-[#29ABE2]" />
            <span>{loading ? 'Enregistrement...' : user?.has_pin ? 'Modifier mon code PIN' : 'Activer mon code PIN'}</span>
          </button>
        </div>
      </form>
    </div>
  );
};
