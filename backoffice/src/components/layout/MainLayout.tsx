import React from 'react';
import { Outlet } from 'react-router-dom';
import { Sidebar } from './Sidebar';
import { Header } from './Header';
import { useSidebar } from '../../context/SidebarContext';
import { PinLockModal } from '../common/PinLockModal';

export const MainLayout: React.FC = () => {
  const { isOpen, close } = useSidebar();

  return (
    <div className="flex h-screen overflow-hidden bg-[#F5FAFD] dark:bg-dark-900 transition-colors duration-200">
      {/* Mobile Backdrop overlay */}
      {isOpen && (
        <div
          onClick={close}
          className="fixed inset-0 bg-[#1C2B3A]/50 z-40 lg:hidden backdrop-blur-xs transition-opacity duration-300 animate-fade-in"
          aria-hidden="true"
        />
      )}

      {/* Responsive Sidebar (desktop anchor + mobile slide-over) */}
      <Sidebar />

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
        <Header />
        <main className="flex-1 overflow-y-auto p-3 sm:p-5 lg:p-8">
          <Outlet />
        </main>
      </div>

      {/* PIN Lock Overlay */}
      <PinLockModal />
    </div>
  );
};
