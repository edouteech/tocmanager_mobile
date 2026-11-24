import React from 'react';
import { usePageTitle } from './hooks/usePageTitle';
import { TERMS_META, TERMS_SECTIONS } from './data/termsContent';
import { LegalDocumentLayout } from './components/LegalDocumentLayout';

export const TermsPage: React.FC = () => {
  usePageTitle(
    "Conditions Générales d'Utilisation (CGU) — TocManager",
    "Consultez les Conditions Générales d'Utilisation de la plateforme SaaS et mobile TocManager."
  );

  return (
    <LegalDocumentLayout
      badge={TERMS_META.badge}
      title={TERMS_META.title}
      subtitle={TERMS_META.subtitle}
      lastUpdated={TERMS_META.lastUpdated}
      sections={TERMS_SECTIONS}
      siblingLink={{
        label: 'Consulter la Politique de Confidentialité',
        to: '/confidentialite',
      }}
    />
  );
};
