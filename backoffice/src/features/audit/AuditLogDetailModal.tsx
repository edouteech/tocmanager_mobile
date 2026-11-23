import React from 'react';
import { ShieldCheck } from 'lucide-react';
import { AuditLogItem } from '../../types';
import { formatDateTime } from '../../lib/formatters';
import { Modal } from '../../components/common/Modal';

interface AuditLogDetailModalProps {
  log: AuditLogItem | null;
  onClose: () => void;
}

export const AuditLogDetailModal: React.FC<AuditLogDetailModalProps> = ({ log, onClose }) => (
  <Modal
    isOpen={!!log}
    onClose={onClose}
    title={
      <div className="flex items-center gap-2">
        <ShieldCheck className="w-5 h-5 text-brand-500" />
        <span>Détails de l'Action d'Audit</span>
      </div>
    }
    subtitle="Payload brut enregistré lors de l'opération"
    footer={
      <button onClick={onClose} className="btn-secondary">
        Fermer
      </button>
    }
  >
    {log && (
      <div className="space-y-4">
        <div className="grid grid-cols-2 gap-3 text-xs bg-[#F5FAFD] dark:bg-dark-700/60 p-3.5 rounded-2xl border border-[#E8EFF5] dark:border-dark-600">
          <div>
            <span className="text-slate-400 dark:text-slate-500 block font-medium">Opérateur :</span>
            <span className="font-bold text-slate-800 dark:text-white">
              {log.user_name || 'Inconnu'}
            </span>
          </div>
          <div>
            <span className="text-slate-400 dark:text-slate-500 block font-medium">Action :</span>
            <span className="font-bold text-slate-800 dark:text-white">{log.action}</span>
          </div>
          <div>
            <span className="text-slate-400 dark:text-slate-500 block font-medium">Date & Heure :</span>
            <span className="font-semibold text-slate-800 dark:text-slate-200 font-mono">
              {formatDateTime(log.created_at)}
            </span>
          </div>
          <div>
            <span className="text-slate-400 dark:text-slate-500 block font-medium">Cible :</span>
            <span className="font-semibold text-slate-800 dark:text-slate-200 font-mono">
              {log.entity_type} {log.entity_id ? `(#${log.entity_id.substring(0, 8)})` : ''}
            </span>
          </div>
        </div>

        <div>
          <span className="text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 block mb-1.5">
            Données de l'événement (Payload JSON) :
          </span>
          <pre className="bg-slate-900 dark:bg-black/60 text-emerald-400 p-3.5 rounded-2xl text-xs font-mono overflow-x-auto max-h-60 border border-slate-800">
            {JSON.stringify(log.details, null, 2)}
          </pre>
        </div>
      </div>
    )}
  </Modal>
);
