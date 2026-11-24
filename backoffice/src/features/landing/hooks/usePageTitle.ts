import { useEffect } from 'react';

const DEFAULT_PAGE_TITLE = 'TocManager - Backoffice de Gestion';

export function usePageTitle(title: string, description?: string): void {
  useEffect(() => {
    document.title = title;

    if (description) {
      const meta = document.querySelector('meta[name="description"]');
      if (meta) {
        meta.setAttribute('content', description);
      }
    }

    return () => {
      document.title = DEFAULT_PAGE_TITLE;
    };
  }, [title, description]);
}
