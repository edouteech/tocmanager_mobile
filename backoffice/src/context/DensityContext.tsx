import React, { createContext, useContext, useEffect, useState } from 'react';

export type Density = 'comfortable' | 'compact';

interface DensityContextType {
  density: Density;
  toggleDensity: () => void;
  setDensity: (density: Density) => void;
  tableClasses: {
    th: string;
    td: string;
    fontSize: string;
  };
}

const DensityContext = createContext<DensityContextType | undefined>(undefined);

export const DensityProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [density, setDensityState] = useState<Density>(() => {
    const saved = localStorage.getItem('toc_density');
    if (saved === 'comfortable' || saved === 'compact') return saved;
    return 'comfortable';
  });

  useEffect(() => {
    localStorage.setItem('toc_density', density);
  }, [density]);

  const toggleDensity = () => {
    setDensityState((prev) => (prev === 'comfortable' ? 'compact' : 'comfortable'));
  };

  const setDensity = (newDensity: Density) => {
    setDensityState(newDensity);
  };

  const tableClasses = {
    comfortable: {
      th: 'px-5 py-3.5 text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider',
      td: 'px-5 py-4 text-sm text-slate-700 dark:text-slate-200',
      fontSize: 'text-sm',
    },
    compact: {
      th: 'px-4 py-2 text-[11px] font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider',
      td: 'px-4 py-2 text-xs text-slate-700 dark:text-slate-200',
      fontSize: 'text-xs',
    },
  }[density];

  return (
    <DensityContext.Provider value={{ density, toggleDensity, setDensity, tableClasses }}>
      {children}
    </DensityContext.Provider>
  );
};

export const useDensity = () => {
  const context = useContext(DensityContext);
  if (!context) {
    throw new Error('useDensity must be used within a DensityProvider');
  }
  return context;
};
