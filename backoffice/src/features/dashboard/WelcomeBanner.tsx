import React from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { Sparkles, X, Package, Store, ShieldCheck } from 'lucide-react';

export const WelcomeBanner: React.FC = () => {
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();
  const isWelcome = searchParams.get('welcome') === '1';

  if (!isWelcome) return null;

  const dismiss = () => {
    const next = new URLSearchParams(searchParams);
    next.delete('welcome');
    setSearchParams(next, { replace: true });
  };

  return (
    <div className="card-toc p-5 border-[#BAE3F9] dark:border-[#29ABE2]/30 bg-[#F0F9FE] dark:bg-[#29ABE2]/10 flex flex-col sm:flex-row sm:items-center justify-between gap-4 animate-fade-in">
      <div className="flex items-start gap-3.5">
        <div className="w-10 h-10 rounded-xl toc-gradient text-white flex items-center justify-center shrink-0">
          <Sparkles className="w-5 h-5" />
        </div>
        <div className="space-y-1">
          <h3 className="text-sm font-bold text-[#1C2B3A] dark:text-white">
            Bienvenue sur TocManager ! Votre boutique est prête.
          </h3>
          <p className="text-xs text-[#5A7184] dark:text-slate-300">
            Finalisez votre démarrage en ajoutant vos premiers produits, en configurant vos magasins ou votre code PIN caisse.
          </p>
          <div className="flex flex-wrap items-center gap-2 pt-1.5">
            <button
              type="button"
              onClick={() => navigate('/produits')}
              className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold bg-[#29ABE2] text-white hover:bg-[#1A8FBF] transition"
            >
              <Package className="w-3.5 h-3.5" />
              <span>Ajouter un produit</span>
            </button>
            <button
              type="button"
              onClick={() => navigate('/magasins')}
              className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold bg-white dark:bg-dark-800 border border-[#E8EFF5] dark:border-dark-600 text-[#1C2B3A] dark:text-white hover:border-[#29ABE2] transition"
            >
              <Store className="w-3.5 h-3.5 text-[#29ABE2]" />
              <span>Gérer mes magasins</span>
            </button>
            <button
              type="button"
              onClick={() => navigate('/parametres')}
              className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold bg-white dark:bg-dark-800 border border-[#E8EFF5] dark:border-dark-600 text-[#1C2B3A] dark:text-white hover:border-[#29ABE2] transition"
            >
              <ShieldCheck className="w-3.5 h-3.5 text-[#27AE60]" />
              <span>Configurer mon PIN</span>
            </button>
          </div>
        </div>
      </div>

      <button
        type="button"
        onClick={dismiss}
        aria-label="Fermer le message de bienvenue"
        className="p-1.5 rounded-lg text-[#5A7184] hover:text-[#1C2B3A] dark:hover:text-white hover:bg-white/60 dark:hover:bg-dark-700 self-start transition"
      >
        <X className="w-4 h-4" />
      </button>
    </div>
  );
};
