import React, { useState } from 'react';
import { ArrowRight, CheckCircle2, Layers, RefreshCw, Smartphone, Store, Users } from 'lucide-react';
import { SurfaceLink } from '../../../components/common/SurfaceLink';
import type { EcosystemStoreId } from '../data/landingContent';
import { ECOSYSTEM_STORES } from '../data/landingDetailsContent';

export const LandingEcosystemSection: React.FC = () => {
  const [selectedStoreId, setSelectedStoreId] = useState<EcosystemStoreId>('all');
  const activeStore =
    ECOSYSTEM_STORES.find((store) => store.id === selectedStoreId) || ECOSYSTEM_STORES[0];

  return (
    <section
      id="multi-magasins"
      className="scroll-mt-20 landing-section-deferred bg-[#F0F9FE] dark:bg-dark-800/60 py-20 border-b border-[#E8EFF5] dark:border-dark-600"
    >
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
        <div className="lg:col-span-6 space-y-6">
          <div className="flex flex-wrap items-center gap-2.5">
            <span className="badge-toc-primary">
              <Layers className="w-3.5 h-3.5" />
              <span>Réseau Commercial Évolutif</span>
            </span>
            <SurfaceLink
              surface="app"
              to="/inscription"
              className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-[#E8F8F0] text-[#27AE60] dark:bg-[#27AE60]/15 border border-[#27AE60]/30 hover:opacity-90 transition"
            >
              <Smartphone className="w-3.5 h-3.5" />
              <span>Application Android incluse dans votre espace</span>
            </SurfaceLink>
          </div>

          <h2 className="text-3xl sm:text-4xl font-extrabold text-[#1C2B3A] dark:text-white leading-tight">
            Une entreprise, plusieurs boutiques et des magasins dédiés
          </h2>

          <p className="text-sm sm:text-base text-[#5A7184] dark:text-slate-300 leading-relaxed">
            Vos caissiers encaissent sur l’application Android au comptoir pendant que vous supervisez chaque point de vente ou la vue consolidée avec le mode « Passer » depuis le backoffice web.
          </p>

          <ul className="space-y-2.5 text-sm text-[#1C2B3A] dark:text-slate-200">
            <li className="flex items-center gap-2.5">
              <CheckCircle2 className="w-4 h-4 text-[#27AE60] shrink-0" />
              <span>Stocks et prix indépendants par magasin physique ou entrepôt</span>
            </li>
            <li className="flex items-center gap-2.5">
              <CheckCircle2 className="w-4 h-4 text-[#27AE60] shrink-0" />
              <span>Affectation granulaire des caissiers et gérants avec code PIN</span>
            </li>
            <li className="flex items-center gap-2.5">
              <CheckCircle2 className="w-4 h-4 text-[#27AE60] shrink-0" />
              <span>Bascule immédiate entre vue magasin et synthèse globale</span>
            </li>
          </ul>

          <div className="flex flex-wrap items-center gap-3 pt-1">
            <SurfaceLink surface="app" to="/inscription" className="btn-primary px-6 py-3 text-sm">
              <span>Configurer ma première boutique</span>
              <ArrowRight className="w-4 h-4" />
            </SurfaceLink>
            <a href="#captures" className="btn-secondary px-5 py-3 text-sm">
              Voir les captures Web & Mobile
            </a>
          </div>
        </div>

        <div className="lg:col-span-6">
          <div className="card-toc p-5 sm:p-6 shadow-soft-lg space-y-5">
            <div className="flex flex-wrap items-center justify-between gap-2 pb-4 border-b border-[#E8EFF5] dark:border-dark-600">
              <div className="flex items-center gap-2">
                <Store className="w-5 h-5 text-[#29ABE2]" />
                <span className="font-bold text-sm text-[#1C2B3A] dark:text-white">
                  Boutique Élégance Dakar
                </span>
              </div>
              <span className="badge-toc-success">3 Magasins Actifs</span>
            </div>

            <div className="flex flex-wrap gap-2" role="group" aria-label="Sélecteur de magasin de démonstration">
              {ECOSYSTEM_STORES.map((store) => {
                const isSelected = store.id === selectedStoreId;
                return (
                  <button
                    key={store.id}
                    type="button"
                    aria-pressed={isSelected}
                    onClick={() => setSelectedStoreId(store.id)}
                    className={`px-3 py-1.5 rounded-xl text-xs font-bold border transition ${
                      isSelected
                        ? 'bg-[#29ABE2] text-white border-[#29ABE2]'
                        : 'bg-[#F5FAFD] dark:bg-dark-700 text-[#5A7184] dark:text-slate-300 border-[#E8EFF5] dark:border-dark-600 hover:text-[#29ABE2]'
                    }`}
                  >
                    {store.id === 'all' ? 'Vue consolidée' : store.label}
                  </button>
                );
              })}
            </div>

            <div className="rounded-2xl bg-[#F5FAFD] dark:bg-dark-900/60 border border-[#E8EFF5] dark:border-dark-600 p-4 sm:p-5 space-y-4">
              <div className="flex items-start justify-between gap-3">
                <div>
                  <div className="text-[11px] font-bold uppercase tracking-wider text-[#29ABE2]">
                    {activeStore.typeLabel}
                  </div>
                  <h3 className="text-base font-extrabold text-[#1C2B3A] dark:text-white mt-0.5">
                    {activeStore.label}
                  </h3>
                </div>
                <span className="text-lg sm:text-xl font-extrabold text-[#1C2B3A] dark:text-white">
                  {activeStore.revenue}
                </span>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
                <div className="p-3 rounded-xl bg-white dark:bg-dark-800 border border-[#E8EFF5] dark:border-dark-600">
                  <div className="text-[#5A7184] dark:text-slate-400">Activité du jour</div>
                  <div className="font-bold text-[#1C2B3A] dark:text-white mt-1">{activeStore.tickets}</div>
                </div>
                <div className="p-3 rounded-xl bg-white dark:bg-dark-800 border border-[#E8EFF5] dark:border-dark-600">
                  <div className="text-[#5A7184] dark:text-slate-400 flex items-center gap-1">
                    <Users className="w-3.5 h-3.5 text-[#29ABE2]" />
                    <span>Équipe affectée</span>
                  </div>
                  <div className="font-bold text-[#1C2B3A] dark:text-white mt-1">{activeStore.staff}</div>
                </div>
              </div>

              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 pt-2 border-t border-[#E8EFF5] dark:border-dark-600 text-[11px]">
                <span className="font-semibold text-[#1C2B3A] dark:text-slate-200">
                  {activeStore.stockStatus}
                </span>
                <span className="inline-flex items-center gap-1 font-bold text-[#27AE60]">
                  <RefreshCw className="w-3 h-3" />
                  <span>{activeStore.syncStatus}</span>
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
};
