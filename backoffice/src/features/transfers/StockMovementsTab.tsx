import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { ClipboardCheck, ArrowUpRight, ArrowDownLeft } from 'lucide-react';
import { productsApi, stockMovementsApi } from '../../lib/api';
import { Product, StockMovement } from '../../types';
import { useTenantStore, useTenantContextKey } from '../../stores/tenantStore';
import { formatDateTime } from '../../lib/formatters';
import { Modal } from '../../components/common/Modal';

export const StockMovementsTab: React.FC = () => {
  const queryClient = useQueryClient();
  const [boutiqueKey, magasinKey] = useTenantContextKey();
  const { magasins, currentMagasin } = useTenantStore();
  const [typeFilter, setTypeFilter] = useState('');
  const [adjustOpen, setAdjustOpen] = useState(false);
  const [magId, setMagId] = useState('');
  const [prodId, setProdId] = useState('');
  const [countedQty, setCountedQty] = useState<number>(0);
  const [movType, setMovType] = useState<'adjustment' | 'loss'>('adjustment');
  const [reason, setReason] = useState('');
  const [adjustErr, setAdjustErr] = useState<string | null>(null);

  const { data: movements = [], isLoading } = useQuery<StockMovement[]>({
    queryKey: ['stock-movements', boutiqueKey, magasinKey, typeFilter],
    queryFn: () =>
      stockMovementsApi.getAll({
        movement_type: typeFilter || undefined,
      }),
  });

  const { data: products = [] } = useQuery<Product[]>({
    queryKey: ['products', boutiqueKey, magasinKey],
    queryFn: () => productsApi.getAll(),
  });

  const adjustMutation = useMutation({
    mutationFn: stockMovementsApi.adjust,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['stock-movements'] });
      queryClient.invalidateQueries({ queryKey: ['products'] });
      setAdjustOpen(false);
      setReason('');
      setAdjustErr(null);
    },
    onError: (err: any) => {
      setAdjustErr(err.response?.data?.detail || "Erreur lors de l'ajustement.");
    },
  });

  const openAdjust = () => {
    setMagId(currentMagasin?.id || magasins[0]?.id || '');
    setProdId(products[0]?.sync_id || '');
    setCountedQty(0);
    setMovType('adjustment');
    setReason('');
    setAdjustErr(null);
    setAdjustOpen(true);
  };

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <select
          value={typeFilter}
          onChange={(e) => setTypeFilter(e.target.value)}
          className="input-toc w-56 text-xs bg-white dark:bg-dark-700"
        >
          <option value="">Tous les types de mouvement</option>
          <option value="sale">Vente (sale)</option>
          <option value="supply">Approvisionnement (supply)</option>
          <option value="transfer_out">Sortie transfert</option>
          <option value="transfer_in">Entrée transfert</option>
          <option value="adjustment">Ajustement inventaire</option>
          <option value="loss">Perte / Casse</option>
          <option value="return">Retour client</option>
        </select>

        <button onClick={openAdjust} className="btn-primary text-xs flex items-center gap-1.5">
          <ClipboardCheck className="w-4 h-4" />
          <span>Ajustement d'inventaire</span>
        </button>
      </div>

      <div className="card-toc overflow-x-auto">
        {isLoading ? (
          <div className="p-10 text-center text-xs text-slate-400">Chargement du journal...</div>
        ) : movements.length === 0 ? (
          <div className="p-10 text-center text-xs text-slate-400">Aucun mouvement de stock enregistré.</div>
        ) : (
          <table className="w-full text-left text-xs">
            <thead className="bg-slate-50 dark:bg-dark-700/60 border-b border-slate-200 dark:border-dark-600 text-[11px] uppercase text-slate-500">
              <tr>
                <th className="py-3 px-4">Date</th>
                <th className="py-3 px-4">Magasin</th>
                <th className="py-3 px-4">Article</th>
                <th className="py-3 px-4">Type</th>
                <th className="py-3 px-4 text-right">Variation</th>
                <th className="py-3 px-4 text-right">Solde</th>
                <th className="py-3 px-4">Motif / Opérateur</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 dark:divide-dark-600">
              {movements.map((m) => {
                const isPos = m.quantity_delta >= 0;
                return (
                  <tr key={m.id} className="hover:bg-slate-50/70 dark:hover:bg-dark-700/40">
                    <td className="py-2.5 px-4 whitespace-nowrap text-slate-500">{formatDateTime(m.created_at)}</td>
                    <td className="py-2.5 px-4 font-semibold">{m.magasin_name || m.magasin_id}</td>
                    <td className="py-2.5 px-4 font-bold text-slate-900 dark:text-white">{m.product_name || m.product_sync_id}</td>
                    <td className="py-2.5 px-4">
                      <span className="px-2 py-0.5 rounded-full bg-slate-100 dark:bg-dark-600 font-mono text-[10px]">
                        {m.movement_type}
                      </span>
                    </td>
                    <td className={`py-2.5 px-4 text-right font-mono font-bold ${isPos ? 'text-emerald-600' : 'text-rose-600'}`}>
                      <span className="inline-flex items-center gap-0.5">
                        {isPos ? <ArrowDownLeft className="w-3 h-3" /> : <ArrowUpRight className="w-3 h-3" />}
                        {isPos ? `+${m.quantity_delta}` : m.quantity_delta}
                      </span>
                    </td>
                    <td className="py-2.5 px-4 text-right font-mono">
                      {m.balance_before} → <strong>{m.balance_after}</strong>
                    </td>
                    <td className="py-2.5 px-4 text-slate-500">
                      <div>{m.reason || '-'}</div>
                      {m.user_name && <div className="text-[10px] text-slate-400">Par {m.user_name}</div>}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>

      <Modal isOpen={adjustOpen} onClose={() => setAdjustOpen(false)} title="Ajustement d'inventaire physique" maxWidth="sm:max-w-md">
        <form
          onSubmit={(e) => {
            e.preventDefault();
            adjustMutation.mutate({
              magasin_id: magId || undefined,
              product_sync_id: prodId,
              counted_quantity: countedQty,
              movement_type: movType,
              reason,
            });
          }}
          className="space-y-3 text-xs"
        >
          <div>
            <label className="block font-bold mb-1">Magasin *</label>
            <select value={magId} onChange={(e) => setMagId(e.target.value)} className="input-toc bg-white dark:bg-dark-700" required>
              {magasins.filter((m) => m.is_active).map((m) => (
                <option key={m.id} value={m.id}>{m.name}</option>
              ))}
            </select>
          </div>
          <div>
            <label className="block font-bold mb-1">Produit *</label>
            <select value={prodId} onChange={(e) => setProdId(e.target.value)} className="input-toc bg-white dark:bg-dark-700" required>
              {products.map((p) => (
                <option key={p.sync_id} value={p.sync_id}>{p.name} (Stock: {p.stock})</option>
              ))}
            </select>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block font-bold mb-1">Quantité réelle comptée *</label>
              <input type="number" min="0" step="any" required value={countedQty} onChange={(e) => setCountedQty(Number(e.target.value) || 0)} className="input-toc font-mono font-bold" />
            </div>
            <div>
              <label className="block font-bold mb-1">Nature</label>
              <select value={movType} onChange={(e) => setMovType(e.target.value as 'adjustment' | 'loss')} className="input-toc bg-white dark:bg-dark-700">
                <option value="adjustment">Ajustement inventaire</option>
                <option value="loss">Perte / Casse</option>
              </select>
            </div>
          </div>
          <div>
            <label className="block font-bold mb-1">Motif obligatoire *</label>
            <input type="text" required minLength={2} placeholder="Ex: Inventaire mensuel, Casse transport..." value={reason} onChange={(e) => setReason(e.target.value)} className="input-toc" />
          </div>
          {adjustErr && <div className="p-2 rounded-xl bg-red-50 text-red-600">{adjustErr}</div>}
          <div className="flex justify-end gap-2 pt-2">
            <button type="button" onClick={() => setAdjustOpen(false)} className="btn-secondary text-xs">Annuler</button>
            <button type="submit" disabled={adjustMutation.isPending} className="btn-primary text-xs">
              {adjustMutation.isPending ? 'Validation...' : "Valider l'écart"}
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
};
