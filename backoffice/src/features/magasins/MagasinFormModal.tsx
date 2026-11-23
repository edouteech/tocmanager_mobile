import React, { useState, useEffect } from 'react';
import { Magasin } from '../../types';

interface MagasinFormModalProps {
  isOpen: boolean;
  editingMagasin: Magasin | null;
  defaultCode: string;
  submitting: boolean;
  onClose: () => void;
  onSubmit: (payload: {
    name: string;
    code?: string;
    address?: string;
    phone?: string;
    is_warehouse: boolean;
  }) => Promise<void>;
}

export const MagasinFormModal: React.FC<MagasinFormModalProps> = ({
  isOpen,
  editingMagasin,
  defaultCode,
  submitting,
  onClose,
  onSubmit,
}) => {
  const [name, setName] = useState('');
  const [code, setCode] = useState('');
  const [address, setAddress] = useState('');
  const [phone, setPhone] = useState('');
  const [isWarehouse, setIsWarehouse] = useState(false);

  useEffect(() => {
    if (editingMagasin) {
      setName(editingMagasin.name);
      setCode(editingMagasin.code || '');
      setAddress(editingMagasin.address || '');
      setPhone(editingMagasin.phone || '');
      setIsWarehouse(Boolean(editingMagasin.is_warehouse));
    } else {
      setName('');
      setCode(defaultCode);
      setAddress('');
      setPhone('');
      setIsWarehouse(false);
    }
  }, [editingMagasin, defaultCode, isOpen]);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) return;
    await onSubmit({
      name: name.trim(),
      code: code.trim() || undefined,
      address: address.trim() || undefined,
      phone: phone.trim() || undefined,
      is_warehouse: isWarehouse,
    });
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-fade-in">
      <div className="bg-white dark:bg-slate-900 rounded-2xl p-6 max-w-md w-full border border-slate-200 dark:border-slate-800 shadow-2xl space-y-4">
        <h3 className="text-lg font-bold text-slate-900 dark:text-white">
          {editingMagasin ? 'Modifier le Magasin' : 'Ajouter un Magasin / Point de Vente'}
        </h3>

        <form onSubmit={handleSubmit} className="space-y-3 text-xs">
          <div>
            <label className="block font-semibold mb-1">Nom du magasin *</label>
            <input
              type="text"
              required
              placeholder="Ex: Succursale Plateau"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full px-3 py-2 rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-800"
            />
          </div>

          <div>
            <label className="block font-semibold mb-1">Code identifiant (optionnel)</label>
            <input
              type="text"
              placeholder="MAG-02"
              value={code}
              onChange={(e) => setCode(e.target.value)}
              className="w-full px-3 py-2 rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-800"
            />
          </div>

          <div>
            <label className="block font-semibold mb-1">Adresse physique</label>
            <input
              type="text"
              placeholder="Rue 14, Médina, Dakar"
              value={address}
              onChange={(e) => setAddress(e.target.value)}
              className="w-full px-3 py-2 rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-800"
            />
          </div>

          <div>
            <label className="block font-semibold mb-1">Téléphone de contact</label>
            <input
              type="tel"
              placeholder="+221 77 000 00 00"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              className="w-full px-3 py-2 rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-800"
            />
          </div>

          <div className="p-3 bg-slate-50 dark:bg-slate-800 rounded-xl space-y-1">
            <div className="flex items-center gap-2">
              <input
                type="checkbox"
                id="isWarehouse"
                checked={isWarehouse}
                onChange={(e) => setIsWarehouse(e.target.checked)}
                className="rounded text-indigo-600"
              />
              <label htmlFor="isWarehouse" className="font-semibold text-slate-800 dark:text-slate-200">
                Entrepôt de réserve / Stockage uniquement
              </label>
            </div>
            <p className="text-[11px] text-slate-400 pl-5">
              Cochez si cet établissement n'effectue pas de vente directe au comptoir.
            </p>
          </div>

          <div className="flex items-center justify-end gap-2 pt-3">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 rounded-lg text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800"
            >
              Annuler
            </button>
            <button
              type="submit"
              disabled={submitting}
              className="px-5 py-2 bg-indigo-600 hover:bg-indigo-700 text-white font-bold rounded-xl shadow transition"
            >
              {submitting
                ? 'Enregistrement...'
                : editingMagasin
                ? 'Mettre à jour'
                : 'Créer le magasin'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
