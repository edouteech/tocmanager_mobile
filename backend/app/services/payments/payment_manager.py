import base64
import hashlib
import json
from typing import Any, Dict
from cryptography.fernet import Fernet, InvalidToken
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models import PaymentProvider
from app.services.payments.feexpay_catalog import FEEXPAY_COUNTRIES, NETWORK_SLUGS
from app.services.payments.feexpay_gateway import FeexPayGateway


def _get_fernet() -> Fernet:
    raw_secret = (settings.PAYMENT_ENCRYPTION_KEY or settings.SECRET_KEY).encode("utf-8")
    digest = hashlib.sha256(raw_secret).digest()
    return Fernet(base64.urlsafe_b64encode(digest))


def encrypt_provider_config(config_data: Dict[str, Any]) -> str:
    payload = json.dumps(config_data, ensure_ascii=False).encode("utf-8")
    return _get_fernet().encrypt(payload).decode("utf-8")


def decrypt_provider_config(token: str | None) -> Dict[str, Any]:
    if not token:
        return {}
    try:
        raw = _get_fernet().decrypt(token.encode("utf-8"))
        parsed = json.loads(raw.decode("utf-8"))
        return parsed if isinstance(parsed, dict) else {}
    except (InvalidToken, ValueError):
        return {}


def resolve_feexpay_config(db: Session) -> Dict[str, Any]:
    provider = db.query(PaymentProvider).filter(PaymentProvider.code == "feexpay").first()
    stored = decrypt_provider_config(provider.config_encrypted if provider else None)
    mode = (provider.mode if provider else None) or settings.FEEXPAY_MODE or "sandbox"
    env_key = settings.FEEXPAY_LIVE_API_KEY if mode == "live" else settings.FEEXPAY_API_KEY
    env_id = settings.FEEXPAY_LIVE_API_ID if mode == "live" else settings.FEEXPAY_API_ID

    mode_cfg = stored.get(mode, {}) if isinstance(stored.get(mode), dict) else {}
    return {
        "code": "feexpay",
        "name": provider.name if provider else "FeexPay Mobile Money",
        "is_active": provider.is_active if provider else True,
        "mode": mode,
        "base_url": stored.get("base_url") or settings.FEEXPAY_BASE_URL,
        "api_key": mode_cfg.get("api_key") or env_key or "",
        "api_id": mode_cfg.get("api_id") or env_id or "",
        "countries": (provider.countries if provider and provider.countries else FEEXPAY_COUNTRIES),
        "networks": (provider.networks if provider and provider.networks else list(NETWORK_SLUGS.keys())),
    }


def get_feexpay_gateway(db: Session) -> FeexPayGateway:
    cfg = resolve_feexpay_config(db)
    return FeexPayGateway(
        base_url=cfg["base_url"],
        api_key=cfg["api_key"],
        api_id=cfg["api_id"],
        mode=cfg["mode"],
    )
