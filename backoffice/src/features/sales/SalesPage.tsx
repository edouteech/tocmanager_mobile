import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  Search,
  Printer,
  X,
  FileText,
  Calendar,
  CheckCircle2,
  Clock,
} from 'lucide-react';
import { api } from '../../lib/api';
import { formatFCFA, formatDateTime } from '../../lib/formatters';
import { Vente } from '../../types';

export const SalesPage: React.FC = () => {
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedVente, setSelectedVente] = useState<Vente | null>(null);

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
          <h2 className="text-2xl font-bold text-slate-900 tracking-tight">
            Journal des Ventes
          </h2>
          <p className="text-sm text-slate-500 mt-1">
            Historique exhaustif de tous les tickets et factures encaissés.
          </p>
        </div>

        {/* Search input */}
        <div className="relative w-full sm:w-80">
          <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-slate-400">
            <Search className="w-4 h-4" />
          </div>
          <input
            type="text"
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            placeholder="Rechercher ticket, client..."
            className="w-full pl-10 pr-4 py-2 bg-white border border-slate-200 rounded-xl text-sm text-slate-800 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-600 shadow-sm transition"
          />
        </div>
      </div>

      {/* Ventes Table */}
      <div className="bg-white rounded-2xl border border-slate-200/80 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm text-slate-600">
            <thead className="bg-slate-50 text-[11px] font-semibold text-slate-500 uppercase tracking-wider border-b border-slate-200/80">
              <tr>
                <th className="px-6 py-3.5">Numéro Ticket</th>
                <th className="px-6 py-3.5">Client</th>
                <th className="px-6 py-3.5">Articles</th>
                <th className="px-6 py-3.5">Mode Paiement</th>
                <th className="px-6 py-3.5">Date</th>
                <th className="px-6 py-3.5 text-right">Montant Total</th>
                <th className="px-6 py-3.5 text-center">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {isLoading ? (
                <tr>
                  <td colSpan={7} className="px-6 py-12 text-center text-slate-400">
                    Chargement des ventes...
                  </td>
                </tr>
              ) : filteredVentes.length > 0 ? (
                filteredVentes.map((v) => (
                  <tr key={v.sync_id} className="hover:bg-slate-50/70 transition">
                    <td className="px-6 py-4 font-mono text-xs font-semibold text-indigo-700">
                      {v.ticket_number}
                    </td>
                    <td className="px-6 py-4 font-medium text-slate-900">
                      {v.client_name || 'Occasionnel'}
                    </td>
                    <td className="px-6 py-4 text-xs text-slate-500">
                      {v.items?.length || 0} article(s)
                    </td>
                    <td className="px-6 py-4">
                      <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-slate-100 text-slate-700">
                        {v.payment_method}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-xs text-slate-500">
                      {formatDateTime(v.created_at)}
                    </td>
                    <td className="px-6 py-4 text-right font-bold text-slate-900">
                      {formatFCFA(v.total_amount)}
                    </td>
                    <td className="px-6 py-4 text-center">
                      <button
                        onClick={() => setSelectedVente(v)}
                        className="px-3 py-1 bg-indigo-50 text-indigo-600 hover:bg-indigo-100 font-medium text-xs rounded-lg transition"
                      >
                        Détails
                      </button>
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={7} className="px-6 py-12 text-center text-slate-400">
                    Aucun ticket trouvé.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal Détail du Ticket */}
      {selectedVente && (
        <div className="fixed inset-0 z-50 bg-slate-900/50 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl shadow-2xl max-w-lg w-full max-h-[90vh] flex flex-col overflow-hidden border border-slate-100 animate-in fade-in zoom-in-95 duration-150">
            {/* Modal Header */}
            <div className="px-6 py-4 border-b border-slate-100 flex items-center justify-between bg-slate-50">
              <div className="flex items-center gap-2">
                <FileText className="w-5 h-5 text-indigo-600" />
                <h3 className="font-bold text-slate-900">
                  Détail Ticket {selectedVente.ticket_number}
                </h3>
              </div>
              <button
                onClick={() => setSelectedVente(null)}
                className="text-slate-400 hover:text-slate-600 rounded-lg p-1 transition"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Modal Body */}
            <div className="p-6 overflow-y-auto space-y-6">
              {/* Meta information */}
              <div className="grid grid-cols-2 gap-4 text-xs bg-slate-50 p-4 rounded-xl border border-slate-100">
                <div>
                  <span className="text-slate-400 block mb-0.5">Client</span>
                  <span className="font-semibold text-slate-800">
                    {selectedVente.client_name || 'Occasionnel'}
                  </span>
                </div>
                <div>
                  <span className="text-slate-400 block mb-0.5">Date & Heure</span>
                  <span className="font-semibold text-slate-800">
                    {formatDateTime(selectedVente.created_at)}
                  </span>
                </div>
                <div>
                  <span className="text-slate-400 block mb-0.5">Mode de Paiement</span>
                  <span className="font-semibold text-slate-800">
                    {selectedVente.payment_method}
                  </span>
                </div>
                <div>
                  <span className="text-slate-400 block mb-0.5">Identifiant Unique (UUID)</span>
                  <span className="font-mono text-[10px] text-slate-500 truncate block">
                    {selectedVente.sync_id}
                  </span>
                </div>
              </div>

              {/* Items List */}
              <div>
                <h4 className="text-xs font-bold uppercase tracking-wider text-slate-500 mb-3">
                  Articles Vendus
                </h4>
                <div className="border border-slate-100 rounded-xl overflow-hidden divide-y divide-slate-100">
                  {selectedVente.items.map((it, idx) => (
                    <div key={idx} className="p-3 text-xs flex items-center justify-between">
                      <div>
                        <div className="font-medium text-slate-800">{it.product_name}</div>
                        <div className="text-slate-400 text-[11px] mt-0.5">
                          {it.quantity} x {formatFCFA(it.unit_price)}
                        </div>
                      </div>
                      <div className="font-bold text-slate-900">
                        {formatFCFA(it.total)}
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Financial summary */}
              <div className="space-y-1.5 pt-2 border-t border-slate-100 text-xs">
                <div className="flex justify-between text-slate-600">
                  <span>Sous-total</span>
                  <span>{formatFCFA(selectedVente.total_amount + (selectedVente.discount_amount || 0))}</span>
                </div>
                {selectedVente.discount_amount > 0 && (
                  <div className="flex justify-between text-rose-600">
                    <span>Remise accordée</span>
                    <span>- {formatFCFA(selectedVente.discount_amount)}</span>
                  </div>
                )}
                <div className="flex justify-between text-sm font-bold text-slate-900 pt-2 border-t border-slate-100">
                  <span>Total Net</span>
                  <span>{formatFCFA(selectedVente.total_amount)}</span>
                </div>
                <div className="flex justify-between text-xs text-emerald-600 font-medium">
                  <span>Montant Encaissé</span>
                  <span>{formatFCFA(selectedVente.paid_amount)}</span>
                </div>
                {selectedVente.paid_amount < selectedVente.total_amount && (
                  <div className="flex justify-between text-xs text-amber-600 font-bold">
                    <span>Reliquat / Créance</span>
                    <span>
                      {formatFCFA(selectedVente.total_amount - selectedVente.paid_amount)}
                    </span>
                  </div>
                )}
              </div>
            </div>

            {/* Modal Footer */}
            <div className="p-4 border-t border-slate-100 bg-slate-50 flex items-center justify-end gap-3">
              <button
                onClick={handlePrintReceipt}
                className="inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-xs font-semibold shadow-sm transition"
              >
                <Printer className="w-4 h-4" />
                <span>Imprimer le Reçu</span>
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
