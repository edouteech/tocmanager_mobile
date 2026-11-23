import { useEffect, useState, useMemo } from 'react';
import { keepPreviousData, useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { clientsApi, suppliersApi } from '../../lib/api';
import { Client, Supplier } from '../../types';
import { exportToExcel } from '../../lib/exportUtils';
import { formatDateTime } from '../../lib/formatters';
import { PaymentReceiptData } from '../../components/common/PaymentReceiptModal';
import { useTenantContextKey } from '../../stores/tenantStore';
import { PartnerFormValues, PartnerKind } from './PartnerFormModal';
import { PartnerPaymentValues } from './PartnerPaymentModal';

export type PartnerEntity = Client | Supplier;

const INITIAL_FORM: PartnerFormValues = {
  name: '',
  contact_person: '',
  phone: '',
  email: '',
  address: '',
  balance: 0,
  notes: '',
};

export function usePartnersDirectory(kind: PartnerKind) {
  const queryClient = useQueryClient();
  const [boutiqueKey, magasinKey] = useTenantContextKey();
  const isSupplier = kind === 'supplier';
  const queryKeyRoot = isSupplier ? 'suppliers' : 'clients';
  const debtFilterId = isSupplier ? 'creditors' : 'debtors';

  const [search, setSearch] = useState('');
  const [filterMode, setFilterMode] = useState<string>('all');
  const [sortBy, setSortBy] = useState<string>('name_asc');
  const [page, setPage] = useState(1);
  const [limit, setLimit] = useState(50);

  const [isFormModalOpen, setIsFormModalOpen] = useState(false);
  const [editingPartner, setEditingPartner] = useState<PartnerEntity | null>(null);
  const [paymentTarget, setPaymentTarget] = useState<PartnerEntity | null>(null);
  const [confirmDelete, setConfirmDelete] = useState<PartnerEntity | null>(null);
  const [receiptData, setReceiptData] = useState<PaymentReceiptData | null>(null);
  const [formValues, setFormValues] = useState<PartnerFormValues>(INITIAL_FORM);
  const [paymentValues, setPaymentValues] = useState<PartnerPaymentValues>({ amount: 0, payment_method: 'Espèces', notes: '' });
  const [formError, setFormError] = useState<string | null>(null);
  const [paymentError, setPaymentError] = useState<string | null>(null);

  useEffect(() => {
    setPage(1);
  }, [boutiqueKey, magasinKey, search, filterMode, sortBy]);

  const { data: pagedData, isLoading, isFetching } = useQuery({
    queryKey: [queryKeyRoot, boutiqueKey, magasinKey, page, limit, search, filterMode, sortBy],
    queryFn: async () => {
      const sortParam = sortBy === 'debt_desc' ? 'balance_desc' : sortBy === 'debt_asc' ? 'balance_asc' : 'name_asc';
      if (isSupplier) {
        const res = await suppliersApi.getPaginated({ page, limit, q: search || undefined, only_creditors: filterMode === debtFilterId, sort: sortParam });
        return {
          items: res.items as PartnerEntity[],
          page: res.page,
          pages: res.pages,
          total: res.total,
          summary: res.summary
            ? { total: res.summary.total_suppliers, withDebt: res.summary.creditors_count, settled: res.summary.settled_count, totalDebt: res.summary.total_debt }
            : undefined,
        };
      }
      const res = await clientsApi.getPaginated({ page, limit, q: search || undefined, only_debtors: filterMode === debtFilterId, sort: sortParam });
      return {
        items: res.items as PartnerEntity[],
        page: res.page,
        pages: res.pages,
        total: res.total,
        summary: res.summary
          ? { total: res.summary.total_clients, withDebt: res.summary.debtors_count, settled: res.summary.settled_count, totalDebt: res.summary.total_debt }
          : undefined,
      };
    },
    placeholderData: keepPreviousData,
  });

  const partners = useMemo(() => pagedData?.items ?? [], [pagedData?.items]);
  const filteredPartners = useMemo(() => {
    return filterMode === 'uptodate' ? partners.filter((p) => p.balance <= 0) : partners;
  }, [partners, filterMode]);

  const stats = useMemo(() => {
    if (pagedData?.summary) return pagedData.summary;
    let withDebt = 0;
    let settled = 0;
    let totalDebt = 0;
    partners.forEach((p) => {
      if (p.balance > 0) {
        withDebt++;
        totalDebt += p.balance;
      } else settled++;
    });
    return { total: partners.length, withDebt, settled, totalDebt };
  }, [pagedData?.summary, partners]);

  const invalidate = () => queryClient.invalidateQueries({ queryKey: [queryKeyRoot] });

  const createMutation = useMutation({
    mutationFn: (payload: PartnerFormValues) =>
      isSupplier ? suppliersApi.create(payload) : clientsApi.create(payload),
    onSuccess: () => {
      invalidate();
      setIsFormModalOpen(false);
      setFormValues(INITIAL_FORM);
    },
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: Partial<PartnerEntity> }) =>
      isSupplier ? suppliersApi.update(id, data) : clientsApi.update(id, data),
    onSuccess: () => {
      invalidate();
      setIsFormModalOpen(false);
      setEditingPartner(null);
      setFormValues(INITIAL_FORM);
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => (isSupplier ? suppliersApi.delete(id) : clientsApi.delete(id)),
    onSuccess: () => {
      invalidate();
      setConfirmDelete(null);
    },
  });

  const paymentMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: PartnerPaymentValues }) =>
      isSupplier ? suppliersApi.recordPayment(id, data) : clientsApi.recordPayment(id, data),
    onSuccess: (updated, variables) => {
      invalidate();
      if (paymentTarget) {
        setReceiptData({
          type: kind,
          recipientName: paymentTarget.name,
          phone: paymentTarget.phone,
          amount: variables.data.amount,
          previousBalance: paymentTarget.balance,
          newBalance: updated.balance,
          paymentMethod: variables.data.payment_method,
          notes: variables.data.notes,
        });
      }
      setPaymentTarget(null);
      setPaymentValues({ amount: 0, payment_method: 'Espèces', notes: '' });
    },
  });

  const openCreate = () => {
    setEditingPartner(null);
    setFormValues(INITIAL_FORM);
    setFormError(null);
    setIsFormModalOpen(true);
  };

  const openEdit = (p: PartnerEntity) => {
    setEditingPartner(p);
    setFormValues({
      name: p.name,
      contact_person: 'contact_person' in p ? p.contact_person || '' : '',
      phone: p.phone || '',
      email: p.email || '',
      address: p.address || '',
      balance: p.balance,
      notes: p.notes || '',
    });
    setFormError(null);
    setIsFormModalOpen(true);
  };

  const openPayment = (p: PartnerEntity) => {
    setPaymentTarget(p);
    setPaymentValues({
      amount: p.balance,
      payment_method: 'Espèces',
      notes: isSupplier ? `Règlement fournisseur ${p.name}` : `Règlement créance ${p.name}`,
    });
    setPaymentError(null);
  };

  const submitForm = (e: React.FormEvent) => {
    e.preventDefault();
    setFormError(null);
    if (!formValues.name.trim()) {
      return setFormError(isSupplier ? 'Le nom du fournisseur est obligatoire.' : 'Le nom du client est obligatoire.');
    }
    if (editingPartner) {
      updateMutation.mutate({
        id: editingPartner.sync_id,
        data: {
          name: formValues.name,
          ...(isSupplier ? { contact_person: formValues.contact_person || null } : {}),
          phone: formValues.phone || null,
          email: formValues.email || null,
          address: formValues.address || null,
          notes: formValues.notes || null,
        },
      });
    } else {
      createMutation.mutate(formValues);
    }
  };

  const submitPayment = (e: React.FormEvent) => {
    e.preventDefault();
    setPaymentError(null);
    if (!paymentTarget || paymentValues.amount <= 0) {
      return setPaymentError('Le montant du règlement doit être supérieur à 0.');
    }
    paymentMutation.mutate({ id: paymentTarget.sync_id, data: paymentValues });
  };

  const handleExport = () => {
    const rows = filteredPartners.map((p) => ({
      [isSupplier ? 'Raison Sociale' : 'Nom du Client']: p.name,
      ...(isSupplier ? { 'Contact Référent': 'contact_person' in p ? p.contact_person || '' : '' } : {}),
      Téléphone: p.phone || '',
      Email: p.email || '',
      Adresse: p.address || '',
      [isSupplier ? 'Dette Due (FCFA)' : 'Dette Restante (FCFA)']: p.balance,
      ...(isSupplier ? {} : { 'Date Création': p.created_at ? formatDateTime(p.created_at) : '' }),
    }));
    exportToExcel(rows, `${isSupplier ? 'fournisseurs' : 'clients'}_${new Date().toISOString().slice(0, 10)}.xlsx`, isSupplier ? 'Fournisseurs' : 'Clients');
  };

  return {
    pagedData, filteredPartners, stats, isLoading, isFetching, search, setSearch, filterMode, setFilterMode,
    sortBy, setSortBy, page, setPage, limit, setLimit, isFormModalOpen, setIsFormModalOpen, editingPartner,
    paymentTarget, setPaymentTarget, confirmDelete, setConfirmDelete, receiptData, setReceiptData,
    formValues, setFormValues, paymentValues, setPaymentValues, formError, paymentError,
    isSavingForm: createMutation.isPending || updateMutation.isPending,
    isDeleting: deleteMutation.isPending, isRecordingPayment: paymentMutation.isPending,
    openCreate, openEdit, openPayment, submitForm, submitPayment, handleExport,
    confirmDeletion: () => { if (confirmDelete) deleteMutation.mutate(confirmDelete.sync_id); },
  };
}
