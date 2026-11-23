import React, { useState } from 'react';
import { Store, ChevronDown, Plus } from 'lucide-react';
import { useTenantStore } from '../../stores/tenantStore';

interface TenantContextSelectorsProps {
  isOwner: boolean;
  onOpenCreateBoutique: () => void;
}

export const TenantContextSelectors: React.FC<TenantContextSelectorsProps> = ({
  isOwner,
  onOpenCreateBoutique,
}) => {
  const {
    boutiques,
    currentBoutique,
    selectBoutique,
    magasins,
    currentMagasin,
    selectMagasin,
    isConsolidatedView,
  } = useTenantStore();

  const [boutiqueDropdownOpen, setBoutiqueDropdownOpen] = useState(false);
  const [magasinDropdownOpen, setMagasinDropdownOpen] = useState(false);

  return (
    <>
      <div className="relative">
        <button
          onClick={() => {
            setBoutiqueDropdownOpen(!boutiqueDropdownOpen);
            setMagasinDropdownOpen(false);
          }}
          className="flex items-center gap-2 px-3 py-1.5 rounded-xl text-xs font-bold text-slate-800 dark:text-white bg-[#F0F9FE] dark:bg-dark-700 hover:bg-[#E8F5FD] dark:hover:bg-dark-600 border border-[#E8EFF5] dark:border-dark-600 transition"
        >
          <Store className="w-3.5 h-3.5 text-[#29ABE2]" />
          <span className="truncate max-w-[120px] sm:max-w-[160px]">
            {currentBoutique?.name || 'Boutique Principale'}
          </span>
          <ChevronDown className="w-3 h-3 text-slate-400" />
        </button>

        {boutiqueDropdownOpen && (
          <div className="absolute top-full left-0 mt-1.5 w-60 bg-white dark:bg-dark-800 rounded-xl shadow-soft-lg border border-[#E8EFF5] dark:border-dark-600 py-1.5 z-50 animate-fade-in">
            <div className="px-3 py-1 text-[10px] font-bold text-[#9FB3C8] uppercase tracking-wider">
              Vos Boutiques
            </div>
            {boutiques.map((b) => (
              <button
                key={b.id}
                onClick={() => {
                  selectBoutique(b);
                  setBoutiqueDropdownOpen(false);
                }}
                className={`w-full text-left px-3 py-2 text-xs flex items-center justify-between hover:bg-[#F0F9FE] dark:hover:bg-dark-700 transition ${
                  b.id === currentBoutique?.id
                    ? 'text-[#29ABE2] font-bold bg-[#E8F5FD] dark:bg-[#29ABE2]/15'
                    : 'text-[#1C2B3A] dark:text-slate-200'
                }`}
              >
                <span className="truncate">{b.name}</span>
                {b.id === currentBoutique?.id && <span className="text-[10px] text-[#29ABE2]">Actif</span>}
              </button>
            ))}
            {isOwner && (
              <>
                <div className="my-1 border-t border-[#E8EFF5] dark:border-dark-600" />
                <button
                  type="button"
                  onClick={() => {
                    setBoutiqueDropdownOpen(false);
                    onOpenCreateBoutique();
                  }}
                  className="w-full text-left px-3 py-2 text-xs font-bold text-[#29ABE2] flex items-center gap-1.5 hover:bg-[#F0F9FE] dark:hover:bg-dark-700 transition"
                >
                  <Plus className="w-3.5 h-3.5" />
                  <span>Nouvelle Boutique</span>
                </button>
              </>
            )}
          </div>
        )}
      </div>

      <div className="relative">
        <button
          onClick={() => {
            setMagasinDropdownOpen(!magasinDropdownOpen);
            setBoutiqueDropdownOpen(false);
          }}
          className={`flex items-center gap-2 px-3 py-1.5 rounded-xl text-xs font-bold transition border ${
            isConsolidatedView
              ? 'bg-amber-50 dark:bg-amber-950/40 text-amber-700 dark:text-amber-300 border-amber-200 dark:border-amber-800'
              : 'bg-white dark:bg-slate-800 text-slate-800 dark:text-slate-200 border-slate-200 dark:border-slate-700'
          }`}
        >
          <span className="truncate max-w-[110px] sm:max-w-[150px]">
            {isConsolidatedView ? 'Vue Consolidée' : currentMagasin?.name || 'Magasin'}
          </span>
          <ChevronDown className="w-3 h-3 text-slate-400" />
        </button>

        {magasinDropdownOpen && (
          <div className="absolute top-full left-0 mt-1.5 w-64 bg-white dark:bg-dark-800 rounded-xl shadow-soft-lg border border-[#E8EFF5] dark:border-dark-600 py-1.5 z-50 animate-fade-in">
            {isOwner && (
              <>
                <div className="px-3 py-1 text-[10px] font-bold text-slate-400 uppercase tracking-wider">
                  Pilotage Global
                </div>
                <button
                  onClick={() => {
                    selectMagasin(null);
                    setMagasinDropdownOpen(false);
                  }}
                  className={`w-full text-left px-3 py-2 text-xs flex items-center justify-between hover:bg-slate-50 dark:hover:bg-slate-800 transition ${
                    isConsolidatedView
                      ? 'text-amber-600 font-bold bg-amber-50/50 dark:bg-amber-950/40'
                      : 'text-slate-700 dark:text-slate-200'
                  }`}
                >
                  <span>Tous les Magasins (Vue Consolidée)</span>
                  {isConsolidatedView && <span className="text-[10px] text-amber-600">Actif</span>}
                </button>
                <div className="my-1 border-t border-slate-100 dark:border-slate-800" />
              </>
            )}

            <div className="px-3 py-1 text-[10px] font-bold text-slate-400 uppercase tracking-wider">
              Points de Vente
            </div>
            {magasins.map((m) => (
              <button
                key={m.id}
                onClick={() => {
                  selectMagasin(m);
                  setMagasinDropdownOpen(false);
                }}
                className={`w-full text-left px-3 py-2 text-xs flex items-center justify-between hover:bg-[#F0F9FE] dark:hover:bg-dark-700 transition ${
                  !isConsolidatedView && m.id === currentMagasin?.id
                    ? 'text-[#29ABE2] font-bold bg-[#E8F5FD] dark:bg-[#29ABE2]/15'
                    : 'text-[#1C2B3A] dark:text-slate-200'
                }`}
              >
                <span className="truncate">{m.name}</span>
                {m.is_warehouse && <span className="text-[9px] text-slate-400">(Dépôt)</span>}
                {!isConsolidatedView && m.id === currentMagasin?.id && (
                  <span className="text-[10px] text-[#29ABE2]">•</span>
                )}
              </button>
            ))}
          </div>
        )}
      </div>
    </>
  );
};
