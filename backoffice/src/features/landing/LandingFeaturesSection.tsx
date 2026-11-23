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
} from 'lucide-react';

export const LandingFeaturesSection: React.FC = () => (
  <>
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
  </>
);
