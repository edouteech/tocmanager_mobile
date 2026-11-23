import React from 'react';
import { Category, Product } from '../../types';
import { Drawer } from '../../components/common/Drawer';
import { ImageUploadInput } from '../../components/common/ImageUploadInput';
import { ProductMagasinAvailabilityPanel } from './ProductMagasinAvailabilityPanel';

export interface ProductFormValues {
  name: string;
  categoryId: string;
  price: number;
  costPrice: number;
  stock: number;
  minStock: number;
  unit: string;
  barcode: string;
  imagePath: string | null;
}

interface ProductFormDrawerProps {
  isOpen: boolean;
  editingProduct: Product | null;
  drawerTab: 'info' | 'magasins';
  categories: Category[];
  values: ProductFormValues;
  formError: string | null;
  isSubmitting: boolean;
  onClose: () => void;
  onTabChange: (tab: 'info' | 'magasins') => void;
  onChange: (next: ProductFormValues) => void;
  onSubmit: (e: React.FormEvent) => void;
}

export const ProductFormDrawer: React.FC<ProductFormDrawerProps> = ({
  isOpen,
  editingProduct,
  drawerTab,
  categories,
  values,
  formError,
  isSubmitting,
  onClose,
  onTabChange,
  onChange,
  onSubmit,
}) => (
  <Drawer
    isOpen={isOpen}
    onClose={onClose}
    title={editingProduct ? "Modifier l'Article" : 'Ajouter un Nouvel Article'}
    subtitle="Renseignez les informations de prix et de stock"
    footer={
      drawerTab === 'info' ? (
        <div className="flex items-center justify-end gap-2.5 w-full">
          <button type="button" onClick={onClose} className="btn-secondary text-xs">
            Annuler
          </button>
          <button type="submit" form="product-form" disabled={isSubmitting} className="btn-primary text-xs">
            {isSubmitting ? 'Enregistrement...' : editingProduct ? 'Mettre à jour' : "Créer l'article"}
          </button>
        </div>
      ) : (
        <div className="flex items-center justify-end w-full">
          <button type="button" onClick={onClose} className="btn-secondary text-xs">
            Fermer
          </button>
        </div>
      )
    }
  >
    {editingProduct && (
      <div className="grid grid-cols-2 gap-2 p-1 rounded-xl bg-slate-100 dark:bg-dark-700 mb-4">
        <button
          type="button"
          onClick={() => onTabChange('info')}
          className={`py-2 px-3 rounded-lg text-xs font-bold transition ${
            drawerTab === 'info'
              ? 'bg-white dark:bg-dark-800 text-brand-600 shadow-sm'
              : 'text-slate-500 hover:text-slate-700'
          }`}
        >
          Informations générales
        </button>
        <button
          type="button"
          onClick={() => onTabChange('magasins')}
          className={`py-2 px-3 rounded-lg text-xs font-bold transition ${
            drawerTab === 'magasins'
              ? 'bg-white dark:bg-dark-800 text-brand-600 shadow-sm'
              : 'text-slate-500 hover:text-slate-700'
          }`}
        >
          Disponibilité & Magasins
        </button>
      </div>
    )}

    {editingProduct && drawerTab === 'magasins' ? (
      <ProductMagasinAvailabilityPanel
        productSyncId={editingProduct.sync_id}
        cataloguePrice={editingProduct.price}
      />
    ) : (
      <form id="product-form" onSubmit={onSubmit} className="space-y-4">
        {formError && (
          <div className="p-3 rounded-xl bg-rose-50 dark:bg-rose-950/40 border border-rose-200 dark:border-rose-800/40 text-rose-700 dark:text-rose-300 text-xs font-medium">
            {formError}
          </div>
        )}
        <ImageUploadInput
          value={values.imagePath}
          onChange={(imagePath) => onChange({ ...values, imagePath })}
          label="Photo de l'article"
        />

        <div>
          <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
            Désignation / Nom de l'Article *
          </label>
          <input
            type="text"
            required
            value={values.name}
            onChange={(e) => onChange({ ...values, name: e.target.value })}
            placeholder="Ex: Coca-Cola 33cl"
            className="input-toc"
          />
        </div>

        <div>
          <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
            Catégorie / Rayon
          </label>
          <select
            value={values.categoryId}
            onChange={(e) => onChange({ ...values, categoryId: e.target.value })}
            className="input-toc bg-white dark:bg-dark-700"
          >
            <option value="">Sélectionner une catégorie (optionnel)...</option>
            {categories.map((c) => (
              <option key={c.sync_id} value={c.sync_id}>
                {c.name}
              </option>
            ))}
          </select>
        </div>

        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Prix de Vente (F CFA) *
            </label>
            <input
              type="number"
              min="0"
              required
              value={values.price}
              onChange={(e) => onChange({ ...values, price: Number(e.target.value) })}
              className="input-toc font-bold font-mono"
            />
          </div>
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Coût d'Achat (F CFA)
            </label>
            <input
              type="number"
              min="0"
              value={values.costPrice}
              onChange={(e) => onChange({ ...values, costPrice: Number(e.target.value) })}
              className="input-toc font-bold font-mono"
            />
          </div>
        </div>

        <div className="grid grid-cols-3 gap-3">
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Stock Initial
            </label>
            <input
              type="number"
              min="0"
              value={values.stock}
              onChange={(e) => onChange({ ...values, stock: Number(e.target.value) })}
              className="input-toc font-bold font-mono"
            />
          </div>
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Seuil Alerte
            </label>
            <input
              type="number"
              min="0"
              value={values.minStock}
              onChange={(e) => onChange({ ...values, minStock: Number(e.target.value) })}
              className="input-toc font-bold font-mono"
            />
          </div>
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Unité
            </label>
            <input
              type="text"
              value={values.unit}
              onChange={(e) => onChange({ ...values, unit: e.target.value })}
              placeholder="pièce, kg, carton..."
              className="input-toc"
            />
          </div>
        </div>

        <div>
          <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
            Code-barres / EAN
          </label>
          <input
            type="text"
            value={values.barcode}
            onChange={(e) => onChange({ ...values, barcode: e.target.value })}
            placeholder="Ex: 3017620422003 (optionnel)"
            className="input-toc font-mono"
          />
        </div>
      </form>
    )}
  </Drawer>
);
