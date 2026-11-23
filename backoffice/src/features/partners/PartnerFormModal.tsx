import React from 'react';
import { Modal } from '../../components/common/Modal';

export type PartnerKind = 'client' | 'supplier';

export interface PartnerFormValues {
  name: string;
  contact_person: string;
  phone: string;
  email: string;
  address: string;
  balance: number;
  notes: string;
}

interface PartnerFormModalProps {
  kind: PartnerKind;
  isOpen: boolean;
  isEditing: boolean;
  values: PartnerFormValues;
  error: string | null;
  isPending: boolean;
  onClose: () => void;
  onChange: (next: PartnerFormValues) => void;
  onSubmit: (e: React.FormEvent) => void;
}

export const PartnerFormModal: React.FC<PartnerFormModalProps> = ({
  kind,
  isOpen,
  isEditing,
  values,
  error,
  isPending,
  onClose,
  onChange,
  onSubmit,
}) => {
  const isSupplier = kind === 'supplier';
  const formId = `${kind}-form`;

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={
        isEditing
          ? isSupplier
            ? 'Modifier le Fournisseur'
            : 'Modifier le Client'
          : isSupplier
            ? 'Nouveau Fournisseur'
            : 'Nouveau Client'
      }
      subtitle={
        isSupplier
          ? 'Renseignez les coordonnées et contacts du fournisseur'
          : 'Renseignez les coordonnées du compte client'
      }
      footer={
        <div className="flex items-center justify-end gap-2 w-full">
          <button type="button" onClick={onClose} className="btn-secondary text-xs">
            Annuler
          </button>
          <button type="submit" form={formId} disabled={isPending} className="btn-primary text-xs">
            {isPending ? 'Enregistrement...' : isEditing ? 'Mettre à jour' : 'Enregistrer'}
          </button>
        </div>
      }
    >
      <form id={formId} onSubmit={onSubmit} className="space-y-4">
        {error && (
          <div className="p-3 rounded-xl bg-rose-50 dark:bg-rose-950/40 border border-rose-200 dark:border-rose-800/40 text-rose-700 dark:text-rose-300 text-xs font-medium">
            {error}
          </div>
        )}
        <div>
          <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
            {isSupplier ? 'Raison Sociale / Nom *' : 'Nom Complet *'}
          </label>
          <input
            type="text"
            required
            value={values.name}
            onChange={(e) => onChange({ ...values, name: e.target.value })}
            placeholder={isSupplier ? 'Ex: Société Générale de Distribution' : 'Ex: Entreprise Toure'}
            className="input-toc"
          />
        </div>

        {isSupplier && (
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Contact Référent (Personne à contacter)
            </label>
            <input
              type="text"
              value={values.contact_person}
              onChange={(e) => onChange({ ...values, contact_person: e.target.value })}
              placeholder="Ex: M. Jean Konan (Commercial)"
              className="input-toc"
            />
          </div>
        )}

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Téléphone
            </label>
            <input
              type="tel"
              value={values.phone}
              onChange={(e) => onChange({ ...values, phone: e.target.value })}
              placeholder="+225 07..."
              className="input-toc font-mono"
            />
          </div>
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Email
            </label>
            <input
              type="email"
              value={values.email}
              onChange={(e) => onChange({ ...values, email: e.target.value })}
              placeholder={isSupplier ? 'contact@fournisseur.com' : 'client@mail.com'}
              className="input-toc"
            />
          </div>
        </div>

        <div>
          <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
            Adresse physique
          </label>
          <input
            type="text"
            value={values.address}
            onChange={(e) => onChange({ ...values, address: e.target.value })}
            placeholder="Quartier, Rue, Ville"
            className="input-toc"
          />
        </div>

        {!isEditing && (
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Solde Initial (Dette antérieure éventuelle)
            </label>
            <input
              type="number"
              min="0"
              value={values.balance}
              onChange={(e) => onChange({ ...values, balance: Number(e.target.value) })}
              className="input-toc font-bold font-mono"
            />
          </div>
        )}

        <div>
          <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
            Notes
          </label>
          <textarea
            rows={2}
            value={values.notes}
            onChange={(e) => onChange({ ...values, notes: e.target.value })}
            placeholder="Remarques, conditions..."
            className="input-toc"
          />
        </div>
      </form>
    </Modal>
  );
};
