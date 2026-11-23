import React, { useState } from 'react';
import { RotateCcw } from 'lucide-react';
import { Modal } from '../../components/common/Modal';
import { Vente } from '../../types';
import { ventesApi } from '../../lib/api';

interface RefundSaleModalProps {
  vente: Vente | null;
  onClose: () => void;
  onRefunded: (updated: Vente) => void;
}

export const RefundSaleModal: React.FC<RefundSaleModalProps> = ({
  vente,
  onClose,
  onRefunded,
}) => {
  const [reason, setReason] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  if (!vente) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (reason.trim().length < 2) {
      setError('Veuillez saisir un motif de retour (minimum 2 caractères).');
      return;
    }
    setSubmitting(true);
    setError(null);
    try {
      const updated = await ventesApi.refund(vente.sync_id, { reason: reason.trim() });
      setReason('');
      onRefunded(updated);
      onClose();
    } catch (err: any) {
      setError(err.response?.data?.detail || 'Erreur lors du remboursement.');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <Modal
      isOpen={Boolean(vente)}
      onClose={onClose}
      title={`Rembourser le ticket ${vente.ticket_number}`}
      maxWidth="sm:max-w-md"
    >
      <form onSubmit={handleSubmit} className="space-y-4 text-xs">
        <p className="text-slate-600 dark:text-slate-300">
          Cette opération va réintégrer tous les articles restants au stock du magasin d'origine et
          ajuster la créance client si applicable.
        </p>

        <div>
          <label className="block font-bold mb-1">Motif du remboursement / annulation *</label>
          <input
            type="text"
            required
            minLength={2}
            placeholder="Ex: Erreur de caisse, Retour produit défectueux..."
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            className="input-toc"
          />
        </div>

        {error && <div className="p-2.5 rounded-xl bg-red-50 text-red-600">{error}</div>}

        <div className="flex justify-end gap-2">
          <button type="button" onClick={onClose} className="btn-toc btn-secondary text-xs">
            Annuler
          </button>
          <button
            type="submit"
            disabled={submitting}
            className="btn-toc btn-primary bg-rose-600 hover:bg-rose-700 text-xs flex items-center gap-1.5"
          >
            <RotateCcw className="w-3.5 h-3.5" />
            <span>{submitting ? 'Traitement...' : 'Confirmer le remboursement'}</span>
          </button>
        </div>
      </form>
    </Modal>
  );
};
