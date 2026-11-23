import React from 'react';
import { Calendar, Truck, CheckCircle2, Clock, UserCheck } from 'lucide-react';
import { Approvisionnement } from '../../types';
import { formatFCFA, formatDateTime } from '../../lib/formatters';
import { useDensity } from '../../context/DensityContext';

interface SuppliesTableProps {
  supplies: Approvisionnement[];
  isLoading: boolean;
}

export const SuppliesTable: React.FC<SuppliesTableProps> = ({ supplies, isLoading }) => {
  const { tableClasses } = useDensity();

  return (
    <div className="card-toc overflow-hidden">
      {isLoading ? (
        <div className="p-12 text-center text-slate-400 text-sm">Chargement des réceptions...</div>
      ) : supplies.length === 0 ? (
        <div className="p-12 text-center text-slate-400 text-sm">
          Aucun approvisionnement enregistré pour le moment.
        </div>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-left min-w-[750px]">
            <thead className="bg-[#F5FAFD] dark:bg-dark-700/50 border-b border-[#E8EFF5] dark:border-dark-600">
              <tr>
                <th className={tableClasses.th}>Date & Heure</th>
                <th className={tableClasses.th}>Article Réceptionné</th>
                <th className={tableClasses.th}>Fournisseur</th>
                <th className={`${tableClasses.th} text-center`}>Quantité</th>
                <th className={`${tableClasses.th} text-right`}>Coût Unitaire</th>
                <th className={`${tableClasses.th} text-right`}>Total Achat</th>
                <th className={`${tableClasses.th} text-center`}>Paiement</th>
                <th className={tableClasses.th}>Opérateur</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#E8EFF5] dark:divide-dark-600/60">
              {supplies.map((s) => {
                const isPaid = s.payment_status === 'Payé';
                return (
                  <tr
                    key={s.sync_id}
                    className="hover:bg-brand-50/30 dark:hover:bg-dark-700/40 transition-colors"
                  >
                    <td className={tableClasses.td}>
                      <div className="flex items-center gap-1.5 font-medium text-slate-900 dark:text-white">
                        <Calendar className="w-3.5 h-3.5 text-brand-500" />
                        <span>{formatDateTime(s.date || s.created_at)}</span>
                      </div>
                      {s.notes && <div className="text-slate-400 text-xs italic mt-0.5">{s.notes}</div>}
                    </td>
                    <td className={`${tableClasses.td} font-bold text-slate-900 dark:text-white`}>
                      {s.product_name}
                    </td>
                    <td className={tableClasses.td}>
                      {s.supplier_name ? (
                        <div className="flex items-center gap-1.5 text-xs text-slate-600 dark:text-slate-300">
                          <Truck className="w-3.5 h-3.5 text-slate-400" />
                          <span>{s.supplier_name}</span>
                        </div>
                      ) : (
                        <span className="text-slate-400 text-xs">Non spécifié</span>
                      )}
                    </td>
                    <td className={`${tableClasses.td} text-center`}>
                      <span className="inline-block px-2.5 py-0.5 rounded-full text-xs font-bold bg-brand-50 dark:bg-brand-500/15 text-brand-700 dark:text-brand-300 border border-brand-200 dark:border-brand-500/30">
                        +{s.quantity}
                      </span>
                    </td>
                    <td className={`${tableClasses.td} text-right text-slate-500 dark:text-slate-400 font-mono`}>
                      {formatFCFA(s.unit_cost)}
                    </td>
                    <td className={`${tableClasses.td} text-right font-extrabold text-slate-900 dark:text-white font-mono`}>
                      {formatFCFA(s.total_cost)}
                    </td>
                    <td className={`${tableClasses.td} text-center`}>
                      {isPaid ? (
                        <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-400 border border-emerald-100 dark:border-emerald-900/50">
                          <CheckCircle2 className="w-3 h-3" />
                          Payé
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-bold bg-amber-50 dark:bg-amber-950/40 text-amber-700 dark:text-amber-400 border border-amber-200 dark:border-amber-900/50">
                          <Clock className="w-3 h-3" />
                          À crédit
                        </span>
                      )}
                    </td>
                    <td className={tableClasses.td}>
                      <div className="flex items-center gap-1 text-xs text-slate-500 dark:text-slate-400">
                        <UserCheck className="w-3.5 h-3.5 text-slate-400" />
                        <span>{s.user_name || 'Système'}</span>
                      </div>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
};
