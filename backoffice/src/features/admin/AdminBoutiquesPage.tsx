import React, { useEffect, useState } from 'react';
import { adminApi } from '../../lib/api';
import { Store, ShieldCheck, Clock, User, Phone, CheckCircle, XCircle } from 'lucide-react';

export const AdminBoutiquesPage: React.FC = () => {
  const [boutiques, setBoutiques] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchBoutiques = () => {
    setLoading(true);
    adminApi
      .getBoutiques()
      .then((data) => setBoutiques(data))
      .catch((e) => console.error(e))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    fetchBoutiques();
  }, []);

  const handleToggleStatus = async (id: string, currentStatus: boolean) => {
    try {
      await adminApi.toggleBoutiqueStatus(id, !currentStatus);
      fetchBoutiques();
    } catch (e) {
      alert('Erreur lors du changement de statut');
    }
  };

  const handleExtendTrial = async (id: string) => {
    const days = prompt("Nombre de jours d'essai supplémentaires à accorder :", "14");
    if (!days) return;
    try {
      await adminApi.extendTrial(id, parseInt(days, 10));
      alert(`Essai gratuit prolongé de ${days} jours avec succès !`);
      fetchBoutiques();
    } catch (e) {
      alert("Erreur lors de la prolongation de l'essai");
    }
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      <div>
        <h1 className="text-2xl font-black text-slate-900 dark:text-white">Annuaire des Boutiques Clientes</h1>
        <p className="text-xs text-slate-500 mt-0.5">
          Surveillez les comptes commerçants, les souscriptions, les points de vente et accordez des extensions d'essai.
        </p>
      </div>

      <div className="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse text-xs">
            <thead>
              <tr className="bg-slate-50 dark:bg-slate-800/60 border-b border-slate-200 dark:border-slate-800 text-slate-500 font-bold uppercase tracking-wider">
                <th className="py-3.5 px-4">Boutique & Entreprise</th>
                <th className="py-3.5 px-4">Propriétaire</th>
                <th className="py-3.5 px-4">Points de Vente</th>
                <th className="py-3.5 px-4">Forfait / Statut</th>
                <th className="py-3.5 px-4">Statut Compte</th>
                <th className="py-3.5 px-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
              {loading ? (
                <tr>
                  <td colSpan={6} className="py-12 text-center text-slate-400">
                    Chargement des boutiques...
                  </td>
                </tr>
              ) : boutiques.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-12 text-center text-slate-400">
                    Aucune boutique enregistrée pour le moment.
                  </td>
                </tr>
              ) : (
                boutiques.map((b) => (
                  <tr key={b.id} className="hover:bg-slate-50/50 dark:hover:bg-slate-800/40 transition">
                    <td className="py-4 px-4">
                      <div className="font-bold text-slate-900 dark:text-white">{b.name}</div>
                      <div className="text-[11px] text-slate-500">
                        {b.company_name} • {b.country} ({b.currency})
                      </div>
                    </td>
                    <td className="py-4 px-4">
                      <div className="font-medium text-slate-800 dark:text-slate-200">{b.owner_name}</div>
                      <div className="text-[11px] text-slate-500">{b.owner_email}</div>
                    </td>
                    <td className="py-4 px-4">
                      <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full font-semibold bg-indigo-50 dark:bg-indigo-950/60 text-indigo-700 dark:text-indigo-400">
                        <Store className="w-3 h-3" />
                        {b.magasin_count} magasin(s)
                      </span>
                    </td>
                    <td className="py-4 px-4">
                      <div className="font-bold text-slate-800 dark:text-slate-200">
                        {b.subscription?.plan_name}
                      </div>
                      {b.subscription?.status === 'trialing' ? (
                        <span className="text-[10px] text-amber-600 dark:text-amber-400 font-semibold flex items-center gap-1 mt-0.5">
                          <Clock className="w-3 h-3" /> Essai en cours
                        </span>
                      ) : (
                        <span className="text-[10px] text-emerald-600 font-semibold uppercase">
                          {b.subscription?.status}
                        </span>
                      )}
                    </td>
                    <td className="py-4 px-4">
                      {b.is_active ? (
                        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold bg-emerald-100 text-emerald-700">
                          <CheckCircle className="w-3 h-3" /> Actif
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-bold bg-rose-100 text-rose-700">
                          <XCircle className="w-3 h-3" /> Suspendu
                        </span>
                      )}
                    </td>
                    <td className="py-4 px-4 text-right space-x-2">
                      <button
                        onClick={() => handleExtendTrial(b.id)}
                        className="px-2.5 py-1 text-[11px] font-medium rounded-lg bg-amber-50 dark:bg-amber-950 text-amber-700 dark:text-amber-400 hover:bg-amber-100 transition"
                      >
                        + Prolongation Essai
                      </button>
                      <button
                        onClick={() => handleToggleStatus(b.id, b.is_active)}
                        className={`px-2.5 py-1 text-[11px] font-medium rounded-lg transition ${
                          b.is_active
                            ? 'bg-rose-50 dark:bg-rose-950 text-rose-700 dark:text-rose-400 hover:bg-rose-100'
                            : 'bg-emerald-50 dark:bg-emerald-950 text-emerald-700 dark:text-emerald-400 hover:bg-emerald-100'
                        }`}
                      >
                        {b.is_active ? 'Suspendre' : 'Réactiver'}
                      </button>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
