import React from 'react';
import { Link } from 'react-router-dom';
import { Store, ArrowRight, CheckCircle2, Sparkles } from 'lucide-react';
import { LandingFeaturesSection } from './LandingFeaturesSection';

export const LandingPage: React.FC = () => {
  return (
    <div className="min-h-screen bg-[#F5FAFD] dark:bg-dark-900 text-[#1C2B3A] dark:text-[#E2E8F0] flex flex-col font-sans transition-colors duration-200">
      <header className="sticky top-0 z-40 bg-white/90 dark:bg-dark-800/90 backdrop-blur-md border-b border-[#E8EFF5] dark:border-dark-600">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl toc-gradient flex items-center justify-center text-white shadow-soft">
              <Store className="w-6 h-6" />
            </div>
            <span className="text-xl font-black tracking-tight text-[#1C2B3A] dark:text-white">
              Toc<span className="text-[#29ABE2]">Manager</span>
            </span>
          </div>

          <nav className="hidden md:flex items-center gap-8 text-sm font-medium text-[#5A7184] dark:text-slate-300">
            <a href="#features" className="hover:text-[#29ABE2] transition">Fonctionnalités</a>
            <a href="#multimag" className="hover:text-[#29ABE2] transition">Multi-Magasins</a>
            <Link to="/tarifs" className="hover:text-[#29ABE2] transition flex items-center gap-1.5">
              <span>Tarifs</span>
              <span className="badge-toc-primary text-[10px] px-2 py-0.5">Essai 14j</span>
            </Link>
            <a href="#faq" className="hover:text-[#29ABE2] transition">FAQ</a>
            <Link to="/contact" className="hover:text-[#29ABE2] transition">Contact</Link>
          </nav>

          <div className="flex items-center gap-3">
            <Link
              to="/login"
              className="px-4 py-2 text-sm font-medium text-[#1C2B3A] dark:text-slate-200 hover:text-[#29ABE2] transition"
            >
              Connexion
            </Link>
            <Link to="/inscription" className="btn-primary py-2 text-xs sm:text-sm">
              <span>Créer mon compte</span>
              <ArrowRight className="w-4 h-4" />
            </Link>
          </div>
        </div>
      </header>

      <section className="relative overflow-hidden pt-12 pb-20 md:pt-20 md:pb-28">
        <div className="absolute inset-0 -z-10 bg-[radial-gradient(ellipse_80%_80%_at_50%_-20%,rgba(41,171,226,0.16),rgba(255,255,255,0))]" />
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center space-y-8">
          <div className="badge-toc-primary mx-auto">
            <Sparkles className="w-3.5 h-3.5" />
            <span>Nouveau : Plateforme SaaS Multi-Boutiques & Multi-Magasins</span>
          </div>

          <h1 className="text-4xl sm:text-5xl md:text-6xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight leading-tight max-w-4xl mx-auto">
            Pilotez vos points de vente, stocks et finances,{' '}
            <span className="text-[#29ABE2]">en ligne comme hors-ligne</span>.
          </h1>

          <p className="text-lg sm:text-xl text-[#5A7184] dark:text-slate-300 max-w-2xl mx-auto leading-relaxed">
            TocManager réunit la caisse mobile ultra-rapide, le suivi précis des stocks par magasin et la vue financière consolidée pour les commerçants exigeants.
          </p>

          <div className="flex flex-col sm:flex-row items-center justify-center gap-4 pt-4">
            <Link to="/inscription" className="w-full sm:w-auto btn-primary px-8 py-3.5 text-base">
              <span>Commencer Gratuitement</span>
              <ArrowRight className="w-5 h-5" />
            </Link>
            <Link to="/tarifs" className="w-full sm:w-auto btn-secondary px-8 py-3.5 text-base">
              Voir les Forfaits & Tarifs
            </Link>
          </div>

          <div className="pt-8 flex flex-wrap items-center justify-center gap-6 text-xs text-[#5A7184] dark:text-slate-400">
            <div className="flex items-center gap-1.5">
              <CheckCircle2 className="w-4 h-4 text-[#27AE60]" />
              <span>Plan gratuit sans engagement</span>
            </div>
            <div className="flex items-center gap-1.5">
              <CheckCircle2 className="w-4 h-4 text-[#27AE60]" />
              <span>14 jours d'essai Pro offerts</span>
            </div>
            <div className="flex items-center gap-1.5">
              <CheckCircle2 className="w-4 h-4 text-[#27AE60]" />
              <span>Synchronisation autonome hors-ligne</span>
            </div>
          </div>
        </div>
      </section>

      <LandingFeaturesSection />

      <section className="toc-gradient text-white py-16 text-center">
        <div className="max-w-4xl mx-auto px-4 space-y-6">
          <h2 className="text-3xl sm:text-4xl font-extrabold tracking-tight">
            Prêt à transformer la gestion de vos boutiques ?
          </h2>
          <p className="text-white/85 text-base max-w-xl mx-auto">
            Inscrivez-vous en 2 minutes et commencez à encaisser dès aujourd'hui.
          </p>
          <Link
            to="/inscription"
            className="inline-flex items-center gap-2 px-8 py-3.5 text-base font-semibold text-[#1A8FBF] bg-white hover:bg-[#F0F9FE] rounded-xl shadow-soft transition"
          >
            <span>Créer mon compte maintenant</span>
            <ArrowRight className="w-5 h-5" />
          </Link>
        </div>
      </section>

      <footer className="bg-white dark:bg-dark-900 border-t border-[#E8EFF5] dark:border-dark-600 py-10 text-xs text-[#5A7184]">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex flex-col sm:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-2">
            <Store className="w-5 h-5 text-[#29ABE2]" />
            <span className="font-bold text-[#1C2B3A] dark:text-white">TocManager SaaS</span>
            <span>• © 2026 Tous droits réservés</span>
          </div>
          <div className="flex items-center gap-6">
            <Link to="/tarifs" className="hover:text-[#29ABE2] transition">Tarifs</Link>
            <Link to="/contact" className="hover:text-[#29ABE2] transition">Contact</Link>
            <Link to="/login" className="hover:text-[#29ABE2] transition">Espace Client</Link>
          </div>
        </div>
      </footer>
    </div>
  );
};
