import React from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowRight, ChevronRight } from 'lucide-react';
import {
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
} from 'recharts';
import { Vente } from '../../types';
import { formatFCFA, formatDateTime } from '../../lib/formatters';

interface DashboardActivitySectionProps {
  recentVentes?: Vente[];
  ventesLoading: boolean;
  theme: string;
}

export const DashboardActivitySection: React.FC<DashboardActivitySectionProps> = ({
  recentVentes,
  ventesLoading,
  theme,
}) => {
  const navigate = useNavigate();

  const chartData = (recentVentes || [])
    .slice()
    .reverse()
    .map((v) => ({
      ticket: v.ticket_number.replace('VNT-', '').slice(-6),
      montant: v.total_amount,
    }));

  return (
    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <div className="lg:col-span-2 card-toc p-6 flex flex-col justify-between">
        <div>
          <div className="flex items-center justify-between mb-4">
            <div>
              <h3 className="text-base font-bold text-[#1C2B3A] dark:text-white">
                Dernières Ventes Encaissées
              </h3>
              <p className="text-xs text-[#5A7184] dark:text-slate-400">Montant par ticket en direct</p>
            </div>
            <span className="badge-toc-primary">Temps Réel</span>
          </div>

          <div className="h-64 w-full">
            {ventesLoading ? (
              <div className="h-full flex items-center justify-center text-xs text-slate-400">
                Chargement du graphique...
              </div>
            ) : chartData.length > 0 ? (
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={chartData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                  <CartesianGrid
                    strokeDasharray="3 3"
                    vertical={false}
                    stroke={theme === 'dark' ? '#26384C' : '#E8EFF5'}
                  />
                  <XAxis
                    dataKey="ticket"
                    stroke={theme === 'dark' ? '#5A7184' : '#94A3B8'}
                    fontSize={11}
                    tickLine={false}
                  />
                  <YAxis
                    stroke={theme === 'dark' ? '#5A7184' : '#94A3B8'}
                    fontSize={11}
                    tickLine={false}
                  />
                  <Tooltip
                    formatter={(val: number) => formatFCFA(val)}
                    contentStyle={{
                      backgroundColor: theme === 'dark' ? '#16222F' : '#1C2B3A',
                      color: '#fff',
                      borderRadius: '12px',
                      border: 'none',
                      fontSize: '12px',
                    }}
                  />
                  <Bar dataKey="montant" name="Montant (FCFA)" fill="#29ABE2" radius={[6, 6, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            ) : (
              <div className="h-full flex items-center justify-center text-xs text-slate-400">
                Aucune vente enregistrée pour le moment.
              </div>
            )}
          </div>
        </div>

        <div className="pt-4 mt-2 border-t border-[#E8EFF5] dark:border-dark-600 flex items-center justify-between">
          <span className="text-xs text-[#5A7184] dark:text-slate-400">
            Synchronisation automatique active
          </span>
          <button
            onClick={() => navigate('/ventes')}
            className="inline-flex items-center gap-1 text-xs font-bold text-brand-500 hover:text-brand-600 transition"
          >
            <span>Consulter le journal</span>
            <ArrowRight className="w-3.5 h-3.5" />
          </button>
        </div>
      </div>

      <div className="card-toc p-6 flex flex-col justify-between">
        <div>
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-base font-bold text-[#1C2B3A] dark:text-white">Tickets Récents</h3>
            <button
              onClick={() => navigate('/ventes')}
              className="text-xs font-bold text-brand-500 hover:underline"
            >
              Tout voir
            </button>
          </div>

          <div className="space-y-3">
            {ventesLoading ? (
              <p className="text-xs text-slate-400">Chargement...</p>
            ) : (recentVentes || []).length > 0 ? (
              (recentVentes || []).slice(0, 5).map((v) => (
                <div
                  key={v.sync_id}
                  onClick={() => navigate('/ventes')}
                  className="flex items-center justify-between p-2.5 rounded-xl hover:bg-[#F0F9FE] dark:hover:bg-dark-700/50 transition cursor-pointer"
                >
                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded-lg bg-brand-50 dark:bg-brand-500/15 text-brand-500 flex items-center justify-center font-bold text-xs">
                      #
                    </div>
                    <div>
                      <p className="text-xs font-bold text-[#1C2B3A] dark:text-white">{v.ticket_number}</p>
                      <p className="text-[11px] text-[#5A7184] dark:text-slate-400">
                        {v.client_name || 'Occasionnel'} • {formatDateTime(v.created_at)}
                      </p>
                    </div>
                  </div>
                  <span className="text-xs font-extrabold text-emerald-600 dark:text-emerald-400 font-mono">
                    {formatFCFA(v.total_amount)}
                  </span>
                </div>
              ))
            ) : (
              <p className="text-xs text-slate-400">Aucune vente récente.</p>
            )}
          </div>
        </div>

        <div className="pt-4 border-t border-[#E8EFF5] dark:border-dark-600 mt-4">
          <button
            onClick={() => navigate('/rapports')}
            className="w-full py-2 bg-slate-50 hover:bg-slate-100 dark:bg-dark-700 dark:hover:bg-dark-600 text-slate-700 dark:text-slate-200 rounded-xl text-xs font-bold transition flex items-center justify-center gap-1.5"
          >
            <span>Voir le rapport financier complet</span>
            <ChevronRight className="w-3.5 h-3.5" />
          </button>
        </div>
      </div>
    </div>
  );
};
