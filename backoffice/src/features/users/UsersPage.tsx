import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  Users,
  UserPlus,
  Shield,
  KeyRound,
  Check,
  AlertCircle,
  UserCheck,
  Store,
} from 'lucide-react';
import { api } from '../../lib/api';
import { UserBrief } from '../../types';
import { Modal } from '../../components/common/Modal';
import { useDensity } from '../../context/DensityContext';
import { useTenantStore } from '../../stores/tenantStore';

export const UsersPage: React.FC = () => {
  const queryClient = useQueryClient();
  const { tableClasses } = useDensity();
  const { magasins } = useTenantStore();
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);

  // Form state
  const [username, setUsername] = useState('');
  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [role, setRole] = useState<'admin' | 'manager' | 'cashier'>('cashier');
  const [pin, setPin] = useState('');
  const [assignedMagasins, setAssignedMagasins] = useState<string[]>([]);
  const [formError, setFormError] = useState<string | null>(null);

  const { data: users, isLoading } = useQuery<UserBrief[]>({
    queryKey: ['users'],
    queryFn: async () => {
      const res = await api.get('/users');
      return res.data;
    },
  });

  const createUserMutation = useMutation({
    mutationFn: async (payload: any) => {
      return api.post('/users', payload);
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
      setIsCreateModalOpen(false);
      resetForm();
    },
    onError: (err: any) => {
      const msg = err.response?.data?.detail || "Erreur lors de la création de l'utilisateur.";
      setFormError(msg);
    },
  });

  const resetForm = () => {
    setUsername('');
    setFullName('');
    setEmail('');
    setPassword('');
    setRole('cashier');
    setPin('');
    setAssignedMagasins([]);
    setFormError(null);
  };

  const toggleMagasinAssign = (magasinId: string) => {
    if (assignedMagasins.includes(magasinId)) {
      setAssignedMagasins(assignedMagasins.filter((id) => id !== magasinId));
    } else {
      setAssignedMagasins([...assignedMagasins, magasinId]);
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);

    if (pin && (pin.length !== 4 && pin.length !== 6 || !/^\d+$/.test(pin))) {
      setFormError('Le code PIN doit comporter exactement 4 ou 6 chiffres numériques.');
      return;
    }

    createUserMutation.mutate({
      username,
      full_name: fullName || null,
      email: email || null,
      password,
      role,
      pin: pin || null,
      assigned_magasin_ids: assignedMagasins,
    });
  };

  const getMagasinNames = (ids?: string[]) => {
    if (!ids || ids.length === 0) return 'Tous les magasins';
    return ids
      .map((id) => magasins.find((m) => m.id === id)?.name || 'Magasin')
      .join(', ');
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Title & Actions */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">
            Utilisateurs & Affectations
          </h1>
          <p className="text-xs sm:text-sm text-[#5A7184] dark:text-slate-400 mt-1">
            Gestion du personnel et affectation aux magasins de la boutique
          </p>
        </div>

        <button
          onClick={() => {
            resetForm();
            setIsCreateModalOpen(true);
          }}
          className="btn-primary"
        >
          <UserPlus className="w-4 h-4" />
          <span>Nouvel Utilisateur</span>
        </button>
      </div>

      {/* Users Table */}
      <div className="card overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-[#E8EFF5] dark:border-dark-600 bg-[#F0F9FE]/50 dark:bg-dark-700/50">
                <th className={tableClasses.th}>Utilisateur</th>
                <th className={tableClasses.th}>Rôle</th>
                <th className={tableClasses.th}>Magasins Assignés</th>
                <th className={tableClasses.th}>PIN Caisse</th>
                <th className={tableClasses.th}>Statut</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#E8EFF5] dark:divide-dark-600">
              {isLoading ? (
                <tr>
                  <td colSpan={5} className="px-6 py-12 text-center text-slate-400">
                    Chargement des utilisateurs...
                  </td>
                </tr>
              ) : users && users.length > 0 ? (
                users.map((u) => (
                  <tr key={u.id} className="hover:bg-[#F0F9FE]/40 dark:hover:bg-dark-700/40 transition">
                    <td className={tableClasses.td}>
                      <div className="font-bold text-[#1C2B3A] dark:text-white">
                        {u.full_name || u.username}
                      </div>
                      <div className="text-xs text-[#5A7184] dark:text-slate-400">
                        @{u.username} {u.email ? `• ${u.email}` : ''}
                      </div>
                    </td>
                    <td className={tableClasses.td}>
                      <span className="badge-blue capitalize">{u.role}</span>
                    </td>
                    <td className={tableClasses.td}>
                      <div className="flex items-center gap-1.5 text-xs text-slate-600 dark:text-slate-300">
                        <Store className="w-3.5 h-3.5 text-indigo-500 shrink-0" />
                        <span className="font-medium">{getMagasinNames(u.assigned_magasin_ids)}</span>
                      </div>
                    </td>
                    <td className={tableClasses.td}>
                      {u.has_pin ? (
                        <span className="badge-emerald flex items-center gap-1 w-max">
                          <Check className="w-3 h-3" /> Configuré
                        </span>
                      ) : (
                        <span className="text-xs text-slate-400">Non défini</span>
                      )}
                    </td>
                    <td className={tableClasses.td}>
                      {u.is_active ? (
                        <span className="badge-emerald">Actif</span>
                      ) : (
                        <span className="badge-rose">Inactif</span>
                      )}
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={5} className="px-6 py-12 text-center text-slate-400">
                    Aucun utilisateur trouvé.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal Création Utilisateur */}
      <Modal
        isOpen={isCreateModalOpen}
        onClose={() => setIsCreateModalOpen(false)}
        title="Créer un Nouvel Utilisateur"
        subtitle="Renseignez les accès et affectez le collaborateur à un ou plusieurs magasins"
        footer={
          <>
            <button
              type="button"
              onClick={() => setIsCreateModalOpen(false)}
              className="btn-secondary"
            >
              Annuler
            </button>
            <button
              type="button"
              onClick={handleSubmit}
              disabled={createUserMutation.isPending}
              className="btn-primary"
            >
              {createUserMutation.isPending ? 'Création en cours...' : 'Créer le compte'}
            </button>
          </>
        }
      >
        {formError && (
          <div className="p-3.5 bg-rose-50 dark:bg-rose-950/40 border border-rose-200 dark:border-rose-900/50 rounded-2xl flex items-start gap-2.5 text-rose-700 dark:text-rose-300 text-xs font-medium">
            <AlertCircle className="w-4 h-4 shrink-0 mt-0.5 text-rose-600" />
            <span>{formError}</span>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Nom d'utilisateur *
              </label>
              <input
                type="text"
                required
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                placeholder="Ex: caissier_nord"
                className="input-toc"
              />
            </div>
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Nom complet
              </label>
              <input
                type="text"
                value={fullName}
                onChange={(e) => setFullName(e.target.value)}
                placeholder="Ex: Jean Koffi"
                className="input-toc"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Adresse Email
            </label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="koffi@magasin.com"
              className="input-toc"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Mot de Passe *
              </label>
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="input-toc"
              />
            </div>
            <div>
              <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
                Code PIN Caisse (4 ou 6 chiffres)
              </label>
              <input
                type="password"
                maxLength={6}
                value={pin}
                onChange={(e) => setPin(e.target.value)}
                placeholder="Ex: 1234"
                className="input-toc"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Rôle du collaborateur
            </label>
            <select
              value={role}
              onChange={(e) => setRole(e.target.value as any)}
              className="input-toc"
            >
              <option value="cashier">Caissier (Ventes et caisse uniquement)</option>
              <option value="manager">Gérant de Magasin (Gestion des stocks et ventes)</option>
              <option value="admin">Administrateur Boutique (Tous droits)</option>
            </select>
          </div>

          {/* Affectation aux Magasins */}
          <div>
            <label className="block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5">
              Magasins Assignés (Points de Vente)
            </label>
            <div className="space-y-2 p-3 bg-slate-50 dark:bg-slate-800 rounded-xl border border-slate-200 dark:border-slate-700">
              {magasins.map((m) => (
                <label key={m.id} className="flex items-center gap-2 text-xs cursor-pointer">
                  <input
                    type="checkbox"
                    checked={assignedMagasins.includes(m.id)}
                    onChange={() => toggleMagasinAssign(m.id)}
                    className="rounded text-indigo-600"
                  />
                  <span className="font-medium text-slate-800 dark:text-slate-200">{m.name}</span>
                  {m.is_warehouse && <span className="text-[10px] text-slate-400">(Dépôt)</span>}
                </label>
              ))}
              {magasins.length === 0 && (
                <span className="text-xs text-slate-400">Aucun magasin configuré.</span>
              )}
            </div>
            <span className="text-[11px] text-slate-400 mt-1 block">
              Si aucun magasin n'est coché, l'utilisateur aura accès à tous les magasins de la boutique.
            </span>
          </div>
        </form>
      </Modal>
    </div>
  );
};
