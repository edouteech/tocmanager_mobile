export const getCategoryBadgeClass = (cat: string): string => {
  switch (cat.toLowerCase().trim()) {
    case 'fournisseur':
      return 'bg-brand-50 text-brand-700 border-brand-200 dark:bg-brand-500/15 dark:text-brand-300 dark:border-brand-500/30';
    case 'loyer':
    case 'télécoms':
    case 'telecoms':
      return 'bg-purple-50 text-purple-700 border-purple-200 dark:bg-purple-950/40 dark:text-purple-300 dark:border-purple-800/40';
    case 'salaires':
      return 'bg-emerald-50 text-emerald-700 border-emerald-200 dark:bg-emerald-950/40 dark:text-emerald-300 dark:border-emerald-800/40';
    case 'transport':
      return 'bg-amber-50 text-amber-700 border-amber-200 dark:bg-amber-950/40 dark:text-amber-300 dark:border-amber-800/40';
    case 'énergie':
    case 'energie':
      return 'bg-sky-50 text-sky-700 border-sky-200 dark:bg-sky-950/40 dark:text-sky-300 dark:border-sky-800/40';
    case 'entretien':
    case 'maintenance':
      return 'bg-orange-50 text-orange-700 border-orange-200 dark:bg-orange-950/40 dark:text-orange-300 dark:border-orange-800/40';
    case 'consommables':
    case 'fournitures':
      return 'bg-indigo-50 text-indigo-700 border-indigo-200 dark:bg-indigo-950/40 dark:text-indigo-300 dark:border-indigo-800/40';
    default:
      return 'bg-slate-100 text-slate-700 border-slate-200 dark:bg-dark-700 dark:text-slate-300 dark:border-dark-600';
  }
};
