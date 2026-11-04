import React from 'react';
import { Package, Edit2, Trash2, AlertTriangle, CheckCircle, Tag } from 'lucide-react';
import { Product } from '../../types';
import { formatFCFA } from '../../lib/formatters';

interface ProductCardProps {
  product: Product;
  categoryName?: string;
  onEdit: (product: Product) => void;
  onDelete: (product: Product) => void;
}

export const ProductCard: React.FC<ProductCardProps> = ({
  product,
  categoryName,
  onEdit,
  onDelete,
}) => {
  const isOutOfStock = product.stock <= 0;
  const isLowStock = !isOutOfStock && product.stock <= (product.min_stock || 5);

  return (
    <div className="card-toc p-4 hover:border-brand-300 dark:hover:border-brand-500/50 hover:shadow-md transition-all flex flex-col justify-between group">
      <div>
        {/* Top: Image/Icon & Stock Status Badge */}
        <div className="flex items-start justify-between gap-3 mb-3">
          <div className="flex items-center gap-3 min-w-0">
            {product.image_path ? (
              <img
                src={product.image_path}
                alt={product.name}
                className="w-12 h-12 rounded-2xl object-cover border border-slate-200 dark:border-dark-600 shrink-0"
              />
            ) : (
              <div className="w-12 h-12 rounded-2xl bg-brand-50 dark:bg-brand-500/15 border border-brand-200 dark:border-brand-500/30 flex items-center justify-center shrink-0 text-brand-600 dark:text-brand-400">
                <Package className="w-6 h-6" />
              </div>
            )}
            <div className="min-w-0">
              <h4 className="font-bold text-sm text-[#1C2B3A] dark:text-white truncate">
                {product.name}
              </h4>
              <div className="flex items-center gap-1.5 mt-0.5">
                <span className="inline-flex items-center gap-1 text-[11px] text-slate-500 dark:text-slate-400">
                  <Tag className="w-3 h-3 text-slate-400" />
                  <span className="truncate">{categoryName || 'Sans catégorie'}</span>
                </span>
                <span className="text-[10px] text-slate-400">·</span>
                <span className="text-[11px] text-slate-400">
                  {product.unit || 'pièce'}
                </span>
              </div>
            </div>
          </div>

          {/* Stock Badge */}
          <div className="shrink-0">
            {isOutOfStock ? (
              <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-xl text-[11px] font-bold bg-rose-50 dark:bg-rose-500/15 text-rose-600 dark:text-rose-400 border border-rose-200 dark:border-rose-500/30">
                <AlertTriangle className="w-3 h-3" />
                <span>Rupture</span>
              </span>
            ) : isLowStock ? (
              <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-xl text-[11px] font-bold bg-amber-50 dark:bg-amber-500/15 text-amber-600 dark:text-amber-400 border border-amber-200 dark:border-amber-500/30">
                <AlertTriangle className="w-3 h-3" />
                <span>Faible ({product.stock})</span>
              </span>
            ) : (
              <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-xl text-[11px] font-bold bg-emerald-50 dark:bg-emerald-500/15 text-emerald-600 dark:text-emerald-400 border border-emerald-200 dark:border-emerald-500/30">
                <CheckCircle className="w-3 h-3" />
                <span>{product.stock} {product.unit || 'en stock'}</span>
              </span>
            )}
          </div>
        </div>

        {/* Pricing Info */}
        <div className="bg-[#F5FAFD] dark:bg-dark-700/50 p-2.5 rounded-xl border border-[#E8EFF5] dark:border-dark-600 flex items-center justify-between text-xs mb-3">
          <div>
            <span className="text-[10px] text-slate-400 block">Prix de Vente</span>
            <span className="font-extrabold text-sm text-slate-900 dark:text-white font-mono">
              {formatFCFA(product.price)}
            </span>
          </div>
          {product.cost_price !== undefined && product.cost_price > 0 && (
            <div className="text-right">
              <span className="text-[10px] text-slate-400 block">Prix d'Achat</span>
              <span className="font-semibold text-slate-600 dark:text-slate-300 font-mono">
                {formatFCFA(product.cost_price)}
              </span>
            </div>
          )}
        </div>
      </div>

      {/* Footer: Quick Actions */}
      <div className="border-t border-slate-100 dark:border-dark-600/70 pt-2.5 flex items-center justify-between">
        <span className="text-[11px] text-slate-400 font-medium">
          Alerte: min {product.min_stock || 5}
        </span>
        <div className="flex items-center gap-1">
          <button
            type="button"
            onClick={() => onEdit(product)}
            className="p-1.5 text-slate-500 hover:text-brand-600 hover:bg-brand-50 dark:hover:bg-brand-500/10 rounded-xl transition"
            title="Modifier le produit"
          >
            <Edit2 className="w-4 h-4" />
          </button>
          <button
            type="button"
            onClick={() => onDelete(product)}
            className="p-1.5 text-slate-500 hover:text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-500/10 rounded-xl transition"
            title="Supprimer le produit"
          >
            <Trash2 className="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>
  );
};
