import React, { useState } from 'react';
import { ArrowRight, CheckCircle2 } from 'lucide-react';
import { SurfaceLink } from '../../../components/common/SurfaceLink';
import { PRODUCT_PILLARS, type ProductPillarId } from '../data/landingContent';
import { ProductPreviewPanel } from './ProductPreviewPanel';

export const LandingProductShowcase: React.FC = () => {
  const [activeId, setActiveId] = useState<ProductPillarId>('pos');
  const activePillar = PRODUCT_PILLARS.find((item) => item.id === activeId) || PRODUCT_PILLARS[0];

  const handleTabKeyDown = (event: React.KeyboardEvent<HTMLButtonElement>, index: number) => {
    const total = PRODUCT_PILLARS.length;
    let nextIndex: number | null = null;

    if (event.key === 'ArrowRight') nextIndex = (index + 1) % total;
    if (event.key === 'ArrowLeft') nextIndex = (index - 1 + total) % total;
    if (event.key === 'Home') nextIndex = 0;
    if (event.key === 'End') nextIndex = total - 1;

    if (nextIndex !== null) {
      event.preventDefault();
      setActiveId(PRODUCT_PILLARS[nextIndex].id);
    }
  };

  return (
    <section
      id="fonctionnalites"
      className="scroll-mt-20 py-20 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 space-y-10"
    >
      <div className="text-center max-w-3xl mx-auto space-y-3">
        <span className="text-xs font-bold uppercase tracking-wider text-[#29ABE2]">
          Conçu pour le commerce réel
        </span>
        <h2 className="text-3xl sm:text-4xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">
          Une plateforme complète de la caisse jusqu’au résultat net
        </h2>
        <p className="text-sm sm:text-base text-[#5A7184] dark:text-slate-300">
          Explorez chaque pilier métier de TocManager : encaissement hors-ligne, stocks multi-magasins, trésorerie et contrôle des accès.
        </p>
      </div>

      <div
        role="tablist"
        aria-label="Piliers fonctionnels de TocManager"
        className="flex flex-wrap items-center justify-center gap-2.5"
      >
        {PRODUCT_PILLARS.map((pillar, index) => {
          const isSelected = pillar.id === activeId;
          return (
            <button
              key={pillar.id}
              id={`tab-${pillar.id}`}
              type="button"
              role="tab"
              aria-selected={isSelected}
              aria-controls={`panel-${pillar.id}`}
              tabIndex={isSelected ? 0 : -1}
              onClick={() => setActiveId(pillar.id)}
              onKeyDown={(e) => handleTabKeyDown(e, index)}
              className={`px-4 py-2.5 rounded-xl text-xs sm:text-sm font-bold transition border ${
                isSelected
                  ? 'bg-[#29ABE2] text-white border-[#29ABE2] shadow-soft'
                  : 'bg-white dark:bg-dark-800 text-[#5A7184] dark:text-slate-300 border-[#E8EFF5] dark:border-dark-600 hover:border-[#BAE3F9] hover:text-[#1C2B3A] dark:hover:text-white'
              }`}
            >
              {pillar.tabLabel}
            </button>
          );
        })}
      </div>

      <div
        id={`panel-${activePillar.id}`}
        role="tabpanel"
        aria-labelledby={`tab-${activePillar.id}`}
        className="grid grid-cols-1 lg:grid-cols-12 gap-8 lg:gap-12 items-center"
      >
        <div className="lg:col-span-6 space-y-5">
          <div className="badge-toc-primary">{activePillar.eyebrow}</div>
          <h3 className="text-2xl sm:text-3xl font-extrabold text-[#1C2B3A] dark:text-white leading-snug">
            {activePillar.title}
          </h3>
          <p className="text-sm sm:text-base text-[#5A7184] dark:text-slate-300 leading-relaxed">
            {activePillar.description}
          </p>

          <ul className="space-y-2.5 pt-1">
            {activePillar.highlights.map((highlight) => (
              <li
                key={highlight}
                className="flex items-start gap-2.5 text-sm text-[#1C2B3A] dark:text-slate-200"
              >
                <CheckCircle2 className="w-4 h-4 text-[#27AE60] shrink-0 mt-0.5" />
                <span>{highlight}</span>
              </li>
            ))}
          </ul>

          <div className="pt-2">
            <SurfaceLink
              surface={activePillar.ctaTo.startsWith('/inscription') ? 'app' : 'public'}
              to={activePillar.ctaTo}
              className="btn-primary inline-flex px-6 py-3 text-sm"
            >
              <span>{activePillar.ctaLabel}</span>
              <ArrowRight className="w-4 h-4" />
            </SurfaceLink>
          </div>
        </div>

        <div className="lg:col-span-6">
          <ProductPreviewPanel activeId={activePillar.id} />
        </div>
      </div>
    </section>
  );
};
