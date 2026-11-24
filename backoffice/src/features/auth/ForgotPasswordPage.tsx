import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { Mail, ArrowLeft, CheckCircle2, AlertCircle } from 'lucide-react';
import { authApi } from '../../lib/api';

export const ForgotPasswordPage: React.FC = () => {
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [submittedMsg, setSubmittedMsg] = useState<string | null>(null);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email.trim()) return;
    setLoading(true);
    setErrorMsg(null);
    try {
      const res = await authApi.forgotPassword(email.trim());
      setSubmittedMsg(res.message);
    } catch {
      setErrorMsg('Impossible de traiter la demande pour le moment.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#F5FAFD] dark:bg-dark-900 flex items-center justify-center p-6">
      <div className="w-full max-w-md bg-white dark:bg-dark-800 rounded-3xl shadow-soft p-8 border border-[#E8EFF5] dark:border-dark-600 space-y-6">
        <div className="text-center space-y-2">
          <div className="w-14 h-14 mx-auto rounded-2xl bg-[#E8F5FD] text-[#29ABE2] flex items-center justify-center">
            <Mail className="w-7 h-7" />
          </div>
          <h1 className="text-xl font-extrabold text-[#1C2B3A] dark:text-white">Mot de passe oublie</h1>
          <p className="text-xs text-[#5A7184] dark:text-slate-400">
            Entrez l'adresse email de votre compte pour recevoir un lien de reinitialisation.
          </p>
        </div>

        {errorMsg && (
          <div className="p-3 bg-[#FDEBE9] text-[#E74C3C] rounded-xl text-xs flex items-center gap-2 font-medium">
            <AlertCircle className="w-4 h-4 shrink-0" />
            <span>{errorMsg}</span>
          </div>
        )}

        {submittedMsg ? (
          <div className="p-4 rounded-2xl bg-[#E8F8F0] text-[#27AE60] text-xs space-y-2 font-medium">
            <div className="flex items-center gap-2 font-bold">
              <CheckCircle2 className="w-4 h-4" />
              <span>Demande enregistree</span>
            </div>
            <p>{submittedMsg}</p>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-[#1C2B3A] dark:text-slate-300 mb-1.5">
                Adresse email
              </label>
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="vous@boutique.com"
                className="w-full px-4 py-2.5 input-toc text-sm"
              />
            </div>
            <button type="submit" disabled={loading} className="w-full py-3 btn-primary text-sm rounded-xl font-bold">
              {loading ? 'Envoi en cours...' : 'Envoyer le lien de reinitialisation'}
            </button>
          </form>
        )}

        <div className="text-center">
          <Link to="/login" className="inline-flex items-center gap-1.5 text-xs font-semibold text-[#5A7184] hover:text-[#29ABE2]">
            <ArrowLeft className="w-3.5 h-3.5" />
            <span>Retour a la connexion</span>
          </Link>
        </div>
      </div>
    </div>
  );
};
