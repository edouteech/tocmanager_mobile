import React from 'react';
import { Modal } from '../../components/common/Modal';

interface ReportCustomPeriodModalProps {
  isOpen: boolean;
  customStart: string;
  customEnd: string;
  onStartChange: (val: string) => void;
  onEndChange: (val: string) => void;
  onClose: () => void;
  onApply: () => void;
}

export const ReportCustomPeriodModal: React.FC<ReportCustomPeriodModalProps> = ({
  isOpen,
  customStart,
  customEnd,
  onStartChange,
  onEndChange,
  onClose,
  onApply,
}) => (
  <Modal
    isOpen={isOpen}
    onClose={onClose}
    title="Sélectionner une Période"
    subtitle="Définissez les dates de début et de fin du rapport"
    footer={
      <div className="flex items-center justify-end gap-2 w-full">
        <button type="button" onClick={onClose} className="btn-secondary text-xs">
          Annuler
        </button>
        <button
          type="button"
          onClick={onApply}
          disabled={!customStart || !customEnd}
          className="btn-primary text-xs"
        >
          Appliquer la Période
        </button>
      </div>
    }
  >
    <div className="space-y-4">
      <div>
        <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
          Date de début *
        </label>
        <input
          type="date"
          required
          value={customStart}
          onChange={(e) => onStartChange(e.target.value)}
          className="input-toc"
        />
      </div>

      <div>
        <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
          Date de fin *
        </label>
        <input
          type="date"
          required
          value={customEnd}
          onChange={(e) => onEndChange(e.target.value)}
          className="input-toc"
        />
      </div>
    </div>
  </Modal>
);
