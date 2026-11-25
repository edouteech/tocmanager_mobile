export type AppSurface = 'public' | 'app' | 'admin' | 'all';
export type TargetSurface = 'public' | 'app' | 'admin';

export interface SurfaceLocationLike {
  protocol: string;
  hostname: string;
  port?: string;
}

const LOCAL_HOST_PATTERN = /^(localhost|127\.0\.0\.1|::1|\[::1\]|[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+)$/;
const SUBDOMAIN_PREFIX_PATTERN = /^(admin|app|www)\./;

const ENV_SURFACE_OVERRIDES: Record<TargetSurface, string | undefined> = {
  public: import.meta.env.VITE_PUBLIC_URL as string | undefined,
  app: import.meta.env.VITE_APP_URL as string | undefined,
  admin: import.meta.env.VITE_ADMIN_URL as string | undefined,
};

const SURFACE_SUBDOMAIN_PREFIX: Record<TargetSurface, string> = {
  public: '',
  app: 'app.',
  admin: 'admin.',
};

/**
 * Determine which frontend application surface should be active for the given hostname.
 */
export function resolveAppSurface(hostname?: string): AppSurface {
  const rawHost = hostname ?? (typeof window !== 'undefined' ? window.location.hostname : '');
  const normalized = rawHost.trim().toLowerCase();

  if (!normalized || LOCAL_HOST_PATTERN.test(normalized)) {
    return 'all';
  }
  if (normalized.startsWith('admin.')) {
    return 'admin';
  }
  if (normalized.startsWith('app.')) {
    return 'app';
  }
  return 'public';
}

/**
 * Strip known application subdomain prefixes to recover the root apex domain.
 */
export function extractRootDomain(hostname: string): string {
  return hostname.trim().toLowerCase().replace(SUBDOMAIN_PREFIX_PATTERN, '');
}

function normalizePath(path: string): string {
  if (!path) return '/';
  return path.startsWith('/') ? path : `/${path}`;
}

/**
 * Build a URL targeting a specific surface (relative in local dev/tests, cross-origin in production).
 */
export function buildSurfaceUrl(
  target: TargetSurface,
  path = '/',
  loc?: SurfaceLocationLike
): string {
  const normalizedPath = normalizePath(path);
  const envBase = ENV_SURFACE_OVERRIDES[target]?.trim().replace(/\/+$/, '');
  if (envBase) {
    return `${envBase}${normalizedPath}`;
  }

  const effectiveLoc: SurfaceLocationLike = loc ?? {
    protocol: typeof window !== 'undefined' ? window.location.protocol : 'http:',
    hostname: typeof window !== 'undefined' ? window.location.hostname : 'localhost',
    port: typeof window !== 'undefined' ? window.location.port : '',
  };

  if (resolveAppSurface(effectiveLoc.hostname) === 'all') {
    return normalizedPath;
  }

  const rootDomain = extractRootDomain(effectiveLoc.hostname);
  const portSuffix = effectiveLoc.port ? `:${effectiveLoc.port}` : '';
  const prefix = SURFACE_SUBDOMAIN_PREFIX[target];
  return `${effectiveLoc.protocol}//${prefix}${rootDomain}${portSuffix}${normalizedPath}`;
}

/**
 * Return true when a target URL points to another origin (`http://` or `https://`).
 */
export function isExternalSurfaceUrl(url: string): boolean {
  return /^https?:\/\//i.test(url);
}

/**
 * Navigate using SPA routing on local/same-surface targets, or browser redirect across subdomains.
 */
export function navigateToSurface(
  target: TargetSurface,
  path: string,
  spaNavigate: (to: string, opts?: { replace?: boolean }) => void,
  replace = false
): void {
  const destination = buildSurfaceUrl(target, path);
  if (isExternalSurfaceUrl(destination)) {
    if (replace) {
      window.location.replace(destination);
    } else {
      window.location.assign(destination);
    }
    return;
  }
  spaNavigate(destination, { replace });
}
