import React from 'react';
import { Briefcase, CheckCircle2 } from 'lucide-react';
import { MERCHANT_USE_CASES } from '../data/landingDetailsContent';

export const LandingUseCasesSection: React.FC = () => {
  return (
    <section className="landing-section-deferred bg-white dark:bg-dark-800/60 border-y border-[#E8EFF5] dark:border-dark-600 py-20">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 space-y-12">
        <div className="text-center max-w-3xl mx-auto space-y-3">
          <span className="text-xs font-bold uppercase tracking-wider text-[#29ABE2]">
            Cas d’usage métiers
          </span>
          <h2 className="text-3xl sm:text-4xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">
            Conçu pour chaque profil de commerce
          </h2>
          <p className="text-sm sm:text-base text-[#5A7184] dark:text-slate-300">
            Que vous gériez une boutique de quartier ou un réseau avec entrepôt central, TocManager s’adapte à votre organisation.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {MERCHANT_USE_CASES.map((useCase) => (
            <article key={useCase.id} className="card-toc card-hover p-6 sm:p-7 flex flex-col justify-between gap-5">
              <div className="space-y-4">
                <div className="flex items-center justify-between gap-2">
                  <span className="badge-toc-primary text-[11px]">{useCase.sector}</span>
                  <Briefcase className="w-4 h-4 text-[#29ABE2] shrink-0" />
                </div>

                <div>
                  <h3 className="text-base font-bold text-[#1C2B3A] dark:text-white">
                    {useCase.profile}
                  </h3>
                  <p className="text-xs sm:text-sm text-[#5A7184] dark:text-slate-300 mt-2 leading-relaxed">
                    {useCase.challenge}
                  </p>
                </div>

                <div className="flex flex-wrap gap-1.5">
                  {useCase.modules.map((mod) => (
                    <span
                      key={mod}
                      className="px-2.5 py-1 rounded-lg bg-[#F5FAFD] dark:bg-dark-700 text-[11px] font-semibold text-[#1C2B3A] dark:text-slate-200 border border-[#E8EFF5] dark:border-dark-600"
                    >
                      {mod}
                    </span>
                  ))}
                </div>
              </div>

              <div className="pt-4 border-t border-[#E8EFF5] dark:border-dark-600 flex items-start gap-2 text-xs font-semibold text-[#1C2B3A] dark:text-slate-200">
                <CheckCircle2 className="w-4 h-4 text-[#27AE60] shrink-0 mt-0.5" />
                <span>{useCase.outcome}</span>
              </div>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
};
