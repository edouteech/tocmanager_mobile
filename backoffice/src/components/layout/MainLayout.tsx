import React, { useEffect } from 'react';
import { Outlet } from 'react-router-dom';
import { Sidebar } from './Sidebar';
import { Header } from './Header';
import { useSidebar } from '../../context/SidebarContext';
import { useTenantStore } from '../../stores/tenantStore';
import { PinLockModal } from '../common/PinLockModal';
import { UpgradePlanModal } from '../common/UpgradePlanModal';

export const MainLayout: React.FC = () => {
  const { isOpen, close } = useSidebar();
  const initTenant = useTenantStore((s) => s.initTenant);
  const openUpgradeModal = useTenantStore((s) => s.openUpgradeModal);

  useEffect(() => {
    initTenant();
  }, [initTenant]);

  useEffect(() => {
    const handler = (event: Event) => {
      const custom = event as CustomEvent<{
        feature?: string;
        recommended_plan?: string;
        message?: string;
      }>;
      const detail = custom.detail || {};
      openUpgradeModal({
        title: 'Mise a niveau requise',
        message: detail.message,
        featureCode: detail.feature,
        recommendedPlan: detail.recommended_plan || 'pro',
      });
    };
    window.addEventListener('toc:plan-upgrade-required', handler);
    return () => window.removeEventListener('toc:plan-upgrade-required', handler);
  }, [openUpgradeModal]);

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

      {/* Responsive Sidebar */}
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

      {/* SaaS Feature Gating & Paywall Modal */}
      <UpgradePlanModal />
    </div>
  );
};
