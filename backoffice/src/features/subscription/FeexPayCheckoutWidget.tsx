import React, { useEffect, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { Loader2, Smartphone, CheckCircle2, AlertCircle, ExternalLink } from 'lucide-react';
import { billingApi } from '../../lib/api';
import { SaasPlan } from '../../types';

interface Props {
  plan: SaasPlan;
  onPaymentSuccess: () => Promise<void> | void;
}

export const FeexPayCheckoutWidget: React.FC<Props> = ({ plan, onPaymentSuccess }) => {
  const [billingCycle, setBillingCycle] = useState<'monthly' | 'yearly'>('monthly');
  const [countryCode, setCountryCode] = useState('BJ');
  const [network, setNetwork] = useState('MTN');
  const [phone, setPhone] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [pendingRef, setPendingRef] = useState<string | null>(null);
  const [paymentStatus, setPaymentStatus] = useState<string | null>(null);
  const [redirectUrl, setRedirectUrl] = useState<string | null>(null);

  const { data: methodsData } = useQuery({
    queryKey: ['billing-payment-methods'],
    queryFn: billingApi.getPaymentMethods,
  });

  const provider = methodsData?.providers?.[0];
  const countries = provider?.countries || [];
  const selectedCountry = countries.find((c) => c.code === countryCode) || countries[0];
  const availableNetworks = selectedCountry?.networks || ['MTN', 'MOOV'];

  useEffect(() => {
    if (selectedCountry && !selectedCountry.networks.includes(network)) {
      setNetwork(selectedCountry.networks[0] || 'MTN');
    }
  }, [countryCode, selectedCountry, network]);

  useEffect(() => {
    if (!pendingRef) return;
    const timer = window.setInterval(async () => {
      try {
        const res = await billingApi.getStatus(pendingRef);
        setPaymentStatus(res.status);
        if (res.status === 'successful') {
          window.clearInterval(timer);
          setPendingRef(null);
          await onPaymentSuccess();
        } else if (res.status === 'failed' || res.status === 'canceled') {
          window.clearInterval(timer);
          setPendingRef(null);
          setErrorMsg('Le paiement n a pas abouti. Veuillez reessayer.');
        }
      } catch {
        // Keep polling transiently until user cancels or succeeds
      }
    }, 3000);
    return () => window.clearInterval(timer);
  }, [pendingRef, onPaymentSuccess]);

  const amount = billingCycle === 'yearly' ? plan.price_yearly : plan.price_monthly;

  const handleCheckout = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMsg(null);
    setRedirectUrl(null);
    if (!phone.trim()) {
      setErrorMsg('Veuillez saisir un numero Mobile Money valide.');
      return;
    }
    setSubmitting(true);
    try {
      const res = await billingApi.checkout({
        plan_code: plan.code,
        billing_cycle: billingCycle,
        network,
        phone: phone.trim(),
      });
      setPaymentStatus(res.status);
      if (res.status === 'successful') {
        await onPaymentSuccess();
        return;
      }
      if (res.flow_type === 'redirect' && res.payment_url) {
        setRedirectUrl(res.payment_url);
        window.location.assign(res.payment_url);
        return;
      }
      setPendingRef(res.reference);
    } catch (err: any) {
      setErrorMsg(err.response?.data?.detail || 'Echec de l initiation du paiement FeexPay.');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <form onSubmit={handleCheckout} className="space-y-4">
      <div className="flex gap-2 p-1 rounded-xl bg-[#F0F9FE] dark:bg-dark-700 border border-[#E8EFF5] dark:border-dark-600">
        {(['monthly', 'yearly'] as const).map((cycle) => (
          <button
            key={cycle}
            type="button"
            onClick={() => setBillingCycle(cycle)}
            className={`flex-1 py-2 text-xs font-bold rounded-lg transition ${
              billingCycle === cycle
                ? 'bg-[#29ABE2] text-white'
                : 'text-[#5A7184] dark:text-slate-300'
            }`}
          >
            {cycle === 'monthly'
              ? `Mensuel (${plan.price_monthly.toLocaleString('fr-FR')} ${plan.currency})`
              : `Annuel (${plan.price_yearly.toLocaleString('fr-FR')} ${plan.currency})`}
          </button>
        ))}
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
        <div>
          <label className="block text-xs font-bold text-[#5A7184] dark:text-slate-400 mb-1">
            Pays
          </label>
          <select
            value={selectedCountry?.code || countryCode}
            onChange={(e) => setCountryCode(e.target.value)}
            className="input-toc text-xs"
          >
            {countries.map((c) => (
              <option key={c.code} value={c.code}>
                {c.name} ({c.dial_code})
              </option>
            ))}
          </select>
        </div>
        <div>
          <label className="block text-xs font-bold text-[#5A7184] dark:text-slate-400 mb-1">
            Operateur Mobile Money
          </label>
          <select
            value={network}
            onChange={(e) => setNetwork(e.target.value)}
            className="input-toc text-xs"
          >
            {availableNetworks.map((net) => (
              <option key={net} value={net}>
                {net}
              </option>
            ))}
          </select>
        </div>
      </div>

      <div>
        <label className="block text-xs font-bold text-[#5A7184] dark:text-slate-400 mb-1">
          Numero Mobile Money ({selectedCountry?.dial_code || '+229'})
        </label>
        <input
          type="tel"
          value={phone}
          onChange={(e) => setPhone(e.target.value)}
          placeholder="Ex: 22990000000"
          className="input-toc text-sm"
        />
      </div>

      {pendingRef && (
        <div className="p-3 rounded-xl bg-[#E8F5FD] dark:bg-[#29ABE2]/10 border border-[#BAE3F9] dark:border-[#29ABE2]/30 flex items-center gap-2.5 text-xs text-[#134B64] dark:text-[#BAE3F9]">
          <Loader2 className="w-4 h-4 animate-spin shrink-0 text-[#29ABE2]" />
          <span>
            Validez le paiement USSD sur votre telephone (Ref: {pendingRef}). Verification automatique...
          </span>
        </div>
      )}

      {redirectUrl && (
        <a
          href={redirectUrl}
          className="flex items-center justify-center gap-1.5 text-xs font-bold text-[#29ABE2] hover:underline"
        >
          <span>Continuer vers la page de paiement FeexPay</span>
          <ExternalLink className="w-3.5 h-3.5" />
        </a>
      )}

      {paymentStatus === 'successful' && (
        <div className="p-3 rounded-xl bg-[#E8F8F0] text-[#27AE60] text-xs font-bold flex items-center gap-2">
          <CheckCircle2 className="w-4 h-4" />
          <span>Paiement confirme et forfait active.</span>
        </div>
      )}

      {errorMsg && (
        <div className="p-3 rounded-xl bg-[#FDEBE9] text-[#E74C3C] text-xs font-semibold flex items-center gap-2">
          <AlertCircle className="w-4 h-4 shrink-0" />
          <span>{errorMsg}</span>
        </div>
      )}

      <button
        type="submit"
        disabled={submitting || Boolean(pendingRef)}
        className="btn-primary w-full"
      >
        <Smartphone className="w-4 h-4" />
        <span>
          {submitting
            ? 'Initialisation FeexPay...'
            : `Payer ${amount.toLocaleString('fr-FR')} ${plan.currency} via FeexPay`}
        </span>
      </button>
    </form>
  );
};
