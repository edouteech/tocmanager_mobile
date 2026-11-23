import React from 'react';
import { AlertTriangle, CheckCircle, Edit2, Package, Tag, Trash2 } from 'lucide-react';
import { Category, Product } from '../../types';
import { formatFCFA } from '../../lib/formatters';
import { useDensity } from '../../context/DensityContext';

interface ProductsTableProps {
  products: Product[];
  categoriesMap: Map<string, Category>;
  canManage: boolean;
  onEdit: (product: Product) => void;
  onDelete: (product: Product) => void;
}

export const ProductsTable: React.FC<ProductsTableProps> = ({
  products,
  categoriesMap,
  canManage,
  onEdit,
  onDelete,
}) => {
  const { tableClasses } = useDensity();

  return (
    <div className="card-toc overflow-hidden">
      <div className="overflow-x-auto">
        <table className="w-full text-left min-w-[700px]">
          <thead className="bg-[#F5FAFD] dark:bg-dark-700/50 border-b border-[#E8EFF5] dark:border-dark-600">
            <tr>
              <th className={tableClasses.th}>Désignation</th>
              <th className={tableClasses.th}>Catégorie</th>
              <th className={`${tableClasses.th} text-right`}>Prix Vente</th>
              <th className={`${tableClasses.th} text-right`}>Coût Achat</th>
              <th className={`${tableClasses.th} text-center`}>Stock Actuel</th>
              <th className={`${tableClasses.th} text-center`}>État Stock</th>
              {canManage && <th className={`${tableClasses.th} text-right`}>Actions</th>}
            </tr>
          </thead>
          <tbody className="divide-y divide-[#E8EFF5] dark:divide-dark-600/60">
            {products.map((p) => {
              const isOut = p.stock <= 0;
              const isLow = !isOut && p.stock <= (p.min_stock || 5);
              const cat = p.category_sync_id ? categoriesMap.get(p.category_sync_id) : undefined;

              return (
                <tr key={p.sync_id} className="hover:bg-brand-50/30 dark:hover:bg-dark-700/40 transition-colors">
                  <td className={`${tableClasses.td} font-bold text-slate-900 dark:text-white`}>
                    <div className="flex items-center gap-3">
                      {p.image_path ? (
                        <img
                          src={p.image_path}
                          alt={p.name}
                          className="w-9 h-9 rounded-xl object-cover border border-slate-200 dark:border-dark-600 shadow-sm shrink-0"
                        />
                      ) : (
                        <div className="w-9 h-9 rounded-xl bg-brand-50 dark:bg-brand-500/15 text-brand-600 dark:text-brand-400 flex items-center justify-center font-bold shrink-0">
                          <Package className="w-4 h-4" />
                        </div>
                      )}
                      <span className="truncate max-w-[220px]">{p.name}</span>
                    </div>
                  </td>
                  <td className={tableClasses.td}>
                    {cat ? (
                      <span
                        className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-semibold"
                        style={{
                          backgroundColor: `${cat.color || '#29ABE2'}18`,
                          color: cat.color || '#29ABE2',
                        }}
                      >
                        <Tag className="w-3 h-3" />
                        {cat.name}
                      </span>
                    ) : (
                      <span className="text-xs text-slate-400">Non classé</span>
                    )}
                  </td>
                  <td className={`${tableClasses.td} text-right font-extrabold text-slate-900 dark:text-white font-mono`}>
                    {formatFCFA(p.price)}
                  </td>
                  <td className={`${tableClasses.td} text-right text-xs text-slate-500 dark:text-slate-400 font-mono`}>
                    {formatFCFA(p.cost_price)}
                  </td>
                  <td className={`${tableClasses.td} text-center font-bold text-slate-900 dark:text-white`}>
                    {p.stock} <span className="text-xs text-slate-400 font-normal">{p.unit || 'pce'}</span>
                  </td>
                  <td className={`${tableClasses.td} text-center`}>
                    {isOut ? (
                      <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-bold bg-rose-50 dark:bg-rose-950/40 text-rose-700 dark:text-rose-400 border border-rose-200 dark:border-rose-900/50">
                        <AlertTriangle className="w-3.5 h-3.5 text-rose-600 dark:text-rose-400" />
                        <span>Rupture</span>
                      </span>
                    ) : isLow ? (
                      <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-bold bg-amber-50 dark:bg-amber-950/40 text-amber-700 dark:text-amber-400 border border-amber-200 dark:border-amber-900/50">
                        <AlertTriangle className="w-3.5 h-3.5 text-amber-600 dark:text-amber-400" />
                        <span>Faible ({p.stock})</span>
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-400 border border-emerald-100 dark:border-emerald-900/50">
                        <CheckCircle className="w-3.5 h-3.5 text-emerald-600 dark:text-emerald-400" />
                        <span>Normal</span>
                      </span>
                    )}
                  </td>
                  {canManage && (
                    <td className={`${tableClasses.td} text-right`}>
                      <div className="flex items-center justify-end gap-2">
                        <button
                          onClick={() => onEdit(p)}
                          className="p-1.5 text-slate-400 hover:text-brand-600 hover:bg-brand-50 dark:hover:bg-dark-700 rounded-xl transition"
                          title="Modifier"
                        >
                          <Edit2 className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => onDelete(p)}
                          className="p-1.5 text-slate-400 hover:text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-950/30 rounded-xl transition"
                          title="Supprimer"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  )}
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
};
