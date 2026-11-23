import React, { useState, useEffect } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Plus, Trash2, ArrowRightLeft } from 'lucide-react';
import { Modal } from '../../components/common/Modal';
import { productsApi, transfersApi } from '../../lib/api';
import { Product } from '../../types';
import { useTenantStore } from '../../stores/tenantStore';

interface TransferLineDraft {
  product_sync_id: string;
  quantity_sent: number;
}

interface CreateTransferModalProps {
  isOpen: boolean;
  onClose: () => void;
  onCreated: () => void;
}

export const CreateTransferModal: React.FC<CreateTransferModalProps> = ({
  isOpen,
  onClose,
  onCreated,
}) => {
  const { magasins, currentMagasin } = useTenantStore();
  const activeMagasins = magasins.filter((m) => m.is_active);
  const [fromMagasinId, setFromMagasinId] = useState('');
  const [toMagasinId, setToMagasinId] = useState('');
  const [notes, setNotes] = useState('');
  const [lines, setLines] = useState<TransferLineDraft[]>([{ product_sync_id: '', quantity_sent: 1 }]);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!isOpen) return;
    const defaultFrom = currentMagasin?.id || activeMagasins[0]?.id || '';
    const defaultTo = activeMagasins.find((m) => m.id !== defaultFrom)?.id || '';
    setFromMagasinId(defaultFrom);
    setToMagasinId(defaultTo);
    setNotes('');
    setLines([{ product_sync_id: '', quantity_sent: 1 }]);
    setError(null);
  }, [isOpen, currentMagasin?.id]);

  const { data: sourceProducts = [] } = useQuery<Product[]>({
    queryKey: ['products', 'transfer-source', fromMagasinId],
    queryFn: () => productsApi.getAll({ magasin_id: fromMagasinId }),
    enabled: isOpen && Boolean(fromMagasinId),
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    const validLines = lines.filter((l) => l.product_sync_id && l.quantity_sent > 0);
    if (!fromMagasinId || !toMagasinId || fromMagasinId === toMagasinId) {
      setError('Sélectionnez deux magasins distincts.');
      return;
    }
    if (validLines.length === 0) {
      setError('Ajoutez au moins un article à transférer.');
      return;
    }

    setSubmitting(true);
    try {
      await transfersApi.create({
        from_magasin_id: fromMagasinId,
        to_magasin_id: toMagasinId,
        items: validLines,
        notes: notes.trim() || undefined,
        ship_immediately: true,
      });
      onCreated();
      onClose();
    } catch (err: any) {
      setError(err.response?.data?.detail || 'Erreur lors de la création du bon de transfert.');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Nouveau Transfert de Stock" maxWidth="sm:max-w-xl">
      <form onSubmit={handleSubmit} className="space-y-4 text-xs">
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div>
            <label className="block font-bold text-slate-700 dark:text-slate-300 mb-1">
              Magasin / Entrepôt Source *
            </label>
            <select
              value={fromMagasinId}
              onChange={(e) => setFromMagasinId(e.target.value)}
              className="input-toc bg-white dark:bg-dark-700"
            >
              <option value="">Source...</option>
              {activeMagasins.map((m) => (
                <option key={m.id} value={m.id}>
                  {m.name} {m.is_warehouse ? '(Dépôt)' : ''}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="block font-bold text-slate-700 dark:text-slate-300 mb-1">
              Magasin Destinataire *
            </label>
            <select
              value={toMagasinId}
              onChange={(e) => setToMagasinId(e.target.value)}
              className="input-toc bg-white dark:bg-dark-700"
            >
              <option value="">Destination...</option>
              {activeMagasins.map((m) => (
                <option key={m.id} value={m.id}>
                  {m.name} {m.is_warehouse ? '(Dépôt)' : ''}
                </option>
              ))}
            </select>
          </div>
        </div>

        <div className="space-y-2">
          <div className="flex items-center justify-between">
            <span className="font-bold text-slate-700 dark:text-slate-300">Articles à expédier</span>
            <button
              type="button"
              onClick={() => setLines([...lines, { product_sync_id: '', quantity_sent: 1 }])}
              className="inline-flex items-center gap-1 text-brand-600 font-bold hover:underline"
            >
              <Plus className="w-3.5 h-3.5" /> Ajouter ligne
            </button>
          </div>

          {lines.map((line, idx) => (
            <div key={idx} className="flex items-center gap-2">
              <select
                value={line.product_sync_id}
                onChange={(e) => {
                  const next = [...lines];
                  next[idx].product_sync_id = e.target.value;
                  setLines(next);
                }}
                className="input-toc flex-1 bg-white dark:bg-dark-700"
              >
                <option value="">Sélectionner un produit...</option>
                {sourceProducts.map((p) => (
                  <option key={p.sync_id} value={p.sync_id}>
                    {p.name} (Dispo: {p.stock})
                  </option>
                ))}
              </select>
              <input
                type="number"
                min="0.01"
                step="any"
                value={line.quantity_sent}
                onChange={(e) => {
                  const next = [...lines];
                  next[idx].quantity_sent = Number(e.target.value) || 0;
                  setLines(next);
                }}
                className="input-toc w-24 font-mono font-bold"
              />
              {lines.length > 1 && (
                <button
                  type="button"
                  onClick={() => setLines(lines.filter((_, i) => i !== idx))}
                  className="p-2 text-rose-500 hover:bg-rose-50 rounded-lg"
                >
                  <Trash2 className="w-3.5 h-3.5" />
                </button>
              )}
            </div>
          ))}
        </div>

        <div>
          <label className="block font-bold text-slate-700 dark:text-slate-300 mb-1">Notes</label>
          <input
            type="text"
            placeholder="Référence transporteur, remarques..."
            value={notes}
            onChange={(e) => setNotes(e.target.value)}
            className="input-toc"
          />
        </div>

        {error && <div className="p-2.5 rounded-xl bg-red-50 text-red-600 font-medium">{error}</div>}

        <div className="flex justify-end gap-2 pt-2">
          <button type="button" onClick={onClose} className="btn-toc btn-secondary text-xs">
            Annuler
          </button>
          <button
            type="submit"
            disabled={submitting}
            className="btn-toc btn-primary text-xs flex items-center gap-1.5"
          >
            <ArrowRightLeft className="w-3.5 h-3.5" />
            <span>{submitting ? 'Expédition...' : 'Expédier le transfert'}</span>
          </button>
        </div>
      </form>
    </Modal>
  );
};
