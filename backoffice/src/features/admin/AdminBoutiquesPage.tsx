import React, { useEffect, useState } from 'react';
import { Store, Clock, CheckCircle, XCircle } from 'lucide-react';
import { adminApi } from '../../lib/api';
import { useDensity } from '../../context/DensityContext';

export const AdminBoutiquesPage: React.FC = () => {
  const { tableClasses } = useDensity();
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
    } catch {
      alert('Erreur lors du changement de statut');
    }
  };

  const handleExtendTrial = async (id: string) => {
    const days = prompt("Nombre de jours d'essai supplémentaires à accorder :", '14');
    if (!days) return;
    try {
      await adminApi.extendTrial(id, parseInt(days, 10));
      alert(`Essai gratuit prolongé de ${days} jours avec succès !`);
      fetchBoutiques();
    } catch {
      alert("Erreur lors de la prolongation de l'essai");
    }
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      <div>
        <h1 className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">
          Annuaire des Boutiques Clientes
        </h1>
        <p className="text-xs sm:text-sm text-[#5A7184] dark:text-slate-400 mt-0.5">
          Surveillez les comptes commerçants, les souscriptions, les points de vente et accordez des extensions d'essai.
        </p>
      </div>

      <div className="card-toc overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse text-xs">
            <thead>
              <tr className="bg-[#F0F9FE] dark:bg-dark-700/60 border-b border-[#E8EFF5] dark:border-dark-600 text-[#5A7184] font-bold uppercase tracking-wider">
                <th className={tableClasses.th}>Boutique & Entreprise</th>
                <th className={tableClasses.th}>Propriétaire</th>
                <th className={tableClasses.th}>Points de Vente</th>
                <th className={tableClasses.th}>Forfait / Statut</th>
                <th className={tableClasses.th}>Statut Compte</th>
                <th className={`${tableClasses.th} text-right`}>Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#E8EFF5] dark:divide-dark-600">
              {loading ? (
                <tr>
                  <td colSpan={6} className="py-12 text-center text-[#5A7184]">
                    Chargement des boutiques...
                  </td>
                </tr>
              ) : boutiques.length === 0 ? (
                <tr>
                  <td colSpan={6} className="py-12 text-center text-[#5A7184]">
                    Aucune boutique enregistrée pour le moment.
                  </td>
                </tr>
              ) : (
                boutiques.map((b) => (
                  <tr key={b.id} className="hover:bg-[#F0F9FE]/40 dark:hover:bg-dark-700/40 transition">
                    <td className={tableClasses.td}>
                      <div className="font-bold text-[#1C2B3A] dark:text-white">{b.name}</div>
                      <div className="text-[11px] text-[#5A7184] dark:text-slate-400">
                        {b.company_name} • {b.country} ({b.currency})
                      </div>
                    </td>
                    <td className={tableClasses.td}>
                      <div className="font-medium text-[#1C2B3A] dark:text-slate-200">{b.owner_name}</div>
                      <div className="text-[11px] text-[#5A7184] dark:text-slate-400">{b.owner_email}</div>
                    </td>
                    <td className={tableClasses.td}>
                      <span className="badge-toc-primary">
                        <Store className="w-3 h-3" />
                        {b.magasin_count} magasin(s)
                      </span>
                    </td>
                    <td className={tableClasses.td}>
                      <div className="font-bold text-[#1C2B3A] dark:text-slate-200">
                        {b.subscription?.plan_name}
                      </div>
                      {b.subscription?.status === 'trialing' ? (
                        <span className="text-[10px] text-[#F39C12] font-semibold flex items-center gap-1 mt-0.5">
                          <Clock className="w-3 h-3" /> Essai en cours
                        </span>
                      ) : (
                        <span className="text-[10px] text-[#27AE60] font-semibold uppercase">
                          {b.subscription?.status}
                        </span>
                      )}
                    </td>
                    <td className={tableClasses.td}>
                      {b.is_active ? (
                        <span className="badge-toc-success text-[10px]">
                          <CheckCircle className="w-3 h-3" /> Actif
                        </span>
                      ) : (
                        <span className="badge-toc-danger text-[10px]">
                          <XCircle className="w-3 h-3" /> Suspendu
                        </span>
                      )}
                    </td>
                    <td className={`${tableClasses.td} text-right space-x-2`}>
                      <button
                        type="button"
                        onClick={() => handleExtendTrial(b.id)}
                        className="px-2.5 py-1 text-[11px] font-semibold rounded-xl bg-[#FEF5E7] text-[#F39C12] hover:opacity-90 transition"
                      >
                        + Prolongation Essai
                      </button>
                      <button
                        type="button"
                        onClick={() => handleToggleStatus(b.id, b.is_active)}
                        className={`px-2.5 py-1 text-[11px] font-semibold rounded-xl transition ${
                          b.is_active
                            ? 'bg-[#FDEBE9] text-[#E74C3C] hover:opacity-90'
                            : 'bg-[#E8F8F0] text-[#27AE60] hover:opacity-90'
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
