import React from 'react';
import { LayoutGrid, Table } from 'lucide-react';

export type ViewMode = 'cards' | 'table';

interface ViewToggleProps {
  mode: ViewMode;
  onChange: (mode: ViewMode) => void;
  className?: string;
}

export const ViewToggle: React.FC<ViewToggleProps> = ({ mode, onChange, className = '' }) => {
  return (
    <div className={`inline-flex items-center p-1 bg-slate-100 dark:bg-dark-700 rounded-xl border border-slate-200 dark:border-dark-600 ${className}`}>
      <button
        type="button"
        onClick={() => onChange('cards')}
        className={`flex items-center gap-1.5 px-2.5 py-1 rounded-lg text-xs font-bold transition-all ${
          mode === 'cards'
            ? 'bg-white dark:bg-dark-800 text-brand-600 dark:text-brand-400 shadow-xs'
            : 'text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200'
        }`}
        title="Vue Cartes (Style Mobile)"
      >
        <LayoutGrid className="w-3.5 h-3.5" />
        <span className="hidden sm:inline">Cartes</span>
      </button>

      <button
        type="button"
        onClick={() => onChange('table')}
        className={`flex items-center gap-1.5 px-2.5 py-1 rounded-lg text-xs font-bold transition-all ${
          mode === 'table'
            ? 'bg-white dark:bg-dark-800 text-brand-600 dark:text-brand-400 shadow-xs'
            : 'text-slate-500 hover:text-slate-700 dark:text-slate-400 dark:hover:text-slate-200'
        }`}
        title="Vue Tableau (Style Desktop)"
      >
        <Table className="w-3.5 h-3.5" />
        <span className="hidden sm:inline">Tableau</span>
      </button>
    </div>
  );
};
