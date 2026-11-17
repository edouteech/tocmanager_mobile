import React, { useState, useEffect } from 'react';
import { Store, Plus, MapPin, Phone, Building2, CheckCircle, ShieldAlert, Sparkles, Layers } from 'lucide-react';
import { tenantApi } from '../../lib/api';
import { Magasin } from '../../types';
import { useTenantStore } from '../../stores/tenantStore';

export const MagasinsPage: React.FC = () => {
  const { currentPlan, openUpgradeModal, fetchMagasins } = useTenantStore();
  const [magasins, setMagasins] = useState<Magasin[]>([]);
  const [loading, setLoading] = useState(true);

  // Modal create/edit state
  const [modalOpen, setModalOpen] = useState(false);
  const [name, setName] = useState('');
  const [code, setCode] = useState('');
  const [address, setAddress] = useState('');
  const [phone, setPhone] = useState('');
  const [isWarehouse, setIsWarehouse] = useState(false);
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
  }, []);

  const handleOpenAddModal = () => {
    // Vérification du quota du plan
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

    setName('');
    setCode(`MAG-0${magasins.length + 1}`);
    setAddress('');
    setPhone('');
    setIsWarehouse(false);
    setModalOpen(true);
  };

  const handleCreateMagasin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) return;

    setSubmitting(true);
    try {
      await tenantApi.createMagasin({
        name: name.trim(),
        code: code.trim() || undefined,
        address: address.trim() || undefined,
        phone: phone.trim() || undefined,
        is_warehouse: isWarehouse,
      });
      setModalOpen(false);
      await loadData();
      await fetchMagasins();
    } catch (err: any) {
      if (err.response?.status === 403) {
        setModalOpen(false);
        openUpgradeModal({
          title: 'Limite de Points de Vente Atteinte',
          message: err.response.data?.detail?.message || 'Quota de magasins atteint pour votre formule.',
        });
      } else {
        alert(err.response?.data?.detail || 'Erreur lors de la création du magasin.');
      }
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Header section */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-black text-slate-900 dark:text-white flex items-center gap-2">
            <span>Points de Vente & Magasins</span>
            <span className="text-xs px-2.5 py-0.5 rounded-full bg-indigo-100 dark:bg-indigo-950/80 text-indigo-700 dark:text-indigo-300 font-bold">
              {magasins.length} {currentPlan?.magasins_limit !== -1 ? `/ ${currentPlan?.magasins_limit}` : ''}
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

      {/* Cartes des Magasins */}
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
                  {m.is_warehouse ? <Building2 className="w-5 h-5" /> : <Store className="w-5 h-5" />}
                </div>
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
            </div>
          ))
        )}
      </div>

      {/* Modal Création Magasin */}
      {modalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-fadeIn">
          <div className="bg-white dark:bg-slate-900 rounded-2xl p-6 max-w-md w-full border border-slate-200 dark:border-slate-800 shadow-2xl space-y-4">
            <h3 className="text-lg font-bold text-slate-900 dark:text-white">Ajouter un Magasin / Point de Vente</h3>

            <form onSubmit={handleCreateMagasin} className="space-y-3 text-xs">
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
                  onClick={() => setModalOpen(false)}
                  className="px-4 py-2 rounded-lg text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-800"
                >
                  Annuler
                </button>
                <button
                  type="submit"
                  disabled={submitting}
                  className="px-5 py-2 bg-indigo-600 hover:bg-indigo-700 text-white font-bold rounded-xl shadow transition"
                >
                  {submitting ? 'Création...' : 'Créer le magasin'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
