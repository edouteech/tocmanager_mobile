import React, { useState } from 'react';
import { ShieldCheck, ArrowRight, ArrowLeft } from 'lucide-react';

interface TwoFactorChallengeFormProps {
  username: string;
  isLoading: boolean;
  onVerify: (code: string) => Promise<void>;
  onCancel: () => void;
}

export const TwoFactorChallengeForm: React.FC<TwoFactorChallengeFormProps> = ({
  username,
  isLoading,
  onVerify,
  onCancel,
}) => {
  const [code, setCode] = useState('');

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!code.trim()) return;
    await onVerify(code.trim());
  };

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <div className="p-3.5 rounded-2xl bg-[#E8F5FD] dark:bg-[#29ABE2]/15 border border-[#29ABE2]/30 flex items-center gap-3 text-xs text-[#1A8FBF] dark:text-[#29ABE2]">
        <ShieldCheck className="w-5 h-5 shrink-0" />
        <div>
          <p className="font-bold">Validation 2FA Super-Administrateur</p>
          <p className="opacity-85">Saisissez le code a 6 chiffres genere pour {username}.</p>
        </div>
      </div>

      <div>
        <label className="block text-xs font-bold uppercase tracking-wider text-[#1C2B3A] dark:text-slate-300 mb-1.5">
          Code TOTP (6 chiffres)
        </label>
        <input
          type="text"
          inputMode="numeric"
          autoComplete="one-time-code"
          maxLength={6}
          required
          value={code}
          onChange={(e) => setCode(e.target.value.replace(/\D/g, '').slice(0, 6))}
          placeholder="000000"
          className="w-full px-4 py-3 input-toc text-center font-mono text-lg tracking-[0.4em] font-bold"
        />
      </div>

      <button
        type="submit"
        disabled={isLoading || code.length < 6}
        className="w-full py-3 px-4 btn-primary font-bold text-sm rounded-xl transition flex items-center justify-center gap-2 disabled:opacity-50"
      >
        <span>{isLoading ? 'Verification...' : 'Valider le code 2FA'}</span>
        <ArrowRight className="w-4 h-4" />
      </button>

      <button
        type="button"
        onClick={onCancel}
        className="w-full py-2 text-xs font-semibold text-[#5A7184] hover:text-[#1C2B3A] dark:text-slate-400 inline-flex items-center justify-center gap-1"
      >
        <ArrowLeft className="w-3.5 h-3.5" />
        <span>Revenir a la connexion</span>
      </button>
    </form>
  );
};
