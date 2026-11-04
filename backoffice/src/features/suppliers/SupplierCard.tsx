import React from 'react';
import {
  Truck,
  Phone,
  MapPin,
  DollarSign,
  AlertCircle,
  CheckCircle2,
  Edit2,
  Trash2,
  MessageCircle,
  User,
} from 'lucide-react';
import { Supplier } from '../../types';
import { formatFCFA } from '../../lib/formatters';

interface SupplierCardProps {
  supplier: Supplier;
  onEdit: (supplier: Supplier) => void;
  onDelete: (supplier: Supplier) => void;
  onPayment: (supplier: Supplier) => void;
}

export const SupplierCard: React.FC<SupplierCardProps> = ({
  supplier,
  onEdit,
  onDelete,
  onPayment,
}) => {
  const hasDebt = (supplier.balance || 0) > 0;

  const cleanPhone = supplier.phone ? supplier.phone.replace(/[^0-9+]/g, '') : '';
  const waPhone = cleanPhone.startsWith('+') ? cleanPhone.slice(1) : cleanPhone;

  return (
    <div className="card-toc p-4 hover:border-brand-300 dark:hover:border-brand-500/50 hover:shadow-md transition-all flex flex-col justify-between group">
      <div>
        {/* Header: Avatar, Name & Debt Pill */}
        <div className="flex items-start justify-between gap-3 mb-3">
          <div className="flex items-center gap-3 min-w-0">
            <div
              className={`w-11 h-11 rounded-2xl flex items-center justify-center shrink-0 font-bold text-sm ${
                hasDebt
                  ? 'bg-amber-100 dark:bg-amber-500/20 text-amber-700 dark:text-amber-400'
                  : 'bg-brand-50 dark:bg-brand-500/15 text-brand-600 dark:text-brand-400'
              }`}
            >
              <Truck className="w-5 h-5" />
            </div>
            <div className="min-w-0">
              <h4 className="font-bold text-sm text-[#1C2B3A] dark:text-white truncate">
                {supplier.name}
              </h4>
              {supplier.contact_person ? (
                <p className="text-[11px] text-slate-500 dark:text-slate-400 flex items-center gap-1 mt-0.5 truncate">
                  <User className="w-3 h-3 shrink-0" />
                  <span className="truncate">{supplier.contact_person}</span>
                </p>
              ) : supplier.address ? (
                <p className="text-[11px] text-slate-400 flex items-center gap-1 mt-0.5 truncate">
                  <MapPin className="w-3 h-3 shrink-0" />
                  <span className="truncate">{supplier.address}</span>
                </p>
              ) : (
                <p className="text-[11px] text-slate-400 mt-0.5">Fournisseur</p>
              )}
            </div>
          </div>

          {/* Balance pill */}
          <div className="shrink-0 text-right">
            {hasDebt ? (
              <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-xl text-xs font-extrabold bg-amber-50 dark:bg-amber-500/15 text-amber-700 dark:text-amber-400 border border-amber-200 dark:border-amber-500/30">
                <AlertCircle className="w-3.5 h-3.5 text-amber-600 shrink-0" />
                <span className="font-mono">{formatFCFA(supplier.balance)}</span>
              </span>
            ) : (
              <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-xl text-xs font-bold bg-emerald-50 dark:bg-emerald-500/15 text-emerald-700 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-500/30">
                <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600 shrink-0" />
                <span>À jour</span>
              </span>
            )}
            <span className="text-[10px] text-slate-400 block mt-0.5">
              {hasDebt ? 'Dette à régler' : 'Solde soldé'}
            </span>
          </div>
        </div>

        {/* Contact info bar */}
        {supplier.phone && (
          <div className="bg-[#F5FAFD] dark:bg-dark-700/50 p-2.5 rounded-xl border border-[#E8EFF5] dark:border-dark-600 flex items-center justify-between text-xs mb-3">
            <span className="font-mono font-bold text-slate-700 dark:text-slate-300">
              {supplier.phone}
            </span>
            <div className="flex items-center gap-1.5">
              <a
                href={`tel:${cleanPhone}`}
                className="p-1 text-slate-500 hover:text-brand-600 hover:bg-white dark:hover:bg-dark-600 rounded-lg transition"
                title="Appeler"
              >
                <Phone className="w-3.5 h-3.5" />
              </a>
              <a
                href={`https://wa.me/${waPhone}`}
                target="_blank"
                rel="noreferrer"
                className="p-1 text-slate-500 hover:text-emerald-600 hover:bg-white dark:hover:bg-dark-600 rounded-lg transition"
                title="WhatsApp"
              >
                <MessageCircle className="w-3.5 h-3.5" />
              </a>
            </div>
          </div>
        )}
      </div>

      {/* Footer */}
      <div className="border-t border-slate-100 dark:border-dark-600/70 pt-2.5 flex items-center justify-between gap-2">
        {hasDebt ? (
          <button
            type="button"
            onClick={() => onPayment(supplier)}
            className="btn-toc btn-primary flex items-center gap-1 py-1.5 px-3 text-xs font-bold bg-emerald-600 hover:bg-emerald-700 text-white"
          >
            <DollarSign className="w-3.5 h-3.5" />
            <span>Payer dette</span>
          </button>
        ) : (
          <span className="text-[11px] text-slate-400">Aucune dette</span>
        )}

        <div className="flex items-center gap-1">
          <button
            type="button"
            onClick={() => onEdit(supplier)}
            className="p-1.5 text-slate-500 hover:text-brand-600 hover:bg-brand-50 dark:hover:bg-brand-500/10 rounded-xl transition"
            title="Modifier"
          >
            <Edit2 className="w-4 h-4" />
          </button>
          <button
            type="button"
            onClick={() => onDelete(supplier)}
            className="p-1.5 text-slate-500 hover:text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-500/10 rounded-xl transition"
            title="Supprimer"
          >
            <Trash2 className="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>
  );
};
