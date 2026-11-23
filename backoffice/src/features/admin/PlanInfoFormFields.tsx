import React from 'react';

interface PlanInfoFormFieldsProps {
  isEditMode: boolean;
  name: string;
  setName: (v: string) => void;
  code: string;
  setCode: (v: string) => void;
  description: string;
  setDescription: (v: string) => void;
  priceMonthly: number;
  setPriceMonthly: (v: number) => void;
  priceYearly: number;
  setPriceYearly: (v: number) => void;
  currency: string;
  setCurrency: (v: string) => void;
  trialDays: number;
  setTrialDays: (v: number) => void;
  badge: string;
  setBadge: (v: string) => void;
  isActive: boolean;
  setIsActive: (v: boolean) => void;
}

export const PlanInfoFormFields: React.FC<PlanInfoFormFieldsProps> = ({
  isEditMode,
  name,
  setName,
  code,
  setCode,
  description,
  setDescription,
  priceMonthly,
  setPriceMonthly,
  priceYearly,
  setPriceYearly,
  currency,
  setCurrency,
  trialDays,
  setTrialDays,
  badge,
  setBadge,
  isActive,
  setIsActive,
}) => (
  <div className="space-y-3 text-xs">
    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
      <div>
        <label className="block font-bold mb-1">Nom commercial *</label>
        <input type="text" required value={name} onChange={(e) => setName(e.target.value)} className="input-toc" />
      </div>
      <div>
        <label className="block font-bold mb-1">Code technique *</label>
        <input
          type="text"
          required
          disabled={isEditMode}
          value={code}
          onChange={(e) => setCode(e.target.value)}
          className="input-toc font-mono disabled:opacity-60"
        />
      </div>
    </div>

    <div>
      <label className="block font-bold mb-1">Description commerciale</label>
      <textarea rows={2} value={description} onChange={(e) => setDescription(e.target.value)} className="input-toc" />
    </div>

    <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
      <div>
        <label className="block font-bold mb-1">Prix Mensuel</label>
        <input type="number" min={0} value={priceMonthly} onChange={(e) => setPriceMonthly(Number(e.target.value))} className="input-toc font-mono" />
      </div>
      <div>
        <label className="block font-bold mb-1">Prix Annuel</label>
        <input type="number" min={0} value={priceYearly} onChange={(e) => setPriceYearly(Number(e.target.value))} className="input-toc font-mono" />
      </div>
      <div>
        <label className="block font-bold mb-1">Devise</label>
        <input type="text" disabled={isEditMode} value={currency} onChange={(e) => setCurrency(e.target.value.toUpperCase())} className="input-toc font-mono disabled:opacity-60" />
      </div>
      <div>
        <label className="block font-bold mb-1">Essai (jours)</label>
        <input type="number" min={0} value={trialDays} onChange={(e) => setTrialDays(Number(e.target.value))} className="input-toc font-mono" />
      </div>
    </div>

    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 items-center pt-1">
      <div>
        <label className="block font-bold mb-1">Badge marketing (optionnel)</label>
        <input type="text" value={badge} onChange={(e) => setBadge(e.target.value)} placeholder="POPULAIRE, RECOMMANDÉ..." className="input-toc" />
      </div>
      <label className="inline-flex items-center gap-2 font-bold pt-4 cursor-pointer">
        <input type="checkbox" checked={isActive} onChange={(e) => setIsActive(e.target.checked)} className="rounded text-[#29ABE2]" />
        <span>Plan actif et visible aux nouveaux inscrits</span>
      </label>
    </div>
  </div>
);
