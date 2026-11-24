import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { User, Mail, Lock, Phone, ArrowRight } from 'lucide-react';

interface RegisterStep1FormProps {
  fullName: string;
  setFullName: (v: string) => void;
  identifier: string;
  setIdentifier: (v: string) => void;
  phone: string;
  setPhone: (v: string) => void;
  password: string;
  setPassword: (v: string) => void;
  acceptTerms: boolean;
  setAcceptTerms: (v: boolean) => void;
  loading: boolean;
  onSubmit: (e: React.FormEvent) => void;
}

const getPasswordStrength = (pwd: string): { label: string; score: number; color: string } => {
  if (!pwd) return { label: '', score: 0, color: 'bg-slate-200 dark:bg-dark-600' };
  let score = 0;
  if (pwd.length >= 6) score += 1;
  if (pwd.length >= 10) score += 1;
  if (/[A-Z]/.test(pwd) && /[0-9]/.test(pwd)) score += 1;
  if (/[^A-Za-z0-9]/.test(pwd)) score += 1;

  if (score <= 1) return { label: 'Faible', score: 1, color: 'bg-[#E74C3C]' };
  if (score <= 2) return { label: 'Moyen', score: 2, color: 'bg-[#F39C12]' };
  return { label: 'Fort', score: Math.min(score, 4), color: 'bg-[#27AE60]' };
};

export const RegisterStep1Form: React.FC<RegisterStep1FormProps> = ({
  fullName,
  setFullName,
  identifier,
  setIdentifier,
  phone,
  setPhone,
  password,
  setPassword,
  acceptTerms,
  setAcceptTerms,
  loading,
  onSubmit,
}) => {
  const [showPwd, setShowPwd] = useState(false);
  const strength = getPasswordStrength(password);

  return (
    <form onSubmit={onSubmit} className="space-y-4">
      <div>
        <h2 className="text-lg font-bold text-[#1C2B3A] dark:text-white">Créez vos identifiants</h2>
        <p className="text-xs text-[#5A7184] dark:text-slate-400 mt-0.5">
          Quelques secondes suffisent pour créer votre compte gérant.
        </p>
      </div>

      <div>
        <label className="block text-xs font-semibold text-[#1C2B3A] dark:text-slate-300 mb-1">
          Nom complet *
        </label>
        <div className="relative">
          <User className="w-4 h-4 text-[#9FB3C8] absolute left-3 top-3" />
          <input
            type="text"
            required
            placeholder="Ex: Amadou Diallo"
            value={fullName}
            onChange={(e) => setFullName(e.target.value)}
            className="input-toc pl-9"
          />
        </div>
      </div>

      <div>
        <label className="block text-xs font-semibold text-[#1C2B3A] dark:text-slate-300 mb-1">
          Email ou Identifiant de connexion *
        </label>
        <div className="relative">
          <Mail className="w-4 h-4 text-[#9FB3C8] absolute left-3 top-3" />
          <input
            type="text"
            required
            placeholder="amadou@boutique.com"
            value={identifier}
            onChange={(e) => setIdentifier(e.target.value)}
            className="input-toc pl-9"
          />
        </div>
      </div>

      <div>
        <label className="block text-xs font-semibold text-[#1C2B3A] dark:text-slate-300 mb-1">
          Numéro de téléphone mobile
        </label>
        <div className="relative">
          <Phone className="w-4 h-4 text-[#9FB3C8] absolute left-3 top-3" />
          <input
            type="tel"
            placeholder="+221 77 000 00 00"
            value={phone}
            onChange={(e) => setPhone(e.target.value)}
            className="input-toc pl-9"
          />
        </div>
      </div>

      <div>
        <div className="flex items-center justify-between mb-1">
          <label className="block text-xs font-semibold text-[#1C2B3A] dark:text-slate-300">
            Mot de passe secret *
          </label>
          {strength.label && (
            <span className="text-[11px] font-semibold text-[#5A7184] dark:text-slate-300">
              Robustesse : {strength.label}
            </span>
          )}
        </div>
        <div className="relative">
          <Lock className="w-4 h-4 text-[#9FB3C8] absolute left-3 top-3" />
          <input
            type={showPwd ? 'text' : 'password'}
            required
            placeholder="Minimum 6 caractères"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="input-toc pl-9 pr-16"
          />
          <button
            type="button"
            onClick={() => setShowPwd((v) => !v)}
            className="absolute right-3 top-2.5 text-[11px] font-semibold text-[#29ABE2] hover:text-[#1A8FBF]"
          >
            {showPwd ? 'Masquer' : 'Afficher'}
          </button>
        </div>
        {password && (
          <div className="grid grid-cols-4 gap-1 mt-2">
            {[1, 2, 3, 4].map((bar) => (
              <div
                key={bar}
                className={`h-1 rounded-full transition-colors ${
                  bar <= strength.score ? strength.color : 'bg-slate-200 dark:bg-dark-600'
                }`}
              />
            ))}
          </div>
        )}
      </div>

      <label className="flex items-start gap-2.5 text-xs text-[#5A7184] dark:text-slate-300 cursor-pointer pt-1">
        <input
          type="checkbox"
          checked={acceptTerms}
          onChange={(e) => setAcceptTerms(e.target.checked)}
          className="mt-0.5 rounded border-slate-300 text-[#29ABE2] focus:ring-[#29ABE2]"
        />
        <span>
          J'accepte les{' '}
          <Link
            to="/cgu"
            target="_blank"
            rel="noopener noreferrer"
            className="text-[#29ABE2] font-semibold hover:underline"
          >
            Conditions Générales d'Utilisation
          </Link>{' '}
          et la{' '}
          <Link
            to="/confidentialite"
            target="_blank"
            rel="noopener noreferrer"
            className="text-[#29ABE2] font-semibold hover:underline"
          >
            politique de confidentialité
          </Link>{' '}
          de TocManager.
        </span>
      </label>

      <div className="pt-2">
        <button type="submit" disabled={loading} className="w-full btn-primary py-3">
          {loading ? (
            <span>Création du profil...</span>
          ) : (
            <>
              <span>Continuer vers mon Entreprise</span>
              <ArrowRight className="w-4 h-4" />
            </>
          )}
        </button>
      </div>

      <div className="text-center text-xs text-[#5A7184] dark:text-slate-400 pt-2">
        Vous avez déjà un compte ?{' '}
        <Link to="/login" className="text-[#29ABE2] font-semibold hover:underline">
          Connectez-vous ici
        </Link>
      </div>
    </form>
  );
};
