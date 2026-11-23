import React, { useState } from 'react';
import { Link } from 'react-router-dom';
import { Store, Send, CheckCircle2, Mail, Building2, Phone, User, AlertCircle } from 'lucide-react';
import { saasApi } from '../../lib/api';

export const ContactPage: React.FC = () => {
  const [fullName, setFullName] = useState('');
  const [email, setEmail] = useState('');
  const [company, setCompany] = useState('');
  const [phone, setPhone] = useState('');
  const [message, setMessage] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [sentMessage, setSentMessage] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setSentMessage(null);

    if (fullName.trim().length < 2) {
      setError('Veuillez saisir votre nom complet.');
      return;
    }
    if (!email.includes('@')) {
      setError('Veuillez saisir une adresse email valide.');
      return;
    }
    if (message.trim().length < 10) {
      setError('Votre message doit comporter au moins 10 caractères.');
      return;
    }

    setLoading(true);
    try {
      const res = await saasApi.sendContact({
        full_name: fullName.trim(),
        email: email.trim(),
        company: company.trim() || undefined,
        phone: phone.trim() || undefined,
        message: message.trim(),
      });
      setSentMessage(res.message);
      setFullName('');
      setEmail('');
      setCompany('');
      setPhone('');
      setMessage('');
    } catch (err: any) {
      const detail = err.response?.data?.detail;
      setError(
        typeof detail === 'string'
          ? detail
          : "Impossible d'envoyer votre message pour le moment."
      );
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#F5FAFD] dark:bg-dark-900 text-[#1C2B3A] dark:text-slate-100 flex flex-col font-sans">
      <header className="sticky top-0 z-40 bg-white/90 dark:bg-dark-800/90 backdrop-blur-md border-b border-[#E8EFF5] dark:border-dark-600">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
          <Link to="/" className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl toc-gradient flex items-center justify-center text-white shadow-soft">
              <Store className="w-6 h-6" />
            </div>
            <span className="text-xl font-black text-[#1C2B3A] dark:text-white">
              Toc<span className="text-[#29ABE2]">Manager</span>
            </span>
          </Link>

          <div className="flex items-center gap-4">
            <Link to="/tarifs" className="text-sm font-medium text-[#5A7184] hover:text-[#29ABE2]">
              Tarifs
            </Link>
            <Link to="/login" className="text-sm font-medium hover:text-[#29ABE2]">
              Connexion
            </Link>
            <Link to="/inscription" className="btn-primary py-2 text-xs sm:text-sm">
              Créer un compte
            </Link>
          </div>
        </div>
      </header>

      <main className="flex-1 max-w-3xl w-full mx-auto px-4 py-12 space-y-6">
        <div className="text-center space-y-2">
          <h1 className="text-3xl font-extrabold text-[#1C2B3A] dark:text-white">
            Contactez l'équipe TocManager
          </h1>
          <p className="text-sm text-[#5A7184] dark:text-slate-300">
            Déploiement multi-magasins, accompagnement Entreprise ou question technique : écrivez-nous.
          </p>
        </div>

        <div className="card-toc p-6 sm:p-8 shadow-soft-md">
          {sentMessage && (
            <div className="mb-6 p-4 rounded-xl bg-[#E8F8F0] dark:bg-[#27AE60]/15 border border-[#27AE60]/30 text-[#27AE60] text-xs font-semibold flex items-center gap-2.5">
              <CheckCircle2 className="w-4 h-4 shrink-0" />
              <span>{sentMessage}</span>
            </div>
          )}

          {error && (
            <div className="mb-6 p-3.5 rounded-xl bg-[#FDEBE9] dark:bg-[#E74C3C]/15 border border-[#E74C3C]/30 text-[#E74C3C] text-xs font-medium flex items-center gap-2.5">
              <AlertCircle className="w-4 h-4 shrink-0" />
              <span>{error}</span>
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-semibold mb-1">Nom complet *</label>
                <div className="relative">
                  <User className="w-4 h-4 text-[#9FB3C8] absolute left-3 top-3" />
                  <input
                    type="text"
                    required
                    value={fullName}
                    onChange={(e) => setFullName(e.target.value)}
                    placeholder="Ex: Awa Diop"
                    className="input-toc pl-9"
                  />
                </div>
              </div>
              <div>
                <label className="block text-xs font-semibold mb-1">Email professionnel *</label>
                <div className="relative">
                  <Mail className="w-4 h-4 text-[#9FB3C8] absolute left-3 top-3" />
                  <input
                    type="email"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="awa@entreprise.com"
                    className="input-toc pl-9"
                  />
                </div>
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-semibold mb-1">Entreprise / Boutique</label>
                <div className="relative">
                  <Building2 className="w-4 h-4 text-[#9FB3C8] absolute left-3 top-3" />
                  <input
                    type="text"
                    value={company}
                    onChange={(e) => setCompany(e.target.value)}
                    placeholder="Ex: Diop Distribution"
                    className="input-toc pl-9"
                  />
                </div>
              </div>
              <div>
                <label className="block text-xs font-semibold mb-1">Téléphone</label>
                <div className="relative">
                  <Phone className="w-4 h-4 text-[#9FB3C8] absolute left-3 top-3" />
                  <input
                    type="tel"
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    placeholder="+221 77 000 00 00"
                    className="input-toc pl-9"
                  />
                </div>
              </div>
            </div>

            <div>
              <label className="block text-xs font-semibold mb-1">Votre besoin *</label>
              <textarea
                rows={4}
                required
                value={message}
                onChange={(e) => setMessage(e.target.value)}
                placeholder="Décrivez votre activité, le nombre de magasins et vos attentes..."
                className="input-toc"
              />
            </div>

            <button type="submit" disabled={loading} className="w-full btn-primary py-3">
              <Send className="w-4 h-4" />
              <span>{loading ? 'Envoi en cours...' : 'Envoyer mon message'}</span>
            </button>
          </form>
        </div>
      </main>
    </div>
  );
};
