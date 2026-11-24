import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { ChevronDown, HelpCircle } from 'lucide-react';
import { FAQ_ITEMS } from '../data/landingDetailsContent';

export const LandingFaqSection: React.FC = () => {
  const [openId, setOpenId] = useState<string | null>(FAQ_ITEMS[0]?.id ?? null);

  const toggleItem = (id: string) => {
    setOpenId((prev) => (prev === id ? null : id));
  };

  return (
    <section
      id="faq"
      className="scroll-mt-20 landing-section-deferred py-20 max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 space-y-10"
    >
      <div className="text-center space-y-3">
        <HelpCircle className="w-8 h-8 text-[#29ABE2] mx-auto" />
        <h2 className="text-3xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">
          Questions fréquentes
        </h2>
        <p className="text-sm text-[#5A7184] dark:text-slate-300">
          Les réponses claires aux questions les plus courantes avant de démarrer.
        </p>
      </div>

      <div className="space-y-3">
        {FAQ_ITEMS.map((item) => {
          const isOpen = openId === item.id;
          const panelId = `faq-panel-${item.id}`;
          const buttonId = `faq-button-${item.id}`;

          return (
            <div key={item.id} className="card-toc overflow-hidden">
              <h3>
                <button
                  id={buttonId}
                  type="button"
                  aria-expanded={isOpen}
                  aria-controls={panelId}
                  onClick={() => toggleItem(item.id)}
                  className="w-full px-6 py-4 text-left flex items-center justify-between gap-4 hover:bg-[#F5FAFD] dark:hover:bg-dark-700/40 transition"
                >
                  <span className="text-sm sm:text-base font-bold text-[#1C2B3A] dark:text-white">
                    {item.question}
                  </span>
                  <ChevronDown
                    className={`w-4 h-4 text-[#29ABE2] shrink-0 transition-transform duration-200 ${
                      isOpen ? 'rotate-180' : ''
                    }`}
                  />
                </button>
              </h3>

              {isOpen && (
                <div
                  id={panelId}
                  role="region"
                  aria-labelledby={buttonId}
                  className="px-6 pb-5 pt-1 text-xs sm:text-sm text-[#5A7184] dark:text-slate-300 leading-relaxed border-t border-[#E8EFF5] dark:border-dark-600"
                >
                  {item.answer}
                </div>
              )}
            </div>
          );
        })}
      </div>

      <div className="text-center text-xs text-[#5A7184] dark:text-slate-400">
        Une question spécifique pour votre réseau de boutiques ?{' '}
        <Link to="/contact" className="font-bold text-[#29ABE2] hover:underline">
          Contactez notre équipe
        </Link>
      </div>
    </section>
  );
};
