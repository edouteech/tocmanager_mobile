import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { ArrowRightLeft, Plus, CheckCircle2, XCircle, History } from 'lucide-react';
import { transfersApi } from '../../lib/api';
import { StockTransfer } from '../../types';
import { useTenantContextKey } from '../../stores/tenantStore';
import { formatDateTime } from '../../lib/formatters';
import { CreateTransferModal } from './CreateTransferModal';
import { StockMovementsTab } from './StockMovementsTab';

const STATUS_BADGES: Record<string, string> = {
  draft: 'bg-slate-100 text-slate-700',
  in_transit: 'bg-amber-100 text-amber-800 dark:bg-amber-950/60 dark:text-amber-300',
  received: 'bg-emerald-100 text-emerald-800 dark:bg-emerald-950/60 dark:text-emerald-300',
  canceled: 'bg-rose-100 text-rose-800 dark:bg-rose-950/60 dark:text-rose-300',
};

export const TransfersPage: React.FC = () => {
  const queryClient = useQueryClient();
  const [boutiqueKey, magasinKey] = useTenantContextKey();
  const [activeTab, setActiveTab] = useState<'transfers' | 'movements'>('transfers');
  const [createOpen, setCreateOpen] = useState(false);

  const { data: transfers = [], isLoading } = useQuery<StockTransfer[]>({
    queryKey: ['transfers', boutiqueKey, magasinKey],
    queryFn: () => transfersApi.getAll(),
  });

  const receiveMutation = useMutation({
    mutationFn: (id: string) => transfersApi.receive(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['transfers'] });
      queryClient.invalidateQueries({ queryKey: ['stock-movements'] });
      queryClient.invalidateQueries({ queryKey: ['products'] });
    },
  });

  const cancelMutation = useMutation({
    mutationFn: (id: string) => transfersApi.cancel(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['transfers'] });
      queryClient.invalidateQueries({ queryKey: ['stock-movements'] });
      queryClient.invalidateQueries({ queryKey: ['products'] });
    },
  });

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">
            Transferts & Mouvements de Stock
          </h1>
          <p className="text-xs sm:text-sm text-[#5A7184] dark:text-slate-400 mt-0.5">
            Pilotez les expéditions inter-magasins en 2 étapes et le grand livre des mouvements
          </p>
        </div>

        <button
          onClick={() => setCreateOpen(true)}
          className="btn-toc btn-primary flex items-center gap-2 text-xs font-bold"
        >
          <Plus className="w-4 h-4" />
          <span>Nouveau Transfert</span>
        </button>
      </div>

      <div className="flex gap-2 p-1 rounded-2xl bg-white dark:bg-dark-800 border border-[#E8EFF5] dark:border-dark-600 w-fit">
        <button
          type="button"
          onClick={() => setActiveTab('transfers')}
          className={`inline-flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition ${
            activeTab === 'transfers' ? 'bg-brand-600 text-white shadow-xs' : 'text-slate-500 hover:text-slate-700'
          }`}
        >
          <ArrowRightLeft className="w-3.5 h-3.5" />
          <span>Bons de transfert</span>
        </button>
        <button
          type="button"
          onClick={() => setActiveTab('movements')}
          className={`inline-flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-bold transition ${
            activeTab === 'movements' ? 'bg-brand-600 text-white shadow-xs' : 'text-slate-500 hover:text-slate-700'
          }`}
        >
          <History className="w-3.5 h-3.5" />
          <span>Journal des mouvements / Inventaire</span>
        </button>
      </div>

      {activeTab === 'movements' ? (
        <StockMovementsTab />
      ) : (
        <div className="space-y-4">
          {isLoading ? (
            <div className="card-toc p-12 text-center text-xs text-slate-400">
              Chargement des transferts...
            </div>
          ) : transfers.length === 0 ? (
            <div className="card-toc p-12 text-center text-xs text-slate-400">
              Aucun transfert de stock enregistré.
            </div>
          ) : (
            transfers.map((tr) => (
              <div key={tr.id} className="card-toc p-5 space-y-3">
                <div className="flex flex-wrap items-center justify-between gap-3">
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="font-mono font-extrabold text-sm text-brand-600">{tr.reference}</span>
                      <span className={`px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase ${STATUS_BADGES[tr.status] || 'bg-slate-100'}`}>
                        {tr.status}
                      </span>
                    </div>
                    <p className="text-xs text-slate-500 mt-1">
                      <strong>{tr.from_magasin_name || tr.from_magasin_id}</strong> →{' '}
                      <strong>{tr.to_magasin_name || tr.to_magasin_id}</strong> • {formatDateTime(tr.created_at)}
                    </p>
                  </div>

                  {tr.status === 'in_transit' && (
                    <div className="flex items-center gap-2">
                      <button
                        type="button"
                        onClick={() => receiveMutation.mutate(tr.id)}
                        disabled={receiveMutation.isPending}
                        className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold transition"
                      >
                        <CheckCircle2 className="w-3.5 h-3.5" />
                        <span>Réceptionner</span>
                      </button>
                      <button
                        type="button"
                        onClick={() => {
                          if (window.confirm(`Annuler le transfert ${tr.reference} et restituer les stocks ?`)) {
                            cancelMutation.mutate(tr.id);
                          }
                        }}
                        disabled={cancelMutation.isPending}
                        className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-rose-50 hover:bg-rose-100 text-rose-700 text-xs font-bold transition"
                      >
                        <XCircle className="w-3.5 h-3.5" />
                        <span>Annuler</span>
                      </button>
                    </div>
                  )}
                </div>

                <div className="flex flex-wrap gap-2 pt-2 border-t border-slate-100 dark:border-dark-600">
                  {tr.items.map((it) => (
                    <span key={it.id} className="px-2.5 py-1 rounded-xl bg-slate-50 dark:bg-dark-700 border border-slate-200 dark:border-dark-600 text-xs">
                      <strong>{it.product_name}</strong> : {it.quantity_sent}
                      {it.quantity_received != null ? ` (Reçu: ${it.quantity_received})` : ''}
                    </span>
                  ))}
                </div>
              </div>
            ))
          )}
        </div>
      )}

      <CreateTransferModal
        isOpen={createOpen}
        onClose={() => setCreateOpen(false)}
        onCreated={() => {
          queryClient.invalidateQueries({ queryKey: ['transfers'] });
          queryClient.invalidateQueries({ queryKey: ['stock-movements'] });
          queryClient.invalidateQueries({ queryKey: ['products'] });
        }}
      />
    </div>
  );
};
