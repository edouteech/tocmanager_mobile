import React from 'react';
import { formatFCFA } from '../../lib/formatters';
import { Modal } from '../../components/common/Modal';
import { PartnerKind } from './PartnerFormModal';

export interface PartnerPaymentValues {
  amount: number;
  payment_method: string;
  notes: string;
}

interface PartnerPaymentModalProps {
  kind: PartnerKind;
  partner: { name: string; balance: number } | null;
  values: PartnerPaymentValues;
  error: string | null;
  isPending: boolean;
  onClose: () => void;
  onChange: (next: PartnerPaymentValues) => void;
  onSubmit: (e: React.FormEvent) => void;
}

export const PartnerPaymentModal: React.FC<PartnerPaymentModalProps> = ({
  kind,
  partner,
  values,
  error,
  isPending,
  onClose,
  onChange,
  onSubmit,
}) => {
  const isSupplier = kind === 'supplier';
  const formId = `${kind}-payment-form`;

  return (
    <Modal
      isOpen={Boolean(partner)}
      onClose={onClose}
      title={isSupplier ? 'Règlement Facture Fournisseur' : 'Règlement de Créance Client'}
      subtitle={
        partner
          ? isSupplier
            ? `Paiement en faveur de ${partner.name}`
            : `Enregistrement d'un paiement pour ${partner.name}`
          : ''
      }
      footer={
        <div className="flex items-center justify-end gap-2 w-full">
          <button type="button" onClick={onClose} className="btn-secondary text-xs">
            Annuler
          </button>
          <button
            type="submit"
            form={formId}
            disabled={isPending}
            className="btn-primary text-xs bg-emerald-600 hover:bg-emerald-700"
          >
            {isPending ? 'Enregistrement...' : isSupplier ? 'Valider le Décaissement' : 'Valider le Règlement'}
          </button>
        </div>
      }
    >
      {partner && (
        <form id={formId} onSubmit={onSubmit} className="space-y-4">
          {error && (
            <div className="p-3 rounded-xl bg-rose-50 dark:bg-rose-950/40 border border-rose-200 dark:border-rose-800/40 text-rose-700 dark:text-rose-300 text-xs font-medium">
              {error}
            </div>
          )}
          <div className="p-4 rounded-2xl bg-amber-50 dark:bg-amber-950/30 border border-amber-200 dark:border-amber-900/50 flex justify-between items-center">
            <div>
              <span className="text-xs text-amber-800 dark:text-amber-300 font-semibold block">
                {isSupplier ? 'Dette à régler :' : 'Dette actuelle due :'}
              </span>
              <span className="text-lg font-extrabold text-amber-900 dark:text-amber-200 font-mono">
                {formatFCFA(partner.balance)}
              </span>
            </div>
            <button
              type="button"
              onClick={() => onChange({ ...values, amount: partner.balance })}
              className="px-2.5 py-1 text-xs font-bold bg-amber-200 dark:bg-amber-800 text-amber-900 dark:text-amber-100 rounded-lg hover:bg-amber-300 transition"
            >
              Tout solder
            </button>
          </div>

          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              {isSupplier ? 'Montant Payé (FCFA) *' : 'Montant Reçu (FCFA) *'}
            </label>
            <input
              type="number"
              min="1"
              required
              value={values.amount || ''}
              onChange={(e) => onChange({ ...values, amount: Number(e.target.value) })}
              placeholder={isSupplier ? 'Montant du décaissement' : 'Montant du versement'}
              className="input-toc text-base font-extrabold font-mono text-emerald-600"
            />
          </div>

          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Mode de Règlement
            </label>
            <select
              value={values.payment_method}
              onChange={(e) => onChange({ ...values, payment_method: e.target.value })}
              className="input-toc bg-white dark:bg-dark-700"
            >
              <option value="Espèces">Espèces</option>
              <option value="Wave">Wave</option>
              <option value="Orange Money">Orange Money</option>
              <option value="MTN MoMo">MTN MoMo</option>
              <option value="Virement Bancaire">Virement Bancaire</option>
              <option value="Chèque">Chèque</option>
            </select>
          </div>

          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Notes / Référence transaction
            </label>
            <input
              type="text"
              value={values.notes}
              onChange={(e) => onChange({ ...values, notes: e.target.value })}
              placeholder={isSupplier ? 'Ex: Facture N° 849...' : 'Ex: Reçu N° 4582...'}
              className="input-toc"
            />
          </div>
        </form>
      )}
    </Modal>
  );
};
