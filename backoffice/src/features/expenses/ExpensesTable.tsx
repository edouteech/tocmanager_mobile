import React from 'react';
import { Calendar, CreditCard, Tag, Trash2, UserCheck } from 'lucide-react';
import { Decaissement } from '../../types';
import { formatFCFA, formatDateTime } from '../../lib/formatters';
import { useDensity } from '../../context/DensityContext';
import { getCategoryBadgeClass } from './expenseBadge';

interface ExpensesTableProps {
  expenses: Decaissement[];
  canDelete: boolean;
  onDelete: (expense: Decaissement) => void;
}

export const ExpensesTable: React.FC<ExpensesTableProps> = ({
  expenses,
  canDelete,
  onDelete,
}) => {
  const { tableClasses } = useDensity();

  return (
    <div className="card-toc overflow-hidden">
      <div className="overflow-x-auto">
        <table className="w-full text-left min-w-[750px]">
          <thead className="bg-[#F5FAFD] dark:bg-dark-700/50 border-b border-[#E8EFF5] dark:border-dark-600">
            <tr>
              <th className={tableClasses.th}>Date & Heure</th>
              <th className={tableClasses.th}>Motif de la Dépense</th>
              <th className={tableClasses.th}>Catégorie</th>
              <th className={tableClasses.th}>Bénéficiaire</th>
              <th className={tableClasses.th}>Moyen</th>
              <th className={`${tableClasses.th} text-right`}>Montant</th>
              <th className={tableClasses.th}>Opérateur</th>
              {canDelete && <th className={`${tableClasses.th} text-right`}>Action</th>}
            </tr>
          </thead>
          <tbody className="divide-y divide-[#E8EFF5] dark:divide-dark-600/60">
            {expenses.map((d) => (
              <tr key={d.sync_id} className="hover:bg-brand-50/30 dark:hover:bg-dark-700/40 transition-colors">
                <td className={tableClasses.td}>
                  <div className="flex items-center gap-1.5 font-medium text-slate-900 dark:text-white">
                    <Calendar className="w-3.5 h-3.5 text-brand-500" />
                    <span>{formatDateTime(d.date || d.created_at)}</span>
                  </div>
                </td>
                <td className={`${tableClasses.td} font-bold text-slate-900 dark:text-white`}>
                  {d.title}
                  {d.notes && <div className="text-xs text-slate-400 italic font-normal mt-0.5">{d.notes}</div>}
                </td>
                <td className={tableClasses.td}>
                  <span
                    className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-bold border ${getCategoryBadgeClass(
                      d.category || 'Général'
                    )}`}
                  >
                    <Tag className="w-3 h-3" />
                    <span>{d.category || 'Général'}</span>
                  </span>
                </td>
                <td className={`${tableClasses.td} text-slate-700 dark:text-slate-200`}>
                  {d.beneficiary || '-'}
                </td>
                <td className={tableClasses.td}>
                  <span className="inline-flex items-center gap-1 text-xs text-slate-600 dark:text-slate-300">
                    <CreditCard className="w-3.5 h-3.5 text-slate-400" />
                    {d.payment_method}
                  </span>
                </td>
                <td className={`${tableClasses.td} text-right font-extrabold text-rose-600 dark:text-rose-400 font-mono`}>
                  - {formatFCFA(d.amount)}
                </td>
                <td className={tableClasses.td}>
                  <div className="flex items-center gap-1 text-xs text-slate-500 dark:text-slate-400">
                    <UserCheck className="w-3.5 h-3.5 text-slate-400" />
                    <span>{d.user_name || 'Système'}</span>
                  </div>
                </td>
                {canDelete && (
                  <td className={`${tableClasses.td} text-right`}>
                    <button
                      onClick={() => onDelete(d)}
                      className="p-1.5 text-slate-400 hover:text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-950/30 rounded-xl transition"
                      title="Annuler le décaissement"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </td>
                )}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};
