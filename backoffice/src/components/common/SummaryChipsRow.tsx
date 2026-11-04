import React from 'react';

export interface SummaryChipItem {
  label: string;
  value: string | number;
  color?: 'primary' | 'success' | 'warning' | 'purple' | 'danger' | 'info';
  icon?: React.ReactNode;
  subtext?: string;
}

interface SummaryChipsRowProps {
  chips: SummaryChipItem[];
  className?: string;
}

const colorClasses: Record<NonNullable<SummaryChipItem['color']>, { bg: string; text: string; border: string }> = {
  primary: {
    bg: 'bg-brand-500/10 dark:bg-brand-500/20',
    text: 'text-brand-600 dark:text-brand-400',
    border: 'border-brand-500/30',
  },
  success: {
    bg: 'bg-emerald-500/10 dark:bg-emerald-500/20',
    text: 'text-emerald-600 dark:text-emerald-400',
    border: 'border-emerald-500/30',
  },
  warning: {
    bg: 'bg-amber-500/10 dark:bg-amber-500/20',
    text: 'text-amber-600 dark:text-amber-400',
    border: 'border-amber-500/30',
  },
  purple: {
    bg: 'bg-purple-500/10 dark:bg-purple-500/20',
    text: 'text-purple-600 dark:text-purple-400',
    border: 'border-purple-500/30',
  },
  danger: {
    bg: 'bg-rose-500/10 dark:bg-rose-500/20',
    text: 'text-rose-600 dark:text-rose-400',
    border: 'border-rose-500/30',
  },
  info: {
    bg: 'bg-sky-500/10 dark:bg-sky-500/20',
    text: 'text-sky-600 dark:text-sky-400',
    border: 'border-sky-500/30',
  },
};

export const SummaryChipsRow: React.FC<SummaryChipsRowProps> = ({ chips, className = '' }) => {
  return (
    <div className={`grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-2.5 sm:gap-3.5 ${className}`}>
      {chips.map((chip, idx) => {
        const theme = colorClasses[chip.color || 'primary'];
        return (
          <div
            key={idx}
            className={`p-3 sm:p-3.5 rounded-2xl border transition-all duration-200 ${theme.bg} ${theme.border} flex flex-col justify-between`}
          >
            <div className="flex items-center justify-between gap-1 mb-1">
              <span className="text-[11px] sm:text-xs font-semibold text-slate-500 dark:text-slate-400 truncate">
                {chip.label}
              </span>
              {chip.icon && (
                <span className={`shrink-0 ${theme.text}`}>
                  {chip.icon}
                </span>
              )}
            </div>
            <div className={`text-base sm:text-lg lg:text-xl font-extrabold tracking-tight ${theme.text} truncate`}>
              {chip.value}
            </div>
            {chip.subtext && (
              <span className="text-[10px] text-slate-400 dark:text-slate-500 mt-0.5 truncate">
                {chip.subtext}
              </span>
            )}
          </div>
        );
      })}
    </div>
  );
};
