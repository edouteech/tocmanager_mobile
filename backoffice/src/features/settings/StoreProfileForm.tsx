import React from 'react';
import { Store, Phone, Mail, MapPin, FileText, AlertTriangle, Save } from 'lucide-react';
import { StoreSettings } from '../../types';
import { CANONICAL_CURRENCIES } from '../../lib/currencies';

interface StoreProfileFormProps {
  form: StoreSettings;
  onChange: (next: StoreSettings) => void;
  onSubmit: (e: React.FormEvent) => void;
  isSubmitting: boolean;
}

export const StoreProfileForm: React.FC<StoreProfileFormProps> = ({
  form,
  onChange,
  onSubmit,
  isSubmitting,
}) => (
  <form onSubmit={onSubmit} className="space-y-6">
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
            onChange={(e) => onChange({ ...form, store_name: e.target.value })}
            className="input-toc"
          />
        </div>

        <div>
          <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
            Devise Monétaire Principale *
          </label>
          <select
            value={form.currency === 'FCFA' ? 'XOF' : form.currency}
            onChange={(e) => onChange({ ...form, currency: e.target.value })}
            className="input-toc bg-white dark:bg-dark-700"
          >
            {CANONICAL_CURRENCIES.map((c) => (
              <option key={c.code} value={c.code}>
                {c.label}
              </option>
            ))}
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
              onChange={(e) => onChange({ ...form, phone: e.target.value })}
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
              onChange={(e) => onChange({ ...form, email: e.target.value })}
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
            onChange={(e) => onChange({ ...form, address: e.target.value })}
            placeholder="Rue, Quartier, Ville, Pays"
            className="input-toc pl-10"
          />
        </div>
      </div>
    </div>

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
            onChange={(e) => onChange({ ...form, rccm: e.target.value })}
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
            onChange={(e) => onChange({ ...form, nif: e.target.value })}
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
          onChange={(e) => onChange({ ...form, tax_rate: parseFloat(e.target.value) || 0 })}
          className="input-toc w-48 font-mono font-bold"
        />
        <p className="text-xs text-slate-400 mt-1">
          Laissez à 0 si votre établissement applique les prix TTC ou est en franchise en base.
        </p>
      </div>
    </div>

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
          onChange={(e) =>
            onChange({ ...form, low_stock_threshold: parseFloat(e.target.value) || 1 })
          }
          className="input-toc w-48 font-mono font-bold"
        />
        <p className="text-xs text-slate-400 mt-1">
          Lorsque le stock d'un produit descend sous ce seuil, une alerte visuelle s'affiche sur la caisse et le tableau de bord.
        </p>
      </div>
    </div>

    <div className="flex justify-end">
      <button type="submit" disabled={isSubmitting} className="btn-primary px-6">
        <Save className="w-4 h-4" />
        <span>Enregistrer les paramètres</span>
      </button>
    </div>
  </form>
);
