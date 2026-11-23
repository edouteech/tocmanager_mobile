import React from 'react';
import { Link } from 'react-router-dom';
import {
  Store,
  WifiOff,
  TrendingUp,
  Smartphone,
  Layers,
  ArrowRight,
  CheckCircle2,
  HelpCircle,
  Sparkles,
} from 'lucide-react';

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
            <a href="#features" className="hover:text-[#29ABE2] transition">
              Fonctionnalités
            </a>
            <a href="#multimag" className="hover:text-[#29ABE2] transition">
              Multi-Magasins
            </a>
            <Link to="/tarifs" className="hover:text-[#29ABE2] transition flex items-center gap-1.5">
              <span>Tarifs</span>
              <span className="badge-toc-primary text-[10px] px-2 py-0.5">Essai 14j</span>
            </Link>
            <a href="#faq" className="hover:text-[#29ABE2] transition">
              FAQ
            </a>
            <Link to="/contact" className="hover:text-[#29ABE2] transition">
              Contact
            </Link>
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

      <section className="bg-white dark:bg-dark-800 border-y border-[#E8EFF5] dark:border-dark-600 py-10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 grid grid-cols-2 md:grid-cols-4 gap-8 text-center">
          <div>
            <div className="text-3xl font-extrabold text-[#29ABE2]">100%</div>
            <div className="text-xs text-[#5A7184] dark:text-slate-400 mt-1">Fonctionnel Hors-Ligne</div>
          </div>
          <div>
            <div className="text-3xl font-extrabold text-[#29ABE2]">&lt; 3 sec</div>
            <div className="text-xs text-[#5A7184] dark:text-slate-400 mt-1">Par Ticket de Vente</div>
          </div>
          <div>
            <div className="text-3xl font-extrabold text-[#29ABE2]">Multi</div>
            <div className="text-xs text-[#5A7184] dark:text-slate-400 mt-1">Magasins & Dépôts Séparés</div>
          </div>
          <div>
            <div className="text-3xl font-extrabold text-[#29ABE2]">0 F</div>
            <div className="text-xs text-[#5A7184] dark:text-slate-400 mt-1">Pour Démarrer Aujourd'hui</div>
          </div>
        </div>
      </section>

      <section id="features" className="py-20 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 space-y-16">
        <div className="text-center max-w-3xl mx-auto space-y-3">
          <h2 className="text-xs font-bold uppercase tracking-wider text-[#29ABE2]">
            Conçu pour le Commerce Réel
          </h2>
          <p className="text-3xl font-bold text-[#1C2B3A] dark:text-white">
            Tout ce dont vous avez besoin pour sécuriser et accélérer vos ventes
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          <div className="card-toc card-hover p-8 space-y-4">
            <div className="w-12 h-12 rounded-xl bg-[#E8F5FD] dark:bg-[#29ABE2]/15 text-[#29ABE2] flex items-center justify-center">
              <WifiOff className="w-6 h-6" />
            </div>
            <h3 className="text-xl font-bold text-[#1C2B3A] dark:text-white">Synchronisation Offline-First</h3>
            <p className="text-sm text-[#5A7184] dark:text-slate-300 leading-relaxed">
              La connexion internet est coupée ? Aucun problème. Les caisses continuent de vendre normalement. Tout se synchronise dès le retour du réseau.
            </p>
          </div>

          <div className="card-toc card-hover p-8 space-y-4">
            <div className="w-12 h-12 rounded-xl bg-[#F5EEF8] dark:bg-[#8E44AD]/15 text-[#8E44AD] flex items-center justify-center">
              <Layers className="w-6 h-6" />
            </div>
            <h3 className="text-xl font-bold text-[#1C2B3A] dark:text-white">Multi-Magasins & Stocks Distincts</h3>
            <p className="text-sm text-[#5A7184] dark:text-slate-300 leading-relaxed">
              Gérez plusieurs boutiques et magasins physiques. Les stocks sont cloisonnés par point de vente, avec transferts et tarifs différenciés.
            </p>
          </div>

          <div className="card-toc card-hover p-8 space-y-4">
            <div className="w-12 h-12 rounded-xl bg-[#E8F8F0] dark:bg-[#27AE60]/15 text-[#27AE60] flex items-center justify-center">
              <TrendingUp className="w-6 h-6" />
            </div>
            <h3 className="text-xl font-bold text-[#1C2B3A] dark:text-white">Vue Financière Consolidée</h3>
            <p className="text-sm text-[#5A7184] dark:text-slate-300 leading-relaxed">
              En tant que propriétaire, accédez en 1 clic à la santé financière globale de toutes vos boutiques : marge brute, bénéfice net et créances.
            </p>
          </div>
        </div>
      </section>

      <section id="multimag" className="bg-[#F0F9FE] dark:bg-dark-800/60 py-20 border-t border-[#E8EFF5] dark:border-dark-600">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          <div className="space-y-6">
            <div className="badge-toc-primary">
              <Smartphone className="w-3.5 h-3.5" />
              <span>Réseau Commercial Évolutif</span>
            </div>
            <h2 className="text-3xl font-extrabold text-[#1C2B3A] dark:text-white leading-snug">
              Une seule entreprise, plusieurs boutiques et des magasins dédiés
            </h2>
            <p className="text-[#5A7184] dark:text-slate-300 text-sm leading-relaxed">
              Affectez vos collaborateurs aux magasins où ils travaillent tout en gardant la vue consolidée avec le mode « Passer ».
            </p>
            <ul className="space-y-3 text-sm text-[#1C2B3A] dark:text-slate-200">
              <li className="flex items-center gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-[#27AE60]" />
                <span>Stocks indépendants par magasin physique</span>
              </li>
              <li className="flex items-center gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-[#27AE60]" />
                <span>Affectation granulaire des caissiers et gérants</span>
              </li>
              <li className="flex items-center gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-[#27AE60]" />
                <span>Consultation financière directe multi-magasins</span>
              </li>
            </ul>
            <Link to="/inscription" className="btn-primary inline-flex px-6 py-3">
              <span>Configurer ma première boutique</span>
              <ArrowRight className="w-4 h-4" />
            </Link>
          </div>

          <div className="card-toc p-6 shadow-soft-lg space-y-4">
            <div className="flex items-center justify-between pb-4 border-b border-[#E8EFF5] dark:border-dark-600">
              <div className="flex items-center gap-2">
                <Store className="w-5 h-5 text-[#29ABE2]" />
                <span className="font-bold text-sm">Boutique Élégance Dakar</span>
              </div>
              <span className="badge-toc-success">3 Magasins Actifs</span>
            </div>
            <div className="space-y-3 text-xs">
              <div className="p-3 bg-[#F5FAFD] dark:bg-dark-700 rounded-xl flex items-center justify-between">
                <div>
                  <div className="font-semibold text-[#1C2B3A] dark:text-white">Point de Vente Plateau</div>
                  <div className="text-[#5A7184]">2 caissiers affectés • 142 ventes aujourd'hui</div>
                </div>
                <span className="font-bold text-[#29ABE2]">485 000 FCFA</span>
              </div>
              <div className="p-3 bg-[#F5FAFD] dark:bg-dark-700 rounded-xl flex items-center justify-between">
                <div>
                  <div className="font-semibold text-[#1C2B3A] dark:text-white">Magasin Almadies</div>
                  <div className="text-[#5A7184]">1 gérant affecté • 89 ventes aujourd'hui</div>
                </div>
                <span className="font-bold text-[#29ABE2]">310 000 FCFA</span>
              </div>
              <div className="p-3 bg-[#F5FAFD] dark:bg-dark-700 rounded-xl flex items-center justify-between">
                <div>
                  <div className="font-semibold text-[#1C2B3A] dark:text-white">Entrepôt Central Réserve</div>
                  <div className="text-[#5A7184]">Stockage de gros • Réapprovisionnements</div>
                </div>
                <span className="text-[#9FB3C8]">Stock uniquement</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section id="faq" className="py-20 max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 space-y-12">
        <div className="text-center space-y-2">
          <HelpCircle className="w-8 h-8 text-[#29ABE2] mx-auto" />
          <h2 className="text-2xl font-bold text-[#1C2B3A] dark:text-white">Questions Fréquentes</h2>
        </div>

        <div className="space-y-4">
          <div className="card-toc p-6 space-y-2">
            <h3 className="font-semibold text-[#1C2B3A] dark:text-white">
              Que se passe-t-il si la connexion internet est coupée ?
            </h3>
            <p className="text-sm text-[#5A7184] dark:text-slate-300">
              L'application mobile et les caisses fonctionnent hors-ligne. Dès le retour du réseau, les données sont automatiquement synchronisées.
            </p>
          </div>
          <div className="card-toc p-6 space-y-2">
            <h3 className="font-semibold text-[#1C2B3A] dark:text-white">
              Puis-je essayer gratuitement le Plan Pro ?
            </h3>
            <p className="text-sm text-[#5A7184] dark:text-slate-300">
              Oui, 14 jours d'essai gratuit sur le Plan Pro, sans carte bancaire requise.
            </p>
          </div>
        </div>
      </section>

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
