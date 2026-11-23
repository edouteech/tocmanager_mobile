import { useTenantStore } from '../stores/tenantStore';
import { getCurrencySymbol } from './currencies';

export function formatMoney(amount: number, currency?: string | null): string {
  let activeCurrency = currency;
  if (!activeCurrency) {
    try {
      activeCurrency = useTenantStore.getState().currentBoutique?.currency || 'XOF';
    } catch {
      activeCurrency = 'XOF';
    }
  }
  const formatted = new Intl.NumberFormat('fr-FR', {
    style: 'decimal',
    maximumFractionDigits: 0,
  }).format(amount || 0);
  return `${formatted} ${getCurrencySymbol(activeCurrency)}`;
}

export function formatFCFA(amount: number): string {
  return formatMoney(amount);
}

export function formatDateTime(isoString: string): string {
  try {
    const d = new Date(isoString);
    return new Intl.DateTimeFormat('fr-FR', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    }).format(d);
  } catch {
    return isoString;
  }
}

export function formatDateOnly(isoString: string): string {
  try {
    const d = new Date(isoString);
    return new Intl.DateTimeFormat('fr-FR', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
    }).format(d);
  } catch {
    return isoString;
  }
}
