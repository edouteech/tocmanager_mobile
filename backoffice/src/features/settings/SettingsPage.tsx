import React, { useState, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { CheckCircle2 } from 'lucide-react';
import { settingsApi } from '../../lib/api';
import { StoreSettings } from '../../types';
import { PinSecurityCard } from './PinSecurityCard';
import { StoreProfileForm } from './StoreProfileForm';

export const SettingsPage: React.FC = () => {
  const queryClient = useQueryClient();
  const [successMsg, setSuccessMsg] = useState(false);

  const { data: initialSettings, isLoading } = useQuery({
    queryKey: ['settings'],
    queryFn: settingsApi.getSettings,
  });

  const [form, setForm] = useState<StoreSettings>({
    store_name: 'TocManager Store',
    currency: 'FCFA',
    phone: '',
    email: '',
    address: '',
    tax_rate: 0,
    low_stock_threshold: 5,
    rccm: '',
    nif: '',
  });

  useEffect(() => {
    if (initialSettings) {
      setForm(initialSettings);
    }
  }, [initialSettings]);

  const updateMutation = useMutation({
    mutationFn: settingsApi.updateSettings,
    onSuccess: (updated) => {
      queryClient.setQueryData(['settings'], updated);
      setSuccessMsg(true);
      setTimeout(() => setSuccessMsg(false), 4000);
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    updateMutation.mutate(form);
  };

  if (isLoading) {
    return (
      <div className="card-toc p-12 text-center text-slate-400 text-sm">
        Chargement des paramètres...
      </div>
    );
  }

  return (
    <div className="space-y-6 max-w-4xl mx-auto">
      <div>
        <h1 className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">
          Paramètres
        </h1>
        <p className="text-xs sm:text-sm text-[#5A7184] dark:text-slate-400 mt-1">
          Configuration des informations du magasin, devise et alertes
        </p>
      </div>

      {successMsg && (
        <div className="p-4 bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-200 dark:border-emerald-800/40 rounded-2xl flex items-center gap-2.5 text-emerald-800 dark:text-emerald-300 text-xs font-semibold animate-fade-in">
          <CheckCircle2 className="w-5 h-5 text-emerald-600 shrink-0" />
          <span>Paramètres du magasin enregistrés avec succès.</span>
        </div>
      )}

      <StoreProfileForm
        form={form}
        onChange={setForm}
        onSubmit={handleSubmit}
        isSubmitting={updateMutation.isPending}
      />

      <PinSecurityCard />
    </div>
  );
};
