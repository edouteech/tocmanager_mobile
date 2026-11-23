import React, { useEffect, useState } from 'react';
import { keepPreviousData, useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { PackagePlus, Plus, DollarSign, Layers } from 'lucide-react';
import { approvisionnementsApi, productsApi, suppliersApi } from '../../lib/api';
import { formatFCFA } from '../../lib/formatters';
import { PaginationControls } from '../../components/common/PaginationControls';
import { useTenantStore, useTenantContextKey } from '../../stores/tenantStore';
import { SuppliesTable } from './SuppliesTable';
import { SupplyFormState, SupplyReceptionDrawer } from './SupplyReceptionDrawer';

const INITIAL_SUPPLY_FORM: SupplyFormState = {
  product_sync_id: '',
  supplier_sync_id: '',
  quantity: 1,
  unit_cost: 0,
  payment_status: 'Payé',
  notes: '',
};

export const SuppliesPage: React.FC = () => {
  const queryClient = useQueryClient();
  const [boutiqueKey, magasinKey] = useTenantContextKey();
  const { magasins, currentMagasin, isConsolidatedView } = useTenantStore();
  const [targetMagasinId, setTargetMagasinId] = useState<string>('');
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);
  const [page, setPage] = useState(1);
  const [limit, setLimit] = useState(50);
  const [form, setForm] = useState<SupplyFormState>(INITIAL_SUPPLY_FORM);
  const [formError, setFormError] = useState<string | null>(null);

  useEffect(() => {
    setPage(1);
  }, [boutiqueKey, magasinKey]);

  const { data: suppliesPage, isLoading, isFetching } = useQuery({
    queryKey: ['approvisionnements', boutiqueKey, magasinKey, page, limit],
    queryFn: () => approvisionnementsApi.getPaginated({ page, limit }),
    placeholderData: keepPreviousData,
  });
  const supplies = suppliesPage?.items ?? [];
  const supplySummary = suppliesPage?.summary;

  const { data: products = [] } = useQuery({
    queryKey: ['products', boutiqueKey, magasinKey, 'supply-select'],
    queryFn: () => productsApi.getAll({ limit: 500 }),
  });

  const { data: suppliers = [] } = useQuery({
    queryKey: ['suppliers', boutiqueKey, magasinKey],
    queryFn: () => suppliersApi.getAll(),
  });

  const createMutation = useMutation({
    mutationFn: approvisionnementsApi.create,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['approvisionnements'] });
      queryClient.invalidateQueries({ queryKey: ['products'] });
      queryClient.invalidateQueries({ queryKey: ['suppliers'] });
      setIsDrawerOpen(false);
      setForm(INITIAL_SUPPLY_FORM);
      setFormError(null);
    },
  });

  const handleProductChange = (prodSyncId: string) => {
    const selectedProd = products.find((p) => p.sync_id === prodSyncId);
    setForm((prev) => ({
      ...prev,
      product_sync_id: prodSyncId,
      unit_cost: selectedProd?.cost_price || 0,
    }));
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);
    if (!form.product_sync_id) {
      setFormError('Veuillez sélectionner un article.');
      return;
    }
    if (form.quantity <= 0) {
      setFormError('La quantité reçue doit être supérieure à 0.');
      return;
    }

    const prod = products.find((p) => p.sync_id === form.product_sync_id);
    const sup = suppliers.find((s) => s.sync_id === form.supplier_sync_id);
    const chosenMagasinId =
      isConsolidatedView && magasins.length > 1 ? targetMagasinId : currentMagasin?.id;
    if (isConsolidatedView && magasins.length > 1 && !chosenMagasinId) {
      setFormError('Veuillez sélectionner le magasin de réception.');
      return;
    }

    createMutation.mutate({
      magasin_id: chosenMagasinId || undefined,
      product_sync_id: form.product_sync_id,
      product_name: prod?.name,
      supplier_sync_id: form.supplier_sync_id || undefined,
      supplier_name: sup?.name,
      quantity: form.quantity,
      unit_cost: form.unit_cost,
      payment_status: form.payment_status,
      notes: form.notes || undefined,
    });
  };

  const totalSupplyCost = supplySummary?.total_cost ?? supplies.reduce((sum, s) => sum + s.total_cost, 0);
  const totalQuantity = supplySummary?.total_quantity ?? supplies.reduce((sum, s) => sum + s.quantity, 0);
  const totalSupplyCount = supplySummary?.total_count ?? supplies.length;

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      <div className="flex flex-col sm:flex-row justify-between items-stretch sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">
            Approvisionnements
          </h1>
          <p className="text-xs sm:text-sm text-[#5A7184] dark:text-slate-400 mt-0.5">
            Réceptions de marchandises et suivi des achats fournisseurs
          </p>
        </div>
        <button
          onClick={() => {
            setForm(INITIAL_SUPPLY_FORM);
            setFormError(null);
            setIsDrawerOpen(true);
          }}
          className="btn-primary flex items-center justify-center gap-2 text-xs font-bold"
        >
          <Plus className="w-4 h-4" />
          <span>Nouvel Approvisionnement</span>
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
        <div className="card-toc card-hover p-5">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                Coût Total Réceptions
              </p>
              <p className="text-2xl font-extrabold text-slate-900 dark:text-white mt-1 font-mono">
                {formatFCFA(totalSupplyCost)}
              </p>
            </div>
            <div className="w-10 h-10 rounded-xl bg-brand-50 dark:bg-brand-500/15 text-brand-600 dark:text-brand-400 flex items-center justify-center border border-brand-200 dark:border-brand-500/30">
              <DollarSign className="w-5 h-5" />
            </div>
          </div>
          <p className="text-xs text-slate-400 dark:text-slate-500 mt-3">Investissement d'approvisionnement</p>
        </div>

        <div className="card-toc card-hover p-5">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                Quantités Totales Reçues
              </p>
              <p className="text-2xl font-extrabold text-slate-900 dark:text-white mt-1">{totalQuantity}</p>
            </div>
            <div className="w-10 h-10 rounded-xl bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 flex items-center justify-center border border-emerald-100 dark:border-emerald-800/40">
              <Layers className="w-5 h-5" />
            </div>
          </div>
          <p className="text-xs text-slate-400 dark:text-slate-500 mt-3">Unités réceptionnées en stock</p>
        </div>

        <div className="card-toc card-hover p-5">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider">
                Bons de Réception
              </p>
              <p className="text-2xl font-extrabold text-slate-900 dark:text-white mt-1">{totalSupplyCount}</p>
            </div>
            <div className="w-10 h-10 rounded-xl bg-amber-50 dark:bg-amber-950/40 text-amber-600 dark:text-amber-400 flex items-center justify-center border border-amber-100 dark:border-amber-900/50">
              <PackagePlus className="w-5 h-5" />
            </div>
          </div>
          <p className="text-xs text-slate-400 dark:text-slate-500 mt-3">Opérations d'entrée répertoriées</p>
        </div>
      </div>

      <SuppliesTable supplies={supplies} isLoading={isLoading} />

      <PaginationControls
        page={suppliesPage?.page || page}
        pages={suppliesPage?.pages || 1}
        total={suppliesPage?.total || 0}
        limit={limit}
        onPageChange={setPage}
        onLimitChange={(nextLimit) => {
          setLimit(nextLimit);
          setPage(1);
        }}
        itemLabel="réceptions"
        isFetching={isFetching}
      />

      <SupplyReceptionDrawer
        isOpen={isDrawerOpen}
        onClose={() => setIsDrawerOpen(false)}
        form={form}
        onChange={setForm}
        onProductChange={handleProductChange}
        onSubmit={handleSubmit}
        isSubmitting={createMutation.isPending}
        formError={formError}
        showMagasinSelector={isConsolidatedView && magasins.length > 1}
        magasins={magasins}
        targetMagasinId={targetMagasinId}
        onTargetMagasinChange={setTargetMagasinId}
        products={products}
        suppliers={suppliers}
      />
    </div>
  );
};
