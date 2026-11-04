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
  maxWidth = 'max-w-lg',
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
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      {/* Backdrop */}
      <div
        onClick={onClose}
        className="fixed inset-0 bg-[#1C2B3A]/50 backdrop-blur-xs transition-opacity"
      />

      {/* Modal Dialog Box */}
      <div
        className={`relative z-10 w-full ${maxWidth} bg-white dark:bg-dark-800 rounded-3xl shadow-soft-lg border border-[#E8EFF5] dark:border-dark-600 overflow-hidden transform animate-fade-in`}
      >
        {/* Header */}
        <div className="px-6 py-5 border-b border-[#E8EFF5] dark:border-dark-600 flex items-center justify-between">
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
            className="p-1.5 text-[#5A7184] hover:text-[#1C2B3A] dark:hover:text-slate-200 hover:bg-[#F0F9FE] dark:hover:bg-dark-700 rounded-xl transition"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Body */}
        <div className="p-6 space-y-4 max-h-[80vh] overflow-y-auto">
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
