from dataclasses import dataclass
from io import BytesIO
from pathlib import Path
from typing import Optional
import uuid

import boto3
from botocore.exceptions import BotoCoreError, ClientError
from fastapi import HTTPException
from PIL import Image, ImageOps, UnidentifiedImageError

from app.core.config import settings

MAX_IMAGE_BYTES = 2 * 1024 * 1024
MAX_IMAGE_DIMENSION = 1024
ALLOWED_IMAGE_MIMES = {"image/jpeg", "image/jpg", "image/png", "image/webp", "application/octet-stream"}
_PIL_TO_MIME = {"JPEG": ("image/jpeg", ".jpg"), "PNG": ("image/png", ".png"), "WEBP": ("image/webp", ".webp")}
_SUSPICIOUS_PREFIXES = (b"mz", b"<!doctype", b"<html", b"<script", b"<?php", b"\x7felf")


@dataclass
class StoredUploadResult:
    url: str
    key: str
    content_type: str
    size_bytes: int
    storage: str


def is_r2_configured() -> bool:
    return bool(
        (settings.S3_BUCKET or "").strip()
        and (settings.S3_ACCESS_KEY_ID or "").strip()
        and (settings.S3_SECRET_ACCESS_KEY or "").strip()
    )


def _create_s3_client():
    return boto3.client(
        "s3",
        endpoint_url=(settings.S3_ENDPOINT_URL or "").strip() or None,
        region_name=(settings.S3_REGION or "auto").strip() or "auto",
        aws_access_key_id=(settings.S3_ACCESS_KEY_ID or "").strip(),
        aws_secret_access_key=(settings.S3_SECRET_ACCESS_KEY or "").strip(),
    )


def validate_and_process_image(raw_bytes: bytes, content_type: Optional[str]) -> tuple[bytes, str, str]:
    """Validate MIME + real image content, strip EXIF, and resize within 1024x1024."""
    if not raw_bytes:
        raise HTTPException(status_code=400, detail="Fichier image vide.")
    if len(raw_bytes) > MAX_IMAGE_BYTES:
        raise HTTPException(status_code=400, detail="Image trop volumineuse (maximum 2 Mo).")

    normalized_mime = (content_type or "").split(";")[0].strip().lower()
    if normalized_mime and normalized_mime not in ALLOWED_IMAGE_MIMES:
        raise HTTPException(status_code=415, detail="Format MIME non autorisé (JPG, PNG ou WebP requis).")

    head = raw_bytes.lstrip()[:32].lower()
    if any(head.startswith(sig) for sig in _SUSPICIOUS_PREFIXES):
        raise HTTPException(status_code=415, detail="Contenu potentiellement dangereux rejeté.")

    try:
        with Image.open(BytesIO(raw_bytes)) as verify_img:
            detected_format = (verify_img.format or "").upper()
            verify_img.verify()
    except (UnidentifiedImageError, OSError, ValueError):
        raise HTTPException(status_code=415, detail="Le fichier transmis n'est pas une image valide.")

    if detected_format not in _PIL_TO_MIME:
        raise HTTPException(status_code=415, detail="Seuls les formats JPEG, PNG et WebP sont acceptés.")

    target_mime, target_ext = _PIL_TO_MIME[detected_format]
    with Image.open(BytesIO(raw_bytes)) as img:
        img = ImageOps.exif_transpose(img)
        if detected_format == "JPEG" and img.mode != "RGB":
            img = img.convert("RGB")
        elif detected_format in ("PNG", "WEBP") and img.mode not in ("RGB", "RGBA"):
            img = img.convert("RGBA")
        img.thumbnail((MAX_IMAGE_DIMENSION, MAX_IMAGE_DIMENSION), Image.Resampling.LANCZOS)
        out = BytesIO()
        save_kwargs = {"optimize": True}
        if detected_format in ("JPEG", "WEBP"):
            save_kwargs["quality"] = 85
        img.save(out, format=detected_format, **save_kwargs)
        processed = out.getvalue()

    if len(processed) > MAX_IMAGE_BYTES:
        raise HTTPException(status_code=400, detail="Image compressée toujours supérieure à 2 Mo.")
    return processed, target_mime, target_ext


def upload_image(raw_bytes: bytes, content_type: Optional[str], boutique_id: str) -> StoredUploadResult:
    """Validate and store product image in Cloudflare R2 (or local fallback in dev)."""
    processed, mime, ext = validate_and_process_image(raw_bytes, content_type)
    safe_boutique = "".join(c for c in boutique_id if c.isalnum() or c in ("-", "_")) or "shared"
    filename = f"{uuid.uuid4().hex}{ext}"
    object_key = f"boutiques/{safe_boutique}/products/{filename}"

    if is_r2_configured():
        client = _create_s3_client()
        client.put_object(
            Bucket=settings.S3_BUCKET,
            Key=object_key,
            Body=processed,
            ContentType=mime,
            CacheControl="public, max-age=31536000, immutable",
        )
        public_base = (settings.S3_PUBLIC_BASE_URL or "").strip().rstrip("/")
        if public_base:
            url = f"{public_base}/{object_key}"
        elif (settings.S3_ENDPOINT_URL or "").strip():
            endpoint = settings.S3_ENDPOINT_URL.strip().rstrip("/")
            url = f"{endpoint}/{settings.S3_BUCKET}/{object_key}"
        else:
            url = f"https://{settings.S3_BUCKET}.s3.amazonaws.com/{object_key}"
        return StoredUploadResult(url=url, key=object_key, content_type=mime, size_bytes=len(processed), storage="r2")

    local_dir = Path(settings.LOCAL_UPLOAD_DIR) / "boutiques" / safe_boutique / "products"
    local_dir.mkdir(parents=True, exist_ok=True)
    target_path = local_dir / filename
    target_path.write_bytes(processed)
    return StoredUploadResult(
        url=f"{settings.API_V1_STR}/uploads/files/{safe_boutique}/{filename}",
        key=object_key,
        content_type=mime,
        size_bytes=len(processed),
        storage="local",
    )


def resolve_local_upload_path(boutique_id: str, filename: str) -> Path:
    """Resolve and validate a local fallback upload path without traversal."""
    safe_boutique = "".join(c for c in boutique_id if c.isalnum() or c in ("-", "_"))
    safe_name = Path(filename).name
    if not safe_boutique or safe_name != filename:
        raise HTTPException(status_code=400, detail="Chemin de fichier invalide.")
    base_dir = (Path(settings.LOCAL_UPLOAD_DIR) / "boutiques" / safe_boutique / "products").resolve()
    candidate = (base_dir / safe_name).resolve()
    if base_dir not in candidate.parents or not candidate.is_file():
        raise HTTPException(status_code=404, detail="Fichier introuvable.")
    return candidate


def check_storage_ready() -> str:
    """Verify Cloudflare R2 / S3 reachability when configured."""
    if not is_r2_configured():
        return "local"
    try:
        client = _create_s3_client()
        client.head_bucket(Bucket=settings.S3_BUCKET)
        return "r2"
    except (BotoCoreError, ClientError) as exc:
        raise RuntimeError(f"S3/R2 unreachable: {exc}") from exc
