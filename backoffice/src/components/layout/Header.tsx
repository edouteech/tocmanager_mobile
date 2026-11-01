import React from 'react';
import { LogOut, User as UserIcon, Shield } from 'lucide-react';
import { useAuthStore } from '../../stores/authStore';

export const Header: React.FC = () => {
  const { user, logout } = useAuthStore();

  const roleLabel =
    user?.role === 'admin'
      ? 'Administrateur'
      : user?.role === 'manager'
      ? 'Gérant'
      : 'Caissier';

  return (
    <header className="h-16 bg-white border-b border-slate-200 px-8 flex items-center justify-between sticky top-0 z-20">
      <div>
        <h1 className="text-base font-semibold text-slate-800">
          Système de Gestion Commerciale
        </h1>
      </div>

      <div className="flex items-center gap-4">
        {/* User profile summary */}
        <div className="flex items-center gap-3 pr-2 border-r border-slate-200">
          <div className="w-9 h-9 rounded-full bg-slate-100 flex items-center justify-center text-slate-600 border border-slate-200">
            <UserIcon className="w-4 h-4" />
          </div>
          <div>
            <div className="text-sm font-medium text-slate-800 leading-tight">
              {user?.full_name || user?.username}
            </div>
            <div className="text-xs text-slate-500 flex items-center gap-1 mt-0.5">
              <Shield className="w-3 h-3 text-indigo-600" />
              <span>{roleLabel}</span>
            </div>
          </div>
        </div>

        {/* Logout button */}
        <button
          onClick={logout}
          className="inline-flex items-center gap-2 px-3 py-1.5 text-sm font-medium text-slate-600 hover:text-rose-600 hover:bg-rose-50 rounded-lg transition-colors border border-transparent hover:border-rose-200"
          title="Se déconnecter"
        >
          <LogOut className="w-4 h-4" />
          <span>Déconnexion</span>
        </button>
      </div>
    </header>
  );
};
