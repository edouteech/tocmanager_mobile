import React, { useState } from 'react';
import { Store } from 'lucide-react';
import { Modal } from './Modal';
import { tenantApi } from '../../lib/api';
import { CANONICAL_CURRENCIES } from '../../lib/currencies';
import { useTenantStore } from '../../stores/tenantStore';

interface CreateBoutiqueModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const CreateBoutiqueModal: React.FC<CreateBoutiqueModalProps> = ({ isOpen, onClose }) => {
  const { selectBoutique, fetchBoutiques, openUpgradeModal } = useTenantStore();
  const [name, setName] = useState('');
  const [companyName, setCompanyName] = useState('');
  const [currency, setCurrency] = useState('XOF');
  const [country, setCountry] = useState('Sénégal');
  const [initialMagasinName, setInitialMagasinName] = useState('Magasin Principal');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) return;
    setSubmitting(true);
    setError(null);
    try {
      const created = await tenantApi.createBoutique({
        name: name.trim(),
        company_name: companyName.trim() || undefined,
        currency,
        country: country.trim() || 'Sénégal',
        initial_magasin_name: initialMagasinName.trim() || 'Magasin Principal',
      });
      await fetchBoutiques();
      await selectBoutique(created);
      setName('');
      setCompanyName('');
      onClose();
    } catch (err: any) {
      if (err.response?.status === 403) {
        onClose();
        openUpgradeModal({
          title: 'Limite de Boutiques Atteinte',
          message:
            err.response?.data?.detail?.message ||
            'Votre forfait actuel ne permet pas de créer une nouvelle boutique.',
          featureCode: 'max_boutiques',
        });
      } else {
        setError(err.response?.data?.detail || 'Erreur lors de la création de la boutique.');
      }
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Nouvelle Boutique" maxWidth="sm:max-w-md">
      <form onSubmit={handleSubmit} className="space-y-4 text-xs">
        <div className="flex items-center gap-2 p-3 rounded-xl bg-brand-50 dark:bg-brand-500/10 text-brand-700 dark:text-brand-300">
          <Store className="w-4 h-4 shrink-0" />
          <span>Créez une nouvelle enseigne commerciale avec son point de vente initial.</span>
        </div>

        <div>
          <label className="block font-bold text-slate-700 dark:text-slate-300 mb-1">
            Nom de la boutique *
          </label>
          <input
            type="text"
            required
            placeholder="Ex: Boutique Plateau"
            value={name}
            onChange={(e) => setName(e.target.value)}
            className="input-toc"
          />
        </div>

        <div>
          <label className="block font-bold text-slate-700 dark:text-slate-300 mb-1">
            Raison sociale (optionnel)
          </label>
          <input
            type="text"
            placeholder="Ex: Groupe Commerce SARL"
            value={companyName}
            onChange={(e) => setCompanyName(e.target.value)}
            className="input-toc"
          />
        </div>

        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="block font-bold text-slate-700 dark:text-slate-300 mb-1">Devise</label>
            <select
              value={currency}
              onChange={(e) => setCurrency(e.target.value)}
              className="input-toc bg-white dark:bg-dark-700"
            >
              {CANONICAL_CURRENCIES.map((c) => (
                <option key={c.code} value={c.code}>
                  {c.label}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="block font-bold text-slate-700 dark:text-slate-300 mb-1">Pays</label>
            <input
              type="text"
              value={country}
              onChange={(e) => setCountry(e.target.value)}
              className="input-toc"
            />
          </div>
        </div>

        <div>
          <label className="block font-bold text-slate-700 dark:text-slate-300 mb-1">
            Premier point de vente
          </label>
          <input
            type="text"
            value={initialMagasinName}
            onChange={(e) => setInitialMagasinName(e.target.value)}
            className="input-toc"
          />
        </div>

        {error && (
          <div className="p-2.5 rounded-xl bg-red-50 text-red-600 font-medium">{error}</div>
        )}

        <div className="flex justify-end gap-2 pt-2">
          <button type="button" onClick={onClose} className="btn-secondary text-xs">
            Annuler
          </button>
          <button
            type="submit"
            disabled={submitting || !name.trim()}
            className="btn-primary text-xs"
          >
            {submitting ? 'Création...' : 'Créer la boutique'}
          </button>
        </div>
      </form>
    </Modal>
  );
};
