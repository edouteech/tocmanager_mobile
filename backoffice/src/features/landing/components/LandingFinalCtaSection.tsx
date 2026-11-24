import React from 'react';
import { Link } from 'react-router-dom';
import { ArrowRight, MessageSquare } from 'lucide-react';

export const LandingFinalCtaSection: React.FC = () => {
  return (
    <section className="toc-gradient text-white py-16 sm:py-20 relative overflow-hidden">
      <div
        className="absolute -right-16 -top-16 w-64 h-64 rounded-full bg-white/10 blur-3xl pointer-events-none"
        aria-hidden="true"
      />
      <div className="max-w-4xl mx-auto px-4 sm:px-6 text-center space-y-6 relative z-10">
        <h2 className="text-3xl sm:text-4xl font-extrabold tracking-tight">
          Prêt à fiabiliser vos ventes et vos stocks dès aujourd’hui ?
        </h2>
        <p className="text-white/90 text-sm sm:text-base max-w-2xl mx-auto leading-relaxed">
          Ouvrez votre espace TocManager en 2 minutes avec le Plan Gratuit ou profitez de 14 jours d’essai Pro offerts, sans carte bancaire.
        </p>

        <div className="flex flex-col sm:flex-row items-center justify-center gap-3.5 pt-2">
          <Link
            to="/inscription"
            className="w-full sm:w-auto inline-flex items-center justify-center gap-2 px-7 py-3.5 text-sm sm:text-base font-bold text-[#1A8FBF] bg-white hover:bg-[#F0F9FE] rounded-xl shadow-soft transition"
          >
            <span>Créer mon compte gratuitement</span>
            <ArrowRight className="w-4 h-4" />
          </Link>
          <Link
            to="/contact"
            className="w-full sm:w-auto inline-flex items-center justify-center gap-2 px-7 py-3.5 text-sm sm:text-base font-bold text-white bg-white/15 hover:bg-white/25 border border-white/30 rounded-xl transition"
          >
            <MessageSquare className="w-4 h-4" />
            <span>Demander une démo Entreprise</span>
          </Link>
        </div>
      </div>
    </section>
  );
};
