import React from 'react';
import { FileText, Printer, RotateCcw, Share2 } from 'lucide-react';
import { Vente } from '../../types';
import { formatFCFA, formatDateTime } from '../../lib/formatters';
import { Drawer } from '../../components/common/Drawer';

interface SaleDetailDrawerProps {
  vente: Vente | null;
  storeDisplayName: string;
  magasinName?: string;
  canRefund: boolean;
  onClose: () => void;
  onShareWhatsApp: (vente: Vente) => void;
  onRequestRefund: (vente: Vente) => void;
  onPrint: () => void;
}

export const SaleDetailDrawer: React.FC<SaleDetailDrawerProps> = ({
  vente,
  storeDisplayName,
  magasinName,
  canRefund,
  onClose,
  onShareWhatsApp,
  onRequestRefund,
  onPrint,
}) => (
  <Drawer
    isOpen={Boolean(vente)}
    onClose={onClose}
    title={
      <div className="flex items-center gap-2">
        <FileText className="w-5 h-5 text-brand-500" />
        <span>Ticket {vente?.ticket_number}</span>
      </div>
    }
    subtitle="Détail complet de la transaction de caisse"
    footer={
      <div className="no-print flex items-center justify-between w-full gap-2">
        {vente && (
          <button
            type="button"
            onClick={() => onShareWhatsApp(vente)}
            className="btn-secondary flex items-center gap-1.5 text-xs text-emerald-600"
          >
            <Share2 className="w-4 h-4" />
            <span>WhatsApp</span>
          </button>
        )}
        {vente && canRefund && vente.status !== 'refunded' && (
          <button
            type="button"
            onClick={() => onRequestRefund(vente)}
            className="btn-secondary flex items-center gap-1.5 text-xs text-rose-600 border-rose-200"
          >
            <RotateCcw className="w-4 h-4" />
            <span>Rembourser</span>
          </button>
        )}
        <button onClick={onPrint} className="btn-primary flex items-center gap-2 text-xs">
          <Printer className="w-4 h-4" />
          <span>Imprimer le Reçu</span>
        </button>
      </div>
    }
  >
    {vente && (
      <div className="printable-area space-y-5">
        <div className="p-4 rounded-2xl bg-gradient-to-br from-brand-500/10 to-brand-500/5 border border-brand-500/20 text-center">
          <p className="text-[11px] font-extrabold uppercase tracking-widest text-slate-600 dark:text-slate-300">
            {storeDisplayName}
            {magasinName ? ` - ${magasinName}` : ''}
          </p>
          <span className="font-mono text-xs font-bold text-brand-600 dark:text-brand-400 uppercase tracking-widest block mb-1">
            Ticket N° {vente.ticket_number}
          </span>
          <div className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white font-mono">
            {formatFCFA(vente.total_amount)}
          </div>
          <span className="inline-block mt-1.5 px-3 py-0.5 rounded-full text-xs font-bold bg-white dark:bg-dark-700 text-slate-700 dark:text-slate-300 border border-slate-200 dark:border-dark-600">
            Paiement : {vente.payment_method}
          </span>
        </div>

        <div className="grid grid-cols-2 gap-3 text-xs bg-[#F5FAFD] dark:bg-dark-700/60 p-4 rounded-2xl border border-[#E8EFF5] dark:border-dark-600">
          <div>
            <span className="text-slate-400 dark:text-slate-500 block mb-0.5">Client</span>
            <span className="font-bold text-slate-900 dark:text-white">
              {vente.client_name || 'Occasionnel'}
            </span>
          </div>
          <div>
            <span className="text-slate-400 dark:text-slate-500 block mb-0.5">Date & Heure</span>
            <span className="font-semibold text-slate-700 dark:text-slate-200">
              {formatDateTime(vente.created_at)}
            </span>
          </div>
          <div>
            <span className="text-slate-400 dark:text-slate-500 block mb-0.5">Montant Versé</span>
            <span className="font-semibold text-emerald-600 dark:text-emerald-400 font-mono">
              {formatFCFA(vente.paid_amount || 0)}
            </span>
          </div>
          <div>
            <span className="text-slate-400 dark:text-slate-500 block mb-0.5">Vendeur / Caissier</span>
            <span className="font-semibold text-slate-700 dark:text-slate-200">
              {vente.user_name || 'Système'}
            </span>
          </div>
          {vente.paid_amount < vente.total_amount && (
            <div className="col-span-2 pt-2 border-t border-slate-200 dark:border-dark-600 flex justify-between items-center text-amber-600 dark:text-amber-400 font-bold">
              <span>Reste Dû (Crédit) :</span>
              <span className="font-mono text-sm">
                {formatFCFA(vente.total_amount - vente.paid_amount)}
              </span>
            </div>
          )}
        </div>

        <div>
          <h4 className="text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-2.5">
            Articles Vendus ({vente.items.length})
          </h4>
          <div className="border border-[#E8EFF5] dark:border-dark-600 rounded-2xl overflow-hidden divide-y divide-[#E8EFF5] dark:divide-dark-600/60 bg-white dark:bg-dark-800">
            {vente.items.map((it, idx) => (
              <div
                key={idx}
                className="p-3.5 text-xs flex items-center justify-between hover:bg-slate-50 dark:hover:bg-dark-700/40"
              >
                <div>
                  <div className="font-bold text-slate-900 dark:text-white">{it.product_name}</div>
                  <div className="text-slate-500 dark:text-slate-400 text-[11px] mt-0.5 font-mono">
                    {it.quantity} x {formatFCFA(it.unit_price)}
                  </div>
                </div>
                <div className="font-extrabold text-slate-900 dark:text-white font-mono text-sm">
                  {formatFCFA(it.total)}
                </div>
              </div>
            ))}
          </div>
        </div>

        {vente.discount_amount > 0 && (
          <div className="flex justify-between items-center px-4 py-2 bg-amber-50 dark:bg-amber-500/10 rounded-xl text-xs font-bold text-amber-700 dark:text-amber-300 border border-amber-200 dark:border-amber-500/20">
            <span>Remise appliquée</span>
            <span>-{formatFCFA(vente.discount_amount)}</span>
          </div>
        )}
      </div>
    )}
  </Drawer>
);
