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
import { Modal } from '../../components/common/Modal';
import { useDensity } from '../../context/DensityContext';

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
  const { tableClasses } = useDensity();
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
          bg: 'bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-300 border-emerald-200 dark:border-emerald-800/40',
        };
      case 'CLIENT_CREATE':
        return {
          label: 'Nouveau Client',
          icon: UserPlus,
          bg: 'bg-brand-50 dark:bg-brand-500/15 text-brand-700 dark:text-brand-300 border-brand-200 dark:border-brand-500/30',
        };
      case 'DEBT_PAYMENT':
        return {
          label: 'Règlement Dette',
          icon: CreditCard,
          bg: 'bg-amber-50 dark:bg-amber-950/40 text-amber-700 dark:text-amber-300 border-amber-200 dark:border-amber-800/40',
        };
      case 'EXPENSE_CREATE':
        return {
          label: 'Décaissement',
          icon: TrendingDown,
          bg: 'bg-rose-50 dark:bg-rose-950/40 text-rose-700 dark:text-rose-300 border-rose-200 dark:border-rose-900/50',
        };
      case 'STOCK_SUPPLY':
        return {
          label: 'Approvisionnement',
          icon: PackagePlus,
          bg: 'bg-brand-50 dark:bg-brand-500/15 text-brand-700 dark:text-brand-300 border-brand-200 dark:border-brand-500/30',
        };
      case 'LOGIN':
        return {
          label: 'Connexion',
          icon: LogIn,
          bg: 'bg-purple-50 dark:bg-purple-950/40 text-purple-700 dark:text-purple-300 border-purple-200 dark:border-purple-800/40',
        };
      case 'PIN_VERIFY':
      case 'PIN_UNLOCK':
        return {
          label: 'Déverrouillage PIN',
          icon: KeyRound,
          bg: 'bg-cyan-50 dark:bg-cyan-950/40 text-cyan-700 dark:text-cyan-300 border-cyan-200 dark:border-cyan-800/40',
        };
      default:
        return {
          label: action,
          icon: FileText,
          bg: 'bg-slate-100 dark:bg-dark-700 text-slate-700 dark:text-slate-300 border-slate-200 dark:border-dark-600',
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
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Page Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <ShieldCheck className="w-6 h-6 text-[#29ABE2]" />
            <h1 className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">
              Journal d'Audit
            </h1>
          </div>
          <p className="text-xs sm:text-sm text-[#5A7184] dark:text-slate-400 mt-1">
            Traçabilité des actions effectuées par les caissiers et administrateurs
          </p>
        </div>
        <button
          onClick={() => refetch()}
          disabled={isFetching}
          className="btn-secondary"
        >
          <RefreshCw className={`w-4 h-4 text-brand-500 ${isFetching ? 'animate-spin' : ''}`} />
          <span>Actualiser</span>
        </button>
      </div>

      {/* Filters Bar */}
      <div className="card-toc p-4 flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1">
          <Search className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-400" />
          <input
            type="text"
            placeholder="Rechercher par opérateur, entité ou référence..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="input-toc pl-10"
          />
        </div>

        <div className="flex items-center gap-2">
          <Filter className="w-4 h-4 text-slate-400" />
          <select
            value={selectedAction}
            onChange={(e) => setSelectedAction(e.target.value)}
            className="input-toc bg-white dark:bg-dark-700 w-auto"
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

      {/* Audit Logs Table with Density */}
      <div className="card-toc overflow-hidden">
        {isLoading ? (
          <div className="p-12 text-center text-slate-400">
            <RefreshCw className="w-6 h-6 animate-spin mx-auto mb-2 text-brand-500" />
            <p className="text-sm font-medium">Chargement du journal d'audit...</p>
          </div>
        ) : filteredItems.length === 0 ? (
          <div className="p-12 text-center text-slate-400">
            <Info className="w-8 h-8 mx-auto mb-2 text-slate-300 dark:text-slate-600" />
            <p className="text-base font-semibold text-slate-700 dark:text-slate-200">Aucun enregistrement d'audit trouvé</p>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
              Les futures opérations sur le mobile et le backoffice apparaîtront ici.
            </p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left">
              <thead className="bg-[#F5FAFD] dark:bg-dark-700/50 border-b border-[#E8EFF5] dark:border-dark-600">
                <tr>
                  <th className={tableClasses.th}>Date & Heure</th>
                  <th className={tableClasses.th}>Opérateur</th>
                  <th className={tableClasses.th}>Action</th>
                  <th className={tableClasses.th}>Entité / Cible</th>
                  <th className={tableClasses.th}>Détails</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#E8EFF5] dark:divide-dark-600/60">
                {filteredItems.map((item) => {
                  const badge = getActionBadge(item.action);
                  const Icon = badge.icon;
                  return (
                    <tr key={item.id} className="hover:bg-brand-50/30 dark:hover:bg-dark-700/40 transition-colors">
                      <td className={`${tableClasses.td} font-mono text-xs text-slate-500 dark:text-slate-400 whitespace-nowrap`}>
                        {formatDateTime(item.created_at)}
                      </td>
                      <td className={`${tableClasses.td} whitespace-nowrap`}>
                        <div className="flex items-center gap-2.5">
                          <div className="w-7 h-7 rounded-full bg-brand-50 dark:bg-brand-500/20 text-brand-700 dark:text-brand-300 flex items-center justify-center font-bold text-xs uppercase border border-brand-200 dark:border-brand-500/30">
                            {(item.user_name || 'U').substring(0, 2)}
                          </div>
                          <div>
                            <span className="font-semibold text-slate-900 dark:text-white block leading-tight">
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
                      <td className={`${tableClasses.td} whitespace-nowrap`}>
                        <span
                          className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-bold border ${badge.bg}`}
                        >
                          <Icon className="w-3.5 h-3.5" />
                          {badge.label}
                        </span>
                      </td>
                      <td className={`${tableClasses.td} whitespace-nowrap`}>
                        <span className="capitalize font-medium text-slate-800 dark:text-slate-200">
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
                      <td className={tableClasses.td}>
                        {item.details ? (
                          <button
                            onClick={() => setSelectedLog(item)}
                            className="inline-flex items-center gap-1 text-xs text-brand-600 dark:text-brand-400 font-bold hover:underline"
                          >
                            <FileText className="w-3.5 h-3.5" />
                            <span>Voir détails</span>
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
      <Modal
        isOpen={!!selectedLog}
        onClose={() => setSelectedLog(null)}
        title={
          <div className="flex items-center gap-2">
            <ShieldCheck className="w-5 h-5 text-brand-500" />
            <span>Détails de l'Action d'Audit</span>
          </div>
        }
        subtitle="Payload brut enregistré lors de l'opération"
        footer={
          <button
            onClick={() => setSelectedLog(null)}
            className="btn-secondary"
          >
            Fermer
          </button>
        }
      >
        {selectedLog && (
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-3 text-xs bg-[#F5FAFD] dark:bg-dark-700/60 p-3.5 rounded-2xl border border-[#E8EFF5] dark:border-dark-600">
              <div>
                <span className="text-slate-400 dark:text-slate-500 block font-medium">Opérateur :</span>
                <span className="font-bold text-slate-800 dark:text-white">
                  {selectedLog.user_name || 'Inconnu'}
                </span>
              </div>
              <div>
                <span className="text-slate-400 dark:text-slate-500 block font-medium">Action :</span>
                <span className="font-bold text-slate-800 dark:text-white">{selectedLog.action}</span>
              </div>
              <div>
                <span className="text-slate-400 dark:text-slate-500 block font-medium">Date & Heure :</span>
                <span className="font-semibold text-slate-800 dark:text-slate-200 font-mono">
                  {formatDateTime(selectedLog.created_at)}
                </span>
              </div>
              <div>
                <span className="text-slate-400 dark:text-slate-500 block font-medium">Cible :</span>
                <span className="font-semibold text-slate-800 dark:text-slate-200 font-mono">
                  {selectedLog.entity_type} {selectedLog.entity_id ? `(#${selectedLog.entity_id.substring(0, 8)})` : ''}
                </span>
              </div>
            </div>

            <div>
              <span className="text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 block mb-1.5">
                Données de l'événement (Payload JSON) :
              </span>
              <pre className="bg-slate-900 dark:bg-black/60 text-emerald-400 p-3.5 rounded-2xl text-xs font-mono overflow-x-auto max-h-60 border border-slate-800">
                {JSON.stringify(selectedLog.details, null, 2)}
              </pre>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
};
