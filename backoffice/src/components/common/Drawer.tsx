import React, { useEffect } from 'react';
import { X } from 'lucide-react';

interface DrawerProps {
  isOpen: boolean;
  onClose: () => void;
  title: React.ReactNode;
  subtitle?: string;
  children: React.ReactNode;
  footer?: React.ReactNode;
  width?: string;
}

export const Drawer: React.FC<DrawerProps> = ({
  isOpen,
  onClose,
  title,
  subtitle,
  children,
  footer,
  width = 'max-w-xl',
}) => {
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isOpen) {
        onClose();
      }
    };
    if (isOpen) {
      document.body.style.overflow = 'hidden';
      window.addEventListener('keydown', handleKeyDown);
    }
    return () => {
      document.body.style.overflow = '';
      window.removeEventListener('keydown', handleKeyDown);
    };
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex justify-end">
      {/* Backdrop */}
      <div
        onClick={onClose}
        className="fixed inset-0 bg-[#1C2B3A]/50 backdrop-blur-xs transition-opacity duration-300"
      />

      {/* Slide-over panel */}
      <div
        className={`relative z-10 w-full ${width} bg-white dark:bg-dark-800 shadow-soft-lg border-l border-[#E8EFF5] dark:border-dark-600 flex flex-col h-full transform transition-transform duration-300 ease-out animate-slide-in-right`}
      >
        {/* Header */}
        <div className="px-6 py-5 border-b border-[#E8EFF5] dark:border-dark-600 flex items-center justify-between bg-white dark:bg-dark-800 sticky top-0 z-10">
          <div>
            <h3 className="text-lg font-bold text-[#1C2B3A] dark:text-white tracking-tight">
              {title}
            </h3>
            {subtitle && (
              <p className="text-xs text-[#5A7184] dark:text-slate-400 mt-0.5">
                {subtitle}
              </p>
            )}
          </div>
          <button
            onClick={onClose}
            className="p-2 text-[#5A7184] hover:text-[#1C2B3A] dark:hover:text-slate-200 hover:bg-[#F0F9FE] dark:hover:bg-dark-700 rounded-xl transition"
            aria-label="Fermer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content body */}
        <div className="flex-1 overflow-y-auto p-6 space-y-6">
          {children}
        </div>

        {/* Footer */}
        {footer && (
          <div className="px-6 py-4 border-t border-[#E8EFF5] dark:border-dark-600 bg-[#F5FAFD] dark:bg-dark-700/50 flex items-center justify-end gap-3">
            {footer}
          </div>
        )}
      </div>
    </div>
  );
};
