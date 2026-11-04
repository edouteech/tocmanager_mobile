import React from 'react';
import {
  User,
  ShoppingBag,
  ChevronRight,
  Printer,
  Share2,
  Calendar,
  CreditCard,
  AlertCircle,
  CheckCircle2,
} from 'lucide-react';
import { Vente } from '../../types';
import { formatFCFA, formatDateTime } from '../../lib/formatters';

interface VenteCardProps {
  vente: Vente;
  onSelect: (vente: Vente) => void;
  onPrint?: (vente: Vente) => void;
  onShareWhatsApp?: (vente: Vente) => void;
}

export const VenteCard: React.FC<VenteCardProps> = ({
  vente,
  onSelect,
  onPrint,
  onShareWhatsApp,
}) => {
  const isCredit = vente.payment_method === 'Crédit' || (vente.paid_amount < vente.total_amount);
  const remaining = Math.max(0, vente.total_amount - (vente.paid_amount || 0));

  return (
    <div
      onClick={() => onSelect(vente)}
      className="card-toc p-4 hover:border-brand-300 dark:hover:border-brand-500/50 hover:shadow-md transition-all cursor-pointer flex flex-col justify-between group"
    >
      <div>
        {/* Header: Ticket Number & Date */}
        <div className="flex items-center justify-between gap-2 mb-3">
          <div className="flex items-center gap-2">
            <span className="font-mono font-extrabold text-xs px-2.5 py-1 rounded-xl bg-slate-100 dark:bg-dark-700 text-slate-800 dark:text-slate-200 border border-slate-200 dark:border-dark-600">
              {vente.ticket_number}
            </span>
          </div>
          <span className="text-[11px] font-medium text-slate-400 dark:text-slate-500 flex items-center gap-1">
            <Calendar className="w-3 h-3" />
            {formatDateTime(vente.created_at)}
          </span>
        </div>

        {/* Client & Amount summary */}
        <div className="flex items-start justify-between gap-3 mb-3">
          <div className="flex items-center gap-3 min-w-0">
            <div
              className={`w-10 h-10 rounded-2xl flex items-center justify-center shrink-0 ${
                isCredit
                  ? 'bg-amber-100 dark:bg-amber-500/20 text-amber-600 dark:text-amber-400'
                  : 'bg-brand-50 dark:bg-brand-500/15 text-brand-600 dark:text-brand-400'
              }`}
            >
              <User className="w-5 h-5" />
            </div>
            <div className="min-w-0">
              <h4 className="font-bold text-sm text-[#1C2B3A] dark:text-white truncate">
                {vente.client_name || 'Occasionnel'}
              </h4>
              <p className="text-xs text-slate-500 dark:text-slate-400 flex items-center gap-1 mt-0.5">
                <ShoppingBag className="w-3.5 h-3.5 text-slate-400" />
                <span>{vente.items?.length || 0} article(s)</span>
              </p>
            </div>
          </div>

          <div className="text-right shrink-0">
            <div
              className={`font-mono text-base font-extrabold ${
                isCredit
                  ? 'text-amber-600 dark:text-amber-400'
                  : 'text-emerald-600 dark:text-emerald-400'
              }`}
            >
              {formatFCFA(vente.total_amount)}
            </div>
            <span className="text-[10px] text-slate-400 block mt-0.5">
              Net à payer
            </span>
          </div>
        </div>
      </div>

      {/* Divider */}
      <div className="border-t border-slate-100 dark:border-dark-600/70 pt-3 mt-1 flex items-center justify-between gap-2">
        {/* Status Pill */}
        <div className="min-w-0">
          {isCredit ? (
            <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-xl text-xs font-bold bg-amber-50 dark:bg-amber-500/15 text-amber-700 dark:text-amber-300 border border-amber-200 dark:border-amber-500/30 truncate max-w-[200px]">
              <AlertCircle className="w-3.5 h-3.5 shrink-0 text-amber-600" />
              <span className="truncate">Crédit - Reste: {formatFCFA(remaining)}</span>
            </span>
          ) : (
            <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-xl text-xs font-bold bg-emerald-50 dark:bg-emerald-500/15 text-emerald-700 dark:text-emerald-300 border border-emerald-200 dark:border-emerald-500/30 truncate">
              <CheckCircle2 className="w-3.5 h-3.5 shrink-0 text-emerald-600" />
              <span>{vente.payment_method} - Payé</span>
            </span>
          )}
        </div>

        {/* Quick action buttons */}
        <div className="flex items-center gap-1 shrink-0" onClick={(e) => e.stopPropagation()}>
          {onShareWhatsApp && (
            <button
              type="button"
              onClick={() => onShareWhatsApp(vente)}
              className="p-1.5 text-slate-400 hover:text-emerald-600 dark:hover:text-emerald-400 hover:bg-emerald-50 dark:hover:bg-emerald-500/10 rounded-xl transition"
              title="Partager Reçu via WhatsApp"
            >
              <Share2 className="w-4 h-4" />
            </button>
          )}

          {onPrint && (
            <button
              type="button"
              onClick={() => onPrint(vente)}
              className="p-1.5 text-slate-400 hover:text-brand-600 dark:hover:text-brand-400 hover:bg-brand-50 dark:hover:bg-brand-500/10 rounded-xl transition"
              title="Imprimer le reçu"
            >
              <Printer className="w-4 h-4" />
            </button>
          )}

          <button
            type="button"
            onClick={() => onSelect(vente)}
            className="flex items-center gap-1 text-xs font-bold text-brand-600 dark:text-brand-400 group-hover:translate-x-0.5 transition-transform ml-1"
          >
            <span className="hidden sm:inline">Détails</span>
            <ChevronRight className="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>
  );
};
