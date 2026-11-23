import React from 'react';
import { Store, Building2, Layers, ArrowRight } from 'lucide-react';
import { Modal } from './Modal';
import { useTenantStore } from '../../stores/tenantStore';

export const SelectMagasinPromptModal: React.FC = () => {
  const {
    currentBoutique,
    magasins,
    showMagasinPrompt,
    selectMagasin,
    dismissMagasinPrompt,
  } = useTenantStore();

  if (!showMagasinPrompt || magasins.length <= 1) {
    return null;
  }

  const handleSkipToConsolidated = () => {
    selectMagasin(null);
    dismissMagasinPrompt();
  };

  return (
    <Modal
      isOpen={showMagasinPrompt}
      onClose={handleSkipToConsolidated}
      title={`Choisir un point de vente — ${currentBoutique?.name || 'Boutique'}`}
      maxWidth="sm:max-w-md"
    >
      <div className="space-y-4">
        <p className="text-xs text-slate-600 dark:text-slate-300">
          Vous disposez de plusieurs établissements actifs. Sélectionnez un magasin pour filtrer
          vos opérations de caisse, ou cliquez sur <strong>Passer</strong> pour accéder au pilotage
          consolidé multi-magasins.
        </p>

        <div className="space-y-2 max-h-64 overflow-y-auto pr-1">
          {magasins.map((m) => (
            <button
              key={m.id}
              type="button"
              onClick={() => selectMagasin(m)}
              className="w-full flex items-center justify-between gap-3 p-3 rounded-xl border border-slate-200 dark:border-slate-700 hover:border-brand-400 hover:bg-brand-50/50 dark:hover:bg-brand-500/10 transition text-left"
            >
              <div className="flex items-center gap-3 min-w-0">
                <div className="w-9 h-9 rounded-xl bg-brand-50 dark:bg-brand-500/15 text-brand-600 dark:text-brand-400 flex items-center justify-center shrink-0">
                  {m.is_warehouse ? <Building2 className="w-4 h-4" /> : <Store className="w-4 h-4" />}
                </div>
                <div className="min-w-0">
                  <div className="text-xs font-bold text-slate-900 dark:text-white truncate">
                    {m.name}
                  </div>
                  <div className="text-[11px] text-slate-500 dark:text-slate-400 truncate">
                    {m.is_warehouse ? 'Entrepôt / Réserve' : 'Point de vente'}
                    {m.code ? ` • ${m.code}` : ''}
                  </div>
                </div>
              </div>
              <ArrowRight className="w-4 h-4 text-slate-400 shrink-0" />
            </button>
          ))}
        </div>

        <div className="pt-3 border-t border-slate-200 dark:border-slate-700 flex items-center justify-between gap-3">
          <span className="text-[11px] text-slate-500 flex items-center gap-1.5">
            <Layers className="w-3.5 h-3.5 text-amber-500" />
            <span>Modifiable à tout moment dans la barre supérieure</span>
          </span>
          <button
            type="button"
            onClick={handleSkipToConsolidated}
            className="px-4 py-2 rounded-xl text-xs font-bold bg-amber-100 hover:bg-amber-200 text-amber-800 dark:bg-amber-900/50 dark:text-amber-200 transition"
          >
            Passer
          </button>
        </div>
      </div>
    </Modal>
  );
};
