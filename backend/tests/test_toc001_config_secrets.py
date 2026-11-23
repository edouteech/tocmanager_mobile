import os
import pathlib
import subprocess
import sys
import pytest
from app.core.config import Settings, DEFAULT_DEV_SECRET_KEY
from app.services.init_db import init_db
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.core.database import Base
from app.models import User, SaasPlan


def test_production_rejects_missing_or_weak_secret_key():
    with pytest.raises(ValueError, match="SECRET_KEY"):
        Settings(
            ENVIRONMENT="production",
            SECRET_KEY=DEFAULT_DEV_SECRET_KEY,
            BACKEND_CORS_ORIGINS=["https://app.tocmanager.com"],
        )

    with pytest.raises(ValueError, match="SECRET_KEY"):
        Settings(
            ENVIRONMENT="production",
            SECRET_KEY="short-key",
            BACKEND_CORS_ORIGINS=["https://app.tocmanager.com"],
        )


def test_production_rejects_wildcard_cors():
    strong_secret = "x" * 40
    with pytest.raises(ValueError, match="BACKEND_CORS_ORIGINS"):
        Settings(
            ENVIRONMENT="production",
            SECRET_KEY=strong_secret,
            BACKEND_CORS_ORIGINS=["https://app.tocmanager.com", "*"],
        )


def test_production_accepts_strong_config_and_csv_cors():
    cfg = Settings(
        ENVIRONMENT="production",
        SECRET_KEY="a" * 48,
        BACKEND_CORS_ORIGINS="https://app.tocmanager.com, https://admin.tocmanager.com",
    )
    assert cfg.BACKEND_CORS_ORIGINS == [
        "https://app.tocmanager.com",
        "https://admin.tocmanager.com",
    ]


def test_production_seed_creates_no_demo_users(tmp_path, monkeypatch):
    db_path = tmp_path / "prod_empty.db"
    test_engine = create_engine(
        f"sqlite:///{db_path}", connect_args={"check_same_thread": False}
    )
    TestingSession = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)

    import app.services.init_db as init_mod
    import app.core.config as config_mod

    monkeypatch.setattr(init_mod, "engine", test_engine)
    monkeypatch.setattr(config_mod.settings, "ENVIRONMENT", "production")
    monkeypatch.setattr(config_mod.settings, "ENABLE_DEMO_SEED", True)
    monkeypatch.setattr(config_mod.settings, "BOOTSTRAP_SUPERADMIN_EMAIL", None)
    monkeypatch.setattr(config_mod.settings, "BOOTSTRAP_SUPERADMIN_PASSWORD", None)

    Base.metadata.create_all(bind=test_engine)
    db = TestingSession()
    try:
        init_db(db)
        assert db.query(SaasPlan).count() == 3
        assert db.query(User).count() == 0
    finally:
        db.close()


def test_production_bootstrap_superadmin_is_idempotent(tmp_path, monkeypatch):
    db_path = tmp_path / "prod_boot.db"
    test_engine = create_engine(
        f"sqlite:///{db_path}", connect_args={"check_same_thread": False}
    )
    TestingSession = sessionmaker(autocommit=False, autoflush=False, bind=test_engine)

    import app.services.init_db as init_mod
    import app.core.config as config_mod

    monkeypatch.setattr(init_mod, "engine", test_engine)
    monkeypatch.setattr(config_mod.settings, "ENVIRONMENT", "production")
    monkeypatch.setattr(config_mod.settings, "BOOTSTRAP_SUPERADMIN_USERNAME", "root_saas")
    monkeypatch.setattr(config_mod.settings, "BOOTSTRAP_SUPERADMIN_EMAIL", "root@tocmanager.com")
    monkeypatch.setattr(config_mod.settings, "BOOTSTRAP_SUPERADMIN_PASSWORD", "StrongPassword#2026")

    Base.metadata.create_all(bind=test_engine)
    db = TestingSession()
    try:
        init_db(db)
        init_db(db)
        admins = db.query(User).filter(User.role == "superadmin").all()
        assert len(admins) == 1
        assert admins[0].username == "root_saas"
        assert admins[0].email == "root@tocmanager.com"
    finally:
        db.close()


def test_cli_create_superadmin_and_upload_script_without_fallback(tmp_path):
    repo_root = pathlib.Path(__file__).resolve().parents[2]
    upload_script = repo_root / ".github" / "scripts" / "upload_to_gdrive.py"
    source = upload_script.read_text(encoding="utf-8")
    assert "FALLBACK_CREDENTIALS_B64" not in source
    assert "BEGIN RSA PRIVATE KEY" not in source

    dummy_apk = tmp_path / "app.apk"
    dummy_apk.write_bytes(b"apk")

    env_clean = {k: v for k, v in os.environ.items() if k != "GDRIVE_CREDENTIALS"}
    res_fail = subprocess.run(
        [sys.executable, str(upload_script), str(dummy_apk)],
        env=env_clean,
        capture_output=True,
        text=True,
    )
    assert res_fail.returncode == 1

    res_skip = subprocess.run(
        [sys.executable, str(upload_script), "--skip-if-missing", str(dummy_apk)],
        env=env_clean,
        capture_output=True,
        text=True,
    )
    assert res_skip.returncode == 0
    assert "[SKIP]" in res_skip.stdout

    # Verify CLI create-superadmin on isolated DB
    cli_db = tmp_path / "cli_test.db"
    cli_env = dict(os.environ)
    cli_env["DATABASE_URL"] = f"sqlite:///{cli_db}"
    cli_env["PYTHONPATH"] = str(repo_root / "backend")
    cli_res = subprocess.run(
        [
            sys.executable,
            "-m",
            "app.cli",
            "create-superadmin",
            "--username",
            "sa_cli",
            "--email",
            "sa_cli@tocmanager.com",
            "--password",
            "SuperPass#2026",
        ],
        env=cli_env,
        capture_output=True,
        text=True,
    )
    assert cli_res.returncode == 0, cli_res.stderr
    assert "created successfully" in cli_res.stdout


def test_no_hardcoded_secrets_in_repository_source():
    repo_root = pathlib.Path(__file__).resolve().parents[2]
    forbidden = (
        "FALLBACK_CREDENTIALS_B64",
        "BEGIN RSA PRIVATE KEY",
        "tocmanager-super-secret-key",
    )
    for folder in (".github", "backend/app", "docker-compose.yml"):
        target = repo_root / folder
        paths = [target] if target.is_file() else [p for p in target.rglob("*") if p.is_file()]
        for p in paths:
            if "__pycache__" in p.parts:
                continue
            text = p.read_text(encoding="utf-8", errors="ignore")
            for token in forbidden:
                assert token not in text, f"Forbidden secret token '{token}' found in {p}"
