import React, { useEffect, useState } from 'react';
import { AlertCircle } from 'lucide-react';
import { Modal } from '../../components/common/Modal';
import { AdminBoutiqueItem } from '../../types';

interface ExtendTrialModalProps {
  boutique: AdminBoutiqueItem | null;
  isSubmitting: boolean;
  error: string | null;
  onClose: () => void;
  onConfirm: (boutiqueId: string, days: number) => void;
}

export const ExtendTrialModal: React.FC<ExtendTrialModalProps> = ({
  boutique,
  isSubmitting,
  error,
  onClose,
  onConfirm,
}) => {
  const [days, setDays] = useState(14);
  const [localError, setLocalError] = useState<string | null>(null);

  useEffect(() => {
    if (boutique) {
      setDays(14);
      setLocalError(null);
    }
  }, [boutique]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!boutique) return;
    if (!Number.isInteger(days) || days < 1 || days > 365) {
      setLocalError('Veuillez saisir un nombre de jours entre 1 et 365.');
      return;
    }
    onConfirm(boutique.id, days);
  };

  return (
    <Modal
      isOpen={Boolean(boutique)}
      onClose={onClose}
      maxWidth="max-w-md"
      title="Prolonger la période d'essai"
      subtitle={boutique ? `Boutique : ${boutique.name}` : undefined}
      footer={
        <>
          <button type="button" onClick={onClose} className="btn-secondary text-xs">
            Annuler
          </button>
          <button type="submit" form="extend-trial-form" disabled={isSubmitting} className="btn-primary text-xs">
            {isSubmitting ? 'Application...' : 'Prolonger'}
          </button>
        </>
      }
    >
      {(localError || error) && (
        <div className="mb-3 p-3 rounded-xl bg-[#FDEBE9] border border-[#E74C3C]/30 text-[#E74C3C] text-xs font-medium flex items-center gap-2">
          <AlertCircle className="w-4 h-4 shrink-0" />
          <span>{localError || error}</span>
        </div>
      )}
      <form id="extend-trial-form" onSubmit={handleSubmit} className="space-y-3 text-xs">
        <div>
          <label className="block font-bold mb-1">Nombre de jours supplémentaires (1 - 365) *</label>
          <input
            type="number"
            min={1}
            max={365}
            required
            value={days}
            onChange={(e) => setDays(parseInt(e.target.value, 10) || 0)}
            className="input-toc font-mono font-bold"
          />
        </div>
      </form>
    </Modal>
  );
};
