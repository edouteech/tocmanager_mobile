import React, { useEffect, useState } from 'react';
import { BrowserRouter } from 'react-router-dom';
import { QueryClientProvider } from '@tanstack/react-query';
import { queryClient } from './lib/queryClient';
import { consumeImpersonationHash } from './lib/impersonationTransfer';
import { ThemeProvider } from './context/ThemeContext';
import { DensityProvider } from './context/DensityContext';
import { SidebarProvider } from './context/SidebarContext';
import { ToastProvider } from './context/ToastContext';
import { useAuthStore } from './stores/authStore';
import { AppRoutes } from './routes/AppRoutes';

export const App: React.FC = () => {
  useState(() => consumeImpersonationHash());
  const initFromStorage = useAuthStore((s) => s.initFromStorage);

  useEffect(() => {
    initFromStorage();
  }, [initFromStorage]);

  return (
    <QueryClientProvider client={queryClient}>
      <ThemeProvider>
        <DensityProvider>
          <SidebarProvider>
            <ToastProvider>
              <BrowserRouter>
                <AppRoutes />
              </BrowserRouter>
            </ToastProvider>
          </SidebarProvider>
        </DensityProvider>
      </ThemeProvider>
    </QueryClientProvider>
  );
};

export default App;
