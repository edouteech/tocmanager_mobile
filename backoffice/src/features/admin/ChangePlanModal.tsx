import React, { useEffect, useState } from 'react';
import { AlertCircle } from 'lucide-react';
import { Modal } from '../../components/common/Modal';
import { AdminBoutiqueItem, SaasPlan } from '../../types';

interface ChangePlanModalProps {
  boutique: AdminBoutiqueItem | null;
  plans: SaasPlan[];
  isSubmitting: boolean;
  error: string | null;
  onClose: () => void;
  onConfirm: (
    boutiqueId: string,
    payload: {
      plan_code: string;
      status: string;
      billing_cycle: 'monthly' | 'yearly';
      period_days: number;
      reason?: string;
    }
  ) => void;
}

export const ChangePlanModal: React.FC<ChangePlanModalProps> = ({
  boutique,
  plans,
  isSubmitting,
  error,
  onClose,
  onConfirm,
}) => {
  const [planCode, setPlanCode] = useState('pro');
  const [status, setStatus] = useState('active');
  const [billingCycle, setBillingCycle] = useState<'monthly' | 'yearly'>('monthly');
  const [periodDays, setPeriodDays] = useState(30);
  const [reason, setReason] = useState('');

  useEffect(() => {
    if (!boutique) return;
    setPlanCode(boutique.subscription?.plan_code || 'free');
    setStatus(
      boutique.subscription?.status && boutique.subscription.status !== 'none'
        ? boutique.subscription.status
        : 'active'
    );
    setBillingCycle(boutique.subscription?.billing_cycle === 'yearly' ? 'yearly' : 'monthly');
    setPeriodDays(30);
    setReason('');
  }, [boutique]);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!boutique) return;
    onConfirm(boutique.id, {
      plan_code: planCode,
      status,
      billing_cycle: billingCycle,
      period_days: Math.max(1, periodDays),
      reason: reason.trim() || undefined,
    });
  };

  return (
    <Modal
      isOpen={Boolean(boutique)}
      onClose={onClose}
      maxWidth="max-w-lg"
      title="Attribution manuelle de forfait"
      subtitle={boutique ? `Boutique : ${boutique.name}` : undefined}
      footer={
        <>
          <button type="button" onClick={onClose} className="btn-secondary text-xs">
            Annuler
          </button>
          <button type="submit" form="change-plan-form" disabled={isSubmitting} className="btn-primary text-xs">
            {isSubmitting ? 'Application...' : 'Appliquer le forfait'}
          </button>
        </>
      }
    >
      {error && (
        <div className="mb-3 p-3 rounded-xl bg-[#FDEBE9] border border-[#E74C3C]/30 text-[#E74C3C] text-xs font-medium flex items-center gap-2">
          <AlertCircle className="w-4 h-4 shrink-0" />
          <span>{error}</span>
        </div>
      )}

      <form id="change-plan-form" onSubmit={handleSubmit} className="space-y-3 text-xs">
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <div>
            <label className="block font-bold mb-1">Forfait cible</label>
            <select value={planCode} onChange={(e) => setPlanCode(e.target.value)} className="input-toc">
              {plans.map((p) => (
                <option key={p.id} value={p.code}>
                  {p.name} ({p.price_monthly.toLocaleString('fr-FR')} {p.currency})
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="block font-bold mb-1">Statut souscription</label>
            <select value={status} onChange={(e) => setStatus(e.target.value)} className="input-toc">
              <option value="active">Actif (Payé / Validé)</option>
              <option value="trialing">En période d'essai</option>
              <option value="past_due">En retard (past_due)</option>
              <option value="canceled">Annulé (canceled)</option>
            </select>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="block font-bold mb-1">Cycle</label>
            <select
              value={billingCycle}
              onChange={(e) => {
                const cyc = e.target.value === 'yearly' ? 'yearly' : 'monthly';
                setBillingCycle(cyc);
                setPeriodDays(cyc === 'yearly' ? 365 : 30);
              }}
              className="input-toc"
            >
              <option value="monthly">Mensuel</option>
              <option value="yearly">Annuel</option>
            </select>
          </div>
          <div>
            <label className="block font-bold mb-1">Durée accordée (jours)</label>
            <input
              type="number"
              min={1}
              max={730}
              value={periodDays}
              onChange={(e) => setPeriodDays(Number(e.target.value) || 30)}
              className="input-toc font-mono"
            />
          </div>
        </div>

        <div>
          <label className="block font-bold mb-1">Motif (journalisé dans l'audit)</label>
          <input
            type="text"
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            placeholder="Ex: Virement bancaire reçu, geste commercial..."
            className="input-toc"
          />
        </div>
      </form>
    </Modal>
  );
};
