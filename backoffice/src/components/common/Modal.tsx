import React, { useEffect } from 'react';
import { X } from 'lucide-react';

interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
  title: React.ReactNode;
  subtitle?: string;
  children: React.ReactNode;
  footer?: React.ReactNode;
  maxWidth?: string;
}

export const Modal: React.FC<ModalProps> = ({
  isOpen,
  onClose,
  title,
  subtitle,
  children,
  footer,
  maxWidth = 'sm:max-w-lg',
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
    <div className="fixed inset-0 z-50 flex items-center justify-center p-3 sm:p-4">
      {/* Backdrop */}
      <div
        onClick={onClose}
        className="fixed inset-0 bg-[#1C2B3A]/50 backdrop-blur-xs transition-opacity"
      />

      {/* Modal Dialog Box */}
      <div
        className={`relative z-10 w-full ${maxWidth} max-h-[90vh] bg-white dark:bg-dark-800 rounded-3xl shadow-soft-lg border border-[#E8EFF5] dark:border-dark-600 overflow-hidden transform animate-fade-in flex flex-col`}
      >
        {/* Header */}
        <div className="px-5 sm:px-6 py-4 sm:py-5 border-b border-[#E8EFF5] dark:border-dark-600 flex items-center justify-between shrink-0">
          <div className="min-w-0 pr-2">
            <h3 className="text-base sm:text-lg font-bold text-[#1C2B3A] dark:text-white tracking-tight truncate">
              {title}
            </h3>
            {subtitle && (
              <p className="text-xs text-[#5A7184] dark:text-slate-400 mt-0.5 truncate">
                {subtitle}
              </p>
            )}
          </div>
          <button
            onClick={onClose}
            className="p-1.5 text-[#5A7184] hover:text-[#1C2B3A] dark:hover:text-slate-200 hover:bg-[#F0F9FE] dark:hover:bg-dark-700 rounded-xl transition shrink-0"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Body */}
        <div className="p-4 sm:p-6 space-y-4 overflow-y-auto flex-1">
          {children}
        </div>

        {/* Footer */}
        {footer && (
          <div className="px-5 sm:px-6 py-3.5 sm:py-4 border-t border-[#E8EFF5] dark:border-dark-600 bg-[#F5FAFD] dark:bg-dark-700/50 flex flex-wrap items-center justify-end gap-2.5 sm:gap-3 shrink-0">
            {footer}
          </div>
        )}
      </div>
    </div>
  );
};
