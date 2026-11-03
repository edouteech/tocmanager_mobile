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
} from 'lucide-react';
import { api } from '../../lib/api';
import { UserBrief } from '../../types';
import { Modal } from '../../components/common/Modal';
import { useDensity } from '../../context/DensityContext';

export const UsersPage: React.FC = () => {
  const queryClient = useQueryClient();
  const { tableClasses } = useDensity();
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);

  // Form state
  const [username, setUsername] = useState('');
  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [role, setRole] = useState<'admin' | 'manager' | 'cashier'>('cashier');
  const [pin, setPin] = useState('');
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
    setFormError(null);
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
    });
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Title & Actions */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-slate-900 dark:text-white tracking-tight">
            Utilisateurs & Rôles
          </h1>
          <p className="text-xs sm:text-sm text-slate-500 dark:text-slate-400 mt-1">
            Gestion des accès centralisés et des identifiants/codes PIN de déverrouillage caisse.
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

      {/* Users Table with Density */}
      <div className="card-toc overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead className="bg-[#F5FAFD] dark:bg-dark-700/50 border-b border-[#E8EFF5] dark:border-dark-600">
              <tr>
                <th className={tableClasses.th}>Utilisateur</th>
                <th className={tableClasses.th}>Rôle Système</th>
                <th className={tableClasses.th}>Code PIN Caisse</th>
                <th className={tableClasses.th}>Statut Compte</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#E8EFF5] dark:divide-dark-600/60">
              {isLoading ? (
                <tr>
                  <td colSpan={4} className="px-6 py-12 text-center text-slate-400">
                    Chargement des utilisateurs...
                  </td>
                </tr>
              ) : (users || []).length > 0 ? (
                users?.map((u) => (
                  <tr key={u.id} className="hover:bg-brand-50/30 dark:hover:bg-dark-700/40 transition-colors">
                    <td className={tableClasses.td}>
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 rounded-xl bg-brand-50 dark:bg-brand-500/15 text-brand-600 dark:text-brand-400 border border-brand-200 dark:border-brand-500/30 flex items-center justify-center font-bold">
                          <UserCheck className="w-4 h-4" />
                        </div>
                        <div>
                          <div className="font-bold text-slate-900 dark:text-white">{u.full_name || u.username}</div>
                          <div className="text-xs text-slate-400">@{u.username}</div>
                        </div>
                      </div>
                    </td>
                    <td className={tableClasses.td}>
                      <span
                        className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold border ${
                          u.role === 'admin'
                            ? 'bg-purple-50 dark:bg-purple-950/40 text-purple-700 dark:text-purple-300 border-purple-200 dark:border-purple-800/40'
                            : u.role === 'manager'
                            ? 'bg-brand-50 dark:bg-brand-500/15 text-brand-700 dark:text-brand-300 border-brand-200 dark:border-brand-500/30'
                            : 'bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-300 border-emerald-200 dark:border-emerald-800/40'
                        }`}
                      >
                        <Shield className="w-3.5 h-3.5" />
                        <span>
                          {u.role === 'admin'
                            ? 'Administrateur'
                            : u.role === 'manager'
                            ? 'Gérant'
                            : 'Caissier'}
                        </span>
                      </span>
                    </td>
                    <td className={tableClasses.td}>
                      {u.has_pin ? (
                        <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-300 border border-emerald-100 dark:border-emerald-800/40">
                          <KeyRound className="w-3 h-3 text-emerald-600" />
                          <span>Actif (4-6 chiffres)</span>
                        </span>
                      ) : (
                        <span className="text-xs text-slate-400">Non configuré</span>
                      )}
                    </td>
                    <td className={tableClasses.td}>
                      <span className="inline-flex items-center gap-1.5 text-xs font-semibold text-emerald-600 dark:text-emerald-400">
                        <Check className="w-4 h-4" />
                        <span>Actif</span>
                      </span>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={4} className="px-6 py-12 text-center text-slate-400">
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
        subtitle="Renseignez les accès pour le backoffice et le code PIN caisse"
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
                Rôle Système *
              </label>
              <select
                value={role}
                onChange={(e) => setRole(e.target.value as any)}
                className="input-toc bg-white dark:bg-dark-700"
              >
                <option value="cashier">Caissier</option>
                <option value="manager">Gérant</option>
                <option value="admin">Administrateur</option>
              </select>
            </div>
          </div>

          <div className="p-4 bg-brand-50/50 dark:bg-dark-700/60 rounded-2xl border border-brand-100 dark:border-dark-600 space-y-2">
            <div className="flex items-center gap-2">
              <KeyRound className="w-4 h-4 text-brand-500" />
              <label className="text-xs font-bold uppercase tracking-wider text-slate-700 dark:text-slate-200">
                Code PIN Caisse (Optionnel)
              </label>
            </div>
            <p className="text-xs text-slate-500 dark:text-slate-400">
              Permet au caissier de déverrouiller rapidement le terminal sans ressaisir son mot de passe complet.
            </p>
            <input
              type="password"
              maxLength={6}
              value={pin}
              onChange={(e) => setPin(e.target.value)}
              placeholder="4 ou 6 chiffres (ex: 1234)"
              className="input-toc font-mono text-center tracking-widest text-lg font-bold"
            />
          </div>
        </form>
      </Modal>
    </div>
  );
};
