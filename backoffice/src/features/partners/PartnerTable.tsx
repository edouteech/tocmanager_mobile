import React from 'react';
import { AlertCircle, CheckCircle2, Edit2, MapPin, Phone, Trash2 } from 'lucide-react';
import { Client, Supplier } from '../../types';
import { formatFCFA, formatDateTime } from '../../lib/formatters';
import { useDensity } from '../../context/DensityContext';
import { PartnerKind } from './PartnerFormModal';

type PartnerEntity = Client | Supplier;

interface PartnerTableProps {
  kind: PartnerKind;
  partners: PartnerEntity[];
  canModify: boolean;
  onEdit: (partner: PartnerEntity) => void;
  onDelete: (partner: PartnerEntity) => void;
  onPayment: (partner: PartnerEntity) => void;
}

export const PartnerTable: React.FC<PartnerTableProps> = ({
  kind,
  partners,
  canModify,
  onEdit,
  onDelete,
  onPayment,
}) => {
  const { tableClasses } = useDensity();
  const isSupplier = kind === 'supplier';

  return (
    <div className="card-toc overflow-hidden">
      <div className="overflow-x-auto">
        <table className="w-full text-left min-w-[650px]">
          <thead className="bg-[#F5FAFD] dark:bg-dark-700/50 border-b border-[#E8EFF5] dark:border-dark-600">
            <tr>
              <th className={tableClasses.th}>{isSupplier ? 'Fournisseur' : 'Client'}</th>
              <th className={tableClasses.th}>Contact</th>
              <th className={tableClasses.th}>Adresse / Notes</th>
              <th className={`${tableClasses.th} text-right`}>
                {isSupplier ? 'Dette Due' : 'Solde Dû'}
              </th>
              <th className={`${tableClasses.th} text-right`}>Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-[#E8EFF5] dark:divide-dark-600/60">
            {partners.map((p) => {
              const hasDebt = p.balance > 0;
              const contactPerson = 'contact_person' in p ? p.contact_person : null;
              return (
                <tr key={p.sync_id} className="hover:bg-brand-50/30 dark:hover:bg-dark-700/40 transition-colors">
                  <td className={tableClasses.td}>
                    <div className="font-bold text-slate-900 dark:text-white">{p.name}</div>
                    {isSupplier && contactPerson ? (
                      <div className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
                        Réf: {contactPerson}
                      </div>
                    ) : !isSupplier && p.created_at ? (
                      <div className="text-xs text-slate-400 mt-0.5">
                        Enregistré le {formatDateTime(p.created_at)}
                      </div>
                    ) : null}
                  </td>
                  <td className={tableClasses.td}>
                    {p.phone ? (
                      <div className="flex items-center gap-1.5 text-xs text-slate-600 dark:text-slate-300">
                        <Phone className="w-3.5 h-3.5 text-brand-500" />
                        <span>{p.phone}</span>
                      </div>
                    ) : (
                      <span className="text-slate-400 text-xs">Aucun tél.</span>
                    )}
                    {p.email && <div className="text-xs text-slate-400 mt-0.5">{p.email}</div>}
                  </td>
                  <td className={tableClasses.td}>
                    {p.address && (
                      <div className="flex items-center gap-1.5 text-xs text-slate-600 dark:text-slate-300">
                        <MapPin className="w-3.5 h-3.5 text-slate-400" />
                        <span>{p.address}</span>
                      </div>
                    )}
                    {p.notes && <div className="text-xs text-slate-400 italic mt-0.5">{p.notes}</div>}
                    {!p.address && !p.notes && <span className="text-slate-400 text-xs">-</span>}
                  </td>
                  <td className={`${tableClasses.td} text-right font-mono`}>
                    {hasDebt ? (
                      <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-bold bg-amber-50 dark:bg-amber-950/40 text-amber-700 dark:text-amber-400 border border-amber-200 dark:border-amber-900/50">
                        <AlertCircle className="w-3 h-3" />
                        {formatFCFA(p.balance)}
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-400 border border-emerald-100 dark:border-emerald-900/50">
                        <CheckCircle2 className="w-3 h-3" />
                        À jour (0 F)
                      </span>
                    )}
                  </td>
                  <td className={`${tableClasses.td} text-right`}>
                    <div className="flex items-center justify-end gap-2">
                      {hasDebt && (
                        <button
                          onClick={() => onPayment(p)}
                          className="px-2.5 py-1 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl text-xs font-bold transition shadow-sm"
                          title="Enregistrer un règlement"
                        >
                          Régler
                        </button>
                      )}
                      {canModify && (
                        <>
                          <button
                            onClick={() => onEdit(p)}
                            className="p-1.5 text-slate-400 hover:text-brand-600 hover:bg-brand-50 dark:hover:bg-dark-700 rounded-xl transition"
                            title="Modifier"
                          >
                            <Edit2 className="w-4 h-4" />
                          </button>
                          <button
                            onClick={() => onDelete(p)}
                            className="p-1.5 text-slate-400 hover:text-rose-600 hover:bg-rose-50 dark:hover:bg-rose-950/30 rounded-xl transition"
                            title="Supprimer"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </>
                      )}
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
};
