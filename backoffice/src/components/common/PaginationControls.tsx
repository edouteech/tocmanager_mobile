import React from 'react';
import { ChevronLeft, ChevronRight } from 'lucide-react';

interface PaginationControlsProps {
  page: number;
  pages: number;
  total: number;
  limit: number;
  onPageChange: (nextPage: number) => void;
  onLimitChange?: (nextLimit: number) => void;
  itemLabel?: string;
  isFetching?: boolean;
}

export const PaginationControls: React.FC<PaginationControlsProps> = ({
  page,
  pages,
  total,
  limit,
  onPageChange,
  onLimitChange,
  itemLabel = 'éléments',
  isFetching = false,
}) => {
  if (total === 0) return null;

  const safePage = Math.max(1, Math.min(page, Math.max(1, pages)));
  const startItem = (safePage - 1) * limit + 1;
  const endItem = Math.min(total, safePage * limit);

  return (
    <div className="no-print card-toc px-4 py-3 flex flex-col sm:flex-row items-center justify-between gap-3 text-xs">
      <div className="text-[#5A7184] dark:text-slate-400 font-medium">
        Affichage <span className="font-bold text-[#1C2B3A] dark:text-white">{startItem}-{endItem}</span> sur{' '}
        <span className="font-bold text-[#1C2B3A] dark:text-white">{total}</span> {itemLabel}
        {isFetching && <span className="ml-2 text-brand-500">Actualisation...</span>}
      </div>

      <div className="flex items-center gap-2 flex-wrap justify-center">
        {onLimitChange && (
          <select
            aria-label="Éléments par page"
            value={limit}
            onChange={(e) => onLimitChange(Number(e.target.value))}
            className="input-toc py-1 px-2 text-xs bg-white dark:bg-dark-700 w-auto"
          >
            {[25, 50, 100].map((size) => (
              <option key={size} value={size}>
                {size} / page
              </option>
            ))}
          </select>
        )}

        <div className="inline-flex items-center gap-1.5">
          <button
            type="button"
            disabled={safePage <= 1}
            onClick={() => onPageChange(safePage - 1)}
            className="btn-secondary py-1.5 px-2.5 text-xs disabled:opacity-40 disabled:cursor-not-allowed inline-flex items-center gap-1"
          >
            <ChevronLeft className="w-3.5 h-3.5" />
            <span>Précédent</span>
          </button>

          <span className="px-2.5 py-1 rounded-lg bg-[#F5FAFD] dark:bg-dark-700 border border-[#E8EFF5] dark:border-dark-600 font-bold text-[#1C2B3A] dark:text-white">
            Page {safePage} / {Math.max(1, pages)}
          </span>

          <button
            type="button"
            disabled={safePage >= pages}
            onClick={() => onPageChange(safePage + 1)}
            className="btn-secondary py-1.5 px-2.5 text-xs disabled:opacity-40 disabled:cursor-not-allowed inline-flex items-center gap-1"
          >
            <span>Suivant</span>
            <ChevronRight className="w-3.5 h-3.5" />
          </button>
        </div>
      </div>
    </div>
  );
};
