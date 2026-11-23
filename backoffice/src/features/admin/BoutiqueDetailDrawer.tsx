import React from 'react';
import { Eye, Store, Users, CreditCard } from 'lucide-react';
import { Drawer } from '../../components/common/Drawer';
import { AdminBoutiqueDetail } from '../../types';
import { formatDateTime } from '../../lib/formatters';

interface BoutiqueDetailDrawerProps {
  detail: AdminBoutiqueDetail | null;
  loading: boolean;
  impersonating: boolean;
  onClose: () => void;
  onImpersonate: (boutiqueId: string) => void;
}

export const BoutiqueDetailDrawer: React.FC<BoutiqueDetailDrawerProps> = ({
  detail,
  loading,
  impersonating,
  onClose,
  onImpersonate,
}) => {
  return (
    <Drawer
      isOpen={Boolean(detail || loading)}
      onClose={onClose}
      title={detail?.name || 'Chargement...'}
      subtitle={detail ? `${detail.company_name || ''} • ${detail.country} (${detail.currency})` : undefined}
      footer={
        detail ? (
          <div className="flex items-center justify-between gap-2 w-full">
            <button type="button" onClick={onClose} className="btn-secondary text-xs">
              Fermer
            </button>
            <button
              type="button"
              disabled={impersonating}
              onClick={() => onImpersonate(detail.id)}
              className="btn-primary text-xs"
            >
              <Eye className="w-4 h-4" />
              <span>
                {impersonating ? 'Ouverture...' : 'Ouvrir en mode support (lecture seule)'}
              </span>
            </button>
          </div>
        ) : null
      }
    >
      {loading || !detail ? (
        <div className="py-12 text-center text-xs text-[#5A7184]">Chargement de la fiche boutique...</div>
      ) : (
        <div className="space-y-5 text-xs">
          <div className="p-4 rounded-xl bg-[#F0F9FE] dark:bg-dark-700/60 border border-[#E8EFF5] dark:border-dark-600 space-y-1.5">
            <div className="font-bold text-[#1C2B3A] dark:text-white">Propriétaire & Abonnement</div>
            <div className="text-[#5A7184] dark:text-slate-300">
              {detail.owner.full_name} ({detail.owner.email})
            </div>
            <div className="flex items-center justify-between pt-1">
              <span className="font-semibold">Forfait : {detail.subscription.plan_name}</span>
              <span className="badge-toc-primary uppercase">{detail.subscription.status}</span>
            </div>
            {detail.subscription.trial_ends_at && (
              <div className="text-[11px] text-[#F39C12]">
                Fin d'essai : {formatDateTime(detail.subscription.trial_ends_at)}
              </div>
            )}
          </div>

          <div className="space-y-2">
            <div className="font-bold flex items-center gap-1.5 text-[#1C2B3A] dark:text-white">
              <Store className="w-4 h-4 text-[#29ABE2]" />
              <span>Magasins ({detail.magasins.length})</span>
            </div>
            <div className="space-y-1.5">
              {detail.magasins.map((m) => (
                <div
                  key={m.id}
                  className="px-3 py-2 rounded-xl border border-[#E8EFF5] dark:border-dark-600 flex items-center justify-between"
                >
                  <span className="font-semibold">{m.name}</span>
                  <span className="text-[11px] text-[#5A7184]">
                    {m.is_warehouse ? 'Entrepôt' : 'Point de vente'} • {m.is_active ? 'Actif' : 'Inactif'}
                  </span>
                </div>
              ))}
            </div>
          </div>

          <div className="space-y-2">
            <div className="font-bold flex items-center gap-1.5 text-[#1C2B3A] dark:text-white">
              <Users className="w-4 h-4 text-[#27AE60]" />
              <span>Équipe ({detail.members.length})</span>
            </div>
            <div className="space-y-1.5">
              {detail.members.map((u) => (
                <div
                  key={u.id}
                  className="px-3 py-2 rounded-xl border border-[#E8EFF5] dark:border-dark-600 flex items-center justify-between"
                >
                  <span>{u.full_name || u.username} (@{u.username})</span>
                  <span className="badge-toc-primary capitalize">{u.role}</span>
                </div>
              ))}
            </div>
          </div>

          <div className="space-y-2">
            <div className="font-bold flex items-center gap-1.5 text-[#1C2B3A] dark:text-white">
              <CreditCard className="w-4 h-4 text-[#8E44AD]" />
              <span>Dernières transactions ({detail.transactions.length})</span>
            </div>
            {detail.transactions.length === 0 ? (
              <p className="text-[11px] text-[#9FB3C8]">Aucune transaction SaaS enregistrée.</p>
            ) : (
              <div className="space-y-1.5">
                {detail.transactions.map((t) => (
                  <div
                    key={t.id}
                    className="px-3 py-2 rounded-xl border border-[#E8EFF5] dark:border-dark-600 flex items-center justify-between"
                  >
                    <div>
                      <div className="font-mono font-bold">{t.reference}</div>
                      <div className="text-[10px] text-[#5A7184]">{t.network} • {formatDateTime(t.created_at)}</div>
                    </div>
                    <div className="text-right">
                      <div className="font-mono font-bold">{t.amount.toLocaleString('fr-FR')} {t.currency}</div>
                      <span className="text-[10px] uppercase">{t.status}</span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      )}
    </Drawer>
  );
};
