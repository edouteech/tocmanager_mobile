import React, { useState } from 'react';
import { Expand, Monitor, Smartphone } from 'lucide-react';
import { SCREENSHOT_ITEMS, type ScreenshotItem, type ScreenshotPlatform } from '../data/landingContent';
import { ScreenshotLightbox } from './ScreenshotLightbox';

type FilterValue = 'all' | ScreenshotPlatform;

const FILTER_OPTIONS: { value: FilterValue; label: string }[] = [
  { value: 'all', label: 'Toutes les captures' },
  { value: 'web', label: 'Espace Web' },
  { value: 'mobile', label: 'Application Mobile' },
];

export const LandingScreenshotsGallery: React.FC = () => {
  const [filter, setFilter] = useState<FilterValue>('all');
  const [lightboxIndex, setLightboxIndex] = useState<number | null>(null);
  const [failedIds, setFailedIds] = useState<Record<string, boolean>>({});

  const visibleItems: ScreenshotItem[] =
    filter === 'all'
      ? SCREENSHOT_ITEMS
      : SCREENSHOT_ITEMS.filter((item) => item.platform === filter);

  const handleImageError = (id: string) => {
    setFailedIds((prev) => ({ ...prev, [id]: true }));
  };

  return (
    <section
      id="captures"
      className="scroll-mt-20 landing-section-deferred bg-[#F0F9FE]/70 dark:bg-dark-800/50 border-y border-[#E8EFF5] dark:border-dark-600 py-20"
    >
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 space-y-10">
        <div className="flex flex-col md:flex-row md:items-end justify-between gap-6">
          <div className="space-y-3 max-w-2xl">
            <span className="text-xs font-bold uppercase tracking-wider text-[#29ABE2]">
              Aperçu réel de l’interface
            </span>
            <h2 className="text-3xl sm:text-4xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">
              Espace utilisateur Web & application mobile Android
            </h2>
            <p className="text-sm sm:text-base text-[#5A7184] dark:text-slate-300">
              Retrouvez la même clarté visuelle au comptoir sur smartphone et au bureau depuis votre backoffice web. Cliquez sur une capture pour l’agrandir.
            </p>
          </div>

          <div className="flex flex-wrap gap-2" role="group" aria-label="Filtrer les captures produit">
            {FILTER_OPTIONS.map((opt) => {
              const active = filter === opt.value;
              return (
                <button
                  key={opt.value}
                  type="button"
                  aria-pressed={active}
                  onClick={() => {
                    setFilter(opt.value);
                    setLightboxIndex(null);
                  }}
                  className={`px-3.5 py-2 rounded-xl text-xs font-bold border transition ${
                    active
                      ? 'bg-[#29ABE2] text-white border-[#29ABE2] shadow-soft'
                      : 'bg-white dark:bg-dark-800 text-[#5A7184] dark:text-slate-300 border-[#E8EFF5] dark:border-dark-600 hover:text-[#29ABE2]'
                  }`}
                >
                  {opt.label}
                </button>
              );
            })}
          </div>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
          {visibleItems.map((item, idx) => {
            const isMobile = item.platform === 'mobile';
            const hasFailed = Boolean(failedIds[item.id]);

            return (
              <article
                key={item.id}
                className="card-toc card-hover overflow-hidden flex flex-col justify-between"
              >
                <button
                  type="button"
                  onClick={() => setLightboxIndex(idx)}
                  aria-label={`Agrandir la capture : ${item.title}`}
                  className="group relative w-full text-left bg-[#F5FAFD] dark:bg-dark-900/70 p-5 sm:p-6 border-b border-[#E8EFF5] dark:border-dark-600 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-[#29ABE2]"
                >
                  <div className="flex items-center justify-between mb-3">
                    <span className="inline-flex items-center gap-1.5 text-[11px] font-bold text-[#29ABE2]">
                      {isMobile ? (
                        <Smartphone className="w-3.5 h-3.5" />
                      ) : (
                        <Monitor className="w-3.5 h-3.5" />
                      )}
                      <span>{item.badge}</span>
                    </span>
                    <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg bg-white/90 dark:bg-dark-800 text-[11px] font-semibold text-[#5A7184] dark:text-slate-300 border border-[#E8EFF5] dark:border-dark-600 group-hover:text-[#29ABE2] transition">
                      <Expand className="w-3 h-3" />
                      <span>Agrandir</span>
                    </span>
                  </div>

                  {hasFailed ? (
                    <div className="h-64 rounded-xl border border-dashed border-[#BAE3F9] dark:border-dark-600 flex items-center justify-center text-xs text-[#5A7184]">
                      Aperçu indisponible ({item.title})
                    </div>
                  ) : isMobile ? (
                    <div className="flex justify-center py-1">
                      <div className="w-52 sm:w-56 rounded-[26px] p-2 bg-[#1C2B3A] shadow-soft-lg border border-slate-700/80">
                        <img
                          src={item.src}
                          alt={item.alt}
                          loading="lazy"
                          decoding="async"
                          onError={() => handleImageError(item.id)}
                          className="w-full aspect-[9/16] object-cover rounded-[18px] bg-white"
                        />
                      </div>
                    </div>
                  ) : (
                    <div className="rounded-xl overflow-hidden border border-[#E8EFF5] dark:border-dark-600 bg-white shadow-soft">
                      <div className="px-3 py-1.5 bg-[#F5FAFD] dark:bg-dark-800 border-b border-[#E8EFF5] dark:border-dark-600 flex items-center gap-1.5">
                        <span className="w-2 h-2 rounded-full bg-slate-300 dark:bg-dark-500" />
                        <span className="w-2 h-2 rounded-full bg-slate-300 dark:bg-dark-500" />
                        <span className="w-2 h-2 rounded-full bg-slate-300 dark:bg-dark-500" />
                      </div>
                      <img
                        src={item.src}
                        alt={item.alt}
                        loading="lazy"
                        decoding="async"
                        onError={() => handleImageError(item.id)}
                        className="w-full aspect-[16/9] object-cover object-top"
                      />
                    </div>
                  )}
                </button>

                <div className="p-6 space-y-3">
                  <h3 className="text-lg font-bold text-[#1C2B3A] dark:text-white">{item.title}</h3>
                  <p className="text-xs sm:text-sm text-[#5A7184] dark:text-slate-300 leading-relaxed">
                    {item.subtitle}
                  </p>
                  <div className="flex flex-wrap gap-1.5 pt-1">
                    {item.highlights.map((tag) => (
                      <span
                        key={tag}
                        className="px-2.5 py-1 rounded-lg bg-[#F5FAFD] dark:bg-dark-700 text-[11px] font-semibold text-[#1C2B3A] dark:text-slate-200 border border-[#E8EFF5] dark:border-dark-600"
                      >
                        {tag}
                      </span>
                    ))}
                  </div>
                </div>
              </article>
            );
          })}
        </div>
      </div>

      <ScreenshotLightbox
        items={visibleItems}
        activeIndex={lightboxIndex}
        onClose={() => setLightboxIndex(null)}
        onSelectIndex={(index) => setLightboxIndex(index)}
      />
    </section>
  );
};
