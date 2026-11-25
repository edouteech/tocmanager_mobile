from pathlib import Path
import yaml


ROOT = Path(__file__).resolve().parents[2]


def test_github_workflows_are_valid_and_complete():
    wf_dir = ROOT / ".github" / "workflows"

    backend_wf = yaml.safe_load((wf_dir / "ci-backend.yml").read_text(encoding="utf-8"))
    assert "postgres" in backend_wf["jobs"]["backend-ci"]["services"]
    step_runs = "\n".join(s.get("run", "") for s in backend_wf["jobs"]["backend-ci"]["steps"])
    assert "ruff check" in step_runs
    assert "alembic upgrade head" in step_runs
    assert "pytest" in step_runs

    backoffice_wf = yaml.safe_load((wf_dir / "ci-backoffice.yml").read_text(encoding="utf-8"))
    bo_runs = "\n".join(s.get("run", "") for s in backoffice_wf["jobs"]["backoffice-ci"]["steps"])
    for cmd in ("npm ci", "npm run lint", "npx tsc --noEmit", "npm test", "npm run build"):
        assert cmd in bo_runs

    apk_wf = yaml.safe_load((wf_dir / "build-apk.yml").read_text(encoding="utf-8"))
    on_cfg = apk_wf.get("on") or apk_wf.get(True)
    assert "pull_request" in on_cfg
    assert "mobile-quality" in apk_wf["jobs"]
    assert apk_wf["jobs"]["build-apk"]["needs"] == "mobile-quality"
    quality_runs = "\n".join(s.get("run", "") for s in apk_wf["jobs"]["mobile-quality"]["steps"])
    assert "flutter analyze" in quality_runs
    assert "flutter test" in quality_runs


def test_nginx_and_backoffice_dockerfile_hardening():
    nginx_conf = (ROOT / "backoffice" / "nginx.conf").read_text(encoding="utf-8")
    assert nginx_conf.count("{") == nginx_conf.count("}")
    assert "server_tokens off;" in nginx_conf
    assert "upstream backend_api" not in nginx_conf
    assert "resolver 127.0.0.11 valid=30s ipv6=off;" in nginx_conf
    assert "set $backend_upstream http://backend:8000;" in nginx_conf
    assert "proxy_pass $backend_upstream;" in nginx_conf
    assert "server_name app.*;" in nginx_conf
    assert "server_name admin.*;" in nginx_conf
    assert "absolute_redirect off;" in nginx_conf
    assert "location ^~ /admin" in nginx_conf
    assert "return 404;" in nginx_conf
    assert 'Cache-Control "no-cache, no-store, must-revalidate"' in nginx_conf
    assert 'Cache-Control "public, max-age=31536000, immutable"' in nginx_conf
    for header in (
        "Content-Security-Policy",
        "X-Frame-Options",
        "X-Content-Type-Options",
        "Referrer-Policy",
        "Permissions-Policy",
    ):
        assert header in nginx_conf

    dockerfile = (ROOT / "backoffice" / "Dockerfile").read_text(encoding="utf-8")
    assert "npm ci || npm install" not in dockerfile
    assert "RUN npm ci" in dockerfile
    assert "RUN nginx -t" in dockerfile
    assert "curl -f http://127.0.0.1/health" in dockerfile
