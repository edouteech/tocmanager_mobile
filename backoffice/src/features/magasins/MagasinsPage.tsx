import React, { useState, useEffect } from 'react';
import { Store, Plus, MapPin, Phone, Building2, Edit2, Power } from 'lucide-react';
import { tenantApi } from '../../lib/api';
import { Magasin } from '../../types';
import { useTenantStore } from '../../stores/tenantStore';
import { useToast } from '../../context/ToastContext';
import { MagasinFormModal } from './MagasinFormModal';

export const MagasinsPage: React.FC = () => {
  const toast = useToast();
  const { currentBoutique, currentPlan, openUpgradeModal, fetchMagasins, fetchPlanStatus } =
    useTenantStore();
  const [magasins, setMagasins] = useState<Magasin[]>([]);
  const [loading, setLoading] = useState(true);
  const [modalOpen, setModalOpen] = useState(false);
  const [editingMagasin, setEditingMagasin] = useState<Magasin | null>(null);
  const [submitting, setSubmitting] = useState(false);

  const loadData = async () => {
    setLoading(true);
    try {
      const data = await tenantApi.getMagasins();
      setMagasins(data);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, [currentBoutique?.id]);

  const handleOpenAddModal = () => {
    if (
      currentPlan &&
      currentPlan.magasins_limit !== -1 &&
      magasins.length >= currentPlan.magasins_limit
    ) {
      openUpgradeModal({
        title: 'Limite de Points de Vente Atteinte',
        message: `Votre forfait actuel (${currentPlan.plan_name}) est limité à ${currentPlan.magasins_limit} magasin(s). Passez au forfait supérieur pour ouvrir et connecter de nouvelles succursales.`,
        featureCode: 'max_magasins',
      });
      return;
    }
    setEditingMagasin(null);
    setModalOpen(true);
  };

  const handleOpenEditModal = (magasin: Magasin) => {
    setEditingMagasin(magasin);
    setModalOpen(true);
  };

  const handleSubmitModal = async (payload: {
    name: string;
    code?: string;
    address?: string;
    phone?: string;
    is_warehouse: boolean;
  }) => {
    setSubmitting(true);
    try {
      if (editingMagasin) {
        await tenantApi.updateMagasin(editingMagasin.id, payload);
      } else {
        await tenantApi.createMagasin(payload);
      }
      setModalOpen(false);
      await loadData();
      await fetchMagasins();
      await fetchPlanStatus();
    } catch (err: any) {
      if (err.response?.status === 403) {
        setModalOpen(false);
        openUpgradeModal({
          title: 'Limite de Points de Vente Atteinte',
          message:
            err.response.data?.detail?.message ||
            'Quota de magasins atteint pour votre formule.',
        });
      } else {
        toast.error(err.response?.data?.detail || "Erreur lors de l'enregistrement du magasin.");
      }
    } finally {
      setSubmitting(false);
    }
  };

  const handleToggleActive = async (magasin: Magasin) => {
    try {
      await tenantApi.updateMagasin(magasin.id, { is_active: !magasin.is_active });
      await loadData();
      await fetchMagasins();
      await fetchPlanStatus();
    } catch (err: any) {
      toast.error(err.response?.data?.detail || 'Impossible de modifier le statut de ce magasin.');
    }
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-black text-slate-900 dark:text-white flex items-center gap-2">
            <span>Points de Vente & Magasins</span>
            <span className="text-xs px-2.5 py-0.5 rounded-full bg-indigo-100 dark:bg-indigo-950/80 text-indigo-700 dark:text-indigo-300 font-bold">
              {magasins.length}{' '}
              {currentPlan?.magasins_limit !== -1 ? `/ ${currentPlan?.magasins_limit}` : ''}
            </span>
          </h1>
          <p className="text-xs text-slate-500 mt-1">
            Gérez vos boutiques physiques, caisses comptoir et réserves de stockage.
          </p>
        </div>

        <button
          onClick={handleOpenAddModal}
          className="inline-flex items-center gap-2 px-4 py-2.5 text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-xl shadow-sm transition"
        >
          <Plus className="w-4 h-4" />
          <span>Nouveau Magasin</span>
        </button>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
        {loading ? (
          <div className="col-span-full py-12 text-center text-slate-400">
            Chargement des points de vente...
          </div>
        ) : magasins.length === 0 ? (
          <div className="col-span-full py-12 text-center text-slate-400">
            Aucun magasin enregistré pour cette boutique.
          </div>
        ) : (
          magasins.map((m) => (
            <div
              key={m.id}
              className="bg-white dark:bg-slate-900 rounded-2xl p-6 border border-slate-200 dark:border-slate-800 shadow-sm hover:shadow-md transition space-y-4"
            >
              <div className="flex items-start justify-between">
                <div className="w-10 h-10 rounded-xl bg-indigo-50 dark:bg-indigo-950/60 text-indigo-600 flex items-center justify-center">
                  {m.is_warehouse ? (
                    <Building2 className="w-5 h-5" />
                  ) : (
                    <Store className="w-5 h-5" />
                  )}
                </div>
                <div className="flex items-center gap-1.5">
                  <span
                    className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${
                      m.is_warehouse
                        ? 'bg-purple-100 dark:bg-purple-950 text-purple-700 dark:text-purple-300'
                        : 'bg-emerald-100 dark:bg-emerald-950 text-emerald-700 dark:text-emerald-300'
                    }`}
                  >
                    {m.is_warehouse ? 'RÉSERVE / DÉPÔT' : 'POINT DE VENTE'}
                  </span>
                </div>
              </div>

              <div>
                <h3 className="text-base font-bold text-slate-900 dark:text-white">{m.name}</h3>
                {m.code && (
                  <span className="font-mono text-[11px] text-slate-400 dark:text-slate-500">
                    Code : {m.code}
                  </span>
                )}
              </div>

              <div className="space-y-1.5 text-xs text-slate-500 border-t border-slate-100 dark:border-slate-800 pt-3">
                <div className="flex items-center gap-2">
                  <MapPin className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                  <span>{m.address || 'Aucune adresse renseignée'}</span>
                </div>
                <div className="flex items-center gap-2">
                  <Phone className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                  <span>{m.phone || 'Non communiqué'}</span>
                </div>
              </div>

              <div className="flex items-center justify-between gap-2 pt-3 border-t border-slate-100 dark:border-slate-800">
                <button
                  type="button"
                  onClick={() => handleOpenEditModal(m)}
                  className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-bold bg-slate-100 hover:bg-slate-200 dark:bg-slate-800 dark:hover:bg-slate-700 text-slate-700 dark:text-slate-200 transition"
                >
                  <Edit2 className="w-3.5 h-3.5" />
                  <span>Modifier</span>
                </button>
                <button
                  type="button"
                  onClick={() => handleToggleActive(m)}
                  className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-bold transition ${
                    m.is_active
                      ? 'bg-emerald-50 text-emerald-700 hover:bg-emerald-100 dark:bg-emerald-950/40 dark:text-emerald-300'
                      : 'bg-rose-50 text-rose-700 hover:bg-rose-100 dark:bg-rose-950/40 dark:text-rose-300'
                  }`}
                >
                  <Power className="w-3.5 h-3.5" />
                  <span>{m.is_active ? 'Actif' : 'Inactif'}</span>
                </button>
              </div>
            </div>
          ))
        )}
      </div>

      <MagasinFormModal
        isOpen={modalOpen}
        editingMagasin={editingMagasin}
        defaultCode={`MAG-0${magasins.length + 1}`}
        submitting={submitting}
        onClose={() => setModalOpen(false)}
        onSubmit={handleSubmitModal}
      />
    </div>
  );
};
