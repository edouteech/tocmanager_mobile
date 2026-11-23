import React, { useEffect, useState } from 'react';
import { CreditCard, Settings, Receipt } from 'lucide-react';
import { adminApi } from '../../lib/api';
import { AdminSubscriptionsResponse } from '../../types';
import { useDensity } from '../../context/DensityContext';
import { formatDateTime } from '../../lib/formatters';
import { FeexPayConfigTab } from './FeexPayConfigTab';

export const AdminSubscriptionsPage: React.FC = () => {
  const { tableClasses } = useDensity();
  const [tab, setTab] = useState<'subscriptions' | 'transactions' | 'feexpay'>('subscriptions');
  const [data, setData] = useState<AdminSubscriptionsResponse | null>(null);
  const [txStatus, setTxStatus] = useState('');
  const [loading, setLoading] = useState(true);

  const loadData = () => {
    setLoading(true);
    adminApi
      .getSubscriptions({ tx_status: txStatus || undefined, limit: 50 })
      .then(setData)
      .catch(() => setData(null))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    if (tab !== 'feexpay') loadData();
  }, [tab, txStatus]);

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">
            Abonnements, Transactions & FeexPay
          </h1>
          <p className="text-xs sm:text-sm text-[#5A7184] dark:text-slate-400 mt-0.5">
            Suivez les souscriptions actives, paiements Mobile Money et identifiants FeexPay.
          </p>
        </div>

        <div className="inline-flex rounded-xl bg-white dark:bg-dark-800 p-1 border border-[#E8EFF5] dark:border-dark-600 text-xs font-semibold">
          <button
            type="button"
            onClick={() => setTab('subscriptions')}
            className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg ${tab === 'subscriptions' ? 'bg-[#29ABE2] text-white' : 'text-[#5A7184]'}`}
          >
            <Receipt className="w-3.5 h-3.5" />
            <span>Abonnements ({data?.total ?? 0})</span>
          </button>
          <button
            type="button"
            onClick={() => setTab('transactions')}
            className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg ${tab === 'transactions' ? 'bg-[#29ABE2] text-white' : 'text-[#5A7184]'}`}
          >
            <CreditCard className="w-3.5 h-3.5" />
            <span>Transactions ({data?.transactions_total ?? 0})</span>
          </button>
          <button
            type="button"
            onClick={() => setTab('feexpay')}
            className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg ${tab === 'feexpay' ? 'bg-[#29ABE2] text-white' : 'text-[#5A7184]'}`}
          >
            <Settings className="w-3.5 h-3.5" />
            <span>Config FeexPay</span>
          </button>
        </div>
      </div>

      {tab === 'feexpay' ? (
        <FeexPayConfigTab />
      ) : tab === 'subscriptions' ? (
        <div className="card-toc overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse text-xs">
              <thead>
                <tr className="bg-[#F0F9FE] dark:bg-dark-700/60 border-b border-[#E8EFF5] dark:border-dark-600 text-[#5A7184]">
                  <th className={tableClasses.th}>Boutique</th>
                  <th className={tableClasses.th}>Forfait</th>
                  <th className={tableClasses.th}>Cycle</th>
                  <th className={tableClasses.th}>Statut</th>
                  <th className={tableClasses.th}>Fin période / essai</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#E8EFF5] dark:divide-dark-600">
                {loading ? (
                  <tr><td colSpan={5} className="py-10 text-center text-[#5A7184]">Chargement...</td></tr>
                ) : (data?.items || []).map((s) => (
                  <tr key={s.id} className="hover:bg-[#F0F9FE]/40 dark:hover:bg-dark-700/40">
                    <td className={`${tableClasses.td} font-bold`}>{s.boutique_name}</td>
                    <td className={tableClasses.td}>{s.plan_name} ({s.plan_code})</td>
                    <td className={`${tableClasses.td} capitalize`}>{s.billing_cycle}</td>
                    <td className={tableClasses.td}>
                      <span className={s.status === 'active' ? 'badge-toc-success' : s.status === 'trialing' ? 'badge-toc-warning' : 'badge-toc-danger'}>
                        {s.status}
                      </span>
                    </td>
                    <td className={tableClasses.td}>{formatDateTime(s.trial_ends_at || s.current_period_end || '')}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      ) : (
        <div className="space-y-3">
          <div className="flex justify-end">
            <select value={txStatus} onChange={(e) => setTxStatus(e.target.value)} className="input-toc w-52 text-xs">
              <option value="">Tous statuts paiement</option>
              <option value="successful">successful</option>
              <option value="pending">pending</option>
              <option value="failed">failed</option>
              <option value="amount_mismatch">amount_mismatch</option>
            </select>
          </div>
          <div className="card-toc overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse text-xs">
                <thead>
                  <tr className="bg-[#F0F9FE] dark:bg-dark-700/60 border-b border-[#E8EFF5] dark:border-dark-600 text-[#5A7184]">
                    <th className={tableClasses.th}>Référence</th>
                    <th className={tableClasses.th}>Boutique</th>
                    <th className={tableClasses.th}>Forfait / Réseau</th>
                    <th className={tableClasses.th}>Montant</th>
                    <th className={tableClasses.th}>Statut</th>
                    <th className={tableClasses.th}>Date</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-[#E8EFF5] dark:divide-dark-600">
                  {loading ? (
                    <tr><td colSpan={6} className="py-10 text-center text-[#5A7184]">Chargement...</td></tr>
                  ) : (data?.transactions || []).length === 0 ? (
                    <tr><td colSpan={6} className="py-10 text-center text-[#5A7184]">Aucune transaction FeexPay.</td></tr>
                  ) : (data?.transactions || []).map((tx) => (
                    <tr key={tx.id} className="hover:bg-[#F0F9FE]/40 dark:hover:bg-dark-700/40">
                      <td className={`${tableClasses.td} font-mono font-bold`}>{tx.reference}</td>
                      <td className={tableClasses.td}>{tx.boutique_name}</td>
                      <td className={tableClasses.td}>{tx.plan_name} • {tx.network}</td>
                      <td className={`${tableClasses.td} font-mono font-bold`}>{tx.amount.toLocaleString('fr-FR')} {tx.currency}</td>
                      <td className={tableClasses.td}>
                        <span className={tx.status === 'successful' ? 'badge-toc-success' : tx.status === 'pending' ? 'badge-toc-warning' : 'badge-toc-danger'}>
                          {tx.status}
                        </span>
                      </td>
                      <td className={tableClasses.td}>{formatDateTime(tx.created_at)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
