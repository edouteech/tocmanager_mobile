import React, { useEffect } from 'react';
import { ChevronLeft, ChevronRight, X } from 'lucide-react';
import type { ScreenshotItem } from '../data/landingContent';

interface ScreenshotLightboxProps {
  items: ScreenshotItem[];
  activeIndex: number | null;
  onClose: () => void;
  onSelectIndex: (index: number) => void;
}

export const ScreenshotLightbox: React.FC<ScreenshotLightboxProps> = ({
  items,
  activeIndex,
  onClose,
  onSelectIndex,
}) => {
  const isOpen = activeIndex !== null && items[activeIndex] !== undefined;

  useEffect(() => {
    if (!isOpen || activeIndex === null) return;
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') onClose();
      if (event.key === 'ArrowRight') onSelectIndex((activeIndex + 1) % items.length);
      if (event.key === 'ArrowLeft') onSelectIndex((activeIndex - 1 + items.length) % items.length);
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, activeIndex, items.length, onClose, onSelectIndex]);

  if (!isOpen || activeIndex === null) return null;

  const current = items[activeIndex];
  const prevIndex = (activeIndex - 1 + items.length) % items.length;
  const nextIndex = (activeIndex + 1) % items.length;

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-label={`Aperçu agrandi : ${current.title}`}
      className="fixed inset-0 z-50 flex items-center justify-center p-4 sm:p-6"
    >
      <div
        className="fixed inset-0 bg-[#0B131B]/80 backdrop-blur-sm"
        onClick={onClose}
        aria-hidden="true"
      />

      <div className="relative z-10 w-full max-w-4xl bg-white dark:bg-dark-800 rounded-2xl border border-[#E8EFF5] dark:border-dark-600 shadow-soft-lg overflow-hidden">
        <div className="px-5 py-3.5 border-b border-[#E8EFF5] dark:border-dark-600 flex items-center justify-between gap-4">
          <div className="min-w-0">
            <span className="text-[11px] font-bold uppercase tracking-wider text-[#29ABE2]">
              {current.badge}
            </span>
            <h3 className="text-sm sm:text-base font-extrabold text-[#1C2B3A] dark:text-white truncate">
              {current.title}
            </h3>
          </div>

          <button
            type="button"
            onClick={onClose}
            aria-label="Fermer l’aperçu"
            className="p-2 rounded-xl bg-[#F0F9FE] dark:bg-dark-700 text-[#1C2B3A] dark:text-slate-200 hover:text-[#29ABE2] transition shrink-0"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <div className="bg-[#F5FAFD] dark:bg-dark-900 p-4 sm:p-6 flex items-center justify-center max-h-[68vh]">
          <img
            src={current.src}
            alt={current.alt}
            className={`rounded-xl border border-[#E8EFF5] dark:border-dark-600 shadow-soft object-contain ${
              current.platform === 'mobile' ? 'max-h-[58vh] w-auto' : 'max-h-[58vh] w-full'
            }`}
          />
        </div>

        <div className="px-5 py-3.5 border-t border-[#E8EFF5] dark:border-dark-600 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <p className="text-xs text-[#5A7184] dark:text-slate-300">{current.subtitle}</p>
          <div className="flex items-center gap-2 shrink-0">
            <button
              type="button"
              onClick={() => onSelectIndex(prevIndex)}
              aria-label="Capture précédente"
              className="btn-secondary px-3 py-1.5 text-xs"
            >
              <ChevronLeft className="w-4 h-4" />
              <span>Précédent</span>
            </button>
            <button
              type="button"
              onClick={() => onSelectIndex(nextIndex)}
              aria-label="Capture suivante"
              className="btn-secondary px-3 py-1.5 text-xs"
            >
              <span>Suivant</span>
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
