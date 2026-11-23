import React, { useEffect, useState } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import { Store } from 'lucide-react';
import { saasApi } from '../../lib/api';
import { useAuthStore } from '../../stores/authStore';
import { useTenantStore } from '../../stores/tenantStore';
import { SaasPlan } from '../../types';
import { RegisterStep1Form } from './RegisterStep1Form';
import { RegisterStep2Form } from './RegisterStep2Form';

export const RegisterPage: React.FC = () => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const initialPlan = searchParams.get('plan') || 'pro';
  const initialCycle = searchParams.get('cycle') === 'yearly' ? 'yearly' : 'monthly';

  const [step, setStep] = useState<1 | 2>(1);
  const [fullName, setFullName] = useState('');
  const [identifier, setIdentifier] = useState('');
  const [password, setPassword] = useState('');
  const [phone, setPhone] = useState('');
  const [acceptTerms, setAcceptTerms] = useState(false);
  const [registeredIdentifier, setRegisteredIdentifier] = useState<string | null>(null);

  const [boutiqueName, setBoutiqueName] = useState('');
  const [companyName, setCompanyName] = useState('');
  const [currency, setCurrency] = useState('XOF');
  const [country, setCountry] = useState('Sénégal');
  const [magasinName, setMagasinName] = useState('Magasin Principal');
  const [selectedPlan, setSelectedPlan] = useState(initialPlan);
  const [billingCycle, setBillingCycle] = useState<'monthly' | 'yearly'>(initialCycle);

  const [plans, setPlans] = useState<SaasPlan[]>([]);
  const [plansLoading, setPlansLoading] = useState(true);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    saasApi
      .getPlans()
      .then((data) => {
        setPlans(data);
        if (data.length > 0) {
          setSelectedPlan((prev) => (data.some((p) => p.code === prev) ? prev : data[0].code));
        }
      })
      .catch(() => {
        setPlans([]);
      })
      .finally(() => setPlansLoading(false));
  }, []);

  const handleStep1Submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    const normalizedIdent = identifier.trim().toLowerCase();
    if (!fullName.trim() || !normalizedIdent || !password) {
      setError('Veuillez remplir tous les champs obligatoires.');
      return;
    }
    if (password.length < 6) {
      setError('Le mot de passe doit comporter au moins 6 caractères.');
      return;
    }
    if (!acceptTerms) {
      setError("Veuillez accepter les Conditions Générales d'Utilisation.");
      return;
    }

    if (registeredIdentifier === normalizedIdent && localStorage.getItem('toc_access_token')) {
      setStep(2);
      return;
    }

    setLoading(true);
    try {
      const res = await saasApi.registerCredentials({
        full_name: fullName.trim(),
        username_or_email: normalizedIdent,
        password,
        phone: phone.trim() || undefined,
      });

      localStorage.setItem('toc_access_token', res.access_token);
      setRegisteredIdentifier(normalizedIdent);
      setStep(2);
    } catch (err: any) {
      setError(
        err.response?.data?.detail ||
          "Une erreur est survenue lors de l'enregistrement de vos identifiants."
      );
    } finally {
      setLoading(false);
    }
  };

  const handleStep2Submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    if (!boutiqueName.trim()) {
      setError('Veuillez renseigner le nom de votre boutique ou entreprise.');
      return;
    }

    setLoading(true);
    try {
      const res = await saasApi.provisionTenant({
        boutique_name: boutiqueName.trim(),
        company_name: companyName.trim() || boutiqueName.trim(),
        currency,
        country: country.trim() || 'Sénégal',
        phone: phone.trim() || undefined,
        magasin_name: magasinName.trim() || 'Magasin Principal',
        plan_code: selectedPlan,
        billing_cycle: billingCycle,
      });

      useAuthStore.getState().setAuth({
        access_token: res.access_token,
        refresh_token: res.refresh_token,
        token_type: res.token_type,
        user: res.user,
      });
      localStorage.setItem('toc_current_boutique_id', res.boutique_id);
      localStorage.setItem('toc_current_magasin_id', res.magasin_id);
      await useTenantStore.getState().initTenant();

      navigate('/?welcome=1', { replace: true });
    } catch (err: any) {
      setError(
        err.response?.data?.detail || "Erreur lors de la configuration de l'entreprise."
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#F5FAFD] dark:bg-dark-900 flex flex-col justify-center py-10 px-4 sm:px-6 lg:px-8 font-sans">
      <div className="sm:mx-auto sm:w-full sm:max-w-md text-center space-y-3">
        <Link to="/" className="inline-flex items-center gap-3">
          <div className="w-11 h-11 rounded-2xl toc-gradient flex items-center justify-center text-white shadow-soft">
            <Store className="w-6 h-6" />
          </div>
          <span className="text-2xl font-black text-[#1C2B3A] dark:text-white">
            Toc<span className="text-[#29ABE2]">Manager</span>
          </span>
        </Link>

        <div className="flex items-center justify-center gap-2 pt-2">
          <div className={`flex items-center gap-1.5 text-xs font-semibold ${step === 1 ? 'text-[#29ABE2]' : 'text-[#27AE60]'}`}>
            <span className="w-5 h-5 rounded-full flex items-center justify-center bg-[#E8F5FD] dark:bg-[#29ABE2]/20">
              1
            </span>
            <span>Identifiants</span>
          </div>
          <div className="w-6 h-0.5 bg-[#E8EFF5] dark:bg-dark-600" />
          <div className={`flex items-center gap-1.5 text-xs font-semibold ${step === 2 ? 'text-[#29ABE2]' : 'text-[#9FB3C8]'}`}>
            <span className="w-5 h-5 rounded-full flex items-center justify-center bg-[#F0F9FE] dark:bg-dark-700">
              2
            </span>
            <span>Entreprise & Boutique</span>
          </div>
        </div>
      </div>

      <div className="mt-6 sm:mx-auto sm:w-full sm:max-w-2xl">
        <div className="card-toc py-8 px-6 sm:px-10 shadow-soft-md">
          {error && (
            <div className="mb-6 p-3 bg-[#FDEBE9] dark:bg-[#E74C3C]/15 border border-[#E74C3C]/30 text-[#E74C3C] text-xs rounded-xl font-medium">
              {error}
            </div>
          )}

          {step === 1 ? (
            <RegisterStep1Form
              fullName={fullName}
              setFullName={setFullName}
              identifier={identifier}
              setIdentifier={setIdentifier}
              phone={phone}
              setPhone={setPhone}
              password={password}
              setPassword={setPassword}
              acceptTerms={acceptTerms}
              setAcceptTerms={setAcceptTerms}
              loading={loading}
              onSubmit={handleStep1Submit}
            />
          ) : (
            <RegisterStep2Form
              boutiqueName={boutiqueName}
              setBoutiqueName={setBoutiqueName}
              companyName={companyName}
              setCompanyName={setCompanyName}
              currency={currency}
              setCurrency={setCurrency}
              country={country}
              setCountry={setCountry}
              magasinName={magasinName}
              setMagasinName={setMagasinName}
              selectedPlan={selectedPlan}
              setSelectedPlan={setSelectedPlan}
              billingCycle={billingCycle}
              setBillingCycle={setBillingCycle}
              plans={plans}
              plansLoading={plansLoading}
              loading={loading}
              onBack={() => {
                setError(null);
                setStep(1);
              }}
              onSubmit={handleStep2Submit}
            />
          )}
        </div>
      </div>
    </div>
  );
};
