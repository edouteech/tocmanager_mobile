import React from 'react';
import { CurrentPlanStatus } from '../../types';

interface Props {
  status: CurrentPlanStatus;
}

export const PlanUsageMeters: React.FC<Props> = ({ status }) => {
  const meters = [
    { label: 'Boutiques', used: status.boutiques_used ?? 1, limit: status.boutiques_limit ?? 1 },
    { label: 'Magasins', used: status.magasins_used, limit: status.magasins_limit },
    { label: 'Produits catalogue', used: status.products_used ?? 0, limit: status.products_limit ?? 100 },
    { label: 'Utilisateurs', used: status.users_used ?? 1, limit: status.users_limit ?? 2 },
    { label: 'Clients', used: status.clients_used ?? 0, limit: status.clients_limit ?? 50 },
    { label: 'Fournisseurs', used: status.suppliers_used ?? 0, limit: status.suppliers_limit ?? 10 },
  ];

  return (
    <div className="card-toc p-5 space-y-4">
      <h2 className="text-sm font-bold text-[#1C2B3A] dark:text-white">
        Consommation des quotas du forfait
      </h2>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {meters.map((m) => {
          const isUnlimited = m.limit === -1;
          const pct = isUnlimited || m.limit <= 0 ? 15 : Math.min(100, Math.round((m.used / m.limit) * 100));
          const isNearLimit = !isUnlimited && m.limit > 0 && m.used >= m.limit;
          return (
            <div key={m.label} className="p-3.5 rounded-xl bg-[#F5FAFD] dark:bg-dark-700/60 border border-[#E8EFF5] dark:border-dark-600 space-y-2">
              <div className="flex items-center justify-between text-xs">
                <span className="font-semibold text-[#5A7184] dark:text-slate-300">{m.label}</span>
                <span className={`font-bold ${isNearLimit ? 'text-[#E74C3C]' : 'text-[#1C2B3A] dark:text-white'}`}>
                  {m.used} / {isUnlimited ? 'Illimite' : m.limit}
                </span>
              </div>
              <div className="h-2 rounded-full bg-[#E8EFF5] dark:bg-dark-600 overflow-hidden">
                <div
                  className={`h-full rounded-full transition-all ${
                    isNearLimit ? 'bg-[#E74C3C]' : 'bg-[#29ABE2]'
                  }`}
                  style={{ width: `${pct}%` }}
                />
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
};
