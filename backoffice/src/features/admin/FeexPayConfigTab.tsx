import React, { useEffect, useState } from 'react';
import { CheckCircle2, AlertCircle, Save, ShieldCheck } from 'lucide-react';
import { adminApi } from '../../lib/api';
import { AdminPaymentProvider } from '../../types';

const ALL_NETWORKS = [
  'MTN', 'MOOV', 'CELTIIS BJ', 'CORIS',
  'TOGOCOM TG', 'MOOV TG',
  'MTN CI', 'ORANGE CI', 'MOOV CI', 'WAVE CI',
  'ORANGE SN', 'WAVE SN', 'FREE SN',
  'MOOV BF', 'ORANGE BF', 'WAVE BF',
  'ORANGE ML', 'MOBICASH ML', 'MTN CG',
];

export const FeexPayConfigTab: React.FC = () => {
  const [provider, setProvider] = useState<AdminPaymentProvider | null>(null);
  const [loading, setLoading] = useState(true);
  const [isActive, setIsActive] = useState(true);
  const [mode, setMode] = useState<'sandbox' | 'live'>('sandbox');
  const [baseUrl, setBaseUrl] = useState('');
  const [sbKey, setSbKey] = useState('');
  const [sbId, setSbId] = useState('');
  const [lvKey, setLvKey] = useState('');
  const [lvId, setLvId] = useState('');
  const [networks, setNetworks] = useState<string[]>([]);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [saved, setSaved] = useState(false);

  const loadProvider = () => {
    setLoading(true);
    adminApi
      .getPaymentProvider('feexpay')
      .then((p) => {
        setProvider(p);
        setIsActive(p.is_active);
        setMode(p.mode);
        setBaseUrl(p.base_url);
        setSbKey('');
        setSbId(p.sandbox.api_id || '');
        setLvKey('');
        setLvId(p.live.api_id || '');
        setNetworks(p.networks || ALL_NETWORKS);
      })
      .catch(() => setError('Impossible de charger la configuration FeexPay.'))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    loadProvider();
  }, []);

  const toggleNetwork = (net: string) => {
    setNetworks((prev) => (prev.includes(net) ? prev.filter((n) => n !== net) : [...prev, net]));
  };

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    setError(null);
    setSaved(false);
    try {
      const updated = await adminApi.updatePaymentProvider('feexpay', {
        is_active: isActive,
        mode,
        base_url: baseUrl.trim(),
        networks,
        sandbox: {
          api_key: sbKey.trim() || undefined,
          api_id: sbId.trim(),
        },
        live: {
          api_key: lvKey.trim() || undefined,
          api_id: lvId.trim(),
        },
      });
      setProvider(updated);
      setSbKey('');
      setLvKey('');
      setSaved(true);
    } catch (err: any) {
      setError(err.response?.data?.detail || 'Erreur lors de la sauvegarde FeexPay.');
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return <div className="card-toc p-8 text-center text-xs text-[#5A7184]">Chargement configuration FeexPay...</div>;
  }

  return (
    <form onSubmit={handleSave} className="space-y-5 text-xs">
      {error && (
        <div className="p-3 rounded-xl bg-[#FDEBE9] border border-[#E74C3C]/30 text-[#E74C3C] flex items-center gap-2">
          <AlertCircle className="w-4 h-4 shrink-0" />
          <span>{error}</span>
        </div>
      )}
      {saved && (
        <div className="p-3 rounded-xl bg-[#E8F8F0] border border-[#27AE60]/30 text-[#27AE60] font-semibold flex items-center gap-2">
          <CheckCircle2 className="w-4 h-4 shrink-0" />
          <span>Configuration FeexPay chiffrée et enregistrée avec succès.</span>
        </div>
      )}

      <div className="card-toc p-5 space-y-4">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3 border-b border-[#E8EFF5] dark:border-dark-600">
          <div className="flex items-center gap-2">
            <ShieldCheck className="w-5 h-5 text-[#29ABE2]" />
            <div>
              <h3 className="text-sm font-bold text-[#1C2B3A] dark:text-white">Passerelle FeexPay Mobile Money</h3>
              <p className="text-[11px] text-[#5A7184]">Les clés API sont chiffrées en base via Fernet et jamais réaffichées en clair.</p>
            </div>
          </div>

          <div className="flex items-center gap-4">
            <label className="inline-flex items-center gap-2 font-bold cursor-pointer">
              <input type="checkbox" checked={isActive} onChange={(e) => setIsActive(e.target.checked)} className="rounded text-[#29ABE2]" />
              <span>Passerelle active</span>
            </label>
            <div className="inline-flex rounded-xl bg-[#F0F9FE] dark:bg-dark-700 p-1 border border-[#E8EFF5] dark:border-dark-600">
              <button type="button" onClick={() => setMode('sandbox')} className={`px-3 py-1 rounded-lg font-bold ${mode === 'sandbox' ? 'bg-[#F39C12] text-white' : 'text-[#5A7184]'}`}>Sandbox</button>
              <button type="button" onClick={() => setMode('live')} className={`px-3 py-1 rounded-lg font-bold ${mode === 'live' ? 'bg-[#27AE60] text-white' : 'text-[#5A7184]'}`}>Live</button>
            </div>
          </div>
        </div>

        <div>
          <label className="block font-bold mb-1">URL API de base</label>
          <input type="url" value={baseUrl} onChange={(e) => setBaseUrl(e.target.value)} className="input-toc font-mono" />
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="p-4 rounded-xl bg-[#FEF5E7]/60 dark:bg-[#F39C12]/10 border border-[#F39C12]/30 space-y-3">
            <div className="font-bold text-[#F39C12]">Identifiants SANDBOX (Test)</div>
            <div>
              <label className="block font-semibold mb-1">
                API Key {provider?.sandbox.has_api_key ? `(${provider.sandbox.api_key_masked})` : ''}
              </label>
              <input type="password" value={sbKey} onChange={(e) => setSbKey(e.target.value)} placeholder={provider?.sandbox.has_api_key ? 'Laisser vide pour conserver' : 'fp_sandbox_...'} className="input-toc font-mono" />
            </div>
            <div>
              <label className="block font-semibold mb-1">Shop / API ID</label>
              <input type="text" value={sbId} onChange={(e) => setSbId(e.target.value)} className="input-toc font-mono" />
            </div>
          </div>

          <div className="p-4 rounded-xl bg-[#E8F8F0]/60 dark:bg-[#27AE60]/10 border border-[#27AE60]/30 space-y-3">
            <div className="font-bold text-[#27AE60]">Identifiants LIVE (Production)</div>
            <div>
              <label className="block font-semibold mb-1">
                API Key {provider?.live.has_api_key ? `(${provider.live.api_key_masked})` : ''}
              </label>
              <input type="password" value={lvKey} onChange={(e) => setLvKey(e.target.value)} placeholder={provider?.live.has_api_key ? 'Laisser vide pour conserver' : 'fp_live_...'} className="input-toc font-mono" />
            </div>
            <div>
              <label className="block font-semibold mb-1">Shop / API ID</label>
              <input type="text" value={lvId} onChange={(e) => setLvId(e.target.value)} className="input-toc font-mono" />
            </div>
          </div>
        </div>

        <div>
          <label className="block font-bold mb-2">Réseaux Mobile Money activés ({networks.length})</label>
          <div className="flex flex-wrap gap-2">
            {ALL_NETWORKS.map((net) => {
              const active = networks.includes(net);
              return (
                <button
                  key={net}
                  type="button"
                  onClick={() => toggleNetwork(net)}
                  className={`px-2.5 py-1 rounded-lg border text-[11px] font-semibold transition ${
                    active ? 'bg-[#E8F5FD] border-[#29ABE2] text-[#29ABE2]' : 'border-[#E8EFF5] dark:border-dark-600 text-[#9FB3C8]'
                  }`}
                >
                  {net}
                </button>
              );
            })}
          </div>
        </div>

        <div className="flex justify-end pt-2">
          <button type="submit" disabled={saving} className="btn-primary text-xs">
            <Save className="w-4 h-4" />
            <span>{saving ? 'Enregistrement...' : 'Enregistrer la configuration FeexPay'}</span>
          </button>
        </div>
      </div>
    </form>
  );
};
