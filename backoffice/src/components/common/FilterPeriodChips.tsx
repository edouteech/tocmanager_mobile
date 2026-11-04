import React, { useState, useRef, useEffect } from 'react';
import { ArrowUpDown, Calendar, ChevronDown, Check } from 'lucide-react';

export interface SortOption {
  id: string;
  label: string;
}

export interface FilterChipItem {
  id: string;
  label: string;
  count?: number;
}

interface FilterPeriodChipsProps {
  chips: FilterChipItem[];
  selectedChip: string;
  onSelectChip: (id: string) => void;
  sortOptions?: SortOption[];
  selectedSort?: string;
  onSelectSort?: (id: string) => void;
  // Optional extra toggle, like "À crédit"
  toggleLabel?: string;
  isToggleActive?: boolean;
  onToggle?: () => void;
  className?: string;
}

export const FilterPeriodChips: React.FC<FilterPeriodChipsProps> = ({
  chips,
  selectedChip,
  onSelectChip,
  sortOptions = [],
  selectedSort,
  onSelectSort,
  toggleLabel,
  isToggleActive,
  onToggle,
  className = '',
}) => {
  const [isSortOpen, setIsSortOpen] = useState(false);
  const sortRef = useRef<HTMLDivElement>(null);

  // Close dropdown when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (sortRef.current && !sortRef.current.contains(event.target as Node)) {
        setIsSortOpen(false);
      }
    };
    if (isSortOpen) {
      document.addEventListener('mousedown', handleClickOutside);
    }
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [isSortOpen]);

  const currentSortLabel = sortOptions.find((s) => s.id === selectedSort)?.label;

  return (
    <div className={`flex flex-col sm:flex-row sm:items-center justify-between gap-2.5 ${className}`}>
      {/* Scrollable Horizontal Chips */}
      <div className="flex items-center gap-1.5 overflow-x-auto no-scrollbar py-1 text-xs">
        {chips.map((chip) => {
          const isSelected = selectedChip === chip.id;
          return (
            <button
              key={chip.id}
              type="button"
              onClick={() => onSelectChip(chip.id)}
              className={`px-3 py-1.5 rounded-xl font-bold whitespace-nowrap transition-all duration-150 flex items-center gap-1.5 shrink-0 ${
                isSelected
                  ? 'bg-brand-600 text-white shadow-xs'
                  : 'bg-white dark:bg-dark-800 text-slate-600 dark:text-slate-300 border border-slate-200 dark:border-dark-600 hover:bg-slate-50 dark:hover:bg-dark-700'
              }`}
            >
              <span>{chip.label}</span>
              {chip.count !== undefined && (
                <span
                  className={`text-[10px] px-1.5 py-0.2 rounded-full font-mono ${
                    isSelected
                      ? 'bg-white/20 text-white'
                      : 'bg-slate-100 dark:bg-dark-700 text-slate-600 dark:text-slate-400'
                  }`}
                >
                  {chip.count}
                </span>
              )}
            </button>
          );
        })}

        {toggleLabel && onToggle && (
          <button
            type="button"
            onClick={onToggle}
            className={`px-3 py-1.5 rounded-xl font-bold whitespace-nowrap transition-all duration-150 flex items-center gap-1.5 shrink-0 ${
              isToggleActive
                ? 'bg-amber-500 text-white shadow-xs'
                : 'bg-white dark:bg-dark-800 text-amber-600 dark:text-amber-400 border border-amber-300 dark:border-amber-500/30 hover:bg-amber-50/50 dark:hover:bg-amber-500/10'
            }`}
          >
            <span>{toggleLabel}</span>
            {isToggleActive && <Check className="w-3.5 h-3.5" />}
          </button>
        )}
      </div>

      {/* Sort Menu Button */}
      {sortOptions.length > 0 && onSelectSort && (
        <div className="relative shrink-0 self-end sm:self-auto" ref={sortRef}>
          <button
            type="button"
            onClick={() => setIsSortOpen((prev) => !prev)}
            className="flex items-center gap-2 px-3 py-1.5 rounded-xl text-xs font-semibold bg-white dark:bg-dark-800 text-slate-700 dark:text-slate-200 border border-slate-200 dark:border-dark-600 hover:bg-slate-50 dark:hover:bg-dark-700 shadow-xs transition"
          >
            <ArrowUpDown className="w-3.5 h-3.5 text-brand-600 dark:text-brand-400" />
            <span className="hidden sm:inline text-slate-400">Tri :</span>
            <span className="font-bold text-slate-900 dark:text-white">
              {currentSortLabel || 'Trier'}
            </span>
            <ChevronDown className={`w-3.5 h-3.5 text-slate-400 transition-transform ${isSortOpen ? 'rotate-180' : ''}`} />
          </button>

          {isSortOpen && (
            <div className="absolute right-0 mt-1.5 w-48 bg-white dark:bg-dark-800 rounded-2xl shadow-xl border border-slate-100 dark:border-dark-600 py-1.5 z-30 animate-fade-in">
              <div className="px-3 py-1 text-[11px] font-semibold text-slate-400 uppercase tracking-wider">
                Trier par
              </div>
              {sortOptions.map((opt) => {
                const isActive = opt.id === selectedSort;
                return (
                  <button
                    key={opt.id}
                    type="button"
                    onClick={() => {
                      onSelectSort(opt.id);
                      setIsSortOpen(false);
                    }}
                    className={`w-full text-left px-3 py-2 text-xs flex items-center justify-between transition-colors ${
                      isActive
                        ? 'bg-brand-50 dark:bg-brand-500/15 text-brand-600 dark:text-brand-400 font-bold'
                        : 'text-slate-700 dark:text-slate-200 hover:bg-slate-50 dark:hover:bg-dark-700'
                    }`}
                  >
                    <span>{opt.label}</span>
                    {isActive && <Check className="w-3.5 h-3.5 text-brand-600 dark:text-brand-400" />}
                  </button>
                );
              })}
            </div>
          )}
        </div>
      )}
    </div>
  );
};
