import {
  ShoppingCart,
  UserPlus,
  CreditCard,
  TrendingDown,
  PackagePlus,
  LogIn,
  KeyRound,
  FileText,
  LucideIcon,
} from 'lucide-react';

export interface AuditActionMeta {
  label: string;
  icon: LucideIcon;
  bg: string;
}

export function getAuditActionMeta(action: string): AuditActionMeta {
  switch (action) {
    case 'SALE_CREATE':
      return {
        label: 'Nouvelle Vente',
        icon: ShoppingCart,
        bg: 'bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-300 border-emerald-200 dark:border-emerald-800/40',
      };
    case 'CLIENT_CREATE':
      return {
        label: 'Nouveau Client',
        icon: UserPlus,
        bg: 'bg-brand-50 dark:bg-brand-500/15 text-brand-700 dark:text-brand-300 border-brand-200 dark:border-brand-500/30',
      };
    case 'DEBT_PAYMENT':
      return {
        label: 'Règlement Dette',
        icon: CreditCard,
        bg: 'bg-amber-50 dark:bg-amber-950/40 text-amber-700 dark:text-amber-300 border-amber-200 dark:border-amber-800/40',
      };
    case 'EXPENSE_CREATE':
      return {
        label: 'Décaissement',
        icon: TrendingDown,
        bg: 'bg-rose-50 dark:bg-rose-950/40 text-rose-700 dark:text-rose-300 border-rose-200 dark:border-rose-900/50',
      };
    case 'STOCK_SUPPLY':
      return {
        label: 'Approvisionnement',
        icon: PackagePlus,
        bg: 'bg-brand-50 dark:bg-brand-500/15 text-brand-700 dark:text-brand-300 border-brand-200 dark:border-brand-500/30',
      };
    case 'LOGIN':
      return {
        label: 'Connexion',
        icon: LogIn,
        bg: 'bg-purple-50 dark:bg-purple-950/40 text-purple-700 dark:text-purple-300 border-purple-200 dark:border-purple-800/40',
      };
    case 'PIN_VERIFY':
    case 'PIN_UNLOCK':
      return {
        label: 'Déverrouillage PIN',
        icon: KeyRound,
        bg: 'bg-cyan-50 dark:bg-cyan-950/40 text-cyan-700 dark:text-cyan-300 border-cyan-200 dark:border-cyan-800/40',
      };
    default:
      return {
        label: action,
        icon: FileText,
        bg: 'bg-slate-100 dark:bg-dark-700 text-slate-700 dark:text-slate-300 border-slate-200 dark:border-dark-600',
      };
  }
}
