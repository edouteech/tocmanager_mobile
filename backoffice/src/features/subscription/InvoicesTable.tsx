import React, { useState } from 'react';
import { Download, FileText } from 'lucide-react';
import { billingApi } from '../../lib/api';
import { formatDateOnly } from '../../lib/formatters';
import { SaasInvoice } from '../../types';

interface Props {
  invoices: SaasInvoice[];
}

export const InvoicesTable: React.FC<Props> = ({ invoices }) => {
  const [downloadingId, setDownloadingId] = useState<string | null>(null);

  const handleDownload = async (inv: SaasInvoice) => {
    setDownloadingId(inv.id);
    try {
      const blob = await billingApi.downloadInvoicePdf(inv.id);
      const url = window.URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = `${inv.invoice_number}.pdf`;
      link.click();
      window.URL.revokeObjectURL(url);
    } finally {
      setDownloadingId(null);
    }
  };

  return (
    <div className="card-toc overflow-hidden">
      <div className="px-5 py-4 border-b border-[#E8EFF5] dark:border-dark-600 flex items-center gap-2">
        <FileText className="w-4 h-4 text-[#29ABE2]" />
        <h2 className="text-sm font-bold text-[#1C2B3A] dark:text-white">
          Historique des paiements & factures PDF
        </h2>
      </div>
      {invoices.length === 0 ? (
        <div className="p-6 text-center text-xs text-[#5A7184] dark:text-slate-400">
          Aucune facture generee pour cette boutique.
        </div>
      ) : (
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-[#F5FAFD] dark:bg-dark-700/50 text-[#5A7184] dark:text-slate-400">
              <tr>
                <th className="px-4 py-3 font-bold">Facture</th>
                <th className="px-4 py-3 font-bold">Forfait</th>
                <th className="px-4 py-3 font-bold">Periode</th>
                <th className="px-4 py-3 font-bold">Montant</th>
                <th className="px-4 py-3 font-bold text-right">PDF</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-[#E8EFF5] dark:divide-dark-600">
              {invoices.map((inv) => (
                <tr key={inv.id}>
                  <td className="px-4 py-3 font-bold text-[#1C2B3A] dark:text-white">{inv.invoice_number}</td>
                  <td className="px-4 py-3">{inv.plan_name} ({inv.billing_cycle})</td>
                  <td className="px-4 py-3">
                    {formatDateOnly(inv.period_start)} - {formatDateOnly(inv.period_end)}
                  </td>
                  <td className="px-4 py-3 font-bold">
                    {inv.amount.toLocaleString('fr-FR')} {inv.currency}
                  </td>
                  <td className="px-4 py-3 text-right">
                    <button
                      type="button"
                      onClick={() => handleDownload(inv)}
                      disabled={downloadingId === inv.id}
                      className="btn-secondary py-1.5 px-3 text-xs"
                    >
                      <Download className="w-3.5 h-3.5" />
                      <span>PDF</span>
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
};
