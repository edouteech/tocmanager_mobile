import React from 'react';
import { AlertTriangle } from 'lucide-react';
import { Modal } from './Modal';

interface ConfirmModalProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void;
  title: string;
  message: string;
  confirmLabel?: string;
  cancelLabel?: string;
  variant?: 'danger' | 'warning' | 'brand';
  isPending?: boolean;
}

const CONFIRM_BTN_STYLES: Record<'danger' | 'warning' | 'brand', string> = {
  danger: 'bg-rose-600 hover:bg-rose-700 text-white',
  warning: 'bg-amber-600 hover:bg-amber-700 text-white',
  brand: 'bg-[#29ABE2] hover:bg-[#1E88E5] text-white',
};

export const ConfirmModal: React.FC<ConfirmModalProps> = ({
  isOpen,
  onClose,
  onConfirm,
  title,
  message,
  confirmLabel = 'Confirmer',
  cancelLabel = 'Annuler',
  variant = 'danger',
  isPending = false,
}) => {
  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={
        <div className="flex items-center gap-2">
          <AlertTriangle
            className={`w-5 h-5 ${
              variant === 'danger'
                ? 'text-rose-500'
                : variant === 'warning'
                  ? 'text-amber-500'
                  : 'text-[#29ABE2]'
            }`}
          />
          <span>{title}</span>
        </div>
      }
      maxWidth="max-w-md"
      footer={
        <div className="flex items-center justify-end gap-2 w-full">
          <button type="button" onClick={onClose} disabled={isPending} className="btn-secondary text-xs">
            {cancelLabel}
          </button>
          <button
            type="button"
            onClick={onConfirm}
            disabled={isPending}
            className={`px-4 py-2 rounded-xl text-xs font-bold transition disabled:opacity-50 ${CONFIRM_BTN_STYLES[variant]}`}
          >
            {isPending ? 'Traitement...' : confirmLabel}
          </button>
        </div>
      }
    >
      <p className="text-sm text-[#5A7184] dark:text-slate-300 leading-relaxed">{message}</p>
    </Modal>
  );
};
