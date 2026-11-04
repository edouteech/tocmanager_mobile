import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  Search,
  Printer,
  FileText,
  CreditCard,
  ShoppingBag,
  Plus,
} from 'lucide-react';
import { api } from '../../lib/api';
import { formatFCFA, formatDateTime } from '../../lib/formatters';
import { Vente } from '../../types';
import { Drawer } from '../../components/common/Drawer';
import { useDensity } from '../../context/DensityContext';
import { CreateSaleModal } from './CreateSaleModal';

export const SalesPage: React.FC = () => {
  const { tableClasses } = useDensity();
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedVente, setSelectedVente] = useState<Vente | null>(null);
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);

  const { data: ventes, isLoading } = useQuery<Vente[]>({
    queryKey: ['ventes'],
    queryFn: async () => {
      const res = await api.get('/ventes?limit=200');
      return res.data;
    },
  });

  const filteredVentes = (ventes || []).filter((v) => {
    const term = searchTerm.toLowerCase();
    return (
      v.ticket_number.toLowerCase().includes(term) ||
      (v.client_name && v.client_name.toLowerCase().includes(term)) ||
      v.payment_method.toLowerCase().includes(term)
    );
  });

  const handlePrintReceipt = () => {
    window.print();
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Title & Actions */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">
            Ventes
          </h1>
          <p className="text-xs sm:text-sm text-[#5A7184] dark:text-slate-400 mt-1">
            Historique des encaissements et tickets de caisse
          </p>
        </div>

        {/* Search input and New Sale button */}
        <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3 w-full sm:w-auto">
          <div className="relative w-full sm:w-72">
            <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-slate-400">
              <Search className="w-4 h-4" />
            </div>
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Rechercher ticket, client, paiement..."
              className="input-toc pl-10"
            />
          </div>

          <button
            onClick={() => setIsCreateModalOpen(true)}
            className="btn-toc btn-primary flex items-center gap-2 whitespace-nowrap w-full sm:w-auto justify-center shadow-sm"
          >
            <Plus className="w-4 h-4" />
            <span>Nouvelle Vente</span>
          </button>
        </div>
      </div>

      {/* Ventes Table with Density */}
      <div className="card-toc overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left min-w-[700px]">
            <thead className="bg-[#F5FAFD] dark:bg-dark-700/50 border-b border-[#E8EFF5] dark:border-dark-600">
              <tr>
                <th className={tableClasses.th}>Numéro Ticket</th>
                <th className={tableClasses.th}>Client</th>
                <th className={tableClasses.th}>Articles</th>
                <th className={tableClasses.th}>Mode Paiement</th>
                <th className={tableClasses.th}>Date & Heure</th>
                <th className={`${tableClasses.th} text-right`}>Montant Total</th>
                <th className={`${tableClasses.th} text-center`}>Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#E8EFF5] dark:divide-dark-600/60">
              {isLoading ? (
                <tr>
                  <td colSpan={7} className="px-6 py-12 text-center text-slate-400">
                    Chargement des ventes...
                  </td>
                </tr>
              ) : filteredVentes.length > 0 ? (
                filteredVentes.map((v) => (
                  <tr key={v.sync_id} className="hover:bg-brand-50/30 dark:hover:bg-dark-700/40 transition-colors">
                    <td className={`${tableClasses.td} font-mono font-bold text-brand-600 dark:text-brand-400`}>
                      {v.ticket_number}
                    </td>
                    <td className={`${tableClasses.td} font-semibold text-slate-900 dark:text-white`}>
                      {v.client_name || 'Occasionnel'}
                    </td>
                    <td className={`${tableClasses.td} text-slate-500 dark:text-slate-400`}>
                      <span className="inline-flex items-center gap-1">
                        <ShoppingBag className="w-3.5 h-3.5 text-brand-500" />
                        {v.items?.length || 0} article(s)
                      </span>
                    </td>
                    <td className={tableClasses.td}>
                      <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-brand-50 dark:bg-brand-500/15 text-brand-600 dark:text-brand-400 border border-brand-200 dark:border-brand-500/30">
                        <CreditCard className="w-3 h-3 text-brand-500" />
                        {v.payment_method}
                      </span>
                    </td>
                    <td className={`${tableClasses.td} text-slate-500 dark:text-slate-400`}>
                      {formatDateTime(v.created_at)}
                    </td>
                    <td className={`${tableClasses.td} text-right font-extrabold text-slate-900 dark:text-white font-mono`}>
                      {formatFCFA(v.total_amount)}
                    </td>
                    <td className={`${tableClasses.td} text-center`}>
                      <button
                        onClick={() => setSelectedVente(v)}
                        className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-brand-50 hover:bg-brand-100 dark:bg-brand-500/15 dark:hover:bg-brand-500/25 text-brand-700 dark:text-brand-300 rounded-xl text-xs font-bold transition-all border border-brand-200 dark:border-brand-500/30"
                      >
                        <FileText className="w-3.5 h-3.5 text-brand-600 dark:text-brand-400" />
                        <span>Détails</span>
                      </button>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={7} className="px-6 py-12 text-center text-slate-400">
                    Aucune vente trouvée pour cette recherche.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Slide-over Drawer for Ticket Detail */}
      <Drawer
        isOpen={!!selectedVente}
        onClose={() => setSelectedVente(null)}
        title={
          <div className="flex items-center gap-2">
            <FileText className="w-5 h-5 text-brand-500" />
            <span>Ticket {selectedVente?.ticket_number}</span>
          </div>
        }
        subtitle="Détail complet de la transaction de caisse"
        footer={
          <button
            onClick={handlePrintReceipt}
            className="btn-primary"
          >
            <Printer className="w-4 h-4" />
            <span>Imprimer le Reçu</span>
          </button>
        }
      >
        {selectedVente && (
          <div className="space-y-6">
            {/* Meta information */}
            <div className="grid grid-cols-2 gap-3.5 text-xs bg-[#F5FAFD] dark:bg-dark-700/60 p-4 rounded-2xl border border-[#E8EFF5] dark:border-dark-600">
              <div>
                <span className="text-slate-400 dark:text-slate-500 block mb-0.5">Client</span>
                <span className="font-bold text-slate-900 dark:text-white">
                  {selectedVente.client_name || 'Occasionnel'}
                </span>
              </div>
              <div>
                <span className="text-slate-400 dark:text-slate-500 block mb-0.5">Date & Heure</span>
                <span className="font-semibold text-slate-700 dark:text-slate-200">
                  {formatDateTime(selectedVente.created_at)}
                </span>
              </div>
              <div>
                <span className="text-slate-400 dark:text-slate-500 block mb-0.5">Mode de Paiement</span>
                <span className="font-semibold text-slate-700 dark:text-slate-200">
                  {selectedVente.payment_method}
                </span>
              </div>
              <div>
                <span className="text-slate-400 dark:text-slate-500 block mb-0.5">Vendeur / Caissier</span>
                <span className="font-semibold text-slate-700 dark:text-slate-200">
                  {selectedVente.user_name || 'Système'}
                </span>
              </div>
            </div>

            {/* Items List */}
            <div>
              <h4 className="text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400 mb-3">
                Articles Vendus
              </h4>
              <div className="border border-[#E8EFF5] dark:border-dark-600 rounded-2xl overflow-hidden divide-y divide-[#E8EFF5] dark:divide-dark-600/60">
                {selectedVente.items.map((it, idx) => (
                  <div key={idx} className="p-3.5 text-xs flex items-center justify-between hover:bg-slate-50 dark:hover:bg-dark-700/40">
                    <div>
                      <div className="font-bold text-slate-900 dark:text-white">{it.product_name}</div>
                      <div className="text-slate-500 dark:text-slate-400 text-[11px] mt-0.5">
                        {it.quantity} x {formatFCFA(it.unit_price)}
                      </div>
                    </div>
                    <div className="font-extrabold text-slate-900 dark:text-white font-mono">
                      {formatFCFA(it.total)}
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Financial summary */}
            <div className="p-4 bg-slate-50 dark:bg-dark-700/40 rounded-2xl border border-[#E8EFF5] dark:border-dark-600 space-y-2 text-xs">
              <div className="flex justify-between text-slate-500 dark:text-slate-400">
                <span>Sous-total</span>
                <span>{formatFCFA(selectedVente.total_amount + (selectedVente.discount_amount || 0))}</span>
              </div>
              {selectedVente.discount_amount > 0 && (
                <div className="flex justify-between text-rose-600 dark:text-rose-400 font-semibold">
                  <span>Remise accordée</span>
                  <span>- {formatFCFA(selectedVente.discount_amount)}</span>
                </div>
              )}
              <div className="flex justify-between text-sm font-extrabold text-slate-900 dark:text-white pt-2 border-t border-[#E8EFF5] dark:border-dark-600">
                <span>Total Net</span>
                <span>{formatFCFA(selectedVente.total_amount)}</span>
              </div>
              <div className="flex justify-between text-xs text-emerald-600 dark:text-emerald-400 font-bold">
                <span>Montant Encaissé</span>
                <span>{formatFCFA(selectedVente.paid_amount)}</span>
              </div>
              {selectedVente.paid_amount < selectedVente.total_amount && (
                <div className="flex justify-between text-xs text-amber-600 dark:text-amber-400 font-bold">
                  <span>Reliquat restant dû (Créance)</span>
                  <span>
                    {formatFCFA(selectedVente.total_amount - selectedVente.paid_amount)}
                  </span>
                </div>
              )}
            </div>
          </div>
        )}
      </Drawer>

      {/* POS / New Sale Modal */}
      <CreateSaleModal
        isOpen={isCreateModalOpen}
        onClose={() => setIsCreateModalOpen(false)}
      />
    </div>
  );
};
