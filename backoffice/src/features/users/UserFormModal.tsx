import React, { useEffect, useState } from 'react';
import { AlertCircle } from 'lucide-react';
import { Magasin, UserBrief } from '../../types';
import { Modal } from '../../components/common/Modal';

export interface UserFormPayload {
  username: string;
  full_name: string | null;
  email: string | null;
  password?: string;
  role: 'store_admin' | 'manager' | 'cashier';
  pin?: string | null;
  assigned_magasin_ids: string[];
}

interface UserFormModalProps {
  isOpen: boolean;
  onClose: () => void;
  editingUser: UserBrief | null;
  magasins: Magasin[];
  isSubmitting: boolean;
  externalError: string | null;
  onSubmit: (payload: UserFormPayload) => void;
}

const INPUT_LABEL =
  'block text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-1.5';

export const UserFormModal: React.FC<UserFormModalProps> = ({
  isOpen,
  onClose,
  editingUser,
  magasins,
  isSubmitting,
  externalError,
  onSubmit,
}) => {
  const isEditing = Boolean(editingUser);
  const isOwnerTarget = editingUser?.role === 'owner' || editingUser?.role === 'merchant';

  const [username, setUsername] = useState('');
  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [role, setRole] = useState<'store_admin' | 'manager' | 'cashier'>('cashier');
  const [pin, setPin] = useState('');
  const [assignedMagasins, setAssignedMagasins] = useState<string[]>([]);
  const [localError, setLocalError] = useState<string | null>(null);

  useEffect(() => {
    if (!isOpen) return;
    setLocalError(null);
    if (editingUser) {
      setUsername(editingUser.username);
      setFullName(editingUser.full_name || '');
      setEmail(editingUser.email || '');
      setPassword('');
      const normalized =
        editingUser.role === 'store_admin' || editingUser.role === 'manager'
          ? editingUser.role
          : 'cashier';
      setRole(normalized);
      setPin('');
      setAssignedMagasins(editingUser.assigned_magasin_ids || []);
    } else {
      setUsername('');
      setFullName('');
      setEmail('');
      setPassword('');
      setRole('cashier');
      setPin('');
      setAssignedMagasins([]);
    }
  }, [isOpen, editingUser]);

  const toggleMagasinAssign = (magasinId: string) => {
    setAssignedMagasins((prev) =>
      prev.includes(magasinId) ? prev.filter((id) => id !== magasinId) : [...prev, magasinId]
    );
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setLocalError(null);
    if (!isEditing && !username.trim()) {
      setLocalError("Le nom d'utilisateur est obligatoire.");
      return;
    }
    if ((!isEditing || password) && password.length < 6) {
      setLocalError('Le mot de passe doit comporter au moins 6 caractères.');
      return;
    }
    if (pin && ((pin.length !== 4 && pin.length !== 6) || !/^\d+$/.test(pin))) {
      setLocalError('Le code PIN doit comporter exactement 4 ou 6 chiffres.');
      return;
    }
    onSubmit({
      username: username.trim(),
      full_name: fullName.trim() || null,
      email: email.trim() || null,
      password: password || undefined,
      role,
      pin: pin || undefined,
      assigned_magasin_ids: assignedMagasins,
    });
  };

  const displayedError = localError || externalError;

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={
        isEditing
          ? `Modifier ${editingUser?.full_name || editingUser?.username}`
          : 'Créer un Nouvel Utilisateur'
      }
      subtitle="Renseignez les accès et affectez le collaborateur aux points de vente"
      footer={
        <>
          <button type="button" onClick={onClose} className="btn-secondary">
            Annuler
          </button>
          <button
            type="submit"
            form="user-crud-form"
            disabled={isSubmitting}
            className="btn-primary"
          >
            {isSubmitting ? 'Enregistrement...' : isEditing ? 'Mettre à jour' : 'Créer le compte'}
          </button>
        </>
      }
    >
      {displayedError && (
        <div className="mb-3 p-3 bg-rose-50 dark:bg-rose-950/40 border border-rose-200 dark:border-rose-900/50 rounded-xl flex items-start gap-2 text-rose-700 dark:text-rose-300 text-xs font-medium">
          <AlertCircle className="w-4 h-4 shrink-0 mt-0.5 text-rose-600" />
          <span>{displayedError}</span>
        </div>
      )}

      <form id="user-crud-form" onSubmit={handleSubmit} className="space-y-4">
        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className={INPUT_LABEL}>Nom d'utilisateur *</label>
            <input
              type="text"
              required={!isEditing}
              disabled={isEditing}
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              placeholder="Ex: caissier_nord"
              className="input-toc disabled:opacity-60"
            />
          </div>
          <div>
            <label className={INPUT_LABEL}>Nom complet</label>
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
          <label className={INPUT_LABEL}>Adresse Email</label>
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
            <label className={INPUT_LABEL}>
              {isEditing ? 'Nouveau mot de passe (optionnel)' : 'Mot de Passe *'}
            </label>
            <input
              type="password"
              required={!isEditing}
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              className="input-toc"
            />
          </div>
          <div>
            <label className={INPUT_LABEL}>
              {isEditing ? 'Nouveau PIN (optionnel)' : 'Code PIN (4 ou 6 chiffres)'}
            </label>
            <input
              type="password"
              maxLength={6}
              value={pin}
              onChange={(e) => setPin(e.target.value.replace(/\D/g, ''))}
              placeholder="Ex: 1234"
              className="input-toc font-mono"
            />
          </div>
        </div>

        {!isOwnerTarget && (
          <div>
            <label className={INPUT_LABEL}>Rôle du collaborateur</label>
            <select
              value={role}
              onChange={(e) => setRole(e.target.value as 'store_admin' | 'manager' | 'cashier')}
              className="input-toc"
            >
              <option value="cashier">Caissier (Ventes et caisse uniquement)</option>
              <option value="manager">Gérant de Magasin (Gestion des stocks et ventes)</option>
              <option value="store_admin">Administrateur Boutique (Tous droits)</option>
            </select>
          </div>
        )}

        <div>
          <label className={INPUT_LABEL}>Magasins Assignés (Points de Vente)</label>
          <div className="space-y-2 p-3 bg-[#F0F9FE] dark:bg-dark-700 rounded-xl border border-[#E8EFF5] dark:border-dark-600">
            {magasins.map((m) => (
              <label key={m.id} className="flex items-center gap-2 text-xs cursor-pointer">
                <input
                  type="checkbox"
                  checked={assignedMagasins.includes(m.id)}
                  onChange={() => toggleMagasinAssign(m.id)}
                  className="rounded text-[#29ABE2]"
                />
                <span className="font-medium text-[#1C2B3A] dark:text-slate-200">{m.name}</span>
                {m.is_warehouse && <span className="text-[10px] text-[#5A7184]">(Dépôt)</span>}
              </label>
            ))}
            {magasins.length === 0 && (
              <span className="text-xs text-[#5A7184]">Aucun magasin configuré.</span>
            )}
          </div>
          <span className="text-[11px] text-[#5A7184] mt-1 block">
            Si aucun magasin n'est coché, l'utilisateur aura accès à tous les magasins.
          </span>
        </div>
      </form>
    </Modal>
  );
};
