import React, { useState } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import { Store, User, Mail, Lock, Phone, ArrowRight, Building, CheckCircle2, ShieldCheck, Sparkles } from 'lucide-react';
import { saasApi } from '../../lib/api';

export const RegisterPage: React.FC = () => {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();
  const initialPlan = searchParams.get('plan') || 'pro';

  // Step 1: Identifiants
  const [step, setStep] = useState<1 | 2>(1);
  const [fullName, setFullName] = useState('');
  const [identifier, setIdentifier] = useState('');
  const [password, setPassword] = useState('');
  const [phone, setPhone] = useState('');
  const [onboardingToken, setOnboardingToken] = useState<string | null>(null);

  // Step 2: Entreprise & Première Boutique
  const [boutiqueName, setBoutiqueName] = useState('');
  const [companyName, setCompanyName] = useState('');
  const [currency, setCurrency] = useState('XOF');
  const [country, setCountry] = useState('Sénégal');
  const [magasinName, setMagasinName] = useState('Magasin Principal');
  const [selectedPlan, setSelectedPlan] = useState(initialPlan);

  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Soumission Étape 1 : Identifiants simples
  const handleStep1Submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    if (!fullName.trim() || !identifier.trim() || !password) {
      setError('Veuillez remplir tous les champs obligatoires.');
      return;
    }
    if (password.length < 6) {
      setError('Le mot de passe doit comporter au moins 6 caractères.');
      return;
    }

    setLoading(true);
    try {
      const res = await saasApi.registerCredentials({
        full_name: fullName.trim(),
        username_or_email: identifier.trim(),
        password,
        phone: phone.trim() || undefined,
      });

      setOnboardingToken(res.access_token);
      localStorage.setItem('toc_access_token', res.access_token);
      setStep(2);
    } catch (err: any) {
      setError(err.response?.data?.detail || "Une erreur est survenue lors de l'enregistrement de vos identifiants.");
    } finally {
      setLoading(false);
    }
  };

  // Soumission Étape 2 : Configuration Entreprise & Première Boutique
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
        country,
        phone: phone.trim() || undefined,
        magasin_name: magasinName.trim() || 'Magasin Principal',
        plan_code: selectedPlan,
      });

      // Stocker les tokens et le contexte actif
      localStorage.setItem('toc_access_token', res.access_token);
      localStorage.setItem('toc_current_boutique_id', res.boutique_id);
      localStorage.setItem('toc_current_magasin_id', res.magasin_id);

      // Redirection directe vers le tableau de bord client
      navigate('/?welcome=1');
    } catch (err: any) {
      setError(err.response?.data?.detail || "Erreur lors de la configuration de l'entreprise.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 dark:bg-slate-950 flex flex-col justify-center py-12 sm:px-6 lg:px-8 font-sans">
      <div className="sm:mx-auto sm:w-full sm:max-w-md text-center space-y-3">
        <Link to="/" className="inline-flex items-center gap-3">
          <div className="w-12 h-12 rounded-2xl bg-gradient-to-tr from-indigo-600 to-indigo-800 flex items-center justify-center text-white shadow-lg shadow-indigo-500/20">
            <Store className="w-7 h-7" />
          </div>
          <span className="text-2xl font-black text-slate-900 dark:text-white">
            Toc<span className="text-indigo-600">Manager</span>
          </span>
        </Link>

        {/* Indicateur d'étape */}
        <div className="flex items-center justify-center gap-2 pt-2">
          <div className={`flex items-center gap-1.5 text-xs font-semibold ${step === 1 ? 'text-indigo-600' : 'text-emerald-500'}`}>
            <span className="w-5 h-5 rounded-full flex items-center justify-center bg-indigo-100 dark:bg-indigo-950">1</span>
            <span>Identifiants</span>
          </div>
          <div className="w-6 h-0.5 bg-slate-200 dark:bg-slate-800" />
          <div className={`flex items-center gap-1.5 text-xs font-semibold ${step === 2 ? 'text-indigo-600' : 'text-slate-400'}`}>
            <span className="w-5 h-5 rounded-full flex items-center justify-center bg-slate-200 dark:bg-slate-800">2</span>
            <span>Entreprise & Boutique</span>
          </div>
        </div>
      </div>

      <div className="mt-6 sm:mx-auto sm:w-full sm:max-w-lg">
        <div className="bg-white dark:bg-slate-900 py-8 px-6 sm:px-10 rounded-2xl shadow-xl border border-slate-200 dark:border-slate-800">
          {error && (
            <div className="mb-6 p-3 bg-rose-50 dark:bg-rose-950/60 border border-rose-300 dark:border-rose-800 text-rose-700 dark:text-rose-300 text-xs rounded-xl font-medium">
              {error}
            </div>
          )}

          {step === 1 ? (
            /* ============================================================ */
            /* ÉTAPE 1 : IDENTIFIANTS SIMPLES                               */
            /* ============================================================ */
            <form onSubmit={handleStep1Submit} className="space-y-4">
              <div>
                <h2 className="text-lg font-bold text-slate-900 dark:text-white">Créez vos identifiants</h2>
                <p className="text-xs text-slate-500 mt-0.5">Quelques secondes suffisent pour créer votre compte gérant.</p>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1">
                  Nom complet *
                </label>
                <div className="relative">
                  <User className="w-4 h-4 text-slate-400 absolute left-3 top-3" />
                  <input
                    type="text"
                    required
                    placeholder="Ex: Amadou Diallo"
                    value={fullName}
                    onChange={(e) => setFullName(e.target.value)}
                    className="w-full pl-9 pr-3 py-2 text-sm rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-900 dark:text-white focus:ring-2 focus:ring-indigo-500 focus:outline-none"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1">
                  Email ou Identifiant de connexion *
                </label>
                <div className="relative">
                  <Mail className="w-4 h-4 text-slate-400 absolute left-3 top-3" />
                  <input
                    type="text"
                    required
                    placeholder="amadou@boutique.com"
                    value={identifier}
                    onChange={(e) => setIdentifier(e.target.value)}
                    className="w-full pl-9 pr-3 py-2 text-sm rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-900 dark:text-white focus:ring-2 focus:ring-indigo-500 focus:outline-none"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1">
                  Numéro de téléphone mobile
                </label>
                <div className="relative">
                  <Phone className="w-4 h-4 text-slate-400 absolute left-3 top-3" />
                  <input
                    type="tel"
                    placeholder="+221 77 000 00 00"
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    className="w-full pl-9 pr-3 py-2 text-sm rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-900 dark:text-white focus:ring-2 focus:ring-indigo-500 focus:outline-none"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1">
                  Mot de passe secret *
                </label>
                <div className="relative">
                  <Lock className="w-4 h-4 text-slate-400 absolute left-3 top-3" />
                  <input
                    type="password"
                    required
                    placeholder="Minimum 6 caractères"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    className="w-full pl-9 pr-3 py-2 text-sm rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-900 dark:text-white focus:ring-2 focus:ring-indigo-500 focus:outline-none"
                  />
                </div>
              </div>

              <div className="pt-2">
                <button
                  type="submit"
                  disabled={loading}
                  className="w-full py-3 text-sm font-semibold text-white bg-indigo-600 hover:bg-indigo-700 rounded-xl shadow-md transition flex items-center justify-center gap-2"
                >
                  {loading ? (
                    <span>Création du profil...</span>
                  ) : (
                    <>
                      <span>Continuer vers mon Entreprise</span>
                      <ArrowRight className="w-4 h-4" />
                    </>
                  )}
                </button>
              </div>

              <div className="text-center text-xs text-slate-500 pt-2">
                Vous avez déjà un compte ?{' '}
                <Link to="/login" className="text-indigo-600 font-semibold hover:underline">
                  Connectez-vous ici
                </Link>
              </div>
            </form>
          ) : (
            /* ============================================================ */
            /* ÉTAPE 2 : INFORMATIONS ENTREPRISE & 1ÈRE BOUTIQUE            */
            /* ============================================================ */
            <form onSubmit={handleStep2Submit} className="space-y-4 animate-fadeIn">
              <div>
                <div className="inline-flex items-center gap-1 text-[11px] font-bold text-emerald-600 dark:text-emerald-400 mb-1">
                  <CheckCircle2 className="w-3.5 h-3.5" /> Identifiants validés
                </div>
                <h2 className="text-lg font-bold text-slate-900 dark:text-white">Configurez votre Entreprise</h2>
                <p className="text-xs text-slate-500">
                  Définissez votre première boutique et votre point de vente initial.
                </p>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1">
                  Nom commercial de la Boutique / Entreprise *
                </label>
                <div className="relative">
                  <Store className="w-4 h-4 text-slate-400 absolute left-3 top-3" />
                  <input
                    type="text"
                    required
                    placeholder="Ex: Boutique Élégance Dakar"
                    value={boutiqueName}
                    onChange={(e) => setBoutiqueName(e.target.value)}
                    className="w-full pl-9 pr-3 py-2 text-sm rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-900 dark:text-white focus:ring-2 focus:ring-indigo-500 focus:outline-none"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1">
                    Devise
                  </label>
                  <select
                    value={currency}
                    onChange={(e) => setCurrency(e.target.value)}
                    className="w-full px-3 py-2 text-sm rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-900 dark:text-white focus:ring-2 focus:ring-indigo-500 focus:outline-none"
                  >
                    <option value="XOF">FCFA (XOF - UEMOA)</option>
                    <option value="XAF">FCFA (XAF - CEMAC)</option>
                    <option value="EUR">Euro (€)</option>
                    <option value="USD">Dollar ($)</option>
                    <option value="GNF">Franc Guinéen</option>
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1">
                    Pays
                  </label>
                  <input
                    type="text"
                    value={country}
                    onChange={(e) => setCountry(e.target.value)}
                    className="w-full px-3 py-2 text-sm rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-900 dark:text-white focus:ring-2 focus:ring-indigo-500 focus:outline-none"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1">
                  Nom du premier point de vente (Magasin)
                </label>
                <input
                  type="text"
                  placeholder="Ex: Magasin Principal / Caisse centrale"
                  value={magasinName}
                  onChange={(e) => setMagasinName(e.target.value)}
                  className="w-full px-3 py-2 text-sm rounded-xl border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-800 text-slate-900 dark:text-white focus:ring-2 focus:ring-indigo-500 focus:outline-none"
                />
                <span className="text-[10px] text-slate-400">
                  Vous pourrez ajouter d'autres magasins et entrepôts à tout moment.
                </span>
              </div>

              {/* Sélection du Plan d'accueil */}
              <div className="pt-2">
                <label className="block text-xs font-semibold text-slate-700 dark:text-slate-300 mb-1.5">
                  Formule d'accueil choisie
                </label>
                <div className="grid grid-cols-2 gap-3">
                  <div
                    onClick={() => setSelectedPlan('free')}
                    className={`p-3 rounded-xl border cursor-pointer transition text-xs ${
                      selectedPlan === 'free'
                        ? 'border-indigo-600 bg-indigo-50/50 dark:bg-indigo-950/40 text-indigo-900 dark:text-indigo-200 ring-2 ring-indigo-500/20'
                        : 'border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800'
                    }`}
                  >
                    <div className="font-bold">Plan Gratuit</div>
                    <div className="text-[11px] text-slate-500">1 magasin • 100 articles</div>
                    <div className="font-extrabold text-indigo-600 mt-1">0 F / mois</div>
                  </div>

                  <div
                    onClick={() => setSelectedPlan('pro')}
                    className={`p-3 rounded-xl border cursor-pointer transition text-xs relative ${
                      selectedPlan === 'pro'
                        ? 'border-indigo-600 bg-indigo-50/50 dark:bg-indigo-950/40 text-indigo-900 dark:text-indigo-200 ring-2 ring-indigo-500/20'
                        : 'border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800'
                    }`}
                  >
                    <div className="absolute -top-2 right-2 px-1.5 py-0.2 rounded-full text-[9px] font-bold bg-amber-500 text-white">
                      14J OFFERTS
                    </div>
                    <div className="font-bold flex items-center gap-1">
                      <span>Plan Pro</span>
                      <Sparkles className="w-3 h-3 text-amber-500" />
                    </div>
                    <div className="text-[11px] text-slate-500">5 magasins • P&L • Stocks</div>
                    <div className="font-extrabold text-indigo-600 mt-1">Essai 14j gratuit</div>
                  </div>
                </div>
              </div>

              <div className="pt-3">
                <button
                  type="submit"
                  disabled={loading}
                  className="w-full py-3.5 text-sm font-bold text-white bg-gradient-to-r from-indigo-600 to-purple-600 hover:from-indigo-700 hover:to-purple-700 rounded-xl shadow-lg transition flex items-center justify-center gap-2"
                >
                  {loading ? (
                    <span>Initialisation de votre espace...</span>
                  ) : (
                    <>
                      <ShieldCheck className="w-4 h-4" />
                      <span>Terminer et accéder à mon espace</span>
                    </>
                  )}
                </button>
              </div>
            </form>
          )}
        </div>
      </div>
    </div>
  );
};
