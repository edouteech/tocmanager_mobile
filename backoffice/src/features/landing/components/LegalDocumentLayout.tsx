import React from 'react';
import { Link } from 'react-router-dom';
import { ArrowRight, CheckCircle2, FileText } from 'lucide-react';
import { SurfaceLink } from '../../../components/common/SurfaceLink';
import { PublicNavbar } from '../../../components/public/PublicNavbar';
import { PublicFooter } from '../../../components/public/PublicFooter';
import type { LegalSection } from '../data/termsContent';

interface LegalDocumentLayoutProps {
  badge: string;
  title: string;
  subtitle: string;
  lastUpdated: string;
  sections: LegalSection[];
  siblingLink: { label: string; to: string };
}

export const LegalDocumentLayout: React.FC<LegalDocumentLayoutProps> = ({
  badge,
  title,
  subtitle,
  lastUpdated,
  sections,
  siblingLink,
}) => {
  return (
    <div className="min-h-screen bg-[#F5FAFD] dark:bg-dark-900 text-[#1C2B3A] dark:text-slate-100 flex flex-col font-sans transition-colors duration-200">
      <PublicNavbar />

      <main id="main-content" className="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-12 space-y-10">
        <div className="card-toc p-6 sm:p-8 space-y-3">
          <div className="flex flex-wrap items-center justify-between gap-2">
            <span className="badge-toc-primary">
              <FileText className="w-3.5 h-3.5" />
              <span>{badge}</span>
            </span>
            <span className="text-xs font-semibold text-[#5A7184] dark:text-slate-400">
              {lastUpdated}
            </span>
          </div>
          <h1 className="text-2xl sm:text-4xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">
            {title}
          </h1>
          <p className="text-sm text-[#5A7184] dark:text-slate-300 max-w-3xl leading-relaxed">
            {subtitle}
          </p>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
          <aside className="lg:col-span-4 lg:sticky lg:top-24 card-toc p-5 space-y-3">
            <h2 className="text-xs font-bold uppercase tracking-wider text-[#29ABE2]">
              Sommaire
            </h2>
            <nav aria-label="Sommaire du document légal" className="flex flex-col gap-1.5 text-xs">
              {sections.map((section) => (
                <a
                  key={section.id}
                  href={`#${section.id}`}
                  className="px-2.5 py-1.5 rounded-lg text-[#5A7184] dark:text-slate-300 hover:bg-[#F0F9FE] dark:hover:bg-dark-700 hover:text-[#29ABE2] transition font-medium"
                >
                  {section.title}
                </a>
              ))}
            </nav>

            <div className="pt-3 border-t border-[#E8EFF5] dark:border-dark-600 flex flex-col gap-2 text-xs">
              <Link to={siblingLink.to} className="font-bold text-[#29ABE2] hover:underline">
                {siblingLink.label}
              </Link>
              <Link to="/contact" className="text-[#5A7184] dark:text-slate-400 hover:text-[#29ABE2]">
                Contacter le support juridique
              </Link>
            </div>
          </aside>

          <div className="lg:col-span-8 space-y-5">
            {sections.map((section) => (
              <article
                key={section.id}
                id={section.id}
                className="scroll-mt-24 card-toc p-6 sm:p-7 space-y-3"
              >
                <h2 className="text-lg font-bold text-[#1C2B3A] dark:text-white">
                  {section.title}
                </h2>
                {section.paragraphs.map((paragraph, index) => (
                  <p
                    key={index}
                    className="text-sm text-[#5A7184] dark:text-slate-300 leading-relaxed"
                  >
                    {paragraph}
                  </p>
                ))}
                {section.bullets && section.bullets.length > 0 && (
                  <ul className="space-y-2 pt-1">
                    {section.bullets.map((bullet) => (
                      <li
                        key={bullet}
                        className="flex items-start gap-2.5 text-sm text-[#1C2B3A] dark:text-slate-200"
                      >
                        <CheckCircle2 className="w-4 h-4 text-[#27AE60] shrink-0 mt-0.5" />
                        <span>{bullet}</span>
                      </li>
                    ))}
                  </ul>
                )}
              </article>
            ))}

            <div className="card-toc p-6 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
              <div className="space-y-1">
                <h3 className="text-sm font-bold text-[#1C2B3A] dark:text-white">
                  Prêt à ouvrir votre boutique sur TocManager ?
                </h3>
                <p className="text-xs text-[#5A7184] dark:text-slate-400">
                  Démarrez gratuitement ou contactez notre équipe pour toute question.
                </p>
              </div>
              <div className="flex items-center gap-2.5 shrink-0">
                <Link to="/contact" className="btn-secondary text-xs py-2.5 px-4">
                  Contact
                </Link>
                <SurfaceLink surface="app" to="/inscription" className="btn-primary text-xs py-2.5 px-4">
                  <span>Créer un compte</span>
                  <ArrowRight className="w-3.5 h-3.5" />
                </SurfaceLink>
              </div>
            </div>
          </div>
        </div>
      </main>

      <PublicFooter />
    </div>
  );
};
