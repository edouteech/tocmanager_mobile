from typing import Any, Dict, List
from fastapi import HTTPException
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models import PaymentProvider, PlatformAuditLog, User
from app.schemas.admin import PaymentProviderUpdateRequest
from app.services.payments.feexpay_catalog import FEEXPAY_COUNTRIES, NETWORK_SLUGS
from app.services.payments.payment_manager import (
    decrypt_provider_config,
    encrypt_provider_config,
)


def mask_secret(secret: str | None) -> str:
    if not secret:
        return ""
    cleaned = str(secret).strip()
    if len(cleaned) <= 8:
        return "****"
    return f"{cleaned[:4]}****{cleaned[-4:]}"


def _is_masked_or_empty(val: str | None) -> bool:
    return not val or not val.strip() or "****" in val


def serialize_provider_admin(provider: PaymentProvider) -> Dict[str, Any]:
    stored = decrypt_provider_config(provider.config_encrypted)
    sandbox_raw = stored.get("sandbox") if isinstance(stored.get("sandbox"), dict) else {}
    live_raw = stored.get("live") if isinstance(stored.get("live"), dict) else {}

    sb_key = sandbox_raw.get("api_key") or settings.FEEXPAY_API_KEY or ""
    sb_id = sandbox_raw.get("api_id") or settings.FEEXPAY_API_ID or ""
    lv_key = live_raw.get("api_key") or settings.FEEXPAY_LIVE_API_KEY or ""
    lv_id = live_raw.get("api_id") or settings.FEEXPAY_LIVE_API_ID or ""

    return {
        "id": provider.id,
        "code": provider.code,
        "name": provider.name,
        "is_active": bool(provider.is_active),
        "mode": provider.mode or "sandbox",
        "base_url": stored.get("base_url") or settings.FEEXPAY_BASE_URL,
        "countries": provider.countries or FEEXPAY_COUNTRIES,
        "networks": provider.networks or list(NETWORK_SLUGS.keys()),
        "sandbox": {
            "api_key_masked": mask_secret(sb_key),
            "has_api_key": bool(sb_key),
            "api_id": sb_id,
        },
        "live": {
            "api_key_masked": mask_secret(lv_key),
            "has_api_key": bool(lv_key),
            "api_id": lv_id,
        },
        "updated_at": provider.updated_at,
    }


def list_payment_providers_admin(db: Session) -> List[Dict[str, Any]]:
    providers = db.query(PaymentProvider).order_by(PaymentProvider.code.asc()).all()
    return [serialize_provider_admin(p) for p in providers]


def get_payment_provider_admin(db: Session, code: str) -> Dict[str, Any]:
    provider = db.query(PaymentProvider).filter(PaymentProvider.code == code).first()
    if not provider:
        raise HTTPException(status_code=404, detail="Fournisseur de paiement introuvable.")
    return serialize_provider_admin(provider)


def update_payment_provider_admin(
    db: Session,
    code: str,
    payload: PaymentProviderUpdateRequest,
    admin: User,
) -> Dict[str, Any]:
    provider = db.query(PaymentProvider).filter(PaymentProvider.code == code).first()
    if not provider:
        raise HTTPException(status_code=404, detail="Fournisseur de paiement introuvable.")

    if payload.name is not None:
        provider.name = payload.name.strip() or provider.name
    if payload.is_active is not None:
        provider.is_active = payload.is_active
    if payload.mode is not None:
        provider.mode = payload.mode
    if payload.countries is not None:
        provider.countries = payload.countries
    if payload.networks is not None:
        provider.networks = payload.networks

    stored = decrypt_provider_config(provider.config_encrypted)
    if payload.base_url is not None:
        stored["base_url"] = payload.base_url.strip()

    for env_key, incoming in (("sandbox", payload.sandbox), ("live", payload.live)):
        if incoming is None:
            continue
        existing_block = stored.get(env_key) if isinstance(stored.get(env_key), dict) else {}
        next_block = dict(existing_block)
        if not _is_masked_or_empty(incoming.api_key):
            next_block["api_key"] = incoming.api_key.strip()  # type: ignore[union-attr]
        if incoming.api_id is not None:
            next_block["api_id"] = incoming.api_id.strip()
        stored[env_key] = next_block

    provider.config_encrypted = encrypt_provider_config(stored)
    db.add(
        PlatformAuditLog(
            admin_user_id=admin.id,
            admin_username=admin.username,
            action="PAYMENT_PROVIDER_UPDATE",
            target_entity="payment_provider",
            target_id=provider.code,
            details={
                "is_active": provider.is_active,
                "mode": provider.mode,
                "networks_count": len(provider.networks or []),
            },
        )
    )
    db.commit()
    db.refresh(provider)
    return serialize_provider_admin(provider)
