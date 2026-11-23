import React from 'react';
import { ShoppingBag, RefreshCcw } from 'lucide-react';
import {
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
} from 'recharts';
import { useTheme } from '../../context/ThemeContext';

interface AdminChartsSectionProps {
  monthlySignups: { month: string; signups: number }[];
  planDistribution: { name: string; count: number }[];
}

export const AdminChartsSection: React.FC<AdminChartsSectionProps> = ({
  monthlySignups,
  planDistribution,
}) => {
  const { theme } = useTheme();
  const gridColor = theme === 'dark' ? '#26384C' : '#E8EFF5';

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
      <div className="card-toc p-5 space-y-3">
        <div className="flex items-center justify-between">
          <h3 className="text-sm font-bold text-[#1C2B3A] dark:text-white">
            Nouvelles Boutiques (6 derniers mois)
          </h3>
          <ShoppingBag className="w-4 h-4 text-[#29ABE2]" />
        </div>
        <div className="h-56">
          {monthlySignups.length > 0 ? (
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={monthlySignups}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke={gridColor} />
                <XAxis dataKey="month" fontSize={11} stroke="#5A7184" />
                <YAxis fontSize={11} allowDecimals={false} stroke="#5A7184" />
                <Tooltip />
                <Bar dataKey="signups" name="Inscriptions" fill="#29ABE2" radius={[6, 6, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          ) : (
            <div className="h-full flex items-center justify-center text-xs text-[#9FB3C8]">
              Données d'inscription en attente.
            </div>
          )}
        </div>
      </div>

      <div className="card-toc p-5 space-y-3">
        <div className="flex items-center justify-between">
          <h3 className="text-sm font-bold text-[#1C2B3A] dark:text-white">
            Répartition par Forfait
          </h3>
          <RefreshCcw className="w-4 h-4 text-[#27AE60]" />
        </div>
        <div className="h-56">
          {planDistribution.length > 0 ? (
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={planDistribution}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke={gridColor} />
                <XAxis dataKey="name" fontSize={11} stroke="#5A7184" />
                <YAxis fontSize={11} allowDecimals={false} stroke="#5A7184" />
                <Tooltip />
                <Bar dataKey="count" name="Boutiques" fill="#27AE60" radius={[6, 6, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          ) : (
            <div className="h-full flex items-center justify-center text-xs text-[#9FB3C8]">
              Aucune souscription active.
            </div>
          )}
        </div>
      </div>
    </div>
  );
};
