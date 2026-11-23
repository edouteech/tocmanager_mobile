import React from 'react';
import { Eye } from 'lucide-react';
import { FeatureCatalogItem } from '../../types';

export interface EditablePlanFeature {
  feature_code: string;
  feature_name: string;
  boolean_value: boolean;
  int_limit: number;
  show_on_pricing: boolean;
}

interface PlanFeaturesTabContentProps {
  items: FeatureCatalogItem[];
  values: Record<string, EditablePlanFeature>;
  onChange: (code: string, patch: Partial<EditablePlanFeature>) => void;
}

export const PlanFeaturesTabContent: React.FC<PlanFeaturesTabContentProps> = ({
  items,
  values,
  onChange,
}) => {
  return (
    <div className="space-y-3 max-h-[55vh] overflow-y-auto pr-1">
      {items.map((item) => {
        const val = values[item.feature_code] || {
          feature_code: item.feature_code,
          feature_name: item.feature_name,
          boolean_value: false,
          int_limit: 0,
          show_on_pricing: item.show_on_pricing,
        };
        const isUnlimited = val.int_limit === -1;

        return (
          <div
            key={item.feature_code}
            className="p-3.5 rounded-xl border border-[#E8EFF5] dark:border-dark-600 bg-[#F5FAFD] dark:bg-dark-700/40 flex flex-col sm:flex-row sm:items-center justify-between gap-3"
          >
            <div className="space-y-0.5 min-w-0 flex-1">
              <div className="font-bold text-xs text-[#1C2B3A] dark:text-white flex items-center gap-2">
                <span>{item.feature_name}</span>
                <span className="font-mono text-[10px] text-[#9FB3C8]">{item.feature_code}</span>
              </div>
              <p className="text-[11px] text-[#5A7184] dark:text-slate-400">{item.description}</p>
            </div>

            <div className="flex flex-wrap items-center gap-3 shrink-0">
              {item.value_type === 'limit_number' ? (
                <div className="flex items-center gap-2">
                  <input
                    type="number"
                    min={-1}
                    disabled={isUnlimited}
                    value={isUnlimited ? '' : val.int_limit}
                    placeholder={isUnlimited ? 'Illimité' : '0'}
                    onChange={(e) =>
                      onChange(item.feature_code, { int_limit: Math.max(0, Number(e.target.value) || 0) })
                    }
                    className="input-toc w-24 py-1.5 text-xs font-mono text-center disabled:opacity-50"
                  />
                  <label className="inline-flex items-center gap-1.5 text-[11px] font-semibold text-[#1C2B3A] dark:text-slate-200 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={isUnlimited}
                      onChange={(e) =>
                        onChange(item.feature_code, { int_limit: e.target.checked ? -1 : 10 })
                      }
                      className="rounded text-[#29ABE2]"
                    />
                    <span>Illimité (-1)</span>
                  </label>
                </div>
              ) : (
                <label className="inline-flex items-center gap-2 text-xs font-bold cursor-pointer">
                  <input
                    type="checkbox"
                    checked={val.boolean_value}
                    onChange={(e) =>
                      onChange(item.feature_code, { boolean_value: e.target.checked })
                    }
                    className="rounded text-[#29ABE2]"
                  />
                  <span className={val.boolean_value ? 'text-[#27AE60]' : 'text-[#9FB3C8]'}>
                    {val.boolean_value ? 'Activé' : 'Verrouillé'}
                  </span>
                </label>
              )}

              <label
                className="inline-flex items-center gap-1 px-2 py-1 rounded-lg border border-[#E8EFF5] dark:border-dark-600 bg-white dark:bg-dark-800 text-[10px] font-semibold text-[#5A7184] cursor-pointer"
                title="Afficher sur la page publique /tarifs"
              >
                <input
                  type="checkbox"
                  checked={val.show_on_pricing}
                  onChange={(e) =>
                    onChange(item.feature_code, { show_on_pricing: e.target.checked })
                  }
                  className="rounded text-[#29ABE2]"
                />
                <Eye className="w-3 h-3 text-[#29ABE2]" />
                <span>/tarifs</span>
              </label>
            </div>
          </div>
        );
      })}
    </div>
  );
};
