import React, { useEffect, useMemo, useState } from 'react';
import { AlertCircle } from 'lucide-react';
import { FeatureCatalogItem, SaasPlan, SaasPlanPayload } from '../../types';
import { Modal } from '../../components/common/Modal';
import { EditablePlanFeature, PlanFeaturesTabContent } from './PlanFeaturesTabContent';
import { PlanInfoFormFields } from './PlanInfoFormFields';

interface PlanEditorModalProps {
  isOpen: boolean;
  mode: 'create' | 'duplicate' | 'edit';
  initialPlan: SaasPlan | null;
  catalog: FeatureCatalogItem[];
  isSubmitting: boolean;
  externalError: string | null;
  onClose: () => void;
  onSave: (payload: SaasPlanPayload, planId?: string) => void;
}

const TABS = [
  { id: 'info', label: 'Infos & Tarifs' },
  { id: 'quotas', label: 'Quotas' },
  { id: 'modules', label: 'Modules Métier' },
  { id: 'multi_magasin', label: 'Multi-Magasins' },
  { id: 'analytics_platform', label: 'Analytique & Plateforme' },
] as const;

export const PlanEditorModal: React.FC<PlanEditorModalProps> = ({
  isOpen,
  mode,
  initialPlan,
  catalog,
  isSubmitting,
  externalError,
  onClose,
  onSave,
}) => {
  const [activeTab, setActiveTab] = useState<(typeof TABS)[number]['id']>('info');
  const [name, setName] = useState('');
  const [code, setCode] = useState('');
  const [description, setDescription] = useState('');
  const [priceMonthly, setPriceMonthly] = useState(0);
  const [priceYearly, setPriceYearly] = useState(0);
  const [currency, setCurrency] = useState('XOF');
  const [trialDays, setTrialDays] = useState(0);
  const [badge, setBadge] = useState('');
  const [isActive, setIsActive] = useState(true);
  const [featureMap, setFeatureMap] = useState<Record<string, EditablePlanFeature>>({});
  const [localError, setLocalError] = useState<string | null>(null);

  useEffect(() => {
    if (!isOpen) return;
    setActiveTab('info');
    setLocalError(null);
    if (initialPlan) {
      setName(mode === 'duplicate' ? `${initialPlan.name} (Copie)` : initialPlan.name);
      setCode(mode === 'duplicate' ? `${initialPlan.code}_copy` : initialPlan.code);
      setDescription(initialPlan.description || '');
      setPriceMonthly(initialPlan.price_monthly);
      setPriceYearly(initialPlan.price_yearly);
      setCurrency(initialPlan.currency || 'XOF');
      setTrialDays(initialPlan.trial_period_days);
      setBadge(initialPlan.badge || '');
      setIsActive(initialPlan.is_active);
    } else {
      setName('');
      setCode('');
      setDescription('');
      setPriceMonthly(0);
      setPriceYearly(0);
      setCurrency('XOF');
      setTrialDays(0);
      setBadge('');
      setIsActive(true);
    }
    const nextMap: Record<string, EditablePlanFeature> = {};
    catalog.forEach((cat) => {
      const existing = initialPlan?.features?.find((f) => f.feature_code === cat.feature_code);
      nextMap[cat.feature_code] = {
        feature_code: cat.feature_code,
        feature_name: existing?.feature_name || cat.feature_name,
        boolean_value: existing ? Boolean(existing.boolean_value) : Boolean(cat.defaults.free),
        int_limit: existing !== undefined ? Number(existing.int_limit) : typeof cat.defaults.free === 'number' ? cat.defaults.free : 0,
        show_on_pricing: existing?.show_on_pricing !== undefined ? Boolean(existing.show_on_pricing) : cat.show_on_pricing,
      };
    });
    setFeatureMap(nextMap);
  }, [isOpen, initialPlan, mode, catalog]);

  const categoryItems = useMemo(() => catalog.filter((c) => c.category === activeTab), [catalog, activeTab]);

  const handleFeatureChange = (featCode: string, patch: Partial<EditablePlanFeature>) => {
    setFeatureMap((prev) => ({ ...prev, [featCode]: { ...prev[featCode], ...patch } }));
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setLocalError(null);
    if (!name.trim() || !code.trim()) {
      setActiveTab('info');
      setLocalError('Le nom et le code technique du forfait sont obligatoires.');
      return;
    }
    onSave(
      {
        name: name.trim(),
        code: code.trim().toLowerCase().replace(/\s+/g, '_'),
        description: description.trim() || null,
        price_monthly: Number(priceMonthly),
        price_yearly: Number(priceYearly),
        currency,
        trial_period_days: Number(trialDays),
        badge: badge.trim() || null,
        is_active: isActive,
        features: Object.values(featureMap),
      },
      mode === 'edit' && initialPlan ? initialPlan.id : undefined
    );
  };

  const displayedError = localError || externalError;

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      maxWidth="max-w-4xl"
      title={mode === 'edit' ? `Configurer le Forfait : ${initialPlan?.name}` : mode === 'duplicate' ? `Dupliquer le Forfait : ${initialPlan?.name}` : 'Créer un Nouveau Forfait'}
      subtitle="Pilotez les tarifs et chacun des 28 accès et quotas du plan"
      footer={
        <>
          <button type="button" onClick={onClose} className="btn-secondary text-xs">Annuler</button>
          <button type="submit" form="plan-editor-form" disabled={isSubmitting} className="btn-primary text-xs">
            {isSubmitting ? 'Enregistrement...' : 'Enregistrer le forfait'}
          </button>
        </>
      }
    >
      <div className="flex flex-wrap gap-1.5 border-b border-[#E8EFF5] dark:border-dark-600 pb-3 mb-4">
        {TABS.map((t) => (
          <button
            key={t.id}
            type="button"
            onClick={() => setActiveTab(t.id)}
            className={`px-3 py-1.5 rounded-xl text-xs font-bold transition ${
              activeTab === t.id ? 'bg-[#E8F5FD] dark:bg-[#29ABE2]/15 text-[#29ABE2]' : 'text-[#5A7184] hover:bg-[#F0F9FE] dark:hover:bg-dark-700'
            }`}
          >
            {t.label}
          </button>
        ))}
      </div>

      {displayedError && (
        <div className="mb-3 p-3 rounded-xl bg-[#FDEBE9] border border-[#E74C3C]/30 text-[#E74C3C] text-xs font-medium flex items-center gap-2">
          <AlertCircle className="w-4 h-4 shrink-0" />
          <span>{displayedError}</span>
        </div>
      )}

      <form id="plan-editor-form" onSubmit={handleSubmit} className="space-y-4">
        {activeTab === 'info' ? (
          <PlanInfoFormFields
            isEditMode={mode === 'edit'}
            name={name}
            setName={setName}
            code={code}
            setCode={setCode}
            description={description}
            setDescription={setDescription}
            priceMonthly={priceMonthly}
            setPriceMonthly={setPriceMonthly}
            priceYearly={priceYearly}
            setPriceYearly={setPriceYearly}
            currency={currency}
            setCurrency={setCurrency}
            trialDays={trialDays}
            setTrialDays={setTrialDays}
            badge={badge}
            setBadge={setBadge}
            isActive={isActive}
            setIsActive={setIsActive}
          />
        ) : (
          <PlanFeaturesTabContent items={categoryItems} values={featureMap} onChange={handleFeatureChange} />
        )}
      </form>
    </Modal>
  );
};
