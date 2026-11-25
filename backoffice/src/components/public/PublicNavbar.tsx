import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { ArrowRight, Menu, Moon, Sun } from 'lucide-react';
import { useTheme } from '../../context/ThemeContext';
import { useAuthStore } from '../../stores/authStore';
import { resolveAppSurface } from '../../lib/domainRouting';
import { BrandLogo } from '../common/BrandLogo';
import { SurfaceLink } from '../common/SurfaceLink';
import { PublicMobileMenu } from './PublicMobileMenu';

export const PublicNavbar: React.FC = () => {
  const [mobileOpen, setMobileOpen] = useState(false);
  const { theme, toggleTheme } = useTheme();
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated);
  const user = useAuthStore((s) => s.user);
  const activeSurface = resolveAppSurface();
  const showWorkspaceCta = isAuthenticated && activeSurface === 'all';

  const landingBase = showWorkspaceCta ? '/landing' : '/';
  const workspacePath = user?.role === 'superadmin' ? '/admin' : '/';

  const navLinks = [
    { label: 'Fonctionnalités', to: `${landingBase}#fonctionnalites` },
    { label: 'Captures', to: `${landingBase}#captures` },
    { label: 'Multi-Magasins', to: `${landingBase}#multi-magasins` },
    { label: 'Tarifs', to: '/tarifs', badge: 'Essai 14j' },
    { label: 'FAQ', to: `${landingBase}#faq` },
    { label: 'Contact', to: '/contact' },
  ];

  return (
    <>
      <a
        href="#main-content"
        className="sr-only focus:not-sr-only focus:fixed focus:top-3 focus:left-3 focus:z-50 focus:px-4 focus:py-2 focus:rounded-xl focus:bg-[#29ABE2] focus:text-white focus:text-xs focus:font-bold focus:shadow-soft"
      >
        Aller au contenu principal
      </a>

      <header className="sticky top-0 z-40 bg-white/90 dark:bg-dark-900/90 backdrop-blur-md border-b border-[#E8EFF5] dark:border-dark-600 transition-colors duration-200">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between gap-4">
          <Link to={landingBase} aria-label="TocManager — Accueil" className="flex items-center shrink-0">
            <BrandLogo variant="full" size="md" priority />
          </Link>

          <nav className="hidden md:flex items-center gap-6 lg:gap-7 text-sm font-medium text-[#5A7184] dark:text-slate-300" aria-label="Navigation principale">
            {navLinks.map((item) => (
              <Link
                key={item.to}
                to={item.to}
                className="hover:text-[#29ABE2] transition inline-flex items-center gap-1.5 whitespace-nowrap"
              >
                <span>{item.label}</span>
                {item.badge && (
                  <span className="badge-toc-primary text-[10px] px-2 py-0.5">{item.badge}</span>
                )}
              </Link>
            ))}
          </nav>

          <div className="flex items-center gap-2.5 shrink-0">
            <button
              type="button"
              onClick={toggleTheme}
              aria-label="Changer de thème"
              title={theme === 'dark' ? 'Passer en mode clair' : 'Passer en mode sombre'}
              className="p-2 rounded-xl bg-[#F0F9FE] dark:bg-dark-800 border border-[#E8EFF5] dark:border-dark-600 text-[#5A7184] dark:text-slate-300 hover:text-[#29ABE2] transition"
            >
              {theme === 'dark' ? (
                <Sun className="w-4 h-4 text-amber-400" />
              ) : (
                <Moon className="w-4 h-4 text-[#1C2B3A]" />
              )}
            </button>

            <div className="hidden md:flex items-center gap-2.5">
              {showWorkspaceCta ? (
                <Link to={workspacePath} className="btn-primary py-2 text-xs sm:text-sm">
                  <span>Accéder à mon espace</span>
                  <ArrowRight className="w-4 h-4" />
                </Link>
              ) : (
                <>
                  <SurfaceLink
                    surface="app"
                    to="/login"
                    className="px-3.5 py-2 text-sm font-semibold text-[#1C2B3A] dark:text-slate-200 hover:text-[#29ABE2] transition"
                  >
                    Connexion
                  </SurfaceLink>
                  <SurfaceLink surface="app" to="/inscription" className="btn-primary py-2 text-xs sm:text-sm">
                    <span>Essai gratuit</span>
                    <ArrowRight className="w-4 h-4" />
                  </SurfaceLink>
                </>
              )}
            </div>

            <button
              type="button"
              onClick={() => setMobileOpen(true)}
              aria-label="Ouvrir le menu"
              aria-expanded={mobileOpen}
              aria-controls="public-mobile-menu"
              className="md:hidden p-2 rounded-xl bg-[#F0F9FE] dark:bg-dark-800 border border-[#E8EFF5] dark:border-dark-600 text-[#1C2B3A] dark:text-slate-200 hover:text-[#29ABE2] transition"
            >
              <Menu className="w-5 h-5" />
            </button>
          </div>
        </div>
      </header>

      <PublicMobileMenu
        isOpen={mobileOpen}
        onClose={() => setMobileOpen(false)}
        navLinks={navLinks}
        theme={theme}
        onToggleTheme={toggleTheme}
        isAuthenticated={showWorkspaceCta}
        workspacePath={workspacePath}
      />
    </>
  );
};
