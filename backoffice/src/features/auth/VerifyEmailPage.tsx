import React, { useEffect, useState } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import { CheckCircle2, AlertCircle, MailCheck } from 'lucide-react';
import { authApi } from '../../lib/api';

export const VerifyEmailPage: React.FC = () => {
  const [params] = useSearchParams();
  const token = params.get('token') || '';
  const [status, setStatus] = useState<'loading' | 'success' | 'error'>(token ? 'loading' : 'error');
  const [message, setMessage] = useState(token ? 'Verification en cours...' : 'Jeton de verification manquant.');

  useEffect(() => {
    if (!token) return;
    authApi
      .verifyEmail(token)
      .then(() => {
        setStatus('success');
        setMessage('Votre adresse email a ete verifiee avec succes.');
      })
      .catch((err: unknown) => {
        const detail = (err as { response?: { data?: { detail?: string } } })?.response?.data?.detail;
        setStatus('error');
        setMessage(detail || 'Lien de verification invalide ou expire.');
      });
  }, [token]);

  return (
    <div className="min-h-screen bg-[#F5FAFD] dark:bg-dark-900 flex items-center justify-center p-6">
      <div className="w-full max-w-md bg-white dark:bg-dark-800 rounded-3xl shadow-soft p-8 border border-[#E8EFF5] dark:border-dark-600 text-center space-y-5">
        <div className="w-14 h-14 mx-auto rounded-2xl bg-[#E8F5FD] text-[#29ABE2] flex items-center justify-center">
          <MailCheck className="w-7 h-7" />
        </div>
        <h1 className="text-xl font-extrabold text-[#1C2B3A] dark:text-white">Verification Email</h1>
        <div
          className={`p-4 rounded-2xl text-xs font-medium flex items-center justify-center gap-2 ${
            status === 'success'
              ? 'bg-[#E8F8F0] text-[#27AE60]'
              : status === 'error'
              ? 'bg-[#FDEBE9] text-[#E74C3C]'
              : 'bg-slate-50 text-slate-600'
          }`}
        >
          {status === 'success' && <CheckCircle2 className="w-4 h-4 shrink-0" />}
          {status === 'error' && <AlertCircle className="w-4 h-4 shrink-0" />}
          <span>{message}</span>
        </div>
        <Link to="/login" className="block w-full py-3 btn-primary text-sm rounded-xl font-bold">
          Aller a la connexion
        </Link>
      </div>
    </div>
  );
};
