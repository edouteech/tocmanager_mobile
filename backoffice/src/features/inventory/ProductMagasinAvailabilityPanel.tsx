import React, { useState, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Store, Building2, Save, Check } from 'lucide-react';
import { productsApi } from '../../lib/api';
import { ProductMagasinItem } from '../../types';
import { formatFCFA } from '../../lib/formatters';

interface ProductMagasinAvailabilityPanelProps {
  productSyncId: string;
  cataloguePrice: number;
}

interface RowDraft {
  is_available: boolean;
  custom_price: string;
  min_stock: string;
}

export const ProductMagasinAvailabilityPanel: React.FC<ProductMagasinAvailabilityPanelProps> = ({
  productSyncId,
  cataloguePrice,
}) => {
  const queryClient = useQueryClient();
  const [drafts, setDrafts] = useState<Record<string, RowDraft>>({});
  const [savedMagId, setSavedMagId] = useState<string | null>(null);

  const { data: rows = [], isLoading } = useQuery<ProductMagasinItem[]>({
    queryKey: ['product-magasins', productSyncId],
    queryFn: () => productsApi.getMagasins(productSyncId),
    enabled: Boolean(productSyncId),
  });

  useEffect(() => {
    const next: Record<string, RowDraft> = {};
    rows.forEach((r) => {
      next[r.magasin_id] = {
        is_available: r.is_available,
        custom_price: r.custom_price != null ? String(r.custom_price) : '',
        min_stock: String(r.min_stock ?? 5),
      };
    });
    setDrafts(next);
  }, [rows]);

  const updateMutation = useMutation({
    mutationFn: ({ magasinId, draft }: { magasinId: string; draft: RowDraft }) => {
      const trimmedPrice = draft.custom_price.trim();
      return productsApi.updateMagasinConfig(productSyncId, magasinId, {
        is_available: draft.is_available,
        custom_price: trimmedPrice !== '' ? Number(trimmedPrice) : undefined,
        clear_custom_price: trimmedPrice === '',
        min_stock: draft.min_stock !== '' ? Number(draft.min_stock) : undefined,
      });
    },
    onSuccess: (_, variables) => {
      setSavedMagId(variables.magasinId);
      setTimeout(() => setSavedMagId(null), 2000);
      queryClient.invalidateQueries({ queryKey: ['product-magasins', productSyncId] });
      queryClient.invalidateQueries({ queryKey: ['products'] });
    },
  });

  if (isLoading) {
    return <div className="py-8 text-center text-xs text-slate-400">Chargement des magasins...</div>;
  }

  return (
    <div className="space-y-3">
      <div className="p-3 rounded-xl bg-slate-50 dark:bg-dark-700/60 border border-slate-200 dark:border-dark-600 text-xs text-slate-600 dark:text-slate-300">
        Prix catalogue de référence : <strong className="font-mono">{formatFCFA(cataloguePrice)}</strong>.
        Laissez le prix spécifique vide pour hériter automatiquement du prix catalogue.
      </div>

      {rows.map((row) => {
        const draft = drafts[row.magasin_id] || {
          is_available: row.is_available,
          custom_price: '',
          min_stock: String(row.min_stock ?? 5),
        };
        return (
          <div
            key={row.magasin_id}
            className="p-3.5 rounded-2xl border border-slate-200 dark:border-dark-600 bg-white dark:bg-dark-700 space-y-3"
          >
            <div className="flex items-center justify-between gap-2">
              <div className="flex items-center gap-2 min-w-0">
                <span className="w-7 h-7 rounded-lg bg-brand-50 dark:bg-brand-500/15 text-brand-600 dark:text-brand-400 flex items-center justify-center shrink-0">
                  {row.is_warehouse ? <Building2 className="w-4 h-4" /> : <Store className="w-4 h-4" />}
                </span>
                <div className="min-w-0">
                  <p className="text-xs font-bold text-slate-900 dark:text-white truncate">
                    {row.magasin_name}
                  </p>
                  <p className="text-[11px] text-slate-400">
                    Stock actuel : <strong className="font-mono text-slate-700 dark:text-slate-200">{row.quantity}</strong>
                  </p>
                </div>
              </div>

              <label className="inline-flex items-center gap-1.5 text-xs font-semibold cursor-pointer">
                <input
                  type="checkbox"
                  checked={draft.is_available}
                  onChange={(e) =>
                    setDrafts((prev) => ({
                      ...prev,
                      [row.magasin_id]: { ...draft, is_available: e.target.checked },
                    }))
                  }
                  className="rounded text-brand-600"
                />
                <span>{draft.is_available ? 'Actif' : 'Désactivé'}</span>
              </label>
            </div>

            <div className="grid grid-cols-2 gap-2.5 text-xs">
              <div>
                <label className="block text-[10px] font-bold uppercase text-slate-400 mb-1">
                  Prix local (optionnel)
                </label>
                <input
                  type="number"
                  min="0"
                  placeholder={String(cataloguePrice)}
                  value={draft.custom_price}
                  onChange={(e) =>
                    setDrafts((prev) => ({
                      ...prev,
                      [row.magasin_id]: { ...draft, custom_price: e.target.value },
                    }))
                  }
                  className="input-toc py-1.5 text-xs font-mono"
                />
              </div>
              <div>
                <label className="block text-[10px] font-bold uppercase text-slate-400 mb-1">
                  Seuil alerte stock
                </label>
                <input
                  type="number"
                  min="0"
                  value={draft.min_stock}
                  onChange={(e) =>
                    setDrafts((prev) => ({
                      ...prev,
                      [row.magasin_id]: { ...draft, min_stock: e.target.value },
                    }))
                  }
                  className="input-toc py-1.5 text-xs font-mono"
                />
              </div>
            </div>

            <div className="flex justify-end">
              <button
                type="button"
                disabled={updateMutation.isPending}
                onClick={() => updateMutation.mutate({ magasinId: row.magasin_id, draft })}
                className="btn-toc btn-outline py-1 px-3 text-xs flex items-center gap-1.5"
              >
                {savedMagId === row.magasin_id ? (
                  <>
                    <Check className="w-3.5 h-3.5 text-emerald-600" />
                    <span className="text-emerald-600">Enregistré</span>
                  </>
                ) : (
                  <>
                    <Save className="w-3.5 h-3.5" />
                    <span>Enregistrer pour ce magasin</span>
                  </>
                )}
              </button>
            </div>
          </div>
        );
      })}
    </div>
  );
};
