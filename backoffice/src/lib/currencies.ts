export interface CurrencyOption {
  code: string;
  symbol: string;
  label: string;
}

export const CANONICAL_CURRENCIES: CurrencyOption[] = [
  { code: 'XOF', symbol: 'F CFA', label: 'Franc CFA UEMOA (XOF)' },
  { code: 'XAF', symbol: 'FCFA', label: 'Franc CFA CEMAC (XAF)' },
  { code: 'EUR', symbol: 'EUR', label: 'Euro (EUR)' },
  { code: 'USD', symbol: '$', label: 'Dollar US (USD)' },
  { code: 'GNF', symbol: 'GNF', label: 'Franc Guinéen (GNF)' },
  { code: 'GHS', symbol: 'GHS', label: 'Cedi Ghanéen (GHS)' },
  { code: 'NGN', symbol: 'NGN', label: 'Naira Nigérian (NGN)' },
];

export function getCurrencySymbol(currencyCode?: string | null): string {
  const code = (currencyCode || 'XOF').toUpperCase();
  if (code === 'FCFA' || code === 'XOF') return 'F';
  if (code === 'XAF') return 'FCFA';
  if (code === 'EUR') return '€';
  if (code === 'USD') return '$';
  if (code === 'GHS') return 'GH₵';
  if (code === 'NGN') return '₦';
  if (code === 'GNF') return 'GNF';
  return code;
}
