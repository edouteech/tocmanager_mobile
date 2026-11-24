import React from 'react';
import { Search, Plus } from 'lucide-react';
import { Category, Product } from '../../types';
import { formatFCFA } from '../../lib/formatters';
import { IconInput } from '../../components/common/IconInput';

export interface PosCartItem {
  product: Product;
  quantity: number;
  unit_price: number;
}

interface PosProductCatalogProps {
  products: Product[];
  filteredProducts: Product[];
  categories: Category[];
  cart: PosCartItem[];
  isLoading: boolean;
  searchTerm: string;
  selectedCategory: string;
  onSearchChange: (val: string) => void;
  onCategoryChange: (catId: string) => void;
  onAddToCart: (product: Product) => void;
}

export const PosProductCatalog: React.FC<PosProductCatalogProps> = ({
  products,
  filteredProducts,
  categories,
  cart,
  isLoading,
  searchTerm,
  selectedCategory,
  onSearchChange,
  onCategoryChange,
  onAddToCart,
}) => (
  <div className="lg:col-span-7 space-y-4">
    <div className="space-y-3">
      <IconInput
        icon={<Search className="w-4 h-4" />}
        iconClassName="text-slate-400"
        type="text"
        value={searchTerm}
        onChange={(e) => onSearchChange(e.target.value)}
        placeholder="Rechercher par nom de produit ou code-barres..."
        className="text-sm"
        autoFocus
      />

      <div className="flex items-center gap-1.5 overflow-x-auto pb-1 scrollbar-thin">
        <button
          onClick={() => onCategoryChange('all')}
          className={`px-3 py-1.5 rounded-xl text-xs font-bold transition-all whitespace-nowrap ${
            selectedCategory === 'all'
              ? 'bg-brand-600 text-white shadow-sm'
              : 'bg-slate-100 dark:bg-dark-700 text-slate-600 dark:text-slate-400 hover:bg-slate-200'
          }`}
        >
          Tous ({products.length})
        </button>
        {categories.map((c) => (
          <button
            key={c.sync_id}
            onClick={() => onCategoryChange(c.sync_id)}
            className={`px-3 py-1.5 rounded-xl text-xs font-bold transition-all whitespace-nowrap ${
              selectedCategory === c.sync_id
                ? 'bg-brand-600 text-white shadow-sm'
                : 'bg-slate-100 dark:bg-dark-700 text-slate-600 dark:text-slate-400 hover:bg-slate-200'
            }`}
          >
            {c.name}
          </button>
        ))}
      </div>
    </div>

    <div className="h-[380px] overflow-y-auto pr-1 grid grid-cols-2 sm:grid-cols-3 gap-3">
      {isLoading ? (
        <div className="col-span-full text-center py-12 text-slate-400 text-sm">
          Chargement des produits...
        </div>
      ) : filteredProducts.length > 0 ? (
        filteredProducts.map((p) => {
          const isInCart = cart.find((it) => it.product.sync_id === p.sync_id);
          const isOutOfStock = p.stock <= 0;
          return (
            <button
              key={p.sync_id}
              onClick={() => !isOutOfStock && onAddToCart(p)}
              disabled={isOutOfStock}
              className={`text-left p-3 rounded-2xl border transition-all flex flex-col justify-between relative group ${
                isOutOfStock
                  ? 'opacity-40 bg-slate-50 dark:bg-dark-800/50 border-slate-200 dark:border-dark-700 cursor-not-allowed'
                  : isInCart
                    ? 'bg-brand-50/50 dark:bg-brand-950/20 border-brand-400 dark:border-brand-500 shadow-sm'
                    : 'bg-white dark:bg-dark-700/60 border-slate-200/80 dark:border-dark-600 hover:border-brand-300 dark:hover:border-brand-500 hover:shadow-md'
              }`}
            >
              {isInCart && (
                <span className="absolute top-2 right-2 w-5 h-5 rounded-full bg-brand-600 text-white text-[10px] font-extrabold flex items-center justify-center shadow">
                  {isInCart.quantity}
                </span>
              )}
              <div className="flex gap-2.5 items-start">
                {p.image_path ? (
                  <img
                    src={p.image_path}
                    alt={p.name}
                    className="w-10 h-10 rounded-xl object-cover border border-slate-200 dark:border-dark-600 shrink-0 shadow-sm"
                  />
                ) : null}
                <div className="min-w-0 flex-1">
                  <h5 className="font-bold text-xs text-slate-900 dark:text-white line-clamp-2 leading-tight">
                    {p.name}
                  </h5>
                  <div className="mt-1 flex items-center gap-1.5">
                    <span
                      className={`text-[10px] font-bold px-1.5 py-0.5 rounded-md ${
                        p.stock > 5
                          ? 'bg-emerald-50 dark:bg-emerald-500/10 text-emerald-600 dark:text-emerald-400'
                          : p.stock > 0
                            ? 'bg-amber-50 dark:bg-amber-500/10 text-amber-600 dark:text-amber-400'
                            : 'bg-red-50 dark:bg-red-500/10 text-red-600 dark:text-red-400'
                      }`}
                    >
                      Stock: {p.stock} {p.unit || 'pièce'}
                    </span>
                  </div>
                </div>
              </div>

              <div className="mt-3 pt-2 border-t border-slate-100 dark:border-dark-600 flex items-center justify-between">
                <span className="font-extrabold text-sm text-brand-600 dark:text-brand-400 font-mono">
                  {formatFCFA(p.price)}
                </span>
                <div className="w-6 h-6 rounded-lg bg-brand-50 dark:bg-brand-500/10 text-brand-600 dark:text-brand-400 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                  <Plus className="w-3.5 h-3.5" />
                </div>
              </div>
            </button>
          );
        })
      ) : (
        <div className="col-span-full text-center py-12 text-slate-400 text-sm">
          Aucun produit ne correspond à cette recherche.
        </div>
      )}
    </div>
  </div>
);
