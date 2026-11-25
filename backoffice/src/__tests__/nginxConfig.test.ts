import fs from 'node:fs';
import path from 'node:path';
import { describe, expect, it } from 'vitest';

const BACKOFFICE_ROOT = path.resolve(__dirname, '../..');

describe('Nginx reverse proxy configuration', () => {
  it('uses dynamic Docker DNS resolver across all 3 virtual host blocks', () => {
    const nginxConf = fs.readFileSync(path.join(BACKOFFICE_ROOT, 'nginx.conf'), 'utf-8');

    expect(nginxConf).not.toContain('upstream backend_api');
    expect(nginxConf).not.toContain('server backend:8000;');
    expect(nginxConf.match(/resolver 127\.0\.0\.11 valid=30s ipv6=off;/g)?.length).toBe(3);
    expect(nginxConf.match(/set \$backend_upstream http:\/\/backend:8000;/g)?.length).toBe(3);
    expect(nginxConf.match(/proxy_pass \$backend_upstream;/g)?.length).toBe(3);
  });

  it('strictly isolates public, app.* and admin.* subdomains', () => {
    const nginxConf = fs.readFileSync(path.join(BACKOFFICE_ROOT, 'nginx.conf'), 'utf-8');

    expect(nginxConf).toContain('server_name app.*;');
    expect(nginxConf).toContain('server_name admin.*;');
    expect(nginxConf.match(/absolute_redirect off;/g)?.length).toBe(3);
    expect(nginxConf.match(/location \^~ \/admin/g)?.length).toBe(2);
    expect(nginxConf).toContain('return 302 $forwarded_scheme://$app_redirect_host$request_uri;');
    expect(nginxConf).toContain('return 302 /admin;');
    expect(nginxConf).toContain('location ~ ^/(landing|tarifs|contact|cgu|confidentialite)(/|$)');
    expect(nginxConf).toContain('return 404;');
  });
});
