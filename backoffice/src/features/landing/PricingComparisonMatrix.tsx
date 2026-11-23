import React from 'react';
import { Check, Minus } from 'lucide-react';
import { FeatureCatalogItem, SaasPlan } from '../../types';

interface PricingComparisonMatrixProps {
  plans: SaasPlan[];
  catalog: FeatureCatalogItem[];
}

const CATEGORY_LABELS: Record<string, string> = {
  quotas: 'Quotas & Capacités',
  modules: 'Modules Métier',
  multi_magasin: 'Multi-Magasins & Logistique',
  analytics_platform: 'Analytique, Exports & Plateforme',
};

export const PricingComparisonMatrix: React.FC<PricingComparisonMatrixProps> = ({
  plans,
  catalog,
}) => {
  if (plans.length === 0 || catalog.length === 0) return null;

  const visibleCatalog = catalog.filter((item) => item.show_on_pricing);
  const categories = Array.from(new Set(visibleCatalog.map((item) => item.category)));

  const renderPlanCell = (plan: SaasPlan, item: FeatureCatalogItem) => {
    const feat = plan.features?.find((f) => f.feature_code === item.feature_code);
    if (!feat) {
      return <Minus className="w-4 h-4 text-slate-300 dark:text-slate-600 mx-auto" />;
    }
    if (item.value_type === 'limit_number') {
      return (
        <span className="font-bold text-xs text-[#1C2B3A] dark:text-white">
          {feat.int_limit === -1 ? 'Illimité' : feat.int_limit}
        </span>
      );
    }
    return feat.boolean_value ? (
      <Check className="w-4 h-4 text-[#27AE60] mx-auto" />
    ) : (
      <Minus className="w-4 h-4 text-slate-300 dark:text-slate-600 mx-auto" />
    );
  };

  return (
    <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pb-14 w-full">
      <div className="text-center mb-6">
        <h2 className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white">
          Comparatif détaillé des fonctionnalités
        </h2>
        <p className="text-xs text-[#5A7184] dark:text-slate-400 mt-1">
          Toutes les capacités incluses par forfait
        </p>
      </div>

      <div className="card-toc overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse text-xs">
            <thead>
              <tr className="bg-[#F0F9FE] dark:bg-dark-700/60 border-b border-[#E8EFF5] dark:border-dark-600">
                <th className="px-4 py-3 font-bold text-[#5A7184] dark:text-slate-300">
                  Fonctionnalité
                </th>
                {plans.map((p) => (
                  <th
                    key={p.id}
                    className="px-4 py-3 text-center font-bold text-[#1C2B3A] dark:text-white"
                  >
                    {p.name}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-[#E8EFF5] dark:divide-dark-600">
              {categories.map((cat) => (
                <React.Fragment key={cat}>
                  <tr className="bg-[#F5FAFD] dark:bg-dark-900/60">
                    <td
                      colSpan={plans.length + 1}
                      className="px-4 py-2 text-[11px] font-bold uppercase tracking-wider text-[#29ABE2]"
                    >
                      {CATEGORY_LABELS[cat] || cat}
                    </td>
                  </tr>
                  {visibleCatalog
                    .filter((item) => item.category === cat)
                    .map((item) => (
                      <tr key={item.feature_code} className="hover:bg-[#F0F9FE]/40 dark:hover:bg-dark-700/30">
                        <td className="px-4 py-2.5 text-[#1C2B3A] dark:text-slate-200 font-medium">
                          {item.feature_name}
                        </td>
                        {plans.map((p) => (
                          <td key={p.id} className="px-4 py-2.5 text-center">
                            {renderPlanCell(p, item)}
                          </td>
                        ))}
                      </tr>
                    ))}
                </React.Fragment>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </section>
  );
};
