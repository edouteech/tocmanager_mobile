import React from 'react';
import { ShoppingCart, User, AlertCircle, Receipt, Store } from 'lucide-react';
import { Client, Magasin } from '../../types';
import { formatFCFA } from '../../lib/formatters';
import { PosCartItem } from './PosProductCatalog';
import { PosCartItemRow } from './PosCartItemRow';

interface PosCartPanelProps {
  cart: PosCartItem[];
  clients: Client[];
  retailMagasins: Magasin[];
  needsExplicitMagasinSelector: boolean;
  targetMagasinId: string;
  selectedClientId: string;
  paymentMethod: string;
  canCreditSales: boolean;
  canOverridePrice: boolean;
  discountAmount: number;
  paidAmount: number;
  paidAmountTouched: boolean;
  effectivePaidAmount: number;
  totalAmount: number;
  changeToReturn: number;
  debtRemaining: number;
  notes: string;
  errorMessage: string | null;
  isSubmitting: boolean;
  onClearCart: () => void;
  onUpdateQty: (id: string, delta: number) => void;
  onUpdateUnitPrice: (id: string, price: number) => void;
  onRemoveItem: (id: string) => void;
  onSelectMagasin: (id: string) => void;
  onSelectClient: (id: string) => void;
  onPaymentMethodChange: (method: string) => void;
  onDiscountChange: (val: number) => void;
  onPaidAmountChange: (val: number) => void;
  onExactPaidAmount: () => void;
  onNotesChange: (val: string) => void;
  onCancel: () => void;
  onSubmit: () => void;
}

export const PosCartPanel: React.FC<PosCartPanelProps> = (props) => {
  const {
    cart,
    clients,
    retailMagasins,
    needsExplicitMagasinSelector,
    targetMagasinId,
    selectedClientId,
    paymentMethod,
    canCreditSales,
    canOverridePrice,
    discountAmount,
    paidAmount,
    paidAmountTouched,
    effectivePaidAmount,
    totalAmount,
    changeToReturn,
    debtRemaining,
    notes,
    errorMessage,
    isSubmitting,
  } = props;

  return (
    <div className="lg:col-span-5 bg-slate-50/80 dark:bg-dark-700 p-4 rounded-2xl border border-slate-200 dark:border-dark-600 flex flex-col justify-between space-y-4">
      <div className="space-y-4">
        <div className="flex items-center justify-between pb-2 border-b border-slate-200 dark:border-dark-600">
          <span className="font-bold text-sm text-slate-900 dark:text-white flex items-center gap-1.5">
            <ShoppingCart className="w-4 h-4 text-brand-500" />
            Panier ({cart.reduce((sum, it) => sum + it.quantity, 0)})
          </span>
          {cart.length > 0 && (
            <button onClick={props.onClearCart} className="text-xs text-red-500 hover:text-red-700 font-semibold">
              Vider le panier
            </button>
          )}
        </div>

        <div className="max-h-44 overflow-y-auto space-y-2 pr-1">
          {cart.length === 0 ? (
            <div className="text-center py-8 text-slate-400 text-xs flex flex-col items-center gap-2">
              <ShoppingCart className="w-8 h-8 opacity-40 text-slate-400" />
              <span>Cliquez sur des articles pour remplir le panier</span>
            </div>
          ) : (
            cart.map((item) => (
              <PosCartItemRow
                key={item.product.sync_id}
                item={item}
                canOverridePrice={canOverridePrice}
                onUpdateQty={props.onUpdateQty}
                onUpdateUnitPrice={props.onUpdateUnitPrice}
                onRemoveItem={props.onRemoveItem}
              />
            ))
          )}
        </div>

        {needsExplicitMagasinSelector && (
          <div className="space-y-1.5 pt-2 border-t border-slate-200 dark:border-dark-600">
            <label className="text-xs font-bold text-amber-600 dark:text-amber-400 flex items-center gap-1">
              <Store className="w-3 h-3" />
              Point de vente *
            </label>
            <select
              value={targetMagasinId}
              onChange={(e) => props.onSelectMagasin(e.target.value)}
              className="input-toc text-xs py-1.5"
            >
              <option value="">Pour quel magasin ?</option>
              {retailMagasins.map((m) => (
                <option key={m.id} value={m.id}>
                  {m.name}
                </option>
              ))}
            </select>
          </div>
        )}

        <div className="space-y-1.5 pt-2 border-t border-slate-200 dark:border-dark-600">
          <label className="text-xs font-bold text-slate-700 dark:text-slate-300 flex items-center gap-1">
            <User className="w-3 h-3 text-brand-500" />
            Client
          </label>
          <select
            value={selectedClientId}
            onChange={(e) => props.onSelectClient(e.target.value)}
            className="input-toc text-xs py-1.5"
          >
            <option value="">Client Occasionnel (Comptoir)</option>
            {clients.map((c) => (
              <option key={c.sync_id} value={c.sync_id}>
                {c.name} {c.balance > 0 ? `(Dette: ${formatFCFA(c.balance)})` : ''}
              </option>
            ))}
          </select>
        </div>

        <div className="grid grid-cols-2 gap-2">
          <div className="space-y-1">
            <label className="text-[11px] font-bold text-slate-700 dark:text-slate-300">Mode Paiement</label>
            <select
              value={paymentMethod}
              onChange={(e) => props.onPaymentMethodChange(e.target.value)}
              className="input-toc text-xs py-1.5"
            >
              <option value="Espèces">Espèces</option>
              <option value="Wave">Wave</option>
              <option value="Orange Money">Orange Money</option>
              <option value="Moov Money">Moov Money</option>
              <option value="Carte Bancaire">Carte Bancaire</option>
              <option value="Crédit">{canCreditSales ? 'Crédit' : 'Crédit (PRO)'}</option>
            </select>
          </div>

          <div className="space-y-1">
            <label className="text-[11px] font-bold text-slate-700 dark:text-slate-300">Remise (FCFA)</label>
            <input
              type="number"
              min="0"
              value={discountAmount || ''}
              onChange={(e) => props.onDiscountChange(Number(e.target.value) || 0)}
              placeholder="0"
              className="input-toc text-xs py-1.5 font-mono"
            />
          </div>
        </div>

        <div className="space-y-1">
          <div className="flex justify-between text-[11px] font-bold text-slate-700 dark:text-slate-300">
            <span>Montant Reçu (FCFA)</span>
            <button type="button" onClick={props.onExactPaidAmount} className="text-brand-600 hover:underline text-[10px]">
              Montant exact
            </button>
          </div>
          <input
            type="number"
            min="0"
            value={paidAmountTouched ? paidAmount : totalAmount}
            onChange={(e) => props.onPaidAmountChange(Number(e.target.value) || 0)}
            className="input-toc text-sm py-1.5 font-mono font-bold"
          />
        </div>

        <div className="space-y-1">
          <label className="text-[11px] font-bold text-slate-700 dark:text-slate-300">
            Notes / Référence ticket (optionnel)
          </label>
          <textarea
            rows={2}
            value={notes}
            onChange={(e) => props.onNotesChange(e.target.value)}
            placeholder="Remarque client, bon de livraison..."
            className="input-toc text-xs py-1.5"
          />
        </div>

        {effectivePaidAmount > totalAmount && (
          <div className="p-2 rounded-xl bg-emerald-50 dark:bg-emerald-500/10 border border-emerald-200 dark:border-emerald-500/20 flex justify-between items-center text-xs text-emerald-700 dark:text-emerald-400 font-bold">
            <span>Monnaie à rendre :</span>
            <span className="font-mono text-sm">{formatFCFA(changeToReturn)}</span>
          </div>
        )}
        {debtRemaining > 0 && (
          <div className="p-2 rounded-xl bg-amber-50 dark:bg-amber-500/10 border border-amber-200 dark:border-amber-500/20 flex justify-between items-center text-xs text-amber-700 dark:text-amber-400 font-bold">
            <span>Solde restant (Créance) :</span>
            <span className="font-mono text-sm">{formatFCFA(debtRemaining)}</span>
          </div>
        )}

        {errorMessage && (
          <div className="p-2.5 rounded-xl bg-red-50 dark:bg-red-500/10 border border-red-200 dark:border-red-500/20 flex items-start gap-2 text-xs text-red-600 dark:text-red-400 font-medium">
            <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
            <span>{errorMessage}</span>
          </div>
        )}
      </div>

      <div className="pt-3 border-t border-slate-200 dark:border-dark-600 space-y-3">
        <div className="flex justify-between items-baseline">
          <span className="text-xs font-bold text-slate-500 dark:text-slate-400 uppercase">Total à encaisser :</span>
          <span className="text-xl font-extrabold text-slate-900 dark:text-white font-mono">
            {formatFCFA(totalAmount)}
          </span>
        </div>

        <div className="flex gap-2">
          <button type="button" onClick={props.onCancel} className="btn-secondary flex-1 py-2 text-xs">
            Annuler
          </button>
          <button
            type="button"
            onClick={props.onSubmit}
            disabled={cart.length === 0 || isSubmitting}
            className="btn-primary flex-[2] py-2 text-xs font-extrabold flex items-center justify-center gap-1.5 shadow-md shadow-brand-500/20"
          >
            <Receipt className="w-4 h-4" />
            <span>{isSubmitting ? 'Encaissement...' : 'Valider & Encaisser'}</span>
          </button>
        </div>
      </div>
    </div>
  );
};
