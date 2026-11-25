import { useAuthStore } from '../stores/authStore';
import { queryClient } from './queryClient';
import { AuthResponse } from '../types';
import { buildSurfaceUrl } from './domainRouting';

export const IMPERSONATION_HASH_PREFIX = '#support_impersonation=';

export interface ImpersonationTransferPayload {
  access_token: string;
  user: AuthResponse['user'];
  boutique_id: string;
  boutique_name: string;
  expires_in_minutes: number;
}

/**
 * Encode an ephemeral support-impersonation payload as UTF-8 safe base64url.
 */
export function encodeImpersonationPayload(payload: ImpersonationTransferPayload): string {
  const bytes = new TextEncoder().encode(JSON.stringify(payload));
  let binary = '';
  for (const byte of bytes) {
    binary += String.fromCharCode(byte);
  }
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '');
}

/**
 * Decode an encoded support-impersonation fragment, returning null on invalid input.
 */
export function decodeImpersonationPayload(encoded: string): ImpersonationTransferPayload | null {
  try {
    const padded = encoded.replace(/-/g, '+').replace(/_/g, '/');
    const padLen = (4 - (padded.length % 4)) % 4;
    const binary = atob(`${padded}${'='.repeat(padLen)}`);
    const bytes = new Uint8Array(binary.length);
    for (let i = 0; i < binary.length; i += 1) {
      bytes[i] = binary.charCodeAt(i);
    }
    const parsed = JSON.parse(new TextDecoder().decode(bytes)) as Partial<ImpersonationTransferPayload>;
    if (!parsed.access_token || !parsed.user || !parsed.boutique_id) {
      return null;
    }
    return {
      access_token: parsed.access_token,
      user: parsed.user,
      boutique_id: parsed.boutique_id,
      boutique_name: parsed.boutique_name || 'Cliente',
      expires_in_minutes: parsed.expires_in_minutes ?? 30,
    };
  } catch {
    return null;
  }
}

/**
 * Build the cross-domain app.* launch URL carrying the ephemeral read-only support session hash.
 */
export function buildCrossDomainImpersonationUrl(payload: ImpersonationTransferPayload): string {
  return `${buildSurfaceUrl('app', '/')}${IMPERSONATION_HASH_PREFIX}${encodeImpersonationPayload(payload)}`;
}

/**
 * Hydrate support impersonation from window.location.hash and erase the hash before storing auth.
 */
export function consumeImpersonationHash(): boolean {
  if (typeof window === 'undefined') return false;
  const { hash, pathname, search } = window.location;
  if (!hash.startsWith(IMPERSONATION_HASH_PREFIX)) return false;

  const encoded = hash.slice(IMPERSONATION_HASH_PREFIX.length);
  window.history.replaceState(null, '', `${pathname}${search}`);

  const payload = decodeImpersonationPayload(encoded);
  if (!payload) return false;

  localStorage.setItem(
    'toc_impersonation_meta',
    JSON.stringify({
      boutique_id: payload.boutique_id,
      boutique_name: payload.boutique_name,
      expires_in_minutes: payload.expires_in_minutes,
      cross_domain: true,
    })
  );
  useAuthStore.getState().setAuth({
    access_token: payload.access_token,
    refresh_token: '',
    token_type: 'bearer',
    user: payload.user,
  });
  localStorage.setItem('toc_current_boutique_id', payload.boutique_id);
  localStorage.removeItem('toc_current_magasin_id');
  queryClient.clear();
  return true;
}
