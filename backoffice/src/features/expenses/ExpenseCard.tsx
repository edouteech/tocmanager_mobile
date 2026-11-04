import React from 'react';
import {
  Receipt,
  Calendar,
  CreditCard,
  UserCheck,
  Tag,
  Trash2,
} from 'lucide-react';
import { Decaissement } from '../../types';
import { formatFCFA, formatDateTime } from '../../lib/formatters';

interface ExpenseCardProps {
  expense: Decaissement;
  onDelete: (expense: Decaissement) => void;
  badgeClass?: string;
}

export const ExpenseCard: React.FC<ExpenseCardProps> = ({
  expense,
  onDelete,
  badgeClass = 'bg-slate-100 text-slate-700 border-slate-200 dark:bg-dark-700 dark:text-slate-300 dark:border-dark-600',
}) => {
  return (
    <div className="card-toc p-4 hover:border-brand-300 dark:hover:border-brand-500/50 hover:shadow-md transition-all flex flex-col justify-between group">
      <div>
        {/* Header: Category Badge & Date */}
        <div className="flex items-center justify-between gap-2 mb-2.5">
          <span
            className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-bold border ${badgeClass}`}
          >
            <Tag className="w-3 h-3" />
            <span>{expense.category || 'Général'}</span>
          </span>
          <span className="text-[11px] text-slate-400 dark:text-slate-500 flex items-center gap-1">
            <Calendar className="w-3 h-3" />
            {formatDateTime(expense.created_at)}
          </span>
        </div>

        {/* Title & Amount */}
        <div className="flex items-start justify-between gap-3 mb-2">
          <h4 className="font-bold text-sm text-[#1C2B3A] dark:text-white line-clamp-2">
            {expense.title}
          </h4>
          <span className="font-mono text-base font-extrabold text-rose-600 dark:text-rose-400 shrink-0">
            {formatFCFA(expense.amount)}
          </span>
        </div>

        {/* Beneficiary & Notes */}
        <div className="space-y-1 text-xs text-slate-500 dark:text-slate-400">
          {expense.beneficiary && (
            <div className="flex items-center gap-1.5">
              <UserCheck className="w-3.5 h-3.5 text-slate-400 shrink-0" />
              <span className="truncate">Bénéficiaire : {expense.beneficiary}</span>
            </div>
          )}
          {expense.notes && (
            <p className="text-[11px] text-slate-400 italic line-clamp-2">
              "{expense.notes}"
            </p>
          )}
        </div>
      </div>

      {/* Footer: Payment Method & Delete button */}
      <div className="border-t border-slate-100 dark:border-dark-600/70 pt-2.5 mt-3 flex items-center justify-between">
        <span className="inline-flex items-center gap-1 text-[11px] font-medium text-slate-500 dark:text-slate-400">
          <CreditCard className="w-3 h-3 text-slate-400" />
          <span>{expense.payment_method || 'Espèces'}</span>
        </span>

        <button
          type="button"
          onClick={() => onDelete(expense)}
          className="p-1.5 text-slate-400 hover:text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-950/30 rounded-xl transition"
          title="Annuler le décaissement"
        >
          <Trash2 className="w-4 h-4" />
        </button>
      </div>
    </div>
  );
};
