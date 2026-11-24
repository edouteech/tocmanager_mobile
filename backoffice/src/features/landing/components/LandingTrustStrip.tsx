import React from 'react';
import { Globe2, ShieldCheck, Store } from 'lucide-react';
import {
  COMMERCE_SECTORS,
  FEEXPAY_COUNTRIES_LIST,
  HERO_METRICS,
  MOBILE_MONEY_NETWORKS,
} from '../data/landingContent';

export const LandingTrustStrip: React.FC = () => {
  return (
    <section className="bg-white dark:bg-dark-800 border-y border-[#E8EFF5] dark:border-dark-600">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10 space-y-8">
        <div className="space-y-3 text-center">
          <p className="text-[11px] font-bold uppercase tracking-wider text-[#5A7184] dark:text-slate-400">
            Adapté aux commerces de détail, boutiques multi-sites et grossistes
          </p>
          <div className="flex flex-wrap items-center justify-center gap-2.5">
            {COMMERCE_SECTORS.map((sector) => (
              <span
                key={sector}
                className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-[#F5FAFD] dark:bg-dark-700/70 border border-[#E8EFF5] dark:border-dark-600 text-xs font-semibold text-[#1C2B3A] dark:text-slate-200"
              >
                <Store className="w-3.5 h-3.5 text-[#29ABE2]" />
                <span>{sector}</span>
              </span>
            ))}
          </div>
        </div>

        <div className="rounded-2xl bg-[#F0F9FE] dark:bg-dark-900/60 border border-[#BAE3F9]/60 dark:border-dark-600 p-4 sm:p-5 flex flex-col lg:flex-row lg:items-center justify-between gap-4">
          <div className="flex items-start sm:items-center gap-3">
            <div className="w-9 h-9 rounded-xl bg-[#29ABE2]/15 text-[#29ABE2] flex items-center justify-center shrink-0">
              <ShieldCheck className="w-5 h-5" />
            </div>
            <div>
              <div className="text-xs font-bold text-[#1C2B3A] dark:text-white">
                Abonnements & facturation Mobile Money via FeexPay
              </div>
              <div className="text-[11px] text-[#5A7184] dark:text-slate-400 flex items-center gap-1.5 mt-0.5">
                <Globe2 className="w-3.5 h-3.5 text-[#29ABE2] shrink-0" />
                <span>{FEEXPAY_COUNTRIES_LIST.join(' • ')}</span>
              </div>
            </div>
          </div>

          <div className="flex flex-wrap gap-1.5">
            {MOBILE_MONEY_NETWORKS.map((network) => (
              <span
                key={network}
                className="px-2.5 py-1 rounded-lg bg-white dark:bg-dark-800 border border-[#E8EFF5] dark:border-dark-600 text-[11px] font-bold text-[#1C2B3A] dark:text-slate-200"
              >
                {network}
              </span>
            ))}
          </div>
        </div>

        <div className="grid grid-cols-2 md:grid-cols-4 gap-6 pt-2 text-center">
          {HERO_METRICS.map((metric) => (
            <div key={metric.label} className="space-y-1">
              <div className="text-2xl sm:text-3xl font-extrabold text-[#29ABE2] tracking-tight">
                {metric.value}
              </div>
              <div className="text-xs text-[#5A7184] dark:text-slate-400 font-medium">
                {metric.label}
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
};
