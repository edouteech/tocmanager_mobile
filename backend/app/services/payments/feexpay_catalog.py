from typing import Any, Dict, List
from sqlalchemy.orm import Session
from app.core.config import settings
from app.models import PaymentProvider

FEEXPAY_COUNTRIES: List[Dict[str, Any]] = [
    {"code": "BJ", "name": "Bénin", "dial_code": "+229", "networks": ["MTN", "MOOV", "CELTIIS BJ", "CORIS"]},
    {"code": "TG", "name": "Togo", "dial_code": "+228", "networks": ["TOGOCOM TG", "MOOV TG"]},
    {"code": "CI", "name": "Côte d'Ivoire", "dial_code": "+225", "networks": ["MTN CI", "ORANGE CI", "MOOV CI", "WAVE CI"]},
    {"code": "SN", "name": "Sénégal", "dial_code": "+221", "networks": ["ORANGE SN", "WAVE SN", "FREE SN"]},
    {"code": "BF", "name": "Burkina Faso", "dial_code": "+226", "networks": ["MOOV BF", "ORANGE BF", "WAVE BF"]},
    {"code": "ML", "name": "Mali", "dial_code": "+223", "networks": ["ORANGE ML", "MOBICASH ML"]},
    {"code": "CG", "name": "Congo Brazzaville", "dial_code": "+242", "networks": ["MTN CG"]},
]

NETWORK_SLUGS: Dict[str, str] = {
    "MTN": "mtn",
    "MOOV": "moov",
    "CELTIIS BJ": "celtiis_bj",
    "CORIS": "coris",
    "TOGOCOM TG": "togocom_tg",
    "MOOV TG": "moov_tg",
    "MTN CI": "mtn_ci",
    "ORANGE CI": "orange_ci",
    "MOOV CI": "moov_ci",
    "WAVE CI": "wave_ci",
    "ORANGE SN": "orange_sn",
    "WAVE SN": "wave_sn",
    "FREE SN": "free_sn",
    "MTN CG": "mtn_cg",
    "MOOV BF": "moov_bf",
    "ORANGE BF": "orange_bf",
    "WAVE BF": "wave_bf",
    "ORANGE ML": "orange_ml",
    "MOBICASH ML": "mobicash_ml",
}

REDIRECT_NETWORKS = {
    "orange_ci",
    "moov_ci",
    "wave_ci",
    "orange_sn",
    "wave_sn",
    "free_sn",
    "wave_bf",
}

OTP_REQUIRED_NETWORKS = {"coris", "orange_bf", "wave_bf"}


def normalize_phone(phone: str) -> str:
    return "".join(ch for ch in (phone or "").strip() if ch.isdigit())


def normalize_status(raw_status: Any) -> str:
    val = str(raw_status or "").strip().upper()
    if val in ("SUCCESSFUL", "SUCCESS", "PAID", "COMPLETED"):
        return "successful"
    if val in ("FAILED", "REJECTED", "EXPIRED", "ERROR"):
        return "failed"
    if val in ("CANCELLED", "CANCELED"):
        return "canceled"
    return "pending"


def seed_default_payment_providers(db: Session) -> None:
    """Seed FeexPay provider metadata idempotently without storing plain credentials."""
    existing = db.query(PaymentProvider).filter(PaymentProvider.code == "feexpay").first()
    if existing:
        if not existing.countries:
            existing.countries = FEEXPAY_COUNTRIES
        if not existing.networks:
            existing.networks = list(NETWORK_SLUGS.keys())
        db.commit()
        return

    db.add(PaymentProvider(
        code="feexpay",
        name="FeexPay Mobile Money",
        is_active=True,
        mode=settings.FEEXPAY_MODE or "sandbox",
        countries=FEEXPAY_COUNTRIES,
        networks=list(NETWORK_SLUGS.keys()),
        config_encrypted=None,
    ))
    db.commit()
