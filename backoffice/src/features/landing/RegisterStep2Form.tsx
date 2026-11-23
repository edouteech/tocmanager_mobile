import React from 'react';
import { Store, Building2, CheckCircle2, ShieldCheck, ArrowLeft, Sparkles } from 'lucide-react';
import { CANONICAL_CURRENCIES } from '../../lib/currencies';
import { SaasPlan } from '../../types';

interface RegisterStep2FormProps {
  boutiqueName: string;
  setBoutiqueName: (v: string) => void;
  companyName: string;
  setCompanyName: (v: string) => void;
  currency: string;
  setCurrency: (v: string) => void;
  country: string;
  setCountry: (v: string) => void;
  magasinName: string;
  setMagasinName: (v: string) => void;
  selectedPlan: string;
  setSelectedPlan: (v: string) => void;
  billingCycle: 'monthly' | 'yearly';
  setBillingCycle: (v: 'monthly' | 'yearly') => void;
  plans: SaasPlan[];
  plansLoading: boolean;
  loading: boolean;
  onBack: () => void;
  onSubmit: (e: React.FormEvent) => void;
}

export const RegisterStep2Form: React.FC<RegisterStep2FormProps> = ({
  boutiqueName,
  setBoutiqueName,
  companyName,
  setCompanyName,
  currency,
  setCurrency,
  country,
  setCountry,
  magasinName,
  setMagasinName,
  selectedPlan,
  setSelectedPlan,
  billingCycle,
  setBillingCycle,
  plans,
  plansLoading,
  loading,
  onBack,
  onSubmit,
}) => {
  return (
    <form onSubmit={onSubmit} className="space-y-4 animate-fade-in">
      <div className="flex items-start justify-between gap-2">
        <div>
          <div className="inline-flex items-center gap-1 text-[11px] font-bold text-[#27AE60] mb-1">
            <CheckCircle2 className="w-3.5 h-3.5" /> Identifiants validés
          </div>
          <h2 className="text-lg font-bold text-[#1C2B3A] dark:text-white">
            Configurez votre Entreprise
          </h2>
          <p className="text-xs text-[#5A7184] dark:text-slate-400">
            Définissez votre société, votre première boutique et votre point de vente initial.
          </p>
        </div>
        <button
          type="button"
          onClick={onBack}
          className="inline-flex items-center gap-1 text-xs font-semibold text-[#5A7184] hover:text-[#29ABE2] shrink-0"
        >
          <ArrowLeft className="w-3.5 h-3.5" />
          <span>Retour</span>
        </button>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
        <div>
          <label className="block text-xs font-semibold text-[#1C2B3A] dark:text-slate-300 mb-1">
            Nom de la Boutique *
          </label>
          <div className="relative">
            <Store className="w-4 h-4 text-[#9FB3C8] absolute left-3 top-3" />
            <input
              type="text"
              required
              placeholder="Ex: Boutique Élégance Dakar"
              value={boutiqueName}
              onChange={(e) => setBoutiqueName(e.target.value)}
              className="input-toc pl-9"
            />
          </div>
        </div>

        <div>
          <label className="block text-xs font-semibold text-[#1C2B3A] dark:text-slate-300 mb-1">
            Raison Sociale / Entreprise
          </label>
          <div className="relative">
            <Building2 className="w-4 h-4 text-[#9FB3C8] absolute left-3 top-3" />
            <input
              type="text"
              placeholder="Ex: Élégance SARL (optionnel)"
              value={companyName}
              onChange={(e) => setCompanyName(e.target.value)}
              className="input-toc pl-9"
            />
          </div>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-3">
        <div>
          <label className="block text-xs font-semibold text-[#1C2B3A] dark:text-slate-300 mb-1">
            Devise
          </label>
          <select
            value={currency}
            onChange={(e) => setCurrency(e.target.value)}
            className="input-toc"
          >
            {CANONICAL_CURRENCIES.map((c) => (
              <option key={c.code} value={c.code}>
                {c.label}
              </option>
            ))}
          </select>
        </div>

        <div>
          <label className="block text-xs font-semibold text-[#1C2B3A] dark:text-slate-300 mb-1">
            Pays
          </label>
          <input
            type="text"
            value={country}
            onChange={(e) => setCountry(e.target.value)}
            className="input-toc"
          />
        </div>
      </div>

      <div>
        <label className="block text-xs font-semibold text-[#1C2B3A] dark:text-slate-300 mb-1">
          Nom du premier point de vente (Magasin)
        </label>
        <input
          type="text"
          placeholder="Ex: Magasin Principal / Caisse centrale"
          value={magasinName}
          onChange={(e) => setMagasinName(e.target.value)}
          className="input-toc"
        />
      </div>

      <div className="pt-1 space-y-2">
        <div className="flex items-center justify-between gap-2">
          <label className="block text-xs font-semibold text-[#1C2B3A] dark:text-slate-300">
            Formule d'accueil choisie
          </label>
          <div className="inline-flex rounded-lg bg-[#F0F9FE] dark:bg-dark-700 p-0.5 border border-[#E8EFF5] dark:border-dark-600 text-[11px] font-semibold">
            <button
              type="button"
              onClick={() => setBillingCycle('monthly')}
              className={`px-2 py-1 rounded-md transition ${
                billingCycle === 'monthly'
                  ? 'bg-[#29ABE2] text-white'
                  : 'text-[#5A7184] dark:text-slate-300'
              }`}
            >
              Mensuel
            </button>
            <button
              type="button"
              onClick={() => setBillingCycle('yearly')}
              className={`px-2 py-1 rounded-md transition ${
                billingCycle === 'yearly'
                  ? 'bg-[#29ABE2] text-white'
                  : 'text-[#5A7184] dark:text-slate-300'
              }`}
            >
              Annuel
            </button>
          </div>
        </div>

        {plansLoading ? (
          <div className="text-xs text-[#5A7184] py-4 text-center">Chargement des forfaits...</div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-2.5">
            {plans.map((plan) => {
              const isSelected = selectedPlan === plan.code;
              const price = billingCycle === 'yearly' ? plan.price_yearly : plan.price_monthly;
              return (
                <button
                  key={plan.id}
                  type="button"
                  onClick={() => setSelectedPlan(plan.code)}
                  className={`p-3 rounded-xl border text-left transition text-xs relative ${
                    isSelected
                      ? 'border-[#29ABE2] bg-[#E8F5FD] dark:bg-[#29ABE2]/15 ring-2 ring-[#29ABE2]/20'
                      : 'border-[#E8EFF5] dark:border-dark-600 hover:bg-[#F0F9FE] dark:hover:bg-dark-700'
                  }`}
                >
                  {plan.trial_period_days > 0 && (
                    <span className="inline-flex items-center gap-0.5 px-1.5 py-0.5 rounded-full text-[9px] font-bold bg-[#FEF5E7] text-[#F39C12] mb-1">
                      <Sparkles className="w-2.5 h-2.5" />
                      {plan.trial_period_days}j offerts
                    </span>
                  )}
                  <div className="font-bold text-[#1C2B3A] dark:text-white">{plan.name}</div>
                  <div className="text-[11px] text-[#5A7184] dark:text-slate-400 line-clamp-2 mt-0.5">
                    {plan.description || 'Forfait TocManager'}
                  </div>
                  <div className="font-extrabold text-[#29ABE2] mt-1.5">
                    {price.toLocaleString('fr-FR')} {plan.currency} / {billingCycle === 'yearly' ? 'an' : 'mois'}
                  </div>
                </button>
              );
            })}
          </div>
        )}
      </div>

      <div className="pt-2">
        <button type="submit" disabled={loading} className="w-full btn-primary py-3.5">
          {loading ? (
            <span>Initialisation de votre espace...</span>
          ) : (
            <>
              <ShieldCheck className="w-4 h-4" />
              <span>Terminer et accéder à mon espace</span>
            </>
          )}
        </button>
      </div>
    </form>
  );
};
