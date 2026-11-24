import React from 'react';
import { CheckCircle2, FileSpreadsheet, Layers, Lock, ShieldCheck, Smartphone, WifiOff } from 'lucide-react';
import type { ProductPillarId } from '../data/landingContent';

interface ProductPreviewPanelProps {
  activeId: ProductPillarId;
}

export const ProductPreviewPanel: React.FC<ProductPreviewPanelProps> = ({ activeId }) => {
  if (activeId === 'pos') {
    return (
      <div className="card-toc p-5 sm:p-6 shadow-soft-md space-y-4">
        <div className="flex items-center justify-between border-b border-[#E8EFF5] dark:border-dark-600 pb-3.5">
          <div className="flex items-center gap-2">
            <Smartphone className="w-4 h-4 text-[#29ABE2]" />
            <span className="text-sm font-bold text-[#1C2B3A] dark:text-white">
              Ticket POS • Caisse Plateau
            </span>
          </div>
          <span className="badge-toc-warning">
            <WifiOff className="w-3 h-3" />
            <span>File locale UUID</span>
          </span>
        </div>

        <div className="space-y-2.5 text-xs">
          <div className="flex items-center justify-between p-3 rounded-xl bg-[#F5FAFD] dark:bg-dark-700/70">
            <div>
              <div className="font-bold text-[#1C2B3A] dark:text-white">Riz Parfumé 25kg (x2)</div>
              <div className="text-[11px] text-[#5A7184] dark:text-slate-400">Stock restant : 18 sacs</div>
            </div>
            <span className="font-extrabold text-[#1C2B3A] dark:text-white">29 000 FCFA</span>
          </div>
          <div className="flex items-center justify-between p-3 rounded-xl bg-[#F5FAFD] dark:bg-dark-700/70">
            <div>
              <div className="font-bold text-[#1C2B3A] dark:text-white">Huile Végétale 5L (x1)</div>
              <div className="text-[11px] text-[#5A7184] dark:text-slate-400">Stock restant : 9 bidons</div>
            </div>
            <span className="font-extrabold text-[#1C2B3A] dark:text-white">7 500 FCFA</span>
          </div>
        </div>

        <div className="rounded-xl bg-[#1C2B3A] text-white p-4 flex items-center justify-between">
          <div>
            <div className="text-[11px] text-slate-300">Total encaissé • Espèces</div>
            <div className="text-lg font-extrabold">36 500 FCFA</div>
          </div>
          <span className="px-3 py-1.5 rounded-lg bg-[#27AE60] text-xs font-bold">
            Ticket validé
          </span>
        </div>
      </div>
    );
  }

  if (activeId === 'multistore') {
    return (
      <div className="card-toc p-5 sm:p-6 shadow-soft-md space-y-4">
        <div className="flex items-center justify-between border-b border-[#E8EFF5] dark:border-dark-600 pb-3.5">
          <div className="flex items-center gap-2">
            <Layers className="w-4 h-4 text-[#8E44AD]" />
            <span className="text-sm font-bold text-[#1C2B3A] dark:text-white">
              Transferts & Cloisonnement Stocks
            </span>
          </div>
          <span className="badge-toc-purple">Mode Passer</span>
        </div>

        <div className="grid grid-cols-2 gap-3 text-xs">
          <div className="p-3 rounded-xl bg-[#F5FAFD] dark:bg-dark-700/70 border border-[#E8EFF5] dark:border-dark-600">
            <div className="font-bold text-[#1C2B3A] dark:text-white">Point de Vente Plateau</div>
            <div className="text-[#29ABE2] font-extrabold mt-1">184 articles actifs</div>
            <div className="text-[11px] text-[#5A7184] dark:text-slate-400 mt-0.5">Tarif zone centre</div>
          </div>
          <div className="p-3 rounded-xl bg-[#F5FAFD] dark:bg-dark-700/70 border border-[#E8EFF5] dark:border-dark-600">
            <div className="font-bold text-[#1C2B3A] dark:text-white">Entrepôt Central</div>
            <div className="text-[#27AE60] font-extrabold mt-1">6 420 unités</div>
            <div className="text-[11px] text-[#5A7184] dark:text-slate-400 mt-0.5">Réserve principale</div>
          </div>
        </div>

        <div className="p-3.5 rounded-xl bg-[#E8F8F0] dark:bg-[#27AE60]/15 border border-[#27AE60]/30 flex items-center justify-between text-xs">
          <div>
            <div className="font-bold text-[#1C2B3A] dark:text-white">
              Transfert #TRF-204 • Entrepôt → Plateau
            </div>
            <div className="text-[11px] text-[#5A7184] dark:text-slate-300">
              45 unités réceptionnées • Mouvement stock journalisé
            </div>
          </div>
          <CheckCircle2 className="w-5 h-5 text-[#27AE60] shrink-0" />
        </div>
      </div>
    );
  }

  if (activeId === 'finance') {
    return (
      <div className="card-toc p-5 sm:p-6 shadow-soft-md space-y-4">
        <div className="flex items-center justify-between border-b border-[#E8EFF5] dark:border-dark-600 pb-3.5">
          <div className="flex items-center gap-2">
            <FileSpreadsheet className="w-4 h-4 text-[#27AE60]" />
            <span className="text-sm font-bold text-[#1C2B3A] dark:text-white">
              Rapport Z & Synthèse P&L
            </span>
          </div>
          <span className="badge-toc-success">Caisse clôturée</span>
        </div>

        <div className="grid grid-cols-2 gap-3 text-xs">
          <div className="p-3 rounded-xl bg-[#F5FAFD] dark:bg-dark-700/70">
            <div className="text-[11px] text-[#5A7184] dark:text-slate-400">CA Brut Clôture Z</div>
            <div className="text-base font-extrabold text-[#1C2B3A] dark:text-white mt-0.5">
              485 000 FCFA
            </div>
          </div>
          <div className="p-3 rounded-xl bg-[#F5FAFD] dark:bg-dark-700/70">
            <div className="text-[11px] text-[#5A7184] dark:text-slate-400">Marge Nette (PAMP)</div>
            <div className="text-base font-extrabold text-[#27AE60] mt-0.5">
              128 400 FCFA
            </div>
          </div>
        </div>

        <div className="space-y-2 text-xs">
          <div className="flex items-center justify-between px-3 py-2 rounded-xl bg-[#F5FAFD] dark:bg-dark-700/60">
            <span className="text-[#5A7184] dark:text-slate-300">Écart comptage caisse</span>
            <span className="font-bold text-[#27AE60]">0 FCFA</span>
          </div>
          <div className="flex items-center justify-between px-3 py-2 rounded-xl bg-[#F5FAFD] dark:bg-dark-700/60">
            <span className="text-[#5A7184] dark:text-slate-300">Créances clients recouvrées</span>
            <span className="font-bold text-[#29ABE2]">65 000 FCFA</span>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="card-toc p-5 sm:p-6 shadow-soft-md space-y-4">
      <div className="flex items-center justify-between border-b border-[#E8EFF5] dark:border-dark-600 pb-3.5">
        <div className="flex items-center gap-2">
          <ShieldCheck className="w-4 h-4 text-[#29ABE2]" />
          <span className="text-sm font-bold text-[#1C2B3A] dark:text-white">
            Contrôle d’accès & Audit Boutique
          </span>
        </div>
        <span className="badge-toc-primary">
          <Lock className="w-3 h-3" />
          <span>PIN 4/6 chiffres</span>
        </span>
      </div>

      <div className="space-y-2.5 text-xs">
        <div className="flex items-center justify-between p-3 rounded-xl bg-[#F5FAFD] dark:bg-dark-700/70">
          <div>
            <div className="font-bold text-[#1C2B3A] dark:text-white">Awa Diop • Propriétaire</div>
            <div className="text-[11px] text-[#5A7184] dark:text-slate-400">Accès total + Mode Passer</div>
          </div>
          <span className="badge-toc-primary">Owner</span>
        </div>
        <div className="flex items-center justify-between p-3 rounded-xl bg-[#F5FAFD] dark:bg-dark-700/70">
          <div>
            <div className="font-bold text-[#1C2B3A] dark:text-white">Moussa Koné • Caissier 1</div>
            <div className="text-[11px] text-[#5A7184] dark:text-slate-400">Affecté : Plateau uniquement</div>
          </div>
          <span className="badge-toc-success">PIN actif</span>
        </div>
        <div className="p-2.5 rounded-xl bg-[#FEF5E7] dark:bg-[#F39C12]/15 text-[11px] font-medium text-[#1C2B3A] dark:text-amber-200">
          Audit 14:22 — Clôture Z validée par Awa Diop (Caisse Plateau)
        </div>
      </div>
    </div>
  );
};
