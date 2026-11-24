import React from 'react';
import { Link } from 'react-router-dom';
import { ArrowRight, Clock } from 'lucide-react';
import { ONBOARDING_STEPS } from '../data/landingDetailsContent';

export const LandingHowItWorksSection: React.FC = () => {
  return (
    <section
      id="comment-ca-marche"
      className="scroll-mt-20 landing-section-deferred bg-white dark:bg-dark-800/70 border-y border-[#E8EFF5] dark:border-dark-600 py-20"
    >
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 space-y-12">
        <div className="text-center max-w-2xl mx-auto space-y-3">
          <span className="text-xs font-bold uppercase tracking-wider text-[#29ABE2]">
            Démarrage rapide
          </span>
          <h2 className="text-3xl sm:text-4xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">
            Opérationnel en 3 étapes simples
          </h2>
          <p className="text-sm sm:text-base text-[#5A7184] dark:text-slate-300">
            Pas de configuration complexe : votre boutique, votre premier magasin et votre période d’essai sont provisionnés instantanément.
          </p>
        </div>

        <div className="relative grid grid-cols-1 md:grid-cols-3 gap-6">
          {ONBOARDING_STEPS.map((item) => (
            <div
              key={item.step}
              className="card-toc p-6 sm:p-7 space-y-4 relative bg-[#F5FAFD]/60 dark:bg-dark-900/50"
            >
              <div className="flex items-center justify-between">
                <span className="w-10 h-10 rounded-xl toc-gradient text-white font-extrabold text-sm flex items-center justify-center shadow-soft">
                  {item.step}
                </span>
                <span className="inline-flex items-center gap-1 text-[11px] font-semibold text-[#5A7184] dark:text-slate-400">
                  <Clock className="w-3.5 h-3.5 text-[#29ABE2]" />
                  <span>{item.duration}</span>
                </span>
              </div>

              <div className="space-y-2">
                <h3 className="text-lg font-bold text-[#1C2B3A] dark:text-white">{item.title}</h3>
                <p className="text-xs sm:text-sm text-[#5A7184] dark:text-slate-300 leading-relaxed">
                  {item.description}
                </p>
              </div>
            </div>
          ))}
        </div>

        <div className="text-center">
          <Link to="/inscription" className="btn-primary inline-flex px-7 py-3.5 text-sm sm:text-base">
            <span>Créer ma boutique en 2 minutes</span>
            <ArrowRight className="w-4 h-4" />
          </Link>
        </div>
      </div>
    </section>
  );
};
