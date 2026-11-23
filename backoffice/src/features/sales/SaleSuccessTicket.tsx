import React from 'react';
import { CheckCircle2, Printer, ShoppingCart } from 'lucide-react';
import { Vente } from '../../types';
import { formatFCFA, formatDateTime } from '../../lib/formatters';

interface SaleSuccessTicketProps {
  vente: Vente;
  storeDisplayName: string;
  magasinName?: string;
  onPrint: () => void;
  onNewSale: () => void;
}

export const SaleSuccessTicket: React.FC<SaleSuccessTicketProps> = ({
  vente,
  storeDisplayName,
  magasinName,
  onPrint,
  onNewSale,
}) => (
  <div className="space-y-6 py-4">
    <div className="no-print text-center space-y-2">
      <div className="w-16 h-16 bg-emerald-100 dark:bg-emerald-500/20 text-emerald-600 dark:text-emerald-400 rounded-full flex items-center justify-center mx-auto">
        <CheckCircle2 className="w-10 h-10" />
      </div>
      <h3 className="text-xl font-extrabold text-slate-900 dark:text-white">
        Vente enregistrée avec succès !
      </h3>
      <p className="text-sm text-slate-500 dark:text-slate-400">
        Ticket N°{' '}
        <span className="font-mono font-bold text-brand-600 dark:text-brand-400">
          {vente.ticket_number}
        </span>
      </p>
    </div>

    <div className="printable-area max-w-md mx-auto bg-slate-50 dark:bg-dark-700 p-6 rounded-2xl border border-slate-200 dark:border-dark-600 space-y-4 font-mono text-xs text-slate-700 dark:text-slate-300">
      <div className="text-center border-b border-dashed border-slate-300 dark:border-dark-500 pb-3">
        <h4 className="font-bold text-sm text-slate-900 dark:text-white uppercase tracking-wider">
          {storeDisplayName}
        </h4>
        {magasinName && (
          <p className="text-[11px] font-semibold text-slate-600 dark:text-slate-300">
            {magasinName}
          </p>
        )}
        <p className="text-[11px] text-slate-500">REÇU DE CAISSE</p>
        <p className="text-slate-500 mt-1">{formatDateTime(vente.created_at)}</p>
        <p className="text-slate-500">Client : {vente.client_name || 'Occasionnel'}</p>
        <p className="text-slate-500">Mode : {vente.payment_method}</p>
      </div>

      <div className="divide-y divide-dashed divide-slate-200 dark:divide-dark-600">
        {vente.items.map((it, idx) => (
          <div key={idx} className="py-2 flex justify-between">
            <div>
              <span className="font-bold">{it.product_name}</span>
              <div className="text-[11px] text-slate-500">
                {it.quantity} x {formatFCFA(it.unit_price)}
              </div>
            </div>
            <span className="font-bold">{formatFCFA(it.total)}</span>
          </div>
        ))}
      </div>

      <div className="border-t border-dashed border-slate-300 dark:border-dark-500 pt-3 space-y-1.5 text-right font-sans">
        {vente.discount_amount > 0 && (
          <div className="flex justify-between text-slate-500">
            <span>Remise accordée :</span>
            <span>-{formatFCFA(vente.discount_amount)}</span>
          </div>
        )}
        <div className="flex justify-between text-sm font-extrabold text-slate-900 dark:text-white">
          <span>TOTAL NET :</span>
          <span className="text-brand-600 dark:text-brand-400">{formatFCFA(vente.total_amount)}</span>
        </div>
        <div className="flex justify-between text-slate-500">
          <span>Montant reçu :</span>
          <span>{formatFCFA(vente.paid_amount)}</span>
        </div>
        {vente.paid_amount > vente.total_amount && (
          <div className="flex justify-between font-bold text-emerald-600">
            <span>Monnaie rendue :</span>
            <span>{formatFCFA(vente.paid_amount - vente.total_amount)}</span>
          </div>
        )}
        {vente.paid_amount < vente.total_amount && (
          <div className="flex justify-between font-bold text-amber-600">
            <span>Reste à payer (Dette) :</span>
            <span>{formatFCFA(vente.total_amount - vente.paid_amount)}</span>
          </div>
        )}
      </div>
    </div>

    <div className="no-print flex justify-center gap-3 pt-2">
      <button onClick={onPrint} className="btn-secondary flex items-center gap-2">
        <Printer className="w-4 h-4" />
        <span>Imprimer le ticket</span>
      </button>
      <button onClick={onNewSale} className="btn-primary flex items-center gap-2">
        <ShoppingCart className="w-4 h-4" />
        <span>Nouvelle Vente</span>
      </button>
    </div>
  </div>
);
