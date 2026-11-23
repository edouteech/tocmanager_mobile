import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Calculator, Lock, Unlock, History, CheckCircle2, AlertTriangle } from 'lucide-react';
import { cashSessionsApi } from '../../lib/api';
import { CashRegisterSession } from '../../types';
import { useTenantStore, useTenantContextKey } from '../../stores/tenantStore';
import { formatMoney, formatDateTime } from '../../lib/formatters';

export const CashSessionsPage: React.FC = () => {
  const queryClient = useQueryClient();
  const [boutiqueKey, magasinKey] = useTenantContextKey();
  const { magasins, currentMagasin, isConsolidatedView } = useTenantStore();

  const retailMagasins = magasins.filter((m) => m.is_active && !m.is_warehouse);
  const [openMagId, setOpenMagId] = useState<string>('');
  const [openingBalance, setOpeningBalance] = useState<number>(0);
  const [openNotes, setOpenNotes] = useState('');

  const [declaredCash, setDeclaredCash] = useState<number>(0);
  const [closeNotes, setCloseNotes] = useState('');
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const effectiveMagId =
    !isConsolidatedView && currentMagasin ? currentMagasin.id : openMagId || retailMagasins[0]?.id || '';

  const { data: currentSession, isLoading: loadingCurrent } = useQuery<CashRegisterSession | null>({
    queryKey: ['cash-session-current', boutiqueKey, magasinKey, effectiveMagId],
    queryFn: () => cashSessionsApi.getCurrent(effectiveMagId || undefined),
  });

  const { data: history = [], isLoading: loadingHistory } = useQuery<CashRegisterSession[]>({
    queryKey: ['cash-sessions-history', boutiqueKey, magasinKey],
    queryFn: () => cashSessionsApi.getAll(),
  });

  const openMutation = useMutation({
    mutationFn: cashSessionsApi.open,
    onSuccess: () => {
      setErrorMsg(null);
      setOpenNotes('');
      queryClient.invalidateQueries({ queryKey: ['cash-session-current'] });
      queryClient.invalidateQueries({ queryKey: ['cash-sessions-history'] });
    },
    onError: (err: any) => {
      setErrorMsg(err.response?.data?.detail || "Impossible d'ouvrir la caisse.");
    },
  });

  const closeMutation = useMutation({
    mutationFn: ({ id, declared_cash, notes }: { id: string; declared_cash: number; notes?: string }) =>
      cashSessionsApi.close(id, { declared_cash, notes }),
    onSuccess: () => {
      setErrorMsg(null);
      setCloseNotes('');
      queryClient.invalidateQueries({ queryKey: ['cash-session-current'] });
      queryClient.invalidateQueries({ queryKey: ['cash-sessions-history'] });
    },
    onError: (err: any) => {
      setErrorMsg(err.response?.data?.detail || 'Erreur lors de la clôture Z.');
    },
  });

  return (
    <div className="space-y-6 max-w-6xl mx-auto">
      <div>
        <h1 className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight flex items-center gap-2">
          <Calculator className="w-6 h-6 text-brand-500" />
          <span>Sessions de Caisse & Clôture Z</span>
        </h1>
        <p className="text-xs sm:text-sm text-[#5A7184] dark:text-slate-400 mt-0.5">
          Ouverture de caisse, suivi du fond de roulement et rapprochement Z journalier
        </p>
      </div>

      {errorMsg && (
        <div className="p-3 rounded-xl bg-rose-50 border border-rose-200 text-rose-700 text-xs font-semibold flex items-center gap-2">
          <AlertTriangle className="w-4 h-4 shrink-0" />
          <span>{errorMsg}</span>
        </div>
      )}

      {loadingCurrent ? (
        <div className="card-toc p-8 text-center text-xs text-slate-400">Chargement session...</div>
      ) : currentSession ? (
        <div className="card-toc p-6 space-y-4 border-l-4 border-l-emerald-500">
          <div className="flex flex-wrap items-center justify-between gap-3">
            <div>
              <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-emerald-100 text-emerald-800">
                <Unlock className="w-3 h-3" /> CAISSE OUVERTE
              </span>
              <h2 className="text-lg font-extrabold text-slate-900 dark:text-white mt-1">
                {currentSession.magasin_name || currentSession.magasin_id}
              </h2>
              <p className="text-xs text-slate-500">
                Ouverte le {formatDateTime(currentSession.opened_at)} • Fond initial :{' '}
                <strong className="font-mono">{formatMoney(currentSession.opening_balance)}</strong>
              </p>
            </div>
          </div>

          <form
            onSubmit={(e) => {
              e.preventDefault();
              closeMutation.mutate({
                id: currentSession.id,
                declared_cash: declaredCash,
                notes: closeNotes.trim() || undefined,
              });
            }}
            className="grid grid-cols-1 md:grid-cols-3 gap-3 pt-3 border-t border-slate-100 dark:border-dark-600 text-xs items-end"
          >
            <div>
              <label className="block font-bold mb-1">Espèces comptées en tiroir *</label>
              <input
                type="number"
                min="0"
                required
                value={declaredCash}
                onChange={(e) => setDeclaredCash(Number(e.target.value) || 0)}
                className="input-toc font-mono font-bold"
              />
            </div>
            <div>
              <label className="block font-bold mb-1">Observations Z (optionnel)</label>
              <input
                type="text"
                placeholder="Billets, écarts constatés..."
                value={closeNotes}
                onChange={(e) => setCloseNotes(e.target.value)}
                className="input-toc"
              />
            </div>
            <button
              type="submit"
              disabled={closeMutation.isPending}
              className="btn-primary flex items-center justify-center gap-1.5 py-2.5"
            >
              <Lock className="w-4 h-4" />
              <span>{closeMutation.isPending ? 'Clôture...' : 'Clôturer la caisse (Z)'}</span>
            </button>
          </form>
        </div>
      ) : (
        <div className="card-toc p-6 space-y-4">
          <h2 className="text-sm font-extrabold text-slate-900 dark:text-white">Ouvrir une nouvelle session de caisse</h2>
          <form
            onSubmit={(e) => {
              e.preventDefault();
              openMutation.mutate({
                magasin_id: effectiveMagId || undefined,
                opening_balance: openingBalance,
                notes: openNotes.trim() || undefined,
              });
            }}
            className="grid grid-cols-1 md:grid-cols-3 gap-3 text-xs items-end"
          >
            <div>
              <label className="block font-bold mb-1">Point de vente *</label>
              <select
                value={effectiveMagId}
                onChange={(e) => setOpenMagId(e.target.value)}
                disabled={!isConsolidatedView && Boolean(currentMagasin)}
                className="input-toc bg-white dark:bg-dark-700"
              >
                {retailMagasins.map((m) => (
                  <option key={m.id} value={m.id}>{m.name}</option>
                ))}
              </select>
            </div>
            <div>
              <label className="block font-bold mb-1">Fond de caisse initial *</label>
              <input
                type="number"
                min="0"
                required
                value={openingBalance}
                onChange={(e) => setOpeningBalance(Number(e.target.value) || 0)}
                className="input-toc font-mono font-bold"
              />
            </div>
            <button
              type="submit"
              disabled={openMutation.isPending || !effectiveMagId}
              className="btn-primary flex items-center justify-center gap-1.5 py-2.5"
            >
              <CheckCircle2 className="w-4 h-4" />
              <span>{openMutation.isPending ? 'Ouverture...' : 'Ouvrir la caisse'}</span>
            </button>
          </form>
        </div>
      )}

      <div className="card-toc overflow-x-auto">
        <div className="px-5 py-3.5 border-b border-slate-100 dark:border-dark-600 flex items-center gap-2 text-xs font-extrabold uppercase text-slate-500">
          <History className="w-4 h-4 text-brand-500" />
          <span>Historique des Clôtures Z</span>
        </div>
        {loadingHistory ? (
          <div className="p-10 text-center text-xs text-slate-400">Chargement...</div>
        ) : history.length === 0 ? (
          <div className="p-10 text-center text-xs text-slate-400">Aucune session enregistrée.</div>
        ) : (
          <table className="w-full text-left text-xs">
            <thead className="bg-slate-50 dark:bg-dark-700/60 border-b border-slate-200 dark:border-dark-600 text-[11px] uppercase text-slate-500">
              <tr>
                <th className="py-3 px-4">Magasin</th>
                <th className="py-3 px-4">Ouverture</th>
                <th className="py-3 px-4">Statut</th>
                <th className="py-3 px-4 text-right">Fond Initial</th>
                <th className="py-3 px-4 text-right">Attendu Esp.</th>
                <th className="py-3 px-4 text-right">Déclaré Esp.</th>
                <th className="py-3 px-4 text-right">Écart</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 dark:divide-dark-600">
              {history.map((s) => (
                <tr key={s.id}>
                  <td className="py-2.5 px-4 font-bold">{s.magasin_name || s.magasin_id}</td>
                  <td className="py-2.5 px-4 text-slate-500">{formatDateTime(s.opened_at)}</td>
                  <td className="py-2.5 px-4">
                    <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold ${s.status === 'open' ? 'bg-emerald-100 text-emerald-700' : 'bg-slate-100 text-slate-700'}`}>
                      {s.status === 'open' ? 'OUVERTE' : 'CLÔTURÉE'}
                    </span>
                  </td>
                  <td className="py-2.5 px-4 text-right font-mono">{formatMoney(s.opening_balance)}</td>
                  <td className="py-2.5 px-4 text-right font-mono">{s.expected_cash != null ? formatMoney(s.expected_cash) : '-'}</td>
                  <td className="py-2.5 px-4 text-right font-mono">{s.declared_cash != null ? formatMoney(s.declared_cash) : '-'}</td>
                  <td className={`py-2.5 px-4 text-right font-mono font-bold ${(s.discrepancy || 0) < 0 ? 'text-rose-600' : 'text-emerald-600'}`}>
                    {s.discrepancy != null ? formatMoney(s.discrepancy) : '-'}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
};
