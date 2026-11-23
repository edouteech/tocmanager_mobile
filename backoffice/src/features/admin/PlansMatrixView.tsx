import React from 'react';
import { Check, Minus } from 'lucide-react';
import { FeatureCatalogItem, SaasPlan } from '../../types';
import { useDensity } from '../../context/DensityContext';

interface PlansMatrixViewProps {
  plans: SaasPlan[];
  catalog: FeatureCatalogItem[];
}

const CAT_LABELS: Record<string, string> = {
  quotas: 'Quotas & Capacités',
  modules: 'Modules Métier',
  multi_magasin: 'Multi-Magasins & Logistique',
  analytics_platform: 'Analytique, Exports & Plateforme',
};

export const PlansMatrixView: React.FC<PlansMatrixViewProps> = ({ plans, catalog }) => {
  const { tableClasses } = useDensity();
  const categories = Array.from(new Set(catalog.map((c) => c.category)));

  return (
    <div className="card-toc overflow-hidden">
      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse text-xs">
          <thead>
            <tr className="bg-[#F0F9FE] dark:bg-dark-700/60 border-b border-[#E8EFF5] dark:border-dark-600">
              <th className={tableClasses.th}>Droit / Fonctionnalité ({catalog.length})</th>
              {plans.map((p) => (
                <th key={p.id} className={`${tableClasses.th} text-center`}>
                  <div>{p.name}</div>
                  <div className="text-[10px] font-normal text-[#9FB3C8]">{p.code}</div>
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-[#E8EFF5] dark:divide-dark-600">
            {categories.map((cat) => (
              <React.Fragment key={cat}>
                <tr className="bg-[#F5FAFD] dark:bg-dark-900/50">
                  <td colSpan={plans.length + 1} className="px-4 py-2 font-bold text-[11px] uppercase tracking-wider text-[#29ABE2]">
                    {CAT_LABELS[cat] || cat}
                  </td>
                </tr>
                {catalog
                  .filter((item) => item.category === cat)
                  .map((item) => (
                    <tr key={item.feature_code} className="hover:bg-[#F0F9FE]/40 dark:hover:bg-dark-700/40">
                      <td className={tableClasses.td}>
                        <div className="font-semibold text-[#1C2B3A] dark:text-white">{item.feature_name}</div>
                        <div className="text-[10px] font-mono text-[#9FB3C8]">{item.feature_code}</div>
                      </td>
                      {plans.map((plan) => {
                        const f = plan.features?.find((pf) => pf.feature_code === item.feature_code);
                        return (
                          <td key={plan.id} className={`${tableClasses.td} text-center`}>
                            {!f ? (
                              <Minus className="w-4 h-4 text-[#9FB3C8] mx-auto" />
                            ) : item.value_type === 'limit_number' ? (
                              <span className="font-mono font-bold text-[#1C2B3A] dark:text-white">
                                {f.int_limit === -1 ? 'Illimité' : f.int_limit}
                              </span>
                            ) : f.boolean_value ? (
                              <Check className="w-4 h-4 text-[#27AE60] mx-auto" />
                            ) : (
                              <Minus className="w-4 h-4 text-[#9FB3C8] mx-auto" />
                            )}
                          </td>
                        );
                      })}
                    </tr>
                  ))}
              </React.Fragment>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
};
