import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  ShieldCheck,
  Search,
  Filter,
  RefreshCw,
  ShoppingCart,
  UserPlus,
  CreditCard,
  TrendingDown,
  PackagePlus,
  LogIn,
  KeyRound,
  FileText,
  Info,
} from 'lucide-react';
import { api } from '../../lib/api';
import { formatDateTime } from '../../lib/formatters';

interface AuditLogItem {
  id: string;
  user_id?: string;
  user_name?: string;
  action: string;
  entity_type?: string;
  entity_id?: string;
  details?: Record<string, any>;
  created_at: string;
}

interface AuditLogResponse {
  total: number;
  items: AuditLogItem[];
}

export const AuditLogsPage: React.FC = () => {
  const [selectedAction, setSelectedAction] = useState<string>('');
  const [searchTerm, setSearchTerm] = useState<string>('');
  const [selectedLog, setSelectedLog] = useState<AuditLogItem | null>(null);

  const { data, isLoading, refetch, isFetching } = useQuery<AuditLogResponse>({
    queryKey: ['audit-logs', selectedAction],
    queryFn: async () => {
      const params = new URLSearchParams();
      if (selectedAction) params.append('action', selectedAction);
      params.append('limit', '100');
      const res = await api.get(`/audit/logs?${params.toString()}`);
      return res.data;
    },
  });

  const getActionBadge = (action: string) => {
    switch (action) {
      case 'SALE_CREATE':
        return {
          label: 'Nouvelle Vente',
          icon: ShoppingCart,
          bg: 'bg-emerald-50 text-emerald-700 border-emerald-200',
        };
      case 'CLIENT_CREATE':
        return {
          label: 'Nouveau Client',
          icon: UserPlus,
          bg: 'bg-blue-50 text-blue-700 border-blue-200',
        };
      case 'DEBT_PAYMENT':
        return {
          label: 'Règlement Dette',
          icon: CreditCard,
          bg: 'bg-amber-50 text-amber-700 border-amber-200',
        };
      case 'EXPENSE_CREATE':
        return {
          label: 'Décaissement',
          icon: TrendingDown,
          bg: 'bg-rose-50 text-rose-700 border-rose-200',
        };
      case 'STOCK_SUPPLY':
        return {
          label: 'Approvisionnement',
          icon: PackagePlus,
          bg: 'bg-indigo-50 text-indigo-700 border-indigo-200',
        };
      case 'LOGIN':
        return {
          label: 'Connexion',
          icon: LogIn,
          bg: 'bg-purple-50 text-purple-700 border-purple-200',
        };
      case 'PIN_VERIFY':
      case 'PIN_UNLOCK':
        return {
          label: 'Déverrouillage PIN',
          icon: KeyRound,
          bg: 'bg-cyan-50 text-cyan-700 border-cyan-200',
        };
      default:
        return {
          label: action,
          icon: FileText,
          bg: 'bg-slate-100 text-slate-700 border-slate-200',
        };
    }
  };

  const filteredItems = (data?.items || []).filter((item) => {
    if (!searchTerm) return true;
    const term = searchTerm.toLowerCase();
    return (
      (item.user_name && item.user_name.toLowerCase().includes(term)) ||
      (item.action && item.action.toLowerCase().includes(term)) ||
      (item.entity_type && item.entity_type.toLowerCase().includes(term)) ||
      (item.entity_id && item.entity_id.toLowerCase().includes(term))
    );
  });

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <ShieldCheck className="w-6 h-6 text-indigo-600" />
            <h1 className="text-2xl font-bold text-slate-900">Journal d'Audit & Sécurité</h1>
          </div>
          <p className="text-sm text-slate-500 mt-1">
            Traçabilité complète de chaque action effectuée par les caissiers et administrateurs.
          </p>
        </div>
        <button
          onClick={() => refetch()}
          disabled={isFetching}
          className="inline-flex items-center gap-2 px-3.5 py-2 text-sm font-medium text-slate-700 bg-white border border-slate-300 rounded-lg hover:bg-slate-50 transition-colors shadow-sm disabled:opacity-50"
        >
          <RefreshCw className={`w-4 h-4 ${isFetching ? 'animate-spin' : ''}`} />
          Actualiser
        </button>
      </div>

      {/* Filters Bar */}
      <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1">
          <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
          <input
            type="text"
            placeholder="Rechercher par opérateur, entité ou référence..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-9 pr-4 py-2 border border-slate-200 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600"
          />
        </div>

        <div className="flex items-center gap-2">
          <Filter className="w-4 h-4 text-slate-400" />
          <select
            value={selectedAction}
            onChange={(e) => setSelectedAction(e.target.value)}
            className="border border-slate-200 rounded-lg px-3 py-2 text-sm text-slate-700 bg-white focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600"
          >
            <option value="">Toutes les actions</option>
            <option value="SALE_CREATE">Nouvelle Vente</option>
            <option value="CLIENT_CREATE">Nouveau Client</option>
            <option value="DEBT_PAYMENT">Règlement Dette</option>
            <option value="EXPENSE_CREATE">Décaissement</option>
            <option value="STOCK_SUPPLY">Approvisionnement</option>
            <option value="LOGIN">Connexion Système</option>
            <option value="PIN_VERIFY">Déverrouillage PIN</option>
          </select>
        </div>
      </div>

      {/* Audit Logs Table */}
      <div className="bg-white rounded-xl border border-slate-200 shadow-sm overflow-hidden">
        {isLoading ? (
          <div className="p-12 text-center text-slate-400">
            <RefreshCw className="w-6 h-6 animate-spin mx-auto mb-2 text-indigo-600" />
            <p className="text-sm font-medium">Chargement du journal d'audit...</p>
          </div>
        ) : filteredItems.length === 0 ? (
          <div className="p-12 text-center text-slate-400">
            <Info className="w-8 h-8 mx-auto mb-2 text-slate-300" />
            <p className="text-base font-semibold text-slate-700">Aucun enregistrement d'audit trouvé</p>
            <p className="text-sm text-slate-500 mt-1">
              Les futures opérations sur le mobile et le backoffice apparaîtront ici.
            </p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm">
              <thead className="bg-slate-50 border-b border-slate-200 text-slate-600 font-semibold text-xs uppercase tracking-wider">
                <tr>
                  <th className="py-3 px-4">Date & Heure</th>
                  <th className="py-3 px-4">Opérateur</th>
                  <th className="py-3 px-4">Action</th>
                  <th className="py-3 px-4">Entité / Cible</th>
                  <th className="py-3 px-4">Détails</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {filteredItems.map((item) => {
                  const badge = getActionBadge(item.action);
                  const Icon = badge.icon;
                  return (
                    <tr key={item.id} className="hover:bg-slate-50/70 transition-colors">
                      <td className="py-3 px-4 text-slate-600 whitespace-nowrap font-mono text-xs">
                        {formatDateTime(item.created_at)}
                      </td>
                      <td className="py-3 px-4 whitespace-nowrap">
                        <div className="flex items-center gap-2">
                          <div className="w-7 h-7 rounded-full bg-slate-200 text-slate-700 flex items-center justify-center font-bold text-xs uppercase">
                            {(item.user_name || 'U').substring(0, 2)}
                          </div>
                          <div>
                            <span className="font-medium text-slate-900 block leading-tight">
                              {item.user_name || 'Utilisateur inconnu'}
                            </span>
                            {item.user_id && (
                              <span className="text-[10px] text-slate-400 font-mono block">
                                ID: {item.user_id.substring(0, 8)}...
                              </span>
                            )}
                          </div>
                        </div>
                      </td>
                      <td className="py-3 px-4 whitespace-nowrap">
                        <span
                          className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-xs font-medium border ${badge.bg}`}
                        >
                          <Icon className="w-3.5 h-3.5" />
                          {badge.label}
                        </span>
                      </td>
                      <td className="py-3 px-4 text-slate-600 whitespace-nowrap">
                        <span className="capitalize font-medium text-slate-800">
                          {item.entity_type || 'Système'}
                        </span>
                        {item.entity_id && (
                          <span className="text-xs text-slate-400 block font-mono">
                            {item.entity_id.length > 15
                              ? `${item.entity_id.substring(0, 15)}...`
                              : item.entity_id}
                          </span>
                        )}
                      </td>
                      <td className="py-3 px-4">
                        {item.details ? (
                          <button
                            onClick={() => setSelectedLog(item)}
                            className="inline-flex items-center gap-1 text-xs text-indigo-600 font-medium hover:text-indigo-800 underline underline-offset-2"
                          >
                            <FileText className="w-3.5 h-3.5" />
                            Voir détails
                          </button>
                        ) : (
                          <span className="text-slate-400 text-xs">-</span>
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Details Modal */}
      {selectedLog && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40 backdrop-blur-sm p-4">
          <div className="bg-white rounded-xl shadow-xl max-w-lg w-full overflow-hidden border border-slate-200">
            <div className="p-4 border-b border-slate-100 flex items-center justify-between">
              <div className="flex items-center gap-2">
                <ShieldCheck className="w-5 h-5 text-indigo-600" />
                <h3 className="font-semibold text-slate-900 text-base">
                  Détails de l'Action d'Audit
                </h3>
              </div>
              <button
                onClick={() => setSelectedLog(null)}
                className="text-slate-400 hover:text-slate-600 text-sm font-bold p-1 rounded-lg hover:bg-slate-100"
              >
                ✕
              </button>
            </div>
            <div className="p-5 space-y-4">
              <div className="grid grid-cols-2 gap-3 text-xs bg-slate-50 p-3 rounded-lg border border-slate-200">
                <div>
                  <span className="text-slate-400 block font-medium">Opérateur :</span>
                  <span className="font-semibold text-slate-800">
                    {selectedLog.user_name || 'Inconnu'}
                  </span>
                </div>
                <div>
                  <span className="text-slate-400 block font-medium">Action :</span>
                  <span className="font-semibold text-slate-800">{selectedLog.action}</span>
                </div>
                <div>
                  <span className="text-slate-400 block font-medium">Date & Heure :</span>
                  <span className="font-semibold text-slate-800 font-mono">
                    {formatDateTime(selectedLog.created_at)}
                  </span>
                </div>
                <div>
                  <span className="text-slate-400 block font-medium">Cible :</span>
                  <span className="font-semibold text-slate-800 font-mono">
                    {selectedLog.entity_type} {selectedLog.entity_id ? `(#${selectedLog.entity_id.substring(0, 8)})` : ''}
                  </span>
                </div>
              </div>

              <div>
                <span className="text-xs font-semibold text-slate-700 block mb-1.5">
                  Données de l'événement (Payload) :
                </span>
                <pre className="bg-slate-950 text-slate-200 p-3 rounded-lg text-xs font-mono overflow-x-auto max-h-60">
                  {JSON.stringify(selectedLog.details, null, 2)}
                </pre>
              </div>
            </div>
            <div className="p-3 bg-slate-50 border-t border-slate-100 flex justify-end">
              <button
                onClick={() => setSelectedLog(null)}
                className="px-4 py-2 text-sm font-medium text-slate-700 bg-white border border-slate-300 rounded-lg hover:bg-slate-100"
              >
                Fermer
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
