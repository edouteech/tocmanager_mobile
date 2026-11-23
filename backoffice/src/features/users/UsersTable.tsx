import React from 'react';
import { Check, Store, Edit2, Trash2, Power } from 'lucide-react';
import { Magasin, UserBrief } from '../../types';
import { useDensity } from '../../context/DensityContext';

interface UsersTableProps {
  users: UserBrief[];
  isLoading: boolean;
  currentUserId?: string;
  magasins: Magasin[];
  onEdit: (user: UserBrief) => void;
  onToggleActive: (user: UserBrief) => void;
  onDelete: (user: UserBrief) => void;
}

export const UsersTable: React.FC<UsersTableProps> = ({
  users,
  isLoading,
  currentUserId,
  magasins,
  onEdit,
  onToggleActive,
  onDelete,
}) => {
  const { tableClasses } = useDensity();

  const getMagasinNames = (ids?: string[]) => {
    if (!ids || ids.length === 0) return 'Tous les magasins';
    return ids.map((id) => magasins.find((m) => m.id === id)?.name || 'Magasin').join(', ');
  };

  return (
    <div className="card-toc overflow-hidden">
      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="border-b border-[#E8EFF5] dark:border-dark-600 bg-[#F0F9FE] dark:bg-dark-700/60">
              <th className={tableClasses.th}>Utilisateur</th>
              <th className={tableClasses.th}>Rôle</th>
              <th className={tableClasses.th}>Magasins Assignés</th>
              <th className={tableClasses.th}>PIN Caisse</th>
              <th className={tableClasses.th}>Statut</th>
              <th className={`${tableClasses.th} text-right`}>Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-[#E8EFF5] dark:divide-dark-600">
            {isLoading ? (
              <tr>
                <td colSpan={6} className="px-6 py-12 text-center text-[#5A7184]">
                  Chargement des utilisateurs...
                </td>
              </tr>
            ) : users.length > 0 ? (
              users.map((u) => {
                const isSelf = currentUserId === u.id;
                const isOwner = u.role === 'owner' || u.role === 'merchant';
                const active = u.is_active ?? true;
                return (
                  <tr key={u.id} className="hover:bg-[#F0F9FE]/40 dark:hover:bg-dark-700/40 transition">
                    <td className={tableClasses.td}>
                      <div className="font-bold text-[#1C2B3A] dark:text-white">
                        {u.full_name || u.username}
                        {isSelf && <span className="ml-2 text-[10px] text-[#29ABE2]">(Vous)</span>}
                      </div>
                      <div className="text-xs text-[#5A7184] dark:text-slate-400">
                        @{u.username} {u.email ? `• ${u.email}` : ''}
                      </div>
                    </td>
                    <td className={tableClasses.td}>
                      <span className="badge-toc-primary capitalize">{u.role}</span>
                    </td>
                    <td className={tableClasses.td}>
                      <div className="flex items-center gap-1.5 text-xs text-[#5A7184] dark:text-slate-300">
                        <Store className="w-3.5 h-3.5 text-[#29ABE2] shrink-0" />
                        <span className="font-medium">{getMagasinNames(u.assigned_magasin_ids)}</span>
                      </div>
                    </td>
                    <td className={tableClasses.td}>
                      {u.has_pin ? (
                        <span className="badge-toc-success w-max">
                          <Check className="w-3 h-3" /> Configuré
                        </span>
                      ) : (
                        <span className="text-xs text-[#9FB3C8]">Non défini</span>
                      )}
                    </td>
                    <td className={tableClasses.td}>
                      {active ? (
                        <span className="badge-toc-success">Actif</span>
                      ) : (
                        <span className="badge-toc-danger">Inactif</span>
                      )}
                    </td>
                    <td className={`${tableClasses.td} text-right`}>
                      <div className="inline-flex items-center justify-end gap-1">
                        {(!isOwner || isSelf) && (
                          <button
                            type="button"
                            onClick={() => onEdit(u)}
                            className="p-1.5 text-[#5A7184] hover:text-[#29ABE2] hover:bg-[#E8F5FD] dark:hover:bg-dark-700 rounded-xl transition"
                            title="Modifier l'utilisateur"
                          >
                            <Edit2 className="w-4 h-4" />
                          </button>
                        )}
                        {!isSelf && !isOwner && (
                          <>
                            <button
                              type="button"
                              onClick={() => onToggleActive(u)}
                              className="p-1.5 text-[#5A7184] hover:text-[#F39C12] hover:bg-[#FEF5E7] dark:hover:bg-dark-700 rounded-xl transition"
                              title={active ? 'Désactiver le compte' : 'Réactiver le compte'}
                            >
                              <Power className="w-4 h-4" />
                            </button>
                            <button
                              type="button"
                              onClick={() => onDelete(u)}
                              className="p-1.5 text-[#5A7184] hover:text-[#E74C3C] hover:bg-[#FDEBE9] dark:hover:bg-dark-700 rounded-xl transition"
                              title="Supprimer l'utilisateur"
                            >
                              <Trash2 className="w-4 h-4" />
                            </button>
                          </>
                        )}
                      </div>
                    </td>
                  </tr>
                );
              })
            ) : (
              <tr>
                <td colSpan={6} className="px-6 py-12 text-center text-[#5A7184]">
                  Aucun utilisateur trouvé.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
};
