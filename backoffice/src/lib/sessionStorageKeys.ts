const TOC_STORAGE_KEYS = [
  'toc_access_token',
  'toc_refresh_token',
  'toc_user',
  'toc_pin_locked',
  'toc_current_boutique_id',
  'toc_current_magasin_id',
  'toc_impersonation_meta',
  'toc_admin_backup_session',
] as const;

export const clearTocStorage = () => {
  TOC_STORAGE_KEYS.forEach((key) => {
    try {
      localStorage.removeItem(key);
    } catch {
      // Ignore storage access failures
    }
  });
  try {
    sessionStorage.removeItem('toc_magasin_prompt_dismissed');
  } catch {
    // Ignore storage access failures
  }
};
