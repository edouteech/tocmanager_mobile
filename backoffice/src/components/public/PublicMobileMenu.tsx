import React, { useEffect } from 'react';
import { Link } from 'react-router-dom';
import { ArrowRight, Moon, Sun, X } from 'lucide-react';
import { BrandLogo } from '../common/BrandLogo';
import { SurfaceLink } from '../common/SurfaceLink';

interface NavLinkItem {
  label: string;
  to: string;
  badge?: string;
}

interface PublicMobileMenuProps {
  isOpen: boolean;
  onClose: () => void;
  navLinks: NavLinkItem[];
  theme: 'light' | 'dark';
  onToggleTheme: () => void;
  isAuthenticated: boolean;
  workspacePath: string;
}

export const PublicMobileMenu: React.FC<PublicMobileMenuProps> = ({
  isOpen,
  onClose,
  navLinks,
  theme,
  onToggleTheme,
  isAuthenticated,
  workspacePath,
}) => {
  useEffect(() => {
    if (!isOpen) return;
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === 'Escape') onClose();
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  return (
    <div
      id="public-mobile-menu"
      role="dialog"
      aria-modal="true"
      aria-label="Navigation mobile"
      className="fixed inset-0 z-50 md:hidden"
    >
      <div
        className="fixed inset-0 bg-[#1C2B3A]/50 backdrop-blur-sm"
        onClick={onClose}
        aria-hidden="true"
      />

      <div className="relative ml-auto h-full w-full max-w-xs bg-white dark:bg-dark-900 border-l border-[#E8EFF5] dark:border-dark-600 p-6 flex flex-col justify-between shadow-soft-lg">
        <div className="space-y-6">
          <div className="flex items-center justify-between">
            <Link to="/" onClick={onClose} aria-label="TocManager — Accueil" className="flex items-center">
              <BrandLogo variant="full" size="sm" />
            </Link>
            <button
              type="button"
              onClick={onClose}
              aria-label="Fermer le menu"
              className="p-2 rounded-xl text-[#5A7184] hover:text-[#1C2B3A] dark:hover:text-white hover:bg-[#F0F9FE] dark:hover:bg-dark-800 transition"
            >
              <X className="w-5 h-5" />
            </button>
          </div>

          <nav className="flex flex-col gap-1" aria-label="Liens mobiles">
            {navLinks.map((item) => (
              <Link
                key={item.to}
                to={item.to}
                onClick={onClose}
                className="flex items-center justify-between px-3.5 py-2.5 rounded-xl text-sm font-semibold text-[#1C2B3A] dark:text-slate-200 hover:bg-[#F0F9FE] dark:hover:bg-dark-800 hover:text-[#29ABE2] transition"
              >
                <span>{item.label}</span>
                {item.badge && (
                  <span className="badge-toc-primary text-[10px] px-2 py-0.5">{item.badge}</span>
                )}
              </Link>
            ))}
          </nav>

          <button
            type="button"
            onClick={onToggleTheme}
            className="w-full flex items-center justify-between px-3.5 py-2.5 rounded-xl bg-[#F5FAFD] dark:bg-dark-800 border border-[#E8EFF5] dark:border-dark-600 text-sm font-medium text-[#1C2B3A] dark:text-slate-200 transition"
          >
            <span>{theme === 'dark' ? 'Passer en mode clair' : 'Passer en mode sombre'}</span>
            {theme === 'dark' ? (
              <Sun className="w-4 h-4 text-amber-400" />
            ) : (
              <Moon className="w-4 h-4 text-[#1C2B3A]" />
            )}
          </button>
        </div>

        <div className="space-y-2.5 pt-6 border-t border-[#E8EFF5] dark:border-dark-600">
          {isAuthenticated ? (
            <Link
              to={workspacePath}
              onClick={onClose}
              className="w-full btn-primary py-3 text-sm"
            >
              <span>Accéder à mon espace</span>
              <ArrowRight className="w-4 h-4" />
            </Link>
          ) : (
            <>
              <SurfaceLink
                surface="app"
                to="/login"
                onClick={onClose}
                className="w-full btn-secondary py-2.5 text-sm"
              >
                Connexion
              </SurfaceLink>
              <SurfaceLink
                surface="app"
                to="/inscription"
                onClick={onClose}
                className="w-full btn-primary py-3 text-sm"
              >
                <span>Essai gratuit</span>
                <ArrowRight className="w-4 h-4" />
              </SurfaceLink>
            </>
          )}
        </div>
      </div>
    </div>
  );
};
