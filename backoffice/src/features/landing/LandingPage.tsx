import React, { useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import { PublicNavbar } from '../../components/public/PublicNavbar';
import { PublicFooter } from '../../components/public/PublicFooter';
import { usePageTitle } from './hooks/usePageTitle';
import { LandingHeroSection } from './components/LandingHeroSection';
import { LandingTrustStrip } from './components/LandingTrustStrip';
import { LandingProductShowcase } from './components/LandingProductShowcase';
import { LandingScreenshotsGallery } from './components/LandingScreenshotsGallery';
import { LandingCapabilitiesBento } from './components/LandingCapabilitiesBento';
import { LandingHowItWorksSection } from './components/LandingHowItWorksSection';
import { LandingEcosystemSection } from './components/LandingEcosystemSection';
import { LandingPricingSection } from './components/LandingPricingSection';
import { LandingUseCasesSection } from './components/LandingUseCasesSection';
import { LandingFaqSection } from './components/LandingFaqSection';
import { LandingFinalCtaSection } from './components/LandingFinalCtaSection';

export const LandingPage: React.FC = () => {
  const { hash } = useLocation();

  usePageTitle(
    'TocManager — Caisse POS, Stocks & Multi-Magasins Offline-First',
    'Pilotez vos points de vente, stocks par magasin et finances en ligne comme hors-ligne avec TocManager.'
  );

  useEffect(() => {
    if (!hash) return;
    const target = document.getElementById(hash.slice(1));
    if (target && typeof target.scrollIntoView === 'function') {
      target.scrollIntoView({ behavior: 'smooth' });
    }
  }, [hash]);

  return (
    <div className="min-h-screen bg-[#F5FAFD] dark:bg-dark-900 text-[#1C2B3A] dark:text-[#E2E8F0] flex flex-col font-sans transition-colors duration-200">
      <PublicNavbar />

      <main id="main-content" className="flex-1">
        <LandingHeroSection />
        <LandingTrustStrip />
        <LandingProductShowcase />
        <LandingScreenshotsGallery />
        <LandingCapabilitiesBento />
        <LandingHowItWorksSection />
        <LandingEcosystemSection />
        <LandingPricingSection />
        <LandingUseCasesSection />
        <LandingFaqSection />
        <LandingFinalCtaSection />
      </main>

      <PublicFooter />
    </div>
  );
};
