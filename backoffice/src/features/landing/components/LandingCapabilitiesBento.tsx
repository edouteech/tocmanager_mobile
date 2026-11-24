import React from 'react';
import { BellRing, Calculator, Coins, FileDown, Receipt, RefreshCw } from 'lucide-react';
import { BENTO_CAPABILITIES } from '../data/landingDetailsContent';
import type { BentoCapability } from '../data/landingContent';

const ICON_BY_ID: Record<string, React.ReactNode> = {
  'sync-uuid': <RefreshCw className="w-5 h-5" />,
  'pamp-alerts': <BellRing className="w-5 h-5" />,
  credits: <Receipt className="w-5 h-5" />,
  'cash-z': <Calculator className="w-5 h-5" />,
  currencies: <Coins className="w-5 h-5" />,
  exports: <FileDown className="w-5 h-5" />,
};

const ACCENT_STYLES: Record<BentoCapability['accent'], string> = {
  cyan: 'bg-[#E8F5FD] text-[#29ABE2] dark:bg-[#29ABE2]/15',
  emerald: 'bg-[#E8F8F0] text-[#27AE60] dark:bg-[#27AE60]/15',
  purple: 'bg-[#F5EEF8] text-[#8E44AD] dark:bg-[#8E44AD]/15',
  amber: 'bg-[#FEF5E7] text-[#F39C12] dark:bg-[#F39C12]/15',
};

export const LandingCapabilitiesBento: React.FC = () => {
  return (
    <section className="landing-section-deferred py-20 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 space-y-12">
      <div className="text-center max-w-3xl mx-auto space-y-3">
        <span className="text-xs font-bold uppercase tracking-wider text-[#29ABE2]">
          Capacités métier natives
        </span>
        <h2 className="text-3xl sm:text-4xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">
          Chaque détail opérationnel pensé pour votre rentabilité
        </h2>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-6 lg:grid-cols-12 gap-5">
        {BENTO_CAPABILITIES.map((cap) => (
          <article
            key={cap.id}
            className={`card-toc card-hover p-6 sm:p-7 flex flex-col justify-between gap-5 ${
              cap.featured ? 'md:col-span-3 lg:col-span-6' : 'md:col-span-3 lg:col-span-3'
            }`}
          >
            <div className="space-y-4">
              <div className="flex items-center justify-between gap-2">
                <div
                  className={`w-11 h-11 rounded-xl flex items-center justify-center ${ACCENT_STYLES[cap.accent]}`}
                >
                  {ICON_BY_ID[cap.id]}
                </div>
                <span className="px-2.5 py-1 rounded-full bg-[#F5FAFD] dark:bg-dark-700 border border-[#E8EFF5] dark:border-dark-600 text-[11px] font-bold text-[#5A7184] dark:text-slate-300">
                  {cap.metric}
                </span>
              </div>

              <div className="space-y-2">
                <h3 className="text-lg font-bold text-[#1C2B3A] dark:text-white">{cap.title}</h3>
                <p className="text-xs sm:text-sm text-[#5A7184] dark:text-slate-300 leading-relaxed">
                  {cap.description}
                </p>
              </div>
            </div>
          </article>
        ))}
      </div>
    </section>
  );
};
