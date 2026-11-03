import React, { useState, useEffect } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Store,
  Phone,
  Mail,
  MapPin,
  FileText,
  AlertTriangle,
  CheckCircle2,
  Save,
} from 'lucide-react';
import { settingsApi } from '../../lib/api';
import { StoreSettings } from '../../types';

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
      {/* Header */}
      <div>
        <h1 className="text-2xl font-extrabold text-slate-900 dark:text-white tracking-tight">Paramètres Généraux</h1>
        <p className="text-xs sm:text-sm text-slate-500 dark:text-slate-400 mt-1">
          Configuration des informations du magasin, devise et alertes opérationnelles
        </p>
      </div>

      {successMsg && (
        <div className="p-4 bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-200 dark:border-emerald-800/40 rounded-2xl flex items-center gap-2.5 text-emerald-800 dark:text-emerald-300 text-xs font-semibold animate-fade-in">
          <CheckCircle2 className="w-5 h-5 text-emerald-600 shrink-0" />
          <span>Paramètres du magasin enregistrés avec succès.</span>
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Identité Magasin */}
        <div className="card-toc p-6 space-y-4">
          <div className="flex items-center gap-2.5 pb-3 border-b border-[#E8EFF5] dark:border-dark-600 font-bold text-slate-900 dark:text-white text-base">
            <Store className="w-5 h-5 text-brand-500" />
            <h2>Identité & En-tête Commercial</h2>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Nom du Magasin / Enseigne *
              </label>
              <input
                type="text"
                required
                value={form.store_name}
                onChange={(e) => setForm({ ...form, store_name: e.target.value })}
                className="input-toc"
              />
            </div>

            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Devise Monétaire Principale *
              </label>
              <select
                value={form.currency}
                onChange={(e) => setForm({ ...form, currency: e.target.value })}
                className="input-toc bg-white dark:bg-dark-700"
              >
                <option value="FCFA">Franc CFA (FCFA / XOF / XAF)</option>
                <option value="EUR">Euro (€)</option>
                <option value="USD">Dollar US ($)</option>
                <option value="GHS">Cedi Ghanéen (GH₵)</option>
                <option value="NGN">Naira Nigérian (₦)</option>
              </select>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Téléphone de contact
              </label>
              <div className="relative">
                <Phone className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
                <input
                  type="text"
                  value={form.phone || ''}
                  onChange={(e) => setForm({ ...form, phone: e.target.value })}
                  placeholder="+228 90 00 00 00"
                  className="input-toc pl-10"
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Email professionnel
              </label>
              <div className="relative">
                <Mail className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
                <input
                  type="email"
                  value={form.email || ''}
                  onChange={(e) => setForm({ ...form, email: e.target.value })}
                  placeholder="contact@boutique.com"
                  className="input-toc pl-10"
                />
              </div>
            </div>
          </div>

          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Adresse géographique
            </label>
            <div className="relative">
              <MapPin className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
              <input
                type="text"
                value={form.address || ''}
                onChange={(e) => setForm({ ...form, address: e.target.value })}
                placeholder="Rue, Quartier, Ville, Pays"
                className="input-toc pl-10"
              />
            </div>
          </div>
        </div>

        {/* Informations Légales */}
        <div className="card-toc p-6 space-y-4">
          <div className="flex items-center gap-2.5 pb-3 border-b border-[#E8EFF5] dark:border-dark-600 font-bold text-slate-900 dark:text-white text-base">
            <FileText className="w-5 h-5 text-brand-500" />
            <h2>Informations Légales & Fiscales</h2>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Numéro RCCM / Registre du Commerce
              </label>
              <input
                type="text"
                value={form.rccm || ''}
                onChange={(e) => setForm({ ...form, rccm: e.target.value })}
                placeholder="Ex: TG-LOM-2024-B-1234"
                className="input-toc"
              />
            </div>

            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Identifiant Fiscal (NIF)
              </label>
              <input
                type="text"
                value={form.nif || ''}
                onChange={(e) => setForm({ ...form, nif: e.target.value })}
                placeholder="Ex: 1000123456"
                className="input-toc"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Taux de TVA optionnel (%)
            </label>
            <input
              type="number"
              min="0"
              max="100"
              step="0.5"
              value={form.tax_rate}
              onChange={(e) => setForm({ ...form, tax_rate: parseFloat(e.target.value) || 0 })}
              className="input-toc w-48 font-mono font-bold"
            />
            <p className="text-xs text-slate-400 mt-1">Laissez à 0 si votre établissement applique les prix TTC ou est en franchise en base.</p>
          </div>
        </div>

        {/* Alertes de Stock */}
        <div className="card-toc p-6 space-y-4">
          <div className="flex items-center gap-2.5 pb-3 border-b border-[#E8EFF5] dark:border-dark-600 font-bold text-slate-900 dark:text-white text-base">
            <AlertTriangle className="w-5 h-5 text-amber-500" />
            <h2>Alertes Opérationnelles de Stock</h2>
          </div>

          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Seuil d'alerte global par défaut pour stock faible (Unités)
            </label>
            <input
              type="number"
              min="1"
              value={form.low_stock_threshold}
              onChange={(e) => setForm({ ...form, low_stock_threshold: parseFloat(e.target.value) || 1 })}
              className="input-toc w-48 font-mono font-bold"
            />
            <p className="text-xs text-slate-400 mt-1">
              Lorsque le stock d'un produit descend sous ce seuil, une alerte visuelle s'affiche sur la caisse et le tableau de bord.
            </p>
          </div>
        </div>

        {/* Submit Button */}
        <div className="flex justify-end">
          <button
            type="submit"
            disabled={updateMutation.isPending}
            className="btn-primary px-6"
          >
            <Save className="w-4 h-4" />
            <span>Enregistrer les paramètres</span>
          </button>
        </div>
      </form>
    </div>
  );
};
