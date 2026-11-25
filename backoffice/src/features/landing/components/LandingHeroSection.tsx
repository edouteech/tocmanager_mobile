import React from 'react';
import { Link } from 'react-router-dom';
import { ArrowRight, CheckCircle2, Sparkles } from 'lucide-react';
import { SurfaceLink } from '../../../components/common/SurfaceLink';
import { HeroProductShowcase } from './HeroProductShowcase';

const HERO_REASSURANCE = [
  'Plan gratuit sans carte bancaire',
  '14 jours d’essai Pro offerts',
  'Mobile Money FeexPay intégré',
  'Opérationnel en 2 minutes',
];

export const LandingHeroSection: React.FC = () => {
  return (
    <section className="relative overflow-hidden pt-10 pb-16 sm:pt-16 sm:pb-24">
      <div
        className="absolute inset-0 -z-10 bg-[radial-gradient(ellipse_80%_75%_at_50%_-15%,rgba(41,171,226,0.18),rgba(255,255,255,0))]"
        aria-hidden="true"
      />

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 grid grid-cols-1 lg:grid-cols-12 gap-12 lg:gap-10 items-center">
        <div className="lg:col-span-6 space-y-6 text-center lg:text-left">
          <div className="badge-toc-primary mx-auto lg:mx-0">
            <Sparkles className="w-3.5 h-3.5" />
            <span>Plateforme SaaS POS • Web & Mobile Offline-First</span>
          </div>

          <h1 className="text-3xl sm:text-5xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight leading-[1.12]">
            Pilotez vos points de vente, stocks et finances,{' '}
            <span className="text-[#29ABE2]">en ligne comme hors-ligne</span>.
          </h1>

          <p className="text-base sm:text-lg text-[#5A7184] dark:text-slate-300 max-w-2xl mx-auto lg:mx-0 leading-relaxed">
            TocManager réunit la caisse mobile Android ultra-rapide, le suivi cloisonné des stocks multi-magasins, la clôture Z et les rapports financiers consolidés pour les commerçants exigeants.
          </p>

          <div className="flex flex-col sm:flex-row items-center justify-center lg:justify-start gap-3.5 pt-1">
            <SurfaceLink surface="app" to="/inscription" className="w-full sm:w-auto btn-primary px-7 py-3.5 text-sm sm:text-base">
              <span>Démarrer gratuitement</span>
              <ArrowRight className="w-4 h-4" />
            </SurfaceLink>
            <Link to="/tarifs" className="w-full sm:w-auto btn-secondary px-7 py-3.5 text-sm sm:text-base">
              Voir les tarifs & forfaits
            </Link>
          </div>

          <div className="pt-2 grid grid-cols-1 sm:grid-cols-2 gap-2.5 text-xs text-[#5A7184] dark:text-slate-400 max-w-xl mx-auto lg:mx-0">
            {HERO_REASSURANCE.map((item) => (
              <div key={item} className="flex items-center justify-center lg:justify-start gap-2">
                <CheckCircle2 className="w-4 h-4 text-[#27AE60] shrink-0" />
                <span>{item}</span>
              </div>
            ))}
          </div>
        </div>

        <div className="lg:col-span-6 lg:pb-6">
          <HeroProductShowcase />
        </div>
      </div>
    </section>
  );
};
