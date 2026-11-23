import React from 'react';
import { Magasin } from '../../types';
import { Modal } from '../../components/common/Modal';

export interface ExpenseFormValues {
  title: string;
  amount: number;
  category: string;
  customCategory: string;
  beneficiary: string;
  payment_method: string;
  notes: string;
}

interface ExpenseFormModalProps {
  isOpen: boolean;
  form: ExpenseFormValues;
  formCategories: string[];
  formError: string | null;
  isSubmitting: boolean;
  showMagasinSelector: boolean;
  magasins: Magasin[];
  targetMagasinId: string;
  onTargetMagasinChange: (id: string) => void;
  onClose: () => void;
  onChange: (next: ExpenseFormValues) => void;
  onSubmit: (e: React.FormEvent) => void;
}

export const ExpenseFormModal: React.FC<ExpenseFormModalProps> = ({
  isOpen,
  form,
  formCategories,
  formError,
  isSubmitting,
  showMagasinSelector,
  magasins,
  targetMagasinId,
  onTargetMagasinChange,
  onClose,
  onChange,
  onSubmit,
}) => (
  <Modal
    isOpen={isOpen}
    onClose={onClose}
    title="Enregistrer un Décaissement"
    subtitle="Sortie de caisse justifiée pour charges d'exploitation"
    footer={
      <div className="flex items-center justify-end gap-2 w-full">
        <button type="button" onClick={onClose} className="btn-secondary text-xs">
          Annuler
        </button>
        <button
          type="submit"
          form="expense-form"
          disabled={isSubmitting}
          className="btn-primary text-xs bg-rose-600 hover:bg-rose-700"
        >
          {isSubmitting ? 'Enregistrement...' : 'Valider la Dépense'}
        </button>
      </div>
    }
  >
    <form id="expense-form" onSubmit={onSubmit} className="space-y-4">
      {formError && (
        <div className="p-3 rounded-xl bg-rose-50 dark:bg-rose-950/40 border border-rose-200 dark:border-rose-800/40 text-rose-700 dark:text-rose-300 text-xs font-medium">
          {formError}
        </div>
      )}
      {showMagasinSelector && (
        <div>
          <label className="block text-xs font-bold uppercase tracking-wider text-amber-600 dark:text-amber-400 mb-1.5">
            Magasin imputé *
          </label>
          <select
            required
            value={targetMagasinId}
            onChange={(e) => onTargetMagasinChange(e.target.value)}
            className="input-toc bg-white dark:bg-dark-700"
          >
            <option value="">Sélectionner un magasin...</option>
            {magasins
              .filter((m) => m.is_active)
              .map((m) => (
                <option key={m.id} value={m.id}>
                  {m.name} {m.is_warehouse ? '(Entrepôt)' : ''}
                </option>
              ))}
          </select>
        </div>
      )}

      <div>
        <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
          Motif du décaissement *
        </label>
        <input
          type="text"
          required
          placeholder="Ex: Facture électricité agence, Frais de livraison..."
          value={form.title}
          onChange={(e) => onChange({ ...form, title: e.target.value })}
          className="input-toc"
        />
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
        <div>
          <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
            Montant décaissé (F CFA) *
          </label>
          <input
            type="number"
            min="1"
            step="100"
            required
            value={form.amount || ''}
            onChange={(e) => onChange({ ...form, amount: parseFloat(e.target.value) || 0 })}
            className="input-toc font-mono font-bold text-rose-600"
          />
        </div>
        <div>
          <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
            Catégorie *
          </label>
          <select
            value={form.category}
            onChange={(e) => onChange({ ...form, category: e.target.value })}
            className="input-toc bg-white dark:bg-dark-700"
          >
            {formCategories.map((cat) => (
              <option key={cat} value={cat}>
                {cat}
              </option>
            ))}
            <option value="__custom__">+ Nouvelle catégorie personnalisée...</option>
          </select>
        </div>
      </div>

      {form.category === '__custom__' && (
        <div>
          <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
            Nom de la nouvelle catégorie *
          </label>
          <input
            type="text"
            required
            placeholder="Ex: Frais Bancaires, Sécurité..."
            value={form.customCategory}
            onChange={(e) => onChange({ ...form, customCategory: e.target.value })}
            className="input-toc"
          />
        </div>
      )}

      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
        <div>
          <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
            Bénéficiaire / Prestataire
          </label>
          <input
            type="text"
            placeholder="Ex: SBEE, Moov Africa, Chauffeur..."
            value={form.beneficiary}
            onChange={(e) => onChange({ ...form, beneficiary: e.target.value })}
            className="input-toc"
          />
        </div>
        <div>
          <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
            Mode de règlement
          </label>
          <select
            value={form.payment_method}
            onChange={(e) => onChange({ ...form, payment_method: e.target.value })}
            className="input-toc bg-white dark:bg-dark-700"
          >
            <option value="Espèces">Espèces de Caisse</option>
            <option value="Mobile Money">Mobile Money (T-Money/Flooz/Moov)</option>
            <option value="Virement">Virement bancaire</option>
            <option value="Chèque">Chèque</option>
          </select>
        </div>
      </div>

      <div>
        <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
          Justificatif / Numéro de reçu / Notes
        </label>
        <textarea
          rows={2}
          placeholder="Réf ticket, n° facture, remarques..."
          value={form.notes}
          onChange={(e) => onChange({ ...form, notes: e.target.value })}
          className="input-toc"
        />
      </div>
    </form>
  </Modal>
);
