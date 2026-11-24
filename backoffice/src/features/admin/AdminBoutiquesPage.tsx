import React, { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Search } from 'lucide-react';
import { adminApi } from '../../lib/api';
import { AdminBoutiqueDetail, AdminBoutiqueItem, SaasPlan } from '../../types';
import { useAuthStore } from '../../stores/authStore';
import { useTenantStore } from '../../stores/tenantStore';
import { queryClient } from '../../lib/queryClient';
import { ExtendTrialModal } from './ExtendTrialModal';
import { ChangePlanModal } from './ChangePlanModal';
import { BoutiqueDetailDrawer } from './BoutiqueDetailDrawer';
import { AdminBoutiquesTable } from './AdminBoutiquesTable';
import { IconInput } from '../../components/common/IconInput';

export const AdminBoutiquesPage: React.FC = () => {
  const navigate = useNavigate();

  const [boutiques, setBoutiques] = useState<AdminBoutiqueItem[]>([]);
  const [plans, setPlans] = useState<SaasPlan[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [q, setQ] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [planFilter, setPlanFilter] = useState('');
  const [page, setPage] = useState(1);

  const [trialBoutique, setTrialBoutique] = useState<AdminBoutiqueItem | null>(null);
  const [planBoutique, setPlanBoutique] = useState<AdminBoutiqueItem | null>(null);
  const [detailData, setDetailData] = useState<AdminBoutiqueDetail | null>(null);
  const [detailLoading, setDetailLoading] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [actionError, setActionError] = useState<string | null>(null);

  const fetchBoutiques = () => {
    setLoading(true);
    adminApi
      .getBoutiques({
        q: q.trim() || undefined,
        status: statusFilter || undefined,
        plan_code: planFilter || undefined,
        paginated: true,
        page,
        limit: 20,
      })
      .then((res) => {
        if (Array.isArray(res)) {
          setBoutiques(res);
          setTotal(res.length);
        } else {
          setBoutiques(res.items);
          setTotal(res.total);
        }
      })
      .catch(() => setBoutiques([]))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    adminApi.getPlans().then(setPlans).catch(() => setPlans([]));
  }, []);

  useEffect(() => {
    fetchBoutiques();
  }, [page, statusFilter, planFilter]);

  const handleToggleStatus = async (b: AdminBoutiqueItem) => {
    setActionError(null);
    try {
      await adminApi.toggleBoutiqueStatus(b.id, !b.is_active);
      fetchBoutiques();
    } catch (err: any) {
      setActionError(err.response?.data?.detail || 'Erreur lors du changement de statut.');
    }
  };

  const handleExtendTrial = async (boutiqueId: string, days: number) => {
    setSubmitting(true);
    setActionError(null);
    try {
      await adminApi.extendTrial(boutiqueId, days);
      setTrialBoutique(null);
      fetchBoutiques();
    } catch (err: any) {
      setActionError(err.response?.data?.detail || "Erreur lors de la prolongation d'essai.");
    } finally {
      setSubmitting(false);
    }
  };

  const handleAssignPlan = async (
    boutiqueId: string,
    payload: Parameters<typeof adminApi.assignBoutiquePlan>[1]
  ) => {
    setSubmitting(true);
    setActionError(null);
    try {
      await adminApi.assignBoutiquePlan(boutiqueId, payload);
      setPlanBoutique(null);
      fetchBoutiques();
    } catch (err: any) {
      setActionError(err.response?.data?.detail || 'Erreur lors du changement de forfait.');
    } finally {
      setSubmitting(false);
    }
  };

  const handleOpenDetail = async (id: string) => {
    setDetailLoading(true);
    setDetailData(null);
    try {
      const detail = await adminApi.getBoutiqueDetail(id);
      setDetailData(detail);
    } catch {
      setActionError('Impossible de charger la fiche détaillée.');
    } finally {
      setDetailLoading(false);
    }
  };

  const handleImpersonate = async (boutiqueId: string) => {
    setSubmitting(true);
    try {
      const res = await adminApi.impersonateBoutique(boutiqueId);
      localStorage.setItem(
        'toc_admin_backup_session',
        JSON.stringify({
          access_token: localStorage.getItem('toc_access_token'),
          refresh_token: localStorage.getItem('toc_refresh_token'),
          user: JSON.parse(localStorage.getItem('toc_user') || 'null'),
        })
      );
      localStorage.setItem(
        'toc_impersonation_meta',
        JSON.stringify({
          boutique_id: res.boutique_id,
          boutique_name: res.boutique_name,
          expires_in_minutes: res.expires_in_minutes,
        })
      );
      useAuthStore.getState().setAuth({
        access_token: res.access_token,
        refresh_token: '',
        token_type: res.token_type,
        user: res.user,
      });
      localStorage.setItem('toc_current_boutique_id', res.boutique_id);
      localStorage.removeItem('toc_current_magasin_id');
      queryClient.clear();
      await useTenantStore.getState().initTenant();
      navigate('/');
    } catch (err: any) {
      setActionError(err.response?.data?.detail || "Impossible d'ouvrir le mode support.");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      <div>
        <h1 className="text-2xl font-extrabold text-[#1C2B3A] dark:text-white tracking-tight">
          Annuaire des Boutiques Clientes ({total})
        </h1>
        <p className="text-xs sm:text-sm text-[#5A7184] dark:text-slate-400 mt-0.5">
          Supervisez les comptes commerçants, prolongez les essais, assignez un forfait ou inspectez en lecture seule.
        </p>
      </div>

      {actionError && (
        <div className="p-3 rounded-xl bg-[#FDEBE9] border border-[#E74C3C]/30 text-[#E74C3C] text-xs font-medium">
          {actionError}
        </div>
      )}

      <div className="card-toc p-4 flex flex-col sm:flex-row gap-3">
        <IconInput
          containerClassName="flex-1"
          icon={<Search className="w-4 h-4" />}
          type="text"
          value={q}
          onChange={(e) => setQ(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === 'Enter') {
              setPage(1);
              fetchBoutiques();
            }
          }}
          placeholder="Rechercher boutique, société, propriétaire, email..."
          className="text-xs"
        />
        <select value={statusFilter} onChange={(e) => { setStatusFilter(e.target.value); setPage(1); }} className="input-toc sm:w-44 text-xs">
          <option value="">Tous statuts</option>
          <option value="active">Abonnement actif</option>
          <option value="trialing">En essai</option>
          <option value="suspended">Compte suspendu</option>
        </select>
        <select value={planFilter} onChange={(e) => { setPlanFilter(e.target.value); setPage(1); }} className="input-toc sm:w-44 text-xs">
          <option value="">Tous forfaits</option>
          {plans.map((p) => (
            <option key={p.id} value={p.code}>{p.name}</option>
          ))}
        </select>
        <button type="button" onClick={() => { setPage(1); fetchBoutiques(); }} className="btn-primary text-xs shrink-0">
          Rechercher
        </button>
      </div>

      <AdminBoutiquesTable
        boutiques={boutiques}
        loading={loading}
        onDetail={handleOpenDetail}
        onAssignPlan={(b) => { setActionError(null); setPlanBoutique(b); }}
        onExtendTrial={(b) => { setActionError(null); setTrialBoutique(b); }}
        onToggleStatus={handleToggleStatus}
      />

      <ExtendTrialModal boutique={trialBoutique} isSubmitting={submitting} error={actionError} onClose={() => setTrialBoutique(null)} onConfirm={handleExtendTrial} />
      <ChangePlanModal boutique={planBoutique} plans={plans} isSubmitting={submitting} error={actionError} onClose={() => setPlanBoutique(null)} onConfirm={handleAssignPlan} />
      <BoutiqueDetailDrawer detail={detailData} loading={detailLoading} impersonating={submitting} onClose={() => setDetailData(null)} onImpersonate={handleImpersonate} />
    </div>
  );
};
