from io import BytesIO
from pathlib import Path
import subprocess
import sys

from alembic.config import Config as AlembicConfig
from alembic.script import ScriptDirectory
from fastapi.testclient import TestClient
from PIL import Image
from sqlalchemy import create_engine, inspect
from sqlalchemy.orm import sessionmaker

from app.core.database import Base, get_db, normalize_database_url
from app.core.security import create_access_token, get_password_hash
from app.main import app
from app.models import Boutique, BoutiqueUserMembership, Client, Magasin, Product, User, Vente, VenteItem
from app.services import storage_service
from scripts.migrate_sqlite_to_pg import migrate_database


def test_normalize_database_url_maps_postgresql_schemes_to_psycopg2():
    assert normalize_database_url("postgres://u:p@h:5432/db") == "postgresql+psycopg2://u:p@h:5432/db"
    assert normalize_database_url("postgresql://u:p@h:5432/db") == "postgresql+psycopg2://u:p@h:5432/db"
    assert normalize_database_url("postgresql+psycopg2://u:p@h:5432/db") == "postgresql+psycopg2://u:p@h:5432/db"
    assert normalize_database_url("sqlite:///./tocmanager.db") == "sqlite:///./tocmanager.db"

    eng = create_engine(normalize_database_url("postgresql://u:p@localhost:5432/tocmanager_ci"))
    assert eng.dialect.driver == "psycopg2"


def test_all_alembic_revision_ids_fit_postgresql_varchar_32():
    backend_dir = Path(__file__).resolve().parents[1]
    cfg = AlembicConfig(str(backend_dir / "alembic.ini"))
    cfg.set_main_option("script_location", str(backend_dir / "alembic"))
    revisions = list(ScriptDirectory.from_config(cfg).walk_revisions())
    assert len(revisions) >= 3
    for rev in revisions:
        assert len(rev.revision) <= 32, f"Alembic revision ID too long for VARCHAR(32): {rev.revision}"


def _make_png_bytes(width: int = 32, height: int = 32) -> bytes:
    buf = BytesIO()
    Image.new("RGBA", (width, height), color=(41, 171, 226, 255)).save(buf, format="PNG")
    return buf.getvalue()


def test_alembic_upgrade_head_creates_full_schema_on_fresh_db(tmp_path):
    backend_dir = Path(__file__).resolve().parents[1]
    db_file = tmp_path / "alembic_fresh.db"
    alembic_bin = Path(sys.executable).parent / "alembic"
    env = {"PATH": str(Path(sys.executable).parent), "DATABASE_URL": f"sqlite:///{db_file}"}

    proc = subprocess.run(
        [str(alembic_bin), "upgrade", "head"],
        cwd=str(backend_dir),
        env=env,
        capture_output=True,
        text=True,
    )
    assert proc.returncode == 0, proc.stderr + proc.stdout

    eng = create_engine(f"sqlite:///{db_file}", connect_args={"check_same_thread": False})
    tables = set(inspect(eng).get_table_names())
    assert {"alembic_version", "boutiques", "magasins", "products", "ventes", "clients", "users"}.issubset(tables)


def _setup_upload_client(tmp_path):
    eng = create_engine(f"sqlite:///{tmp_path / 'upload.db'}", connect_args={"check_same_thread": False})
    Base.metadata.create_all(bind=eng)
    Session = sessionmaker(autocommit=False, autoflush=False, bind=eng)

    def override_db():
        db = Session()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_db
    db = Session()
    user = User(
        username="owner_up",
        email="owner_up@test.local",
        hashed_password=get_password_hash("Secret123!"),
        role="merchant",
        permissions=["*"],
        is_active=True,
    )
    db.add(user)
    db.flush()
    btq = Boutique(slug="btq-up", name="Boutique Upload", owner_user_id=user.id, is_active=True)
    db.add(btq)
    db.flush()
    mag = Magasin(boutique_id=btq.id, name="Mag Upload", code="M1")
    db.add(mag)
    db.add(BoutiqueUserMembership(boutique_id=btq.id, user_id=user.id, role="owner", assigned_magasin_ids=[]))
    db.commit()
    token = create_access_token(user.id)
    headers = {"Authorization": f"Bearer {token}", "X-Boutique-Id": btq.id}
    db.close()
    return TestClient(app), headers, btq.id


def test_upload_image_valid_r2_and_local_fallback_and_rejects_bad_files(tmp_path, monkeypatch):
    client, headers, btq_id = _setup_upload_client(tmp_path)
    try:
        monkeypatch.setattr(storage_service.settings, "LOCAL_UPLOAD_DIR", str(tmp_path / "local_uploads"))
        monkeypatch.setattr(storage_service.settings, "S3_BUCKET", None)

        png_data = _make_png_bytes(1600, 1200)
        res = client.post(
            "/api/v1/uploads/images",
            headers=headers,
            files={"file": ("photo.png", png_data, "image/png")},
        )
        assert res.status_code == 200, res.text
        body = res.json()
        assert body["storage"] == "local"
        assert body["url"].startswith(f"/api/v1/uploads/files/{btq_id}/")
        assert body["key"].startswith(f"boutiques/{btq_id}/products/")
        assert client.get(body["url"]).status_code == 200

        # Malicious executable & HTML polyglot payloads must be rejected
        for fname, payload, mime in [
            ("malware.exe", b"MZ\x90\x00\x03\x00\x00\x00", "application/octet-stream"),
            ("page.html", b"<!doctype html><script>alert(1)</script>", "text/html"),
            ("polyglot.png", b"\x89PNG\r\n\x1a\n<html><script>alert(1)</script></html>", "image/png"),
        ]:
            bad = client.post("/api/v1/uploads/images", headers=headers, files={"file": (fname, payload, mime)})
            assert bad.status_code in (400, 415), f"{fname}: {bad.status_code} {bad.text}"

        # Oversized payload (> 2 Mo) rejected with 400
        too_big = b"A" * (storage_service.MAX_IMAGE_BYTES + 10)
        big_res = client.post("/api/v1/uploads/images", headers=headers, files={"file": ("big.png", too_big, "image/png")})
        assert big_res.status_code == 400

        # Mocked Cloudflare R2 S3 upload
        captured = {}

        class FakeS3Client:
            def put_object(self, **kwargs):
                captured.update(kwargs)

        monkeypatch.setattr(storage_service.settings, "S3_BUCKET", "tocmanager-media")
        monkeypatch.setattr(storage_service.settings, "S3_ACCESS_KEY_ID", "test-key")
        monkeypatch.setattr(storage_service.settings, "S3_SECRET_ACCESS_KEY", "test-secret")
        monkeypatch.setattr(storage_service.settings, "S3_PUBLIC_BASE_URL", "https://cdn.tocmanager.test")
        monkeypatch.setattr(storage_service, "_create_s3_client", lambda: FakeS3Client())

        r2_res = client.post("/api/v1/uploads/images", headers=headers, files={"file": ("photo.png", png_data, "image/png")})
        assert r2_res.status_code == 200, r2_res.text
        r2_body = r2_res.json()
        assert r2_body["storage"] == "r2"
        assert r2_body["url"].startswith(f"https://cdn.tocmanager.test/boutiques/{btq_id}/products/")
        assert captured["Bucket"] == "tocmanager-media"
        assert captured["ContentType"] == "image/png"
    finally:
        app.dependency_overrides.clear()


def test_migrate_database_preserves_boutiques_products_clients_ventes_and_sync_ids(tmp_path):
    src_url = f"sqlite:///{tmp_path / 'src.db'}"
    dst_url = f"sqlite:///{tmp_path / 'dst.db'}"
    src_engine = create_engine(src_url, connect_args={"check_same_thread": False})
    Base.metadata.create_all(bind=src_engine)
    SrcSession = sessionmaker(bind=src_engine)
    db = SrcSession()
    try:
        owner = User(username="mig_owner", email="mig@test.local", hashed_password="h", role="merchant")
        db.add(owner)
        db.flush()
        btq = Boutique(slug="mig-shop", name="Migration Shop", owner_user_id=owner.id)
        db.add(btq)
        db.flush()
        prod = Product(boutique_id=btq.id, sync_id="prod-sync-1", name="Savon", price=500.0, stock=10.0)
        cli = Client(boutique_id=btq.id, sync_id="cli-sync-1", name="Awa", balance=0.0)
        db.add_all([prod, cli])
        db.flush()
        vnt = Vente(
            boutique_id=btq.id,
            sync_id="vnt-sync-1",
            ticket_number="VNT-MIG-01",
            client_sync_id=cli.sync_id,
            total_amount=1000.0,
            paid_amount=1000.0,
        )
        db.add(vnt)
        db.flush()
        db.add(VenteItem(vente_sync_id=vnt.sync_id, product_sync_id=prod.sync_id, product_name="Savon", quantity=2, unit_price=500, total=1000))
        db.commit()
    finally:
        db.close()

    counts = migrate_database(src_url, dst_url)
    assert counts["boutiques"] == 1
    assert counts["products"] == 1
    assert counts["clients"] == 1
    assert counts["ventes"] == 1

    dst_engine = create_engine(dst_url, connect_args={"check_same_thread": False})
    DstSession = sessionmaker(bind=dst_engine)
    dst_db = DstSession()
    try:
        assert dst_db.query(Boutique).filter_by(slug="mig-shop").one().owner_user_id
        assert dst_db.query(Product).one().sync_id == "prod-sync-1"
        assert dst_db.query(Client).one().sync_id == "cli-sync-1"
        assert dst_db.query(Vente).one().sync_id == "vnt-sync-1"
    finally:
        dst_db.close()
