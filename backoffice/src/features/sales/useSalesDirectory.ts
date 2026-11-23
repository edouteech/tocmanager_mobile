import { useEffect, useMemo, useState } from 'react';
import { keepPreviousData, useQuery, useQueryClient } from '@tanstack/react-query';
import { ventesApi } from '../../lib/api';
import { exportToExcel } from '../../lib/exportUtils';
import { formatDateTime, formatFCFA } from '../../lib/formatters';
import { Vente } from '../../types';
import { ViewMode } from '../../components/common/ViewToggle';
import { useAuthStore } from '../../stores/authStore';
import { useTenantContextKey, useTenantStore } from '../../stores/tenantStore';

export const useSalesDirectory = () => {
  const queryClient = useQueryClient();
  const user = useAuthStore((s) => s.user);
  const { currentBoutique, currentMagasin } = useTenantStore();
  const [boutiqueKey, magasinKey] = useTenantContextKey();

  const [searchTerm, setSearchTerm] = useState('');
  const [selectedVente, setSelectedVente] = useState<Vente | null>(null);
  const [refundTarget, setRefundTarget] = useState<Vente | null>(null);
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
  const [selectedPeriod, setSelectedPeriod] = useState<string>('all');
  const [onlyCredit, setOnlyCredit] = useState<boolean>(false);
  const [sortBy, setSortBy] = useState<string>('recent');
  const [viewMode, setViewMode] = useState<ViewMode>('cards');
  const [page, setPage] = useState(1);
  const [limit, setLimit] = useState(50);

  const canRefund = Boolean(user && user.role !== 'cashier');

  useEffect(() => {
    setPage(1);
  }, [boutiqueKey, magasinKey, searchTerm, selectedPeriod, onlyCredit]);

  const dateRange = useMemo(() => {
    const now = new Date();
    const toYmd = (d: Date) =>
      `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
    const todayYmd = toYmd(now);
    if (selectedPeriod === 'today') return { start_date: todayYmd, end_date: todayYmd };
    if (selectedPeriod === 'week') {
      const start = new Date(now);
      start.setDate(now.getDate() - 7);
      return { start_date: toYmd(start), end_date: todayYmd };
    }
    if (selectedPeriod === 'month') {
      return { start_date: toYmd(new Date(now.getFullYear(), now.getMonth(), 1)), end_date: todayYmd };
    }
    return {};
  }, [selectedPeriod]);

  const { data: ventesPage, isLoading, isFetching } = useQuery({
    queryKey: ['ventes', boutiqueKey, magasinKey, page, limit, searchTerm, selectedPeriod, onlyCredit],
    queryFn: () =>
      ventesApi.getPaginated({ page, limit, q: searchTerm || undefined, only_credit: onlyCredit || undefined, ...dateRange }),
    placeholderData: keepPreviousData,
  });

  const ventes = useMemo(() => ventesPage?.items ?? [], [ventesPage?.items]);
  const salesSummary = ventesPage?.summary;

  const sortedVentes = useMemo(() => {
    const list = [...ventes];
    if (sortBy === 'amount_desc') return list.sort((a, b) => b.total_amount - a.total_amount);
    if (sortBy === 'amount_asc') return list.sort((a, b) => a.total_amount - b.total_amount);
    if (sortBy === 'client_asc') {
      return list.sort((a, b) => (a.client_name || 'Occasionnel').localeCompare(b.client_name || 'Occasionnel'));
    }
    return list;
  }, [ventes, sortBy]);

  const filteredTotalAmount = useMemo(
    () => sortedVentes.reduce((s, v) => s + (v.total_amount || 0), 0),
    [sortedVentes]
  );

  const handleShareWhatsApp = (vente: Vente) => {
    const storeTitle = currentBoutique?.company_name || currentBoutique?.name || 'TocManager';
    const text = encodeURIComponent(
      `*REÇU DE VENTE - ${vente.ticket_number}*\n${storeTitle}${currentMagasin ? ` (${currentMagasin.name})` : ''}\nDate : ${formatDateTime(vente.created_at)}\nClient : ${vente.client_name || 'Occasionnel'}\nMontant Total : ${formatFCFA(vente.total_amount)}\nMode : ${vente.payment_method}\nMerci pour votre confiance !`
    );
    window.open(`https://wa.me/?text=${text}`, '_blank', 'noopener,noreferrer');
  };

  const handleExportExcel = () => {
    exportToExcel(
      sortedVentes.map((v) => ({
        'N° Ticket': v.ticket_number,
        'Date & Heure': formatDateTime(v.created_at),
        Client: v.client_name || 'Occasionnel',
        'Mode Paiement': v.payment_method,
        'Nb Articles': v.items?.length || 0,
        'Montant Total (FCFA)': v.total_amount,
        'Montant Versé (FCFA)': v.paid_amount,
        'Remise (FCFA)': v.discount_amount,
        'Reste Dû (FCFA)': v.total_amount > v.paid_amount ? v.total_amount - v.paid_amount : 0,
        Caissier: v.user_name || '',
      })),
      `ventes_${new Date().toISOString().slice(0, 10)}.xlsx`,
      'Journal des Ventes'
    );
  };

  const handleRefunded = (updated: Vente) => {
    setSelectedVente(updated);
    queryClient.invalidateQueries({ queryKey: ['ventes'] });
    queryClient.invalidateQueries({ queryKey: ['products'] });
    queryClient.invalidateQueries({ queryKey: ['clients'] });
  };

  return {
    canRefund,
    storeDisplayName: currentBoutique?.company_name || currentBoutique?.name || 'TocManager',
    magasinName: currentMagasin?.name,
    searchTerm, setSearchTerm, selectedVente, setSelectedVente, refundTarget, setRefundTarget,
    isCreateModalOpen, setIsCreateModalOpen, selectedPeriod, setSelectedPeriod,
    onlyCredit, setOnlyCredit, sortBy, setSortBy, viewMode, setViewMode,
    page, setPage, limit, setLimit,
    ventesPage, ventes, sortedVentes, filteredTotalAmount, salesSummary,
    isLoading, isFetching, handleShareWhatsApp, handleExportExcel, handleRefunded,
  };
};
