import React from 'react';
import { usePageTitle } from './hooks/usePageTitle';
import { PRIVACY_META, PRIVACY_SECTIONS } from './data/privacyContent';
import { LegalDocumentLayout } from './components/LegalDocumentLayout';

export const PrivacyPage: React.FC = () => {
  usePageTitle(
    'Politique de Confidentialité — TocManager',
    'Découvrez comment TocManager isole et protège les données de vos boutiques, ventes et collaborateurs.'
  );

  return (
    <LegalDocumentLayout
      badge={PRIVACY_META.badge}
      title={PRIVACY_META.title}
      subtitle={PRIVACY_META.subtitle}
      lastUpdated={PRIVACY_META.lastUpdated}
      sections={PRIVACY_SECTIONS}
      siblingLink={{
        label: "Consulter les Conditions Générales d'Utilisation (CGU)",
        to: '/cgu',
      }}
    />
  );
};
