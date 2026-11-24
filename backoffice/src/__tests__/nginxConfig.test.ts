import fs from 'node:fs';
import path from 'node:path';
import { describe, expect, it } from 'vitest';

const BACKOFFICE_ROOT = path.resolve(__dirname, '../..');

describe('Nginx reverse proxy configuration', () => {
  it('uses dynamic Docker DNS resolver instead of static upstream backend:8000', () => {
    const nginxConf = fs.readFileSync(path.join(BACKOFFICE_ROOT, 'nginx.conf'), 'utf-8');

    expect(nginxConf).not.toContain('upstream backend_api');
    expect(nginxConf).not.toContain('server backend:8000;');
    expect(nginxConf.match(/resolver 127\.0\.0\.11 valid=30s ipv6=off;/g)?.length).toBe(2);
    expect(nginxConf.match(/set \$backend_upstream http:\/\/backend:8000;/g)?.length).toBe(2);
    expect(nginxConf.match(/proxy_pass \$backend_upstream;/g)?.length).toBe(2);
  });

  it('isolates /admin routes on primary host and redirects admin.* root to /admin', () => {
    const nginxConf = fs.readFileSync(path.join(BACKOFFICE_ROOT, 'nginx.conf'), 'utf-8');

    expect(nginxConf).toContain('location ^~ /admin');
    expect(nginxConf).toContain('return 404;');
    expect(nginxConf).toContain('server_name admin.*;');
    expect(nginxConf).toContain('return 302 /admin;');
  });
});
