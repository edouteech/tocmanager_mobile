import React from 'react';
import { Store, Clock, CheckCircle, XCircle, Eye, Shield } from 'lucide-react';
import { AdminBoutiqueItem } from '../../types';
import { useDensity } from '../../context/DensityContext';

interface AdminBoutiquesTableProps {
  boutiques: AdminBoutiqueItem[];
  loading: boolean;
  onDetail: (boutiqueId: string) => void;
  onAssignPlan: (boutique: AdminBoutiqueItem) => void;
  onExtendTrial: (boutique: AdminBoutiqueItem) => void;
  onToggleStatus: (boutique: AdminBoutiqueItem) => void;
}

export const AdminBoutiquesTable: React.FC<AdminBoutiquesTableProps> = ({
  boutiques,
  loading,
  onDetail,
  onAssignPlan,
  onExtendTrial,
  onToggleStatus,
}) => {
  const { tableClasses } = useDensity();

  return (
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
                  Aucune boutique correspondante.
                </td>
              </tr>
            ) : (
              boutiques.map((b) => (
                <tr key={b.id} className="hover:bg-[#F0F9FE]/40 dark:hover:bg-dark-700/40 transition">
                  <td className={tableClasses.td}>
                    <div className="font-bold text-[#1C2B3A] dark:text-white">{b.name}</div>
                    <div className="text-[11px] text-[#5A7184]">
                      {b.company_name} • {b.country} ({b.currency})
                    </div>
                  </td>
                  <td className={tableClasses.td}>
                    <div className="font-medium text-[#1C2B3A] dark:text-slate-200">{b.owner_name}</div>
                    <div className="text-[11px] text-[#5A7184]">{b.owner_email}</div>
                  </td>
                  <td className={tableClasses.td}>
                    <span className="badge-toc-primary">
                      <Store className="w-3 h-3" /> {b.magasin_count}
                    </span>
                  </td>
                  <td className={tableClasses.td}>
                    <div className="font-bold">{b.subscription?.plan_name}</div>
                    <span className="text-[10px] text-[#29ABE2] font-semibold inline-flex items-center gap-1">
                      <Clock className="w-3 h-3" /> {b.subscription?.status}
                    </span>
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
                  <td className={`${tableClasses.td} text-right space-x-1.5 whitespace-nowrap`}>
                    <button
                      type="button"
                      onClick={() => onDetail(b.id)}
                      className="px-2 py-1 rounded-lg bg-[#E8F5FD] text-[#29ABE2] font-semibold text-[11px]"
                    >
                      <Eye className="w-3.5 h-3.5 inline mr-1" />
                      Fiche
                    </button>
                    <button
                      type="button"
                      onClick={() => onAssignPlan(b)}
                      className="px-2 py-1 rounded-lg bg-[#F5EEF8] text-[#8E44AD] font-semibold text-[11px]"
                    >
                      <Shield className="w-3 h-3 inline mr-1" />
                      Forfait
                    </button>
                    <button
                      type="button"
                      onClick={() => onExtendTrial(b)}
                      className="px-2 py-1 rounded-lg bg-[#FEF5E7] text-[#F39C12] font-semibold text-[11px]"
                    >
                      + Essai
                    </button>
                    <button
                      type="button"
                      onClick={() => onToggleStatus(b)}
                      className={`px-2 py-1 rounded-lg font-semibold text-[11px] ${
                        b.is_active ? 'bg-[#FDEBE9] text-[#E74C3C]' : 'bg-[#E8F8F0] text-[#27AE60]'
                      }`}
                    >
                      {b.is_active ? 'Suspendre' : 'Activer'}
                    </button>
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
};
