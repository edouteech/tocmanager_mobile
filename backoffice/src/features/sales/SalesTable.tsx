import React from 'react';
import { CreditCard, FileText, Share2, ShoppingBag } from 'lucide-react';
import { Vente } from '../../types';
import { formatFCFA, formatDateTime } from '../../lib/formatters';
import { useDensity } from '../../context/DensityContext';

interface SalesTableProps {
  ventes: Vente[];
  onSelect: (vente: Vente) => void;
  onShareWhatsApp: (vente: Vente) => void;
}

export const SalesTable: React.FC<SalesTableProps> = ({
  ventes,
  onSelect,
  onShareWhatsApp,
}) => {
  const { tableClasses } = useDensity();

  return (
    <div className="card-toc overflow-hidden">
      <div className="overflow-x-auto">
        <table className="w-full text-left min-w-[700px]">
          <thead className="bg-[#F5FAFD] dark:bg-dark-700/50 border-b border-[#E8EFF5] dark:border-dark-600">
            <tr>
              <th className={tableClasses.th}>Numéro Ticket</th>
              <th className={tableClasses.th}>Client</th>
              <th className={tableClasses.th}>Articles</th>
              <th className={tableClasses.th}>Mode Paiement</th>
              <th className={tableClasses.th}>Date & Heure</th>
              <th className={`${tableClasses.th} text-right`}>Montant Total</th>
              <th className={`${tableClasses.th} text-center`}>Action</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-[#E8EFF5] dark:divide-dark-600/60">
            {ventes.map((v) => (
              <tr
                key={v.sync_id}
                className="hover:bg-brand-50/30 dark:hover:bg-dark-700/40 transition-colors cursor-pointer"
                onClick={() => onSelect(v)}
              >
                <td className={`${tableClasses.td} font-mono font-bold text-brand-600 dark:text-brand-400`}>
                  {v.ticket_number}
                </td>
                <td className={`${tableClasses.td} font-semibold text-slate-900 dark:text-white`}>
                  {v.client_name || 'Occasionnel'}
                </td>
                <td className={`${tableClasses.td} text-slate-500 dark:text-slate-400`}>
                  <span className="inline-flex items-center gap-1">
                    <ShoppingBag className="w-3.5 h-3.5 text-brand-500" />
                    {v.items?.length || 0} article(s)
                  </span>
                </td>
                <td className={tableClasses.td}>
                  <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-brand-50 dark:bg-brand-500/15 text-brand-600 dark:text-brand-400 border border-brand-200 dark:border-brand-500/30">
                    <CreditCard className="w-3 h-3 text-brand-500" />
                    {v.payment_method}
                  </span>
                </td>
                <td className={`${tableClasses.td} text-slate-500 dark:text-slate-400`}>
                  {formatDateTime(v.created_at)}
                </td>
                <td className={`${tableClasses.td} text-right font-extrabold text-slate-900 dark:text-white font-mono`}>
                  {formatFCFA(v.total_amount)}
                </td>
                <td className={`${tableClasses.td} text-center`} onClick={(e) => e.stopPropagation()}>
                  <div className="flex items-center justify-center gap-1.5">
                    <button
                      onClick={() => onShareWhatsApp(v)}
                      className="p-1.5 text-slate-400 hover:text-emerald-600 hover:bg-emerald-50 rounded-xl transition"
                      title="WhatsApp"
                    >
                      <Share2 className="w-3.5 h-3.5" />
                    </button>
                    <button
                      onClick={() => onSelect(v)}
                      className="inline-flex items-center gap-1 px-2.5 py-1 bg-brand-50 hover:bg-brand-100 dark:bg-brand-500/15 text-brand-700 dark:text-brand-300 rounded-xl text-xs font-bold transition-all border border-brand-200 dark:border-brand-500/30"
                    >
                      <FileText className="w-3.5 h-3.5" />
                      <span>Détails</span>
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};
