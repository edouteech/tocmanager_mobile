import React from 'react';
import { Link } from 'react-router-dom';
import { Home } from 'lucide-react';
import { BrandLogo } from './BrandLogo';

/**
 * Render a strict 404 screen for unknown or cross-surface routes.
 */
export const NotFoundPage: React.FC = () => {
  return (
    <div className="min-h-screen bg-[#F5FAFD] dark:bg-dark-900 flex items-center justify-center p-6 font-sans">
      <div className="w-full max-w-md card-toc p-8 sm:p-10 text-center space-y-5 shadow-soft">
        <div className="flex justify-center">
          <BrandLogo variant="full" size="md" priority />
        </div>

        <div className="text-5xl font-black text-[#29ABE2] tracking-tight">404</div>

        <div className="space-y-1.5">
          <h1 className="text-xl font-extrabold text-[#1C2B3A] dark:text-white">
            Page introuvable
          </h1>
          <p className="text-xs text-[#5A7184] dark:text-slate-400">
            La ressource demandée n'existe pas ou n'est pas disponible sur ce domaine.
          </p>
        </div>

        <Link
          to="/"
          className="inline-flex items-center justify-center gap-2 btn-primary px-5 py-2.5 text-sm font-bold"
        >
          <Home className="w-4 h-4" />
          <span>Retour à l'accueil</span>
        </Link>
      </div>
    </div>
  );
};
