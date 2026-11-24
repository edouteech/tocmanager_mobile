import React, { useState } from 'react';
import { CheckCircle2, Cloud, RefreshCw, TrendingUp, WifiOff } from 'lucide-react';

const CHART_POINTS = [34, 48, 42, 66, 58, 79, 92];

export const HeroProductShowcase: React.FC = () => {
  const [isOfflineDemo, setIsOfflineDemo] = useState(false);

  return (
    <div className="relative mx-auto w-full max-w-xl lg:max-w-none">
      <div className="card-toc overflow-hidden shadow-soft-lg border border-[#BAE3F9]/80 dark:border-dark-600">
        <div className="bg-[#F5FAFD] dark:bg-dark-900/90 px-4 py-3 border-b border-[#E8EFF5] dark:border-dark-600 flex items-center justify-between gap-2">
          <div className="flex items-center gap-2 min-w-0">
            <div className="flex items-center gap-1.5 shrink-0" aria-hidden="true">
              <span className="w-2.5 h-2.5 rounded-full bg-[#E74C3C]/70" />
              <span className="w-2.5 h-2.5 rounded-full bg-[#F39C12]/70" />
              <span className="w-2.5 h-2.5 rounded-full bg-[#27AE60]/70" />
            </div>
            <span className="text-[11px] font-bold text-[#1C2B3A] dark:text-slate-200 truncate">
              Boutique Élégance Dakar • 3 magasins
            </span>
          </div>
          <span className="badge-toc-primary text-[10px] shrink-0">Plan Pro</span>
        </div>

        <div className="p-4 sm:p-5 space-y-4 bg-white dark:bg-dark-800">
          <div className="grid grid-cols-3 gap-2.5 sm:gap-3">
            <div className="p-3 rounded-xl bg-[#F5FAFD] dark:bg-dark-700/70 border border-[#E8EFF5] dark:border-dark-600">
              <div className="text-[10px] font-semibold uppercase tracking-wider text-[#5A7184] dark:text-slate-400">
                Ventes du jour
              </div>
              <div className="text-sm sm:text-base font-extrabold text-[#1C2B3A] dark:text-white mt-1">
                795 000 F
              </div>
              <div className="text-[10px] font-semibold text-[#27AE60] mt-0.5">+18% vs hier</div>
            </div>

            <div className="p-3 rounded-xl bg-[#F5FAFD] dark:bg-dark-700/70 border border-[#E8EFF5] dark:border-dark-600">
              <div className="text-[10px] font-semibold uppercase tracking-wider text-[#5A7184] dark:text-slate-400">
                Marge nette
              </div>
              <div className="text-sm sm:text-base font-extrabold text-[#1C2B3A] dark:text-white mt-1">
                214 500 F
              </div>
              <div className="text-[10px] font-semibold text-[#29ABE2] mt-0.5">Calcul PAMP</div>
            </div>

            <div className="p-3 rounded-xl bg-[#F5FAFD] dark:bg-dark-700/70 border border-[#E8EFF5] dark:border-dark-600">
              <div className="text-[10px] font-semibold uppercase tracking-wider text-[#5A7184] dark:text-slate-400">
                Alertes stock
              </div>
              <div className="text-sm sm:text-base font-extrabold text-[#E74C3C] mt-1">
                3 articles
              </div>
              <div className="text-[10px] font-semibold text-[#5A7184] dark:text-slate-400 mt-0.5">
                Seuil critique
              </div>
            </div>
          </div>

          <div className="p-3.5 rounded-xl bg-[#F5FAFD] dark:bg-dark-900/50 border border-[#E8EFF5] dark:border-dark-600 space-y-2.5">
            <div className="flex items-center justify-between text-xs">
              <div className="flex items-center gap-1.5 font-bold text-[#1C2B3A] dark:text-white">
                <TrendingUp className="w-3.5 h-3.5 text-[#29ABE2]" />
                <span>Tendance consolidée 7 jours</span>
              </div>
              <span className="text-[11px] text-[#27AE60] font-semibold">Temps réel</span>
            </div>

            <svg
              viewBox="0 0 280 68"
              className="w-full h-16 overflow-visible"
              role="img"
              aria-label="Courbe de progression des ventes sur 7 jours"
            >
              <defs>
                <linearGradient id="tocHeroArea" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="0%" stopColor="#29ABE2" stopOpacity="0.32" />
                  <stop offset="100%" stopColor="#29ABE2" stopOpacity="0" />
                </linearGradient>
              </defs>
              <path
                d="M 8 46 L 52 36 L 96 41 L 140 24 L 184 29 L 228 14 L 272 6 L 272 66 L 8 66 Z"
                fill="url(#tocHeroArea)"
              />
              <polyline
                fill="none"
                stroke="#29ABE2"
                strokeWidth="2.5"
                strokeLinecap="round"
                strokeLinejoin="round"
                points="8,46 52,36 96,41 140,24 184,29 228,14 272,6"
              />
              {CHART_POINTS.map((val, index) => {
                const x = 8 + index * 44;
                const y = 66 - Math.round((val / 100) * 60);
                return (
                  <circle
                    key={index}
                    cx={x}
                    cy={y}
                    r="3.2"
                    fill="#FFFFFF"
                    stroke="#29ABE2"
                    strokeWidth="2"
                  />
                );
              })}
            </svg>
          </div>

          <div className="space-y-2 pb-10 sm:pb-8">
            <div className="flex items-center justify-between text-[11px] font-bold text-[#5A7184] dark:text-slate-400 uppercase tracking-wider">
              <span>Derniers tickets synchronisés</span>
              <span>Montant</span>
            </div>
            <div className="flex items-center justify-between p-2.5 rounded-xl bg-[#F5FAFD] dark:bg-dark-700/50 text-xs">
              <div>
                <div className="font-bold text-[#1C2B3A] dark:text-white">#VNT-0942 • Plateau</div>
                <div className="text-[11px] text-[#5A7184] dark:text-slate-400">
                  Mobile Money • Caissier 1
                </div>
              </div>
              <span className="font-extrabold text-[#27AE60]">24 500 FCFA</span>
            </div>
            <div className="flex items-center justify-between p-2.5 rounded-xl bg-[#F5FAFD] dark:bg-dark-700/50 text-xs">
              <div>
                <div className="font-bold text-[#1C2B3A] dark:text-white">#VNT-0941 • Almadies</div>
                <div className="text-[11px] text-[#5A7184] dark:text-slate-400">
                  Espèces • Gérant
                </div>
              </div>
              <span className="font-extrabold text-[#27AE60]">42 000 FCFA</span>
            </div>
          </div>
        </div>
      </div>

      <div className="mt-4 sm:mt-0 sm:absolute sm:-bottom-5 sm:right-4 w-full sm:w-80 rounded-2xl bg-[#1C2B3A] dark:bg-dark-900 text-white p-4 shadow-soft-lg border border-white/10 space-y-3">
        <div className="flex items-center justify-between gap-2">
          <span className="text-xs font-bold tracking-tight">Caisse Mobile POS</span>
          {isOfflineDemo ? (
            <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-[#F39C12]/20 text-[#F39C12]">
              <WifiOff className="w-3 h-3" />
              <span>Hors-ligne • 3 UUID en file</span>
            </span>
          ) : (
            <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-[#27AE60]/20 text-[#27AE60]">
              <Cloud className="w-3 h-3" />
              <span>En ligne • Synchronisé</span>
            </span>
          )}
        </div>

        <p className="text-[11px] text-slate-300 leading-relaxed">
          {isOfflineDemo
            ? 'Internet coupé : les ventes restent encaissées en SQLite locale et seront poussées sans doublon.'
            : '0 ticket en attente. Base locale et backoffice cloud parfaitement synchronisés.'}
        </p>

        <div className="flex items-center justify-between gap-2 pt-1">
          <div className="flex items-center gap-1.5 text-[11px] text-slate-300">
            <CheckCircle2 className="w-3.5 h-3.5 text-[#29ABE2]" />
            <span>{isOfflineDemo ? '3 tickets sécurisés' : 'Mode continu actif'}</span>
          </div>
          <button
            type="button"
            onClick={() => setIsOfflineDemo((prev) => !prev)}
            className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-[#29ABE2] hover:bg-[#1A8FBF] text-white text-[11px] font-bold transition"
          >
            <RefreshCw className="w-3 h-3" />
            <span>{isOfflineDemo ? 'Reconnecter & sync' : 'Simuler coupure internet'}</span>
          </button>
        </div>
      </div>
    </div>
  );
};
