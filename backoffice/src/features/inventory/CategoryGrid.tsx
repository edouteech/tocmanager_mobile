import React from 'react';
import { Tag, Edit2, Trash2, Package } from 'lucide-react';
import { Category } from '../../types';
import { formatDateTime } from '../../lib/formatters';

interface CategoryGridProps {
  categories: Category[];
  canManage: boolean;
  onEdit: (category: Category) => void;
  onDelete: (category: Category) => void;
}

export const CategoryGrid: React.FC<CategoryGridProps> = ({
  categories,
  canManage,
  onEdit,
  onDelete,
}) => (
  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
    {categories.map((c) => (
      <div key={c.sync_id} className="card-toc card-hover p-5 flex flex-col justify-between">
        <div>
          <div className="flex items-start justify-between gap-3">
            <div className="flex items-center gap-3">
              <div
                className="w-10 h-10 rounded-xl flex items-center justify-center text-white font-bold shadow-sm"
                style={{ backgroundColor: c.color || '#29ABE2' }}
              >
                <Tag className="w-5 h-5" />
              </div>
              <div>
                <h3 className="font-bold text-slate-900 dark:text-white text-base">{c.name}</h3>
                <span className="inline-flex items-center gap-1 text-xs font-medium text-slate-500 dark:text-slate-400 mt-0.5">
                  <Package className="w-3.5 h-3.5 text-brand-500" />
                  {c.products_count || 0} article(s)
                </span>
              </div>
            </div>
            {canManage && (
              <div className="flex items-center gap-1">
                <button
                  onClick={() => onEdit(c)}
                  className="p-1.5 text-slate-400 hover:text-brand-600 hover:bg-brand-50 dark:hover:bg-dark-700 rounded-xl transition"
                  title="Modifier"
                >
                  <Edit2 className="w-4 h-4" />
                </button>
                <button
                  onClick={() => onDelete(c)}
                  className="p-1.5 text-slate-400 hover:text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-950/30 rounded-xl transition"
                  title="Supprimer"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            )}
          </div>

          {c.description && (
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-3 line-clamp-2">
              {c.description}
            </p>
          )}
        </div>

        <div className="mt-4 pt-3 border-t border-[#E8EFF5] dark:border-dark-600 flex items-center justify-between text-[11px] text-slate-400">
          <span>Créée le {formatDateTime(c.created_at)}</span>
          <span
            className="w-3.5 h-3.5 rounded-full border border-white dark:border-dark-700 shadow-sm"
            style={{ backgroundColor: c.color || '#29ABE2' }}
            title={`Couleur : ${c.color}`}
          />
        </div>
      </div>
    ))}
  </div>
);
