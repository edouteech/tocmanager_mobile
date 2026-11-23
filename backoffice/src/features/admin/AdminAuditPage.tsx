import React, { useEffect, useState } from 'react';
import { Search, ShieldAlert } from 'lucide-react';
import { adminApi } from '../../lib/api';
import { PlatformAuditItem } from '../../types';
import { useDensity } from '../../context/DensityContext';
import { formatDateTime } from '../../lib/formatters';

export const AdminAuditPage: React.FC = () => {
  const { tableClasses } = useDensity();
  const [items, setItems] = useState<PlatformAuditItem[]>([]);
  const [total, setTotal] = useState(0);
  const [action, setAction] = useState('');
  const [q, setQ] = useState('');
  const [loading, setLoading] = useState(true);

  const fetchLogs = () => {
    setLoading(true);
    adminApi
      .getAuditLogs({
        action: action.trim() || undefined,
        q: q.trim() || undefined,
        limit: 100,
      })
      .then((res) => {
        setItems(res.items);
        setTotal(res.total);
      })
      .catch(() => setItems([]))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    fetchLogs();
  }, [action]);

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      <div>
        <h1 className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">
          Journal d'Audit Plateforme ({total})
        </h1>
        <p className="text-xs sm:text-sm text-[#5A7184] dark:text-slate-400 mt-0.5">
          Historique des actions Super-Admin, webhooks FeexPay, impersonations support et contacts publics.
        </p>
      </div>

      <div className="card-toc p-4 flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1">
          <Search className="w-4 h-4 text-[#9FB3C8] absolute left-3.5 top-3" />
          <input
            type="text"
            value={q}
            onChange={(e) => setQ(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === 'Enter') fetchLogs();
            }}
            placeholder="Filtrer par admin, cible, action..."
            className="input-toc pl-10 text-xs"
          />
        </div>
        <select value={action} onChange={(e) => setAction(e.target.value)} className="input-toc sm:w-64 text-xs">
          <option value="">Toutes les actions</option>
          <option value="PLAN_UPDATE">PLAN_UPDATE</option>
          <option value="PLAN_CREATE">PLAN_CREATE</option>
          <option value="MANUAL_PLAN_CHANGE">MANUAL_PLAN_CHANGE</option>
          <option value="TRIAL_EXTEND">TRIAL_EXTEND</option>
          <option value="SUPPORT_IMPERSONATE_START">SUPPORT_IMPERSONATE_START</option>
          <option value="PAYMENT_PROVIDER_UPDATE">PAYMENT_PROVIDER_UPDATE</option>
          <option value="SUBSCRIPTION_PAYMENT_SUCCESS">SUBSCRIPTION_PAYMENT_SUCCESS</option>
          <option value="FEEXPAY_AMOUNT_MISMATCH">FEEXPAY_AMOUNT_MISMATCH</option>
          <option value="PUBLIC_CONTACT_MESSAGE">PUBLIC_CONTACT_MESSAGE</option>
        </select>
        <button type="button" onClick={fetchLogs} className="btn-primary text-xs">
          Filtrer
        </button>
      </div>

      <div className="card-toc overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse text-xs">
            <thead>
              <tr className="bg-[#F0F9FE] dark:bg-dark-700/60 border-b border-[#E8EFF5] dark:border-dark-600 text-[#5A7184]">
                <th className={tableClasses.th}>Date</th>
                <th className={tableClasses.th}>Action</th>
                <th className={tableClasses.th}>Acteur</th>
                <th className={tableClasses.th}>Cible</th>
                <th className={tableClasses.th}>Détails</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#E8EFF5] dark:divide-dark-600">
              {loading ? (
                <tr><td colSpan={5} className="py-10 text-center text-[#5A7184]">Chargement du journal...</td></tr>
              ) : items.length === 0 ? (
                <tr><td colSpan={5} className="py-10 text-center text-[#5A7184]">Aucun événement enregistré.</td></tr>
              ) : (
                items.map((log) => (
                  <tr key={log.id} className="hover:bg-[#F0F9FE]/40 dark:hover:bg-dark-700/40">
                    <td className={`${tableClasses.td} whitespace-nowrap`}>{formatDateTime(log.created_at)}</td>
                    <td className={tableClasses.td}>
                      <span className="badge-toc-primary font-mono text-[10px]">
                        <ShieldAlert className="w-3 h-3" /> {log.action}
                      </span>
                    </td>
                    <td className={tableClasses.td}>{log.admin_username || 'Système'}</td>
                    <td className={`${tableClasses.td} font-mono text-[11px]`}>
                      {log.target_entity || '-'} {log.target_id ? `• ${log.target_id.slice(0, 12)}` : ''}
                    </td>
                    <td className={`${tableClasses.td} max-w-md truncate font-mono text-[10px] text-[#5A7184]`}>
                      {log.details ? JSON.stringify(log.details) : '-'}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
