import fs from 'node:fs';
import path from 'node:path';
import { describe, expect, it } from 'vitest';

const BACKOFFICE_ROOT = path.resolve(__dirname, '../..');

describe('Self-hosted fonts and strict Nginx CSP', () => {
  it('removes external Google Fonts links from index.html and preloads local latin WOFF2', () => {
    const html = fs.readFileSync(path.join(BACKOFFICE_ROOT, 'index.html'), 'utf-8');

    expect(html).not.toContain('fonts.googleapis.com');
    expect(html).not.toContain('fonts.gstatic.com');
    expect(html).toContain('href="/assets/fonts/plus-jakarta-sans-latin.woff2"');
  });

  it('declares @font-face rules pointing to valid binary wOF2 files on disk', () => {
    const css = fs.readFileSync(path.join(BACKOFFICE_ROOT, 'src/index.css'), 'utf-8');

    expect(css).toContain("font-family: 'Plus Jakarta Sans'");
    expect(css).toContain('font-display: swap');

    const matches = Array.from(css.matchAll(/url\('(\/assets\/fonts\/[^']+\.woff2)'\)/g));
    expect(matches.length).toBeGreaterThanOrEqual(2);

    for (const [, assetUrl] of matches) {
      const fontPath = path.join(BACKOFFICE_ROOT, 'public', assetUrl.slice(1));
      expect(fs.existsSync(fontPath)).toBe(true);

      const bytes = fs.readFileSync(fontPath);
      expect(bytes.byteLength).toBeGreaterThan(1000);
      expect(bytes.subarray(0, 4).toString('ascii')).toBe('wOF2');
    }
  });

  it('keeps strict font-src self CSP and immutable caching in nginx.conf', () => {
    const nginxConf = fs.readFileSync(path.join(BACKOFFICE_ROOT, 'nginx.conf'), 'utf-8');

    expect(nginxConf).toContain("font-src 'self' data:");
    expect(nginxConf).toContain('location /assets/');
    expect(nginxConf).toContain('Cache-Control "public, max-age=31536000, immutable"');
  });
});
