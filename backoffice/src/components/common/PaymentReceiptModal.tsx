import React from 'react';
import {
  Printer,
  CheckCircle2,
  Share2,
  Phone,
  FileCheck,
  CreditCard,
  X,
} from 'lucide-react';
import { formatFCFA, formatDateTime } from '../../lib/formatters';
import { Modal } from './Modal';

export interface PaymentReceiptData {
  type: 'client' | 'supplier';
  recipientName: string;
  phone?: string | null;
  amount: number;
  previousBalance: number;
  newBalance: number;
  paymentMethod: string;
  date?: string;
  receiptNumber?: string;
  notes?: string | null;
}

interface PaymentReceiptModalProps {
  isOpen: boolean;
  onClose: () => void;
  data: PaymentReceiptData | null;
}

export const PaymentReceiptModal: React.FC<PaymentReceiptModalProps> = ({
  isOpen,
  onClose,
  data,
}) => {
  if (!data) return null;

  const isClient = data.type === 'client';
  const receiptNum = data.receiptNumber || `REC-${Date.now().toString().slice(-6)}`;
  const dateStr = formatDateTime(data.date || new Date().toISOString());

  const handlePrint = () => {
    window.print();
  };

  const handleWhatsAppShare = () => {
    const rawPhone = (data.phone || '').replace(/[^0-9]/g, '');
    const clientGreeting = isClient
      ? `Cher(e) ${data.recipientName}`
      : `À l'attention de ${data.recipientName}`;

    const text =
      `*ACCUSÉ DE RÉCEPTION DE PAIEMENT*\n` +
      `--------------------------------\n` +
      `N° Reçu : *${receiptNum}*\n` +
      `Date : ${dateStr}\n` +
      `${clientGreeting},\n\n` +
      `Nous confirmons le versement de : *${formatFCFA(data.amount)}*\n` +
      `Mode de règlement : ${data.paymentMethod}\n` +
      `Dette antérieure : ${formatFCFA(data.previousBalance)}\n` +
      `*Nouveau solde restant : ${formatFCFA(data.newBalance)}*\n\n` +
      `Merci pour votre confiance !\n` +
      `_TocManager Store_`;

    const url = rawPhone
      ? `https://api.whatsapp.com/send?phone=${rawPhone}&text=${encodeURIComponent(text)}`
      : `https://api.whatsapp.com/send?text=${encodeURIComponent(text)}`;

    window.open(url, '_blank');
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-lg bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 flex items-center justify-center">
            <CheckCircle2 className="w-4 h-4" />
          </div>
          <span>Reçu de Règlement & Accusé de Paiement</span>
        </div>
      }
      subtitle={`Enregistrement du règlement pour ${data.recipientName}`}
      maxWidth="max-w-md"
    >
      <div className="space-y-5 py-2">
        {/* Printable Receipt Card */}
        <div
          id="payment-receipt-print"
          className="bg-slate-50 dark:bg-dark-750 p-6 rounded-2xl border border-slate-200 dark:border-dark-600 font-mono text-xs text-slate-700 dark:text-slate-300 space-y-4 shadow-xs"
        >
          <div className="text-center border-b border-dashed border-slate-300 dark:border-dark-500 pb-3">
            <h4 className="font-bold text-sm text-slate-900 dark:text-white uppercase tracking-wider font-sans">
              TOCMANAGER STORE
            </h4>
            <p className="text-[11px] text-slate-500 mt-0.5">
              REÇU DE RÈGLEMENT ({isClient ? 'CLIENT' : 'FOURNISSEUR'})
            </p>
            <p className="text-brand-600 dark:text-brand-400 font-bold mt-1">N° {receiptNum}</p>
            <p className="text-slate-500">{dateStr}</p>
          </div>

          <div className="space-y-2 font-sans text-xs">
            <div className="flex justify-between">
              <span className="text-slate-500">{isClient ? 'Client' : 'Fournisseur'} :</span>
              <span className="font-bold text-slate-900 dark:text-white">{data.recipientName}</span>
            </div>
            {data.phone && (
              <div className="flex justify-between">
                <span className="text-slate-500">Téléphone :</span>
                <span>{data.phone}</span>
              </div>
            )}
            <div className="flex justify-between">
              <span className="text-slate-500">Mode de paiement :</span>
              <span className="font-semibold">{data.paymentMethod}</span>
            </div>
            {data.notes && (
              <div className="flex justify-between">
                <span className="text-slate-500">Note :</span>
                <span className="italic">{data.notes}</span>
              </div>
            )}
          </div>

          <div className="border-t border-b border-dashed border-slate-300 dark:border-dark-500 py-3 space-y-2 font-sans">
            <div className="flex justify-between text-slate-500 text-xs">
              <span>Dette antérieure :</span>
              <span className="font-mono">{formatFCFA(data.previousBalance)}</span>
            </div>
            <div className="flex justify-between text-sm font-extrabold text-emerald-600 dark:text-emerald-400">
              <span>MONTANT VERSÉ :</span>
              <span className="font-mono text-base">{formatFCFA(data.amount)}</span>
            </div>
            <div className="flex justify-between text-xs font-bold text-slate-900 dark:text-white pt-1">
              <span>Nouveau solde restant :</span>
              <span className="font-mono text-brand-600 dark:text-brand-400">{formatFCFA(data.newBalance)}</span>
            </div>
          </div>

          <div className="text-center text-[11px] text-slate-500 italic pt-1">
            Merci pour votre confiance ! Conservez ce reçu comme preuve de paiement.
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex flex-col sm:flex-row gap-2 pt-1">
          <button
            onClick={handlePrint}
            className="btn-toc btn-outline flex-1 py-2.5 text-xs flex items-center justify-center gap-2"
          >
            <Printer className="w-4 h-4" />
            <span>Imprimer le reçu</span>
          </button>

          <button
            onClick={handleWhatsAppShare}
            className="btn-toc bg-emerald-600 hover:bg-emerald-700 text-white flex-1 py-2.5 text-xs font-bold flex items-center justify-center gap-2 shadow-sm"
          >
            <Share2 className="w-4 h-4" />
            <span>Partager WhatsApp</span>
          </button>
        </div>
      </div>
    </Modal>
  );
};
