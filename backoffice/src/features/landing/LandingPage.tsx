import React from 'react';
import { Link } from 'react-router-dom';
import {
  Store,
  WifiOff,
  TrendingUp,
  ShieldCheck,
  Smartphone,
  Layers,
  ArrowRight,
  CheckCircle2,
  Users,
  Receipt,
  HelpCircle,
  Sparkles,
} from 'lucide-react';

export const LandingPage: React.FC = () => {
  return (
    <div className="min-h-screen bg-slate-50 dark:bg-slate-950 text-slate-800 dark:text-slate-100 flex flex-col font-sans transition-colors duration-200">
      {/* Header / Navbar */}
      <header className="sticky top-0 z-40 bg-white/80 dark:bg-slate-900/80 backdrop-blur-md border-b border-slate-200 dark:border-slate-800">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-indigo-600 to-indigo-800 flex items-center justify-center text-white shadow-md shadow-indigo-500/20">
              <Store className="w-6 h-6" />
            </div>
            <span className="text-xl font-black tracking-tight text-slate-900 dark:text-white">
              Toc<span className="text-indigo-600">Manager</span>
            </span>
          </div>

          <nav className="hidden md:flex items-center gap-8 text-sm font-medium text-slate-600 dark:text-slate-300">
            <a href="#features" className="hover:text-indigo-600 dark:hover:text-indigo-400 transition">
              Fonctionnalités
            </a>
            <a href="#multimag" className="hover:text-indigo-600 dark:hover:text-indigo-400 transition">
              Multi-Magasins
            </a>
            <Link to="/tarifs" className="hover:text-indigo-600 dark:hover:text-indigo-400 transition flex items-center gap-1">
              <span>Tarifs</span>
              <span className="px-1.5 py-0.5 text-[10px] bg-indigo-100 dark:bg-indigo-900/60 text-indigo-700 dark:text-indigo-300 rounded font-semibold">
                Essai 14j
              </span>
            </Link>
            <a href="#faq" className="hover:text-indigo-600 dark:hover:text-indigo-400 transition">
              FAQ
            </a>
          </nav>

          <div className="flex items-center gap-3">
            <Link
              to="/login"
              className="px-4 py-2 text-sm font-medium text-slate-700 dark:text-slate-200 hover:text-indigo-600 transition"
            >
              Connexion
            </Link>
            <Link
              to="/inscription"
              className="px-4 py-2 text-sm font-semibold text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg shadow-sm hover:shadow transition flex items-center gap-1.5"
            >
              <span>Créer mon compte</span>
              <ArrowRight className="w-4 h-4" />
            </Link>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <section className="relative overflow-hidden pt-12 pb-20 md:pt-20 md:pb-28">
        <div className="absolute inset-0 -z-10 bg-[radial-gradient(ellipse_80%_80%_at_50%_-20%,rgba(99,102,241,0.15),rgba(255,255,255,0))]" />
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center space-y-8">
          <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full text-xs font-semibold bg-indigo-50 dark:bg-indigo-950/60 text-indigo-700 dark:text-indigo-300 border border-indigo-200 dark:border-indigo-800">
            <Sparkles className="w-3.5 h-3.5" />
            <span>Nouveau : Plateforme SaaS Multi-Boutiques & Multi-Magasins</span>
          </div>

          <h1 className="text-4xl sm:text-5xl md:text-6xl font-extrabold text-slate-900 dark:text-white tracking-tight leading-tight max-w-4xl mx-auto">
            Pilotez vos points de vente, stocks et finances,{' '}
            <span className="text-transparent bg-clip-text bg-gradient-to-r from-indigo-600 via-purple-600 to-indigo-800">
              en ligne comme hors-ligne
            </span>
            .
          </h1>

          <p className="text-lg sm:text-xl text-slate-600 dark:text-slate-300 max-w-2xl mx-auto leading-relaxed">
            TocManager réunit la caisse mobile ultra-rapide, le suivi précis des stocks par magasin et la vue financière consolidée pour les commerçants exigeants.
          </p>

          <div className="flex flex-col sm:flex-row items-center justify-center gap-4 pt-4">
            <Link
              to="/inscription"
              className="w-full sm:w-auto px-8 py-3.5 text-base font-semibold text-white bg-indigo-600 hover:bg-indigo-700 rounded-xl shadow-lg hover:shadow-indigo-500/25 transition flex items-center justify-center gap-2"
            >
              <span>Commencer Gratuitement</span>
              <ArrowRight className="w-5 h-5" />
            </Link>
            <Link
              to="/tarifs"
              className="w-full sm:w-auto px-8 py-3.5 text-base font-semibold text-slate-700 dark:text-slate-200 bg-white dark:bg-slate-800 hover:bg-slate-100 dark:hover:bg-slate-700 rounded-xl border border-slate-200 dark:border-slate-700 shadow-sm transition"
            >
              Voir les Forfaits & Tarifs
            </Link>
          </div>

          <div className="pt-8 flex flex-wrap items-center justify-center gap-6 text-xs text-slate-500 dark:text-slate-400">
            <div className="flex items-center gap-1.5">
              <CheckCircle2 className="w-4 h-4 text-emerald-500" />
              <span>Plan gratuit sans engagement</span>
            </div>
            <div className="flex items-center gap-1.5">
              <CheckCircle2 className="w-4 h-4 text-emerald-500" />
              <span>14 jours d'essai Pro offerts</span>
            </div>
            <div className="flex items-center gap-1.5">
              <CheckCircle2 className="w-4 h-4 text-emerald-500" />
              <span>Synchronisation autonome hors-ligne</span>
            </div>
          </div>
        </div>
      </section>

      {/* Chiffres Clés */}
      <section className="bg-white dark:bg-slate-900 border-y border-slate-200 dark:border-slate-800 py-10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 grid grid-cols-2 md:grid-cols-4 gap-8 text-center">
          <div>
            <div className="text-3xl font-extrabold text-indigo-600 dark:text-indigo-400">100%</div>
            <div className="text-xs text-slate-500 dark:text-slate-400 mt-1">Fonctionnel Hors-Ligne</div>
          </div>
          <div>
            <div className="text-3xl font-extrabold text-indigo-600 dark:text-indigo-400">&lt; 3 sec</div>
            <div className="text-xs text-slate-500 dark:text-slate-400 mt-1">Par Ticket de Vente</div>
          </div>
          <div>
            <div className="text-3xl font-extrabold text-indigo-600 dark:text-indigo-400">Multi</div>
            <div className="text-xs text-slate-500 dark:text-slate-400 mt-1">Magasins & Dépôts Séparés</div>
          </div>
          <div>
            <div className="text-3xl font-extrabold text-indigo-600 dark:text-indigo-400">0 F</div>
            <div className="text-xs text-slate-500 dark:text-slate-400 mt-1">Pour Démarrer Aujourd'hui</div>
          </div>
        </div>
      </section>

      {/* Piliers Fonctionnels */}
      <section id="features" className="py-20 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 space-y-16">
        <div className="text-center max-w-3xl mx-auto space-y-3">
          <h2 className="text-xs font-bold uppercase tracking-wider text-indigo-600 dark:text-indigo-400">
            Conçu pour le Commerce Réel
          </h2>
          <p className="text-3xl font-bold text-slate-900 dark:text-white">
            Tout ce dont vous avez besoin pour sécuriser et accélérer vos ventes
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
          {/* Card 1 */}
          <div className="bg-white dark:bg-slate-900 p-8 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm hover:shadow-md transition space-y-4">
            <div className="w-12 h-12 rounded-xl bg-blue-100 dark:bg-blue-950/60 text-blue-600 dark:text-blue-400 flex items-center justify-center">
              <WifiOff className="w-6 h-6" />
            </div>
            <h3 className="text-xl font-bold text-slate-900 dark:text-white">Synchronisation Offline-First</h3>
            <p className="text-sm text-slate-600 dark:text-slate-300 leading-relaxed">
              La connexion internet est coupée ? Aucun problème. Les caisses continuent de vendre normalement. Tout se synchronise de manière transparente dès le retour du réseau.
            </p>
          </div>

          {/* Card 2 */}
          <div className="bg-white dark:bg-slate-900 p-8 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm hover:shadow-md transition space-y-4">
            <div className="w-12 h-12 rounded-xl bg-purple-100 dark:bg-purple-950/60 text-purple-600 dark:text-purple-400 flex items-center justify-center">
              <Layers className="w-6 h-6" />
            </div>
            <h3 className="text-xl font-bold text-slate-900 dark:text-white">Multi-Magasins & Stocks Distincts</h3>
            <p className="text-sm text-slate-600 dark:text-slate-300 leading-relaxed">
              Gérez plusieurs boutiques et magasins physiques. Les stocks sont cloisonnés par point de vente, avec possibilité de transferts de marchandises et catalogues différenciés.
            </p>
          </div>

          {/* Card 3 */}
          <div className="bg-white dark:bg-slate-900 p-8 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm hover:shadow-md transition space-y-4">
            <div className="w-12 h-12 rounded-xl bg-emerald-100 dark:bg-emerald-950/60 text-emerald-600 dark:text-emerald-400 flex items-center justify-center">
              <TrendingUp className="w-6 h-6" />
            </div>
            <h3 className="text-xl font-bold text-slate-900 dark:text-white">Vue Financière Consolidée</h3>
            <p className="text-sm text-slate-600 dark:text-slate-300 leading-relaxed">
              En tant que propriétaire, accédez en 1 clic à la santé financière globale de toutes vos boutiques : marge brute, bénéfice net, dépenses et dettes en temps réel.
            </p>
          </div>
        </div>
      </section>

      {/* Focus Multi-Magasin */}
      <section id="multimag" className="bg-slate-100 dark:bg-slate-900/60 py-20 border-t border-slate-200 dark:border-slate-800">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
          <div className="space-y-6">
            <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full text-xs font-semibold bg-indigo-100 dark:bg-indigo-950/60 text-indigo-700 dark:text-indigo-400">
              <Store className="w-3.5 h-3.5" />
              <span>Réseau Commercial Évolutif</span>
            </div>
            <h2 className="text-3xl font-extrabold text-slate-900 dark:text-white leading-snug">
              Une seule entreprise, plusieurs boutiques et des magasins dédiés
            </h2>
            <p className="text-slate-600 dark:text-slate-300 text-sm leading-relaxed">
              Chaque établissement commercial a ses spécificités. Avec TocManager, affectez vos collaborateurs précisément aux magasins où ils travaillent, tandis que vous conservez une vue d'ensemble avec le mode « Passer » immédiat vers vos états financiers.
            </p>
            <ul className="space-y-3 text-sm text-slate-700 dark:text-slate-200">
              <li className="flex items-center gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-emerald-500" />
                <span>Stocks indépendants par magasin physique</span>
              </li>
              <li className="flex items-center gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-emerald-500" />
                <span>Affectation granulaire des caissiers et gérants</span>
              </li>
              <li className="flex items-center gap-2.5">
                <CheckCircle2 className="w-4 h-4 text-emerald-500" />
                <span>Bouton « Passer » pour consultation financière directe</span>
              </li>
            </ul>
            <div className="pt-2">
              <Link
                to="/inscription"
                className="inline-flex items-center gap-2 px-6 py-3 text-sm font-semibold text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg shadow transition"
              >
                <span>Configurer ma première boutique</span>
                <ArrowRight className="w-4 h-4" />
              </Link>
            </div>
          </div>

          <div className="bg-white dark:bg-slate-900 rounded-2xl p-6 border border-slate-200 dark:border-slate-800 shadow-xl space-y-4">
            <div className="flex items-center justify-between pb-4 border-b border-slate-100 dark:border-slate-800">
              <div className="flex items-center gap-2">
                <Store className="w-5 h-5 text-indigo-600" />
                <span className="font-bold text-sm">Boutique Élégance Dakar</span>
              </div>
              <span className="text-xs px-2 py-0.5 rounded-full bg-emerald-100 dark:bg-emerald-950/60 text-emerald-700 dark:text-emerald-400 font-medium">
                3 Magasins Actifs
              </span>
            </div>
            <div className="space-y-3 text-xs">
              <div className="p-3 bg-slate-50 dark:bg-slate-800 rounded-xl flex items-center justify-between">
                <div>
                  <div className="font-semibold text-slate-900 dark:text-white">Point de Vente Plateau</div>
                  <div className="text-slate-500">2 caissiers affectés • 142 ventes aujourd'hui</div>
                </div>
                <span className="font-bold text-indigo-600">485 000 FCFA</span>
              </div>
              <div className="p-3 bg-slate-50 dark:bg-slate-800 rounded-xl flex items-center justify-between">
                <div>
                  <div className="font-semibold text-slate-900 dark:text-white">Magasin Almadies</div>
                  <div className="text-slate-500">1 gérant affecté • 89 ventes aujourd'hui</div>
                </div>
                <span className="font-bold text-indigo-600">310 000 FCFA</span>
              </div>
              <div className="p-3 bg-slate-50 dark:bg-slate-800 rounded-xl flex items-center justify-between">
                <div>
                  <div className="font-semibold text-slate-900 dark:text-white">Entrepôt Central Réserve</div>
                  <div className="text-slate-500">Stockage de gros • Réapprovisionnements</div>
                </div>
                <span className="text-slate-400">Stock uniquement</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* FAQ */}
      <section id="faq" className="py-20 max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 space-y-12">
        <div className="text-center space-y-2">
          <HelpCircle className="w-8 h-8 text-indigo-600 mx-auto" />
          <h2 className="text-2xl font-bold text-slate-900 dark:text-white">Questions Fréquentes</h2>
        </div>

        <div className="space-y-4">
          <div className="bg-white dark:bg-slate-900 p-6 rounded-xl border border-slate-200 dark:border-slate-800 space-y-2">
            <h3 className="font-semibold text-slate-900 dark:text-white">
              Que se passe-t-il si la connexion internet est coupée ?
            </h3>
            <p className="text-sm text-slate-600 dark:text-slate-300">
              L'application mobile et les caisses sont pensées pour être 100% autonomes hors-ligne. Vous continuez d'encaisser, d'imprimer les reçus et de gérer vos clients. Dès qu'une connexion revient, les données sont automatiquement synchronisées.
            </p>
          </div>

          <div className="bg-white dark:bg-slate-900 p-6 rounded-xl border border-slate-200 dark:border-slate-800 space-y-2">
            <h3 className="font-semibold text-slate-900 dark:text-white">
              Puis-je essayer gratuitement le Plan Pro ?
            </h3>
            <p className="text-sm text-slate-600 dark:text-slate-300">
              Absolument. Vous bénéficiez de 14 jours d'essai gratuit sur le Plan Pro, sans carte bancaire requise. Si vous ne souhaitez pas continuer, vous conservez l'accès au Plan Gratuit permanent.
            </p>
          </div>

          <div className="bg-white dark:bg-slate-900 p-6 rounded-xl border border-slate-200 dark:border-slate-800 space-y-2">
            <h3 className="font-semibold text-slate-900 dark:text-white">
              Les caissiers peuvent-ils voir les bénéfices de la boutique ?
            </h3>
            <p className="text-sm text-slate-600 dark:text-slate-300">
              Non. Les rôles et permissions sont strictement cloisonnés. Un caissier n'a accès qu'à la caisse de son magasin assigné. Seul le propriétaire dispose de la vue financière consolidée.
            </p>
          </div>
        </div>
      </section>

      {/* CTA Final */}
      <section className="bg-gradient-to-tr from-indigo-700 via-indigo-800 to-purple-900 text-white py-16 text-center">
        <div className="max-w-4xl mx-auto px-4 space-y-6">
          <h2 className="text-3xl sm:text-4xl font-extrabold tracking-tight">
            Prêt à transformer la gestion de vos boutiques ?
          </h2>
          <p className="text-indigo-200 text-base max-w-xl mx-auto">
            Inscrivez-vous en 2 minutes et commencez à encaisser dès aujourd'hui.
          </p>
          <div className="pt-2">
            <Link
              to="/inscription"
              className="inline-flex items-center gap-2 px-8 py-3.5 text-base font-semibold text-indigo-900 bg-white hover:bg-slate-100 rounded-xl shadow-lg transition"
            >
              <span>Créer mon compte maintenant</span>
              <ArrowRight className="w-5 h-5 text-indigo-700" />
            </Link>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-white dark:bg-slate-950 border-t border-slate-200 dark:border-slate-800 py-10 text-xs text-slate-500">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex flex-col sm:flex-row items-center justify-between gap-4">
          <div className="flex items-center gap-2">
            <Store className="w-5 h-5 text-indigo-600" />
            <span className="font-bold text-slate-900 dark:text-white">TocManager SaaS</span>
            <span>• © 2026 Tous droits réservés</span>
          </div>
          <div className="flex items-center gap-6">
            <Link to="/tarifs" className="hover:text-indigo-600 transition">Tarifs</Link>
            <Link to="/login" className="hover:text-indigo-600 transition">Espace Client</Link>
            <Link to="/admin" className="hover:text-indigo-600 transition">Portail Super-Admin</Link>
          </div>
        </div>
      </footer>
    </div>
  );
};
