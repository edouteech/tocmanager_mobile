import React from 'react';
import { Link } from 'react-router-dom';
import { ShieldCheck, Smartphone, WifiOff } from 'lucide-react';
import { useAuthStore } from '../../stores/authStore';
import { resolveAppSurface } from '../../lib/domainRouting';
import { BrandLogo } from '../common/BrandLogo';
import { SurfaceLink } from '../common/SurfaceLink';

export const PublicFooter: React.FC = () => {
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated);
  const landingBase = isAuthenticated && resolveAppSurface() === 'all' ? '/landing' : '/';

  return (
    <footer className="bg-white dark:bg-dark-900 border-t border-[#E8EFF5] dark:border-dark-600 text-[#5A7184] dark:text-slate-400">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-14">
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-10">
          <div className="space-y-4">
            <Link to={landingBase} aria-label="TocManager — Accueil" className="inline-flex items-center">
              <BrandLogo variant="full" size="md" />
            </Link>

            <p className="text-xs leading-relaxed">
              Logiciel de caisse POS offline-first, gestion des stocks multi-magasins et pilotage financier consolidé pour les commerces exigeants.
            </p>

            <div className="flex flex-wrap gap-2">
              <span className="badge-toc-primary text-[11px]">
                <WifiOff className="w-3 h-3" />
                <span>Offline-First</span>
              </span>
              <span className="badge-toc-success text-[11px]">
                <ShieldCheck className="w-3 h-3" />
                <span>FeexPay Mobile Money</span>
              </span>
            </div>
          </div>

          <div className="space-y-3">
            <h3 className="text-xs font-bold uppercase tracking-wider text-[#1C2B3A] dark:text-white">
              Produit
            </h3>
            <ul className="space-y-2.5 text-xs">
              <li>
                <Link to={`${landingBase}#fonctionnalites`} className="hover:text-[#29ABE2] transition">
                  Fonctionnalités clés
                </Link>
              </li>
              <li>
                <Link to={`${landingBase}#captures`} className="hover:text-[#29ABE2] transition">
                  Captures Web & Mobile
                </Link>
              </li>
              <li>
                <Link to={`${landingBase}#multi-magasins`} className="hover:text-[#29ABE2] transition">
                  Architecture Multi-Magasins
                </Link>
              </li>
              <li>
                <Link to="/tarifs" className="hover:text-[#29ABE2] transition">
                  Tarifs & Comparatif 28 droits
                </Link>
              </li>
            </ul>
          </div>

          <div className="space-y-3">
            <h3 className="text-xs font-bold uppercase tracking-wider text-[#1C2B3A] dark:text-white">
              Ressources
            </h3>
            <ul className="space-y-2.5 text-xs">
              <li>
                <Link to={`${landingBase}#comment-ca-marche`} className="hover:text-[#29ABE2] transition">
                  Comment ça marche
                </Link>
              </li>
              <li>
                <Link to={`${landingBase}#faq`} className="hover:text-[#29ABE2] transition">
                  Questions fréquentes
                </Link>
              </li>
              <li>
                <Link to="/contact" className="hover:text-[#29ABE2] transition">
                  Contacter l'équipe
                </Link>
              </li>
              <li>
                <SurfaceLink surface="app" to="/login" className="hover:text-[#29ABE2] transition">
                  Connexion Espace Client
                </SurfaceLink>
              </li>
            </ul>
          </div>

          <div className="space-y-3">
            <h3 className="text-xs font-bold uppercase tracking-wider text-[#1C2B3A] dark:text-white">
              Démarrer & Légal
            </h3>
            <ul className="space-y-2.5 text-xs">
              <li>
                <SurfaceLink surface="app" to="/inscription?plan=pro" className="hover:text-[#29ABE2] transition">
                  Essai Pro 14 jours offert
                </SurfaceLink>
              </li>
              <li>
                <SurfaceLink surface="app" to="/inscription?plan=free" className="hover:text-[#29ABE2] transition">
                  Démarrer avec le Plan Gratuit
                </SurfaceLink>
              </li>
              <li>
                <Link to="/cgu" className="hover:text-[#29ABE2] transition">
                  Conditions d'utilisation (CGU)
                </Link>
              </li>
              <li>
                <Link to="/confidentialite" className="hover:text-[#29ABE2] transition">
                  Politique de confidentialité
                </Link>
              </li>
            </ul>
          </div>
        </div>

        <div className="mt-10 pt-6 border-t border-[#E8EFF5] dark:border-dark-600 flex flex-col sm:flex-row items-center justify-between gap-3 text-[11px]">
          <div className="flex items-center gap-2">
            <span>© 2026 TocManager SaaS • Tous droits réservés</span>
          </div>
          <div className="flex items-center gap-2 text-[#5A7184] dark:text-slate-400">
            <Smartphone className="w-3.5 h-3.5 text-[#29ABE2]" />
            <span>Bénin • Sénégal • Côte d'Ivoire • Togo • Burkina Faso • Mali • Congo</span>
          </div>
        </div>
      </div>
    </footer>
  );
};
