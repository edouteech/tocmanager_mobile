import React from 'react';
import { Modal } from '../../components/common/Modal';

const PRESET_COLORS = [
  '#29ABE2',
  '#27AE60',
  '#F39C12',
  '#E74C3C',
  '#8E44AD',
  '#1A8FBF',
  '#5A7184',
  '#E67E22',
];

export interface CategoryFormState {
  name: string;
  description: string;
  color: string;
  icon: string;
}

interface CategoryFormModalProps {
  isOpen: boolean;
  isEditing: boolean;
  form: CategoryFormState;
  formError: string | null;
  isPending: boolean;
  onClose: () => void;
  onChange: (next: CategoryFormState) => void;
  onSubmit: (e: React.FormEvent) => void;
}

export const CategoryFormModal: React.FC<CategoryFormModalProps> = ({
  isOpen,
  isEditing,
  form,
  formError,
  isPending,
  onClose,
  onChange,
  onSubmit,
}) => (
  <Modal
    isOpen={isOpen}
    onClose={onClose}
    title={isEditing ? 'Modifier la Catégorie' : 'Nouvelle Catégorie'}
    subtitle="Définissez le nom et la couleur d'identification"
    footer={
      <>
        <button type="button" onClick={onClose} className="btn-secondary">
          Annuler
        </button>
        <button type="submit" form="category-form" disabled={isPending} className="btn-primary">
          {isEditing ? 'Enregistrer' : 'Créer la catégorie'}
        </button>
      </>
    }
  >
    <form id="category-form" onSubmit={onSubmit} className="space-y-4">
      {formError && (
        <div className="p-3 rounded-xl bg-rose-50 dark:bg-rose-950/40 border border-rose-200 dark:border-rose-800/40 text-rose-700 dark:text-rose-300 text-xs font-medium">
          {formError}
        </div>
      )}
      <div>
        <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
          Nom de la catégorie *
        </label>
        <input
          type="text"
          required
          placeholder="Ex: Boissons, Alimentation, Cosmétiques..."
          value={form.name}
          onChange={(e) => onChange({ ...form, name: e.target.value })}
          className="input-toc"
        />
      </div>

      <div>
        <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
          Description
        </label>
        <textarea
          rows={2}
          placeholder="Courte description ou notes de rayon..."
          value={form.description}
          onChange={(e) => onChange({ ...form, description: e.target.value })}
          className="input-toc"
        />
      </div>

      <div>
        <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-2">
          Couleur d'identification
        </label>
        <div className="flex items-center gap-2 flex-wrap">
          {PRESET_COLORS.map((c) => (
            <button
              key={c}
              type="button"
              onClick={() => onChange({ ...form, color: c })}
              className={`w-7 h-7 rounded-full border-2 transition ${
                form.color === c
                  ? 'border-brand-500 scale-110 shadow-md ring-2 ring-brand-500/30'
                  : 'border-transparent hover:scale-105'
              }`}
              style={{ backgroundColor: c }}
            />
          ))}
        </div>
      </div>
    </form>
  </Modal>
);
