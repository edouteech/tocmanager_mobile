import React from 'react';
import { CheckCircle2, Clock } from 'lucide-react';
import { Magasin, Product, Supplier } from '../../types';
import { formatFCFA } from '../../lib/formatters';
import { Drawer } from '../../components/common/Drawer';

export interface SupplyFormState {
  product_sync_id: string;
  supplier_sync_id: string;
  quantity: number;
  unit_cost: number;
  payment_status: string;
  notes: string;
}

interface SupplyReceptionDrawerProps {
  isOpen: boolean;
  onClose: () => void;
  form: SupplyFormState;
  onChange: (next: SupplyFormState) => void;
  onProductChange: (prodSyncId: string) => void;
  onSubmit: (e: React.FormEvent) => void;
  isSubmitting: boolean;
  formError: string | null;
  showMagasinSelector: boolean;
  magasins: Magasin[];
  targetMagasinId: string;
  onTargetMagasinChange: (id: string) => void;
  products: Product[];
  suppliers: Supplier[];
}

export const SupplyReceptionDrawer: React.FC<SupplyReceptionDrawerProps> = ({
  isOpen,
  onClose,
  form,
  onChange,
  onProductChange,
  onSubmit,
  isSubmitting,
  formError,
  showMagasinSelector,
  magasins,
  targetMagasinId,
  onTargetMagasinChange,
  products,
  suppliers,
}) => (
  <Drawer
    isOpen={isOpen}
    onClose={onClose}
    title="Réception de Marchandises"
    subtitle="Entrée en stock avec recalcul automatique du PAMP"
    footer={
      <>
        <button type="button" onClick={onClose} className="btn-secondary">
          Annuler
        </button>
        <button type="submit" form="supply-form" disabled={isSubmitting} className="btn-primary">
          {isSubmitting ? 'Enregistrement...' : 'Valider la Réception'}
        </button>
      </>
    }
  >
    <form id="supply-form" onSubmit={onSubmit} className="space-y-4">
      {formError && (
        <div className="p-3 rounded-xl bg-rose-50 dark:bg-rose-950/40 border border-rose-200 dark:border-rose-800/40 text-rose-700 dark:text-rose-300 text-xs font-medium">
          {formError}
        </div>
      )}
      {showMagasinSelector && (
        <div>
          <label className="block text-xs font-bold uppercase tracking-wider text-amber-600 dark:text-amber-400 mb-1.5">
            Magasin / Entrepôt de réception *
          </label>
          <select
            required
            value={targetMagasinId}
            onChange={(e) => onTargetMagasinChange(e.target.value)}
            className="input-toc bg-white dark:bg-dark-700"
          >
            <option value="">Sélectionner le magasin destinataire...</option>
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
          Article réceptionné *
        </label>
        <select
          required
          value={form.product_sync_id}
          onChange={(e) => onProductChange(e.target.value)}
          className="input-toc bg-white dark:bg-dark-700"
        >
          <option value="">Sélectionner un produit du catalogue...</option>
          {products.map((p) => (
            <option key={p.sync_id} value={p.sync_id}>
              {p.name} (Stock actuel: {p.stock})
            </option>
          ))}
        </select>
      </div>

      <div>
        <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
          Fournisseur partenaire
        </label>
        <select
          value={form.supplier_sync_id}
          onChange={(e) => onChange({ ...form, supplier_sync_id: e.target.value })}
          className="input-toc bg-white dark:bg-dark-700"
        >
          <option value="">Sélectionner un fournisseur (optionnel)...</option>
          {suppliers.map((s) => (
            <option key={s.sync_id} value={s.sync_id}>
              {s.name} (Solde dû: {formatFCFA(s.balance)})
            </option>
          ))}
        </select>
      </div>

      <div className="grid grid-cols-2 gap-3">
        <div>
          <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
            Quantité reçue *
          </label>
          <input
            type="number"
            min="1"
            required
            value={form.quantity}
            onChange={(e) => onChange({ ...form, quantity: parseInt(e.target.value, 10) || 1 })}
            className="input-toc font-mono font-bold"
          />
        </div>
        <div>
          <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
            Coût unitaire d'achat (F CFA) *
          </label>
          <input
            type="number"
            min="0"
            step="50"
            required
            value={form.unit_cost}
            onChange={(e) => onChange({ ...form, unit_cost: parseFloat(e.target.value) || 0 })}
            className="input-toc font-mono font-bold"
          />
        </div>
      </div>

      <div className="p-3.5 bg-brand-50/50 dark:bg-dark-700/60 rounded-2xl border border-brand-100 dark:border-dark-600 flex justify-between items-center text-xs">
        <span className="font-semibold text-slate-600 dark:text-slate-300">
          Montant Total de la Réception :
        </span>
        <span className="font-extrabold text-brand-600 dark:text-brand-400 text-sm font-mono">
          {formatFCFA(form.quantity * form.unit_cost)}
        </span>
      </div>

      <div>
        <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
          Modalité de règlement
        </label>
        <div className="grid grid-cols-2 gap-3">
          <label
            className={`flex items-center justify-center gap-2 p-3 rounded-xl border text-xs font-bold cursor-pointer transition ${
              form.payment_status === 'Payé'
                ? 'border-emerald-500 bg-emerald-50 text-emerald-700 dark:bg-emerald-950/40 dark:text-emerald-300'
                : 'border-slate-200 dark:border-dark-600 text-slate-600 dark:text-slate-400'
            }`}
          >
            <input
              type="radio"
              name="payment_status"
              value="Payé"
              checked={form.payment_status === 'Payé'}
              onChange={() => onChange({ ...form, payment_status: 'Payé' })}
              className="sr-only"
            />
            <CheckCircle2 className="w-4 h-4 text-emerald-600" />
            <span>Payé (Comptant)</span>
          </label>

          <label
            className={`flex items-center justify-center gap-2 p-3 rounded-xl border text-xs font-bold cursor-pointer transition ${
              form.payment_status === 'À crédit'
                ? 'border-amber-500 bg-amber-50 text-amber-700 dark:bg-amber-950/40 dark:text-amber-300'
                : 'border-slate-200 dark:border-dark-600 text-slate-600 dark:text-slate-400'
            }`}
          >
            <input
              type="radio"
              name="payment_status"
              value="À crédit"
              checked={form.payment_status === 'À crédit'}
              onChange={() => onChange({ ...form, payment_status: 'À crédit' })}
              className="sr-only"
            />
            <Clock className="w-4 h-4 text-amber-600" />
            <span>À Crédit (Dette)</span>
          </label>
        </div>
        {form.payment_status === 'À crédit' && form.supplier_sync_id && (
          <p className="text-[11px] text-amber-600 dark:text-amber-400 mt-1.5">
            Ce montant sera ajouté automatiquement au solde débiteur du fournisseur.
          </p>
        )}
      </div>

      <div>
        <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
          Numéro de bon / Facture / Notes
        </label>
        <textarea
          rows={2}
          placeholder="Ex: Facture BL-9042, date de livraison..."
          value={form.notes}
          onChange={(e) => onChange({ ...form, notes: e.target.value })}
          className="input-toc"
        />
      </div>
    </form>
  </Drawer>
);
