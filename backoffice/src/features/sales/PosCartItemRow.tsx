import React from 'react';
import { Plus, Minus, Trash2 } from 'lucide-react';
import { formatFCFA } from '../../lib/formatters';
import { PosCartItem } from './PosProductCatalog';

interface PosCartItemRowProps {
  item: PosCartItem;
  canOverridePrice: boolean;
  onUpdateQty: (id: string, delta: number) => void;
  onUpdateUnitPrice: (id: string, price: number) => void;
  onRemoveItem: (id: string) => void;
}

export const PosCartItemRow: React.FC<PosCartItemRowProps> = ({
  item,
  canOverridePrice,
  onUpdateQty,
  onUpdateUnitPrice,
  onRemoveItem,
}) => (
  <div className="bg-white dark:bg-dark-700 p-2.5 rounded-xl border border-slate-200/80 dark:border-dark-600 flex items-center justify-between gap-2 shadow-sm">
    <div className="min-w-0 flex-1">
      <p className="font-bold text-xs text-slate-900 dark:text-white truncate">{item.product.name}</p>
      {canOverridePrice ? (
        <div className="flex items-center gap-1.5 text-[11px] text-slate-500 font-mono mt-0.5">
          <input
            type="number"
            min="0"
            value={item.unit_price}
            onChange={(e) => onUpdateUnitPrice(item.product.sync_id, Number(e.target.value) || 0)}
            aria-label={`Prix unitaire ${item.product.name}`}
            className="w-20 px-1.5 py-0.5 rounded border border-slate-200 dark:border-dark-600 bg-slate-50 dark:bg-dark-800 text-xs font-mono text-slate-900 dark:text-white"
          />
          <span>
            × {item.quantity} = {formatFCFA(item.quantity * item.unit_price)}
          </span>
        </div>
      ) : (
        <p className="text-[11px] text-slate-500 font-mono">
          {formatFCFA(item.unit_price)} × {item.quantity} = {formatFCFA(item.quantity * item.unit_price)}
        </p>
      )}
    </div>

    <div className="flex items-center gap-1.5">
      <button
        onClick={() => onUpdateQty(item.product.sync_id, -1)}
        className="w-6 h-6 rounded-md bg-slate-100 dark:bg-dark-600 text-slate-600 dark:text-slate-300 flex items-center justify-center hover:bg-slate-200"
      >
        <Minus className="w-3 h-3" />
      </button>
      <span className="w-6 text-center font-bold text-xs text-slate-900 dark:text-white font-mono">
        {item.quantity}
      </span>
      <button
        onClick={() => onUpdateQty(item.product.sync_id, 1)}
        className="w-6 h-6 rounded-md bg-slate-100 dark:bg-dark-600 text-slate-600 dark:text-slate-300 flex items-center justify-center hover:bg-slate-200"
      >
        <Plus className="w-3 h-3" />
      </button>
      <button
        onClick={() => onRemoveItem(item.product.sync_id)}
        className="w-6 h-6 rounded-md text-red-400 hover:text-red-600 flex items-center justify-center ml-1"
      >
        <Trash2 className="w-3 h-3" />
      </button>
    </div>
  </div>
);
