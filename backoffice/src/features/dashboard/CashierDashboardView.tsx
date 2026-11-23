import React from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { ShoppingCart, Calculator, Users, Wallet, Store, CheckCircle2, Clock } from 'lucide-react';
import { cashSessionsApi, ventesApi } from '../../lib/api';
import { formatFCFA, formatDateTime } from '../../lib/formatters';
import { useTenantContextKey, useTenantStore } from '../../stores/tenantStore';
import { useAuthStore } from '../../stores/authStore';

export const CashierDashboardView: React.FC = () => {
  const navigate = useNavigate();
  const user = useAuthStore((s) => s.user);
  const { currentMagasin } = useTenantStore();
  const [boutiqueKey, magasinKey] = useTenantContextKey();

  const { data: currentSession } = useQuery({
    queryKey: ['cash-session-current', boutiqueKey, magasinKey],
    queryFn: () => cashSessionsApi.getCurrent(currentMagasin?.id),
  });

  const { data: recentVentes = [], isLoading: ventesLoading } = useQuery({
    queryKey: ['recent-ventes', boutiqueKey, magasinKey],
    queryFn: () => ventesApi.getAll({ limit: 8 }),
    refetchInterval: 20000,
  });

  const todayPrefix = new Date().toISOString().slice(0, 10);
  const todaySales = recentVentes.filter((v) => v.created_at?.startsWith(todayPrefix));
  const todayRevenue = todaySales.reduce((acc, v) => acc + (v.total_amount || 0), 0);

  return (
    <div className="space-y-6 max-w-6xl mx-auto">
      <div className="rounded-3xl toc-gradient p-6 sm:p-8 text-white shadow-soft flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div className="space-y-1.5">
          <div className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-white/20 text-[11px] font-semibold">
            <Store className="w-3.5 h-3.5" />
            <span>{currentMagasin?.name || 'Caisse Point de Vente'}</span>
          </div>
          <h1 className="text-2xl font-extrabold">
            Bienvenue, {user?.full_name || user?.username}
          </h1>
          <p className="text-xs text-white/85">
            {todaySales.length} vente(s) aujourd'hui • Encaissement du jour : {formatFCFA(todayRevenue)}
          </p>
        </div>

        <button
          type="button"
          onClick={() => navigate('/ventes')}
          className="px-5 py-3 rounded-xl bg-white text-[#1A8FBF] font-bold text-sm hover:bg-[#F0F9FE] transition inline-flex items-center justify-center gap-2 shrink-0"
        >
          <ShoppingCart className="w-4 h-4" />
          <span>Ouvrir la Caisse</span>
        </button>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="card-toc p-4 space-y-2">
          <div className="flex items-center justify-between text-xs font-bold text-[#5A7184]">
            <span>Session Caisse</span>
            {currentSession ? (
              <CheckCircle2 className="w-4 h-4 text-[#27AE60]" />
            ) : (
              <Clock className="w-4 h-4 text-[#F39C12]" />
            )}
          </div>
          <div className="text-sm font-extrabold text-[#1C2B3A] dark:text-white">
            {currentSession ? 'Caisse Ouverte' : 'Caisse Fermée'}
          </div>
          <button
            type="button"
            onClick={() => navigate('/caisse-z')}
            className="text-xs font-semibold text-[#29ABE2] hover:underline inline-flex items-center gap-1"
          >
            <Calculator className="w-3.5 h-3.5" />
            <span>Gérer la caisse Z</span>
          </button>
        </div>

        <button
          type="button"
          onClick={() => navigate('/ventes')}
          className="card-toc card-hover p-4 text-left space-y-1"
        >
          <ShoppingCart className="w-5 h-5 text-[#29ABE2]" />
          <div className="text-sm font-bold text-[#1C2B3A] dark:text-white pt-1">Ventes & Encaissement</div>
          <p className="text-xs text-[#5A7184]">Créer un ticket ou consulter l'historique</p>
        </button>

        <button
          type="button"
          onClick={() => navigate('/clients')}
          className="card-toc card-hover p-4 text-left space-y-1"
        >
          <Users className="w-5 h-5 text-[#27AE60]" />
          <div className="text-sm font-bold text-[#1C2B3A] dark:text-white pt-1">Clients & Créances</div>
          <p className="text-xs text-[#5A7184]">Consulter ou enregistrer un règlement client</p>
        </button>

        <button
          type="button"
          onClick={() => navigate('/depenses')}
          className="card-toc card-hover p-4 text-left space-y-1"
        >
          <Wallet className="w-5 h-5 text-[#E74C3C]" />
          <div className="text-sm font-bold text-[#1C2B3A] dark:text-white pt-1">Décaissements</div>
          <p className="text-xs text-[#5A7184]">Saisir une petite dépense de caisse</p>
        </button>
      </div>

      <div className="card-toc p-5 space-y-3">
        <div className="flex items-center justify-between">
          <h2 className="text-sm font-bold text-[#1C2B3A] dark:text-white">Derniers tickets du magasin</h2>
          <button
            type="button"
            onClick={() => navigate('/ventes')}
            className="text-xs font-semibold text-[#29ABE2] hover:underline"
          >
            Voir tout
          </button>
        </div>
        {ventesLoading ? (
          <p className="text-xs text-[#5A7184]">Chargement...</p>
        ) : recentVentes.length === 0 ? (
          <p className="text-xs text-[#5A7184]">Aucune vente récente.</p>
        ) : (
          <div className="divide-y divide-[#E8EFF5] dark:divide-dark-600">
            {recentVentes.slice(0, 6).map((v) => (
              <div key={v.sync_id} className="py-2.5 flex items-center justify-between text-xs">
                <div>
                  <div className="font-bold text-[#1C2B3A] dark:text-white">{v.ticket_number}</div>
                  <div className="text-[11px] text-[#5A7184]">
                    {v.client_name || 'Occasionnel'} • {formatDateTime(v.created_at)}
                  </div>
                </div>
                <span className="font-mono font-bold text-[#27AE60]">{formatFCFA(v.total_amount)}</span>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};
