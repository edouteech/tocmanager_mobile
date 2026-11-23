import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { UserPlus, AlertCircle } from 'lucide-react';
import { usersApi } from '../../lib/api';
import { UserBrief } from '../../types';
import { useTenantStore, useTenantContextKey } from '../../stores/tenantStore';
import { useAuthStore } from '../../stores/authStore';
import { ConfirmModal } from '../../components/common/ConfirmModal';
import { UserFormModal, UserFormPayload } from './UserFormModal';
import { UsersTable } from './UsersTable';

export const UsersPage: React.FC = () => {
  const queryClient = useQueryClient();
  const { magasins } = useTenantStore();
  const [boutiqueKey, magasinKey] = useTenantContextKey();
  const currentUser = useAuthStore((s) => s.user);

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingUser, setEditingUser] = useState<UserBrief | null>(null);
  const [confirmDeleteUser, setConfirmDeleteUser] = useState<UserBrief | null>(null);
  const [formError, setFormError] = useState<string | null>(null);
  const [pageError, setPageError] = useState<string | null>(null);

  const { data: users = [], isLoading } = useQuery<UserBrief[]>({
    queryKey: ['users', boutiqueKey, magasinKey],
    queryFn: () => usersApi.getAll(),
  });

  const createMutation = useMutation({
    mutationFn: usersApi.create,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
      setIsModalOpen(false);
      setFormError(null);
    },
    onError: (err: any) => {
      setFormError(err.response?.data?.detail || "Erreur lors de la création de l'utilisateur.");
    },
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: Parameters<typeof usersApi.update>[1] }) =>
      usersApi.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
      setIsModalOpen(false);
      setEditingUser(null);
      setFormError(null);
      setPageError(null);
    },
    onError: (err: any) => {
      const msg = err.response?.data?.detail || "Erreur lors de la mise à jour de l'utilisateur.";
      setFormError(msg);
      setPageError(msg);
    },
  });

  const deleteMutation = useMutation({
    mutationFn: usersApi.delete,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['users'] });
      setPageError(null);
      setConfirmDeleteUser(null);
    },
    onError: (err: any) => {
      setPageError(err.response?.data?.detail || "Impossible de supprimer cet utilisateur.");
      setConfirmDeleteUser(null);
    },
  });

  const handleOpenCreate = () => {
    setEditingUser(null);
    setFormError(null);
    setIsModalOpen(true);
  };

  const handleOpenEdit = (u: UserBrief) => {
    setEditingUser(u);
    setFormError(null);
    setIsModalOpen(true);
  };

  const handleFormSubmit = (payload: UserFormPayload) => {
    if (editingUser) {
      updateMutation.mutate({
        id: editingUser.id,
        data: {
          full_name: payload.full_name,
          email: payload.email,
          role:
            editingUser.role === 'owner' || editingUser.role === 'merchant'
              ? undefined
              : payload.role,
          password: payload.password,
          pin: payload.pin,
          assigned_magasin_ids: payload.assigned_magasin_ids,
        },
      });
    } else {
      createMutation.mutate({
        username: payload.username,
        full_name: payload.full_name,
        email: payload.email,
        password: payload.password || '',
        role: payload.role,
        pin: payload.pin || null,
        assigned_magasin_ids: payload.assigned_magasin_ids,
      });
    }
  };

  const handleToggleActive = (u: UserBrief) => {
    setPageError(null);
    updateMutation.mutate({
      id: u.id,
      data: { is_active: !(u.is_active ?? true) },
    });
  };

  const handleDelete = (u: UserBrief) => {
    setConfirmDeleteUser(u);
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">
            Utilisateurs & Affectations
          </h1>
          <p className="text-xs sm:text-sm text-[#5A7184] dark:text-slate-400 mt-1">
            Gestion du personnel et affectation aux magasins de la boutique
          </p>
        </div>

        <button onClick={handleOpenCreate} className="btn-primary">
          <UserPlus className="w-4 h-4" />
          <span>Nouvel Utilisateur</span>
        </button>
      </div>

      {pageError && (
        <div className="p-3.5 rounded-xl bg-rose-50 dark:bg-rose-950/40 border border-rose-200 dark:border-rose-900/50 text-rose-700 dark:text-rose-300 text-xs font-medium flex items-center gap-2">
          <AlertCircle className="w-4 h-4 shrink-0" />
          <span>{pageError}</span>
        </div>
      )}

      <UsersTable
        users={users}
        isLoading={isLoading}
        currentUserId={currentUser?.id}
        magasins={magasins}
        onEdit={handleOpenEdit}
        onToggleActive={handleToggleActive}
        onDelete={handleDelete}
      />

      <UserFormModal
        isOpen={isModalOpen}
        onClose={() => {
          setIsModalOpen(false);
          setEditingUser(null);
          setFormError(null);
        }}
        editingUser={editingUser}
        magasins={magasins}
        isSubmitting={createMutation.isPending || updateMutation.isPending}
        externalError={formError}
        onSubmit={handleFormSubmit}
      />

      <ConfirmModal
        isOpen={Boolean(confirmDeleteUser)}
        onClose={() => setConfirmDeleteUser(null)}
        onConfirm={() => {
          if (confirmDeleteUser) {
            setPageError(null);
            deleteMutation.mutate(confirmDeleteUser.id);
          }
        }}
        title="Supprimer l'utilisateur"
        message={
          confirmDeleteUser
            ? `Confirmer la suppression définitive de "${confirmDeleteUser.full_name || confirmDeleteUser.username}" ?`
            : ''
        }
        confirmLabel="Supprimer"
        isPending={deleteMutation.isPending}
      />
    </div>
  );
};
