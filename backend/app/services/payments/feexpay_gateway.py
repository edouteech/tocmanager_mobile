import logging
from typing import Any, Dict, Optional
import httpx

from app.services.payments.feexpay_catalog import (
    NETWORK_SLUGS,
    OTP_REQUIRED_NETWORKS,
    REDIRECT_NETWORKS,
    normalize_phone,
    normalize_status,
)
from app.services.payments.gateway_protocol import (
    InitiationResult,
    ParsedCallback,
    StatusCheckResult,
    redact_payload,
)

logger = logging.getLogger(__name__)


class FeexPayGateway:
    """HTTP adapter for FeexPay REST v2 (based on verified secondnum integration)."""

    requires_callback_confirmation = True

    def __init__(
        self,
        base_url: str,
        api_key: str,
        api_id: str,
        mode: str = "sandbox",
        http_client: Optional[httpx.Client] = None,
    ) -> None:
        self.base_url = base_url.rstrip("/")
        self.api_key = api_key
        self.api_id = api_id
        self.mode = mode
        self._http_client = http_client

    def _headers(self) -> Dict[str, str]:
        return {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
            "Accept": "application/json",
        }

    def initiate(
        self,
        reference: str,
        amount: float,
        phone: str,
        network: str,
        fullname: str,
        email: str,
        description: str,
    ) -> InitiationResult:
        network_key = network.strip().upper()
        slug = NETWORK_SLUGS.get(network_key)
        if not slug:
            raise ValueError(f"Réseau FeexPay non supporté : {network}")

        payload: Dict[str, Any] = {
            "shop": self.api_id,
            "amount": int(round(amount)),
            "phoneNumber": normalize_phone(phone),
            "fullname": fullname,
            "email": email,
            "callback_info": reference,
            "description": description,
        }
        if slug in OTP_REQUIRED_NETWORKS:
            payload["otp"] = ""

        url = f"{self.base_url}/api/transactions/public/requesttopay/{slug}"
        if self._http_client is not None:
            response = self._http_client.post(url, json=payload, headers=self._headers(), timeout=30.0)
        else:
            with httpx.Client(timeout=30.0) as client:
                response = client.post(url, json=payload, headers=self._headers())
        response.raise_for_status()
        data = response.json() if response.content else {}

        flow_type = "redirect" if slug in REDIRECT_NETWORKS else "ussd_push"
        payment_url = data.get("payment_url") or data.get("url")
        ext_ref = data.get("reference") or data.get("order_id") or data.get("transref")
        return InitiationResult(
            status=normalize_status(data.get("status")),
            flow_type=flow_type,
            external_reference=str(ext_ref) if ext_ref else None,
            payment_url=str(payment_url) if payment_url else None,
            raw_payload=redact_payload(data),
        )

    def parse_callback(self, payload: Dict[str, Any]) -> ParsedCallback:
        ref = payload.get("callback_info") or payload.get("reference")
        ext_ref = payload.get("reference") or payload.get("order_id") or payload.get("transref")
        raw_amount = payload.get("amount")
        amount_val = float(raw_amount) if raw_amount is not None else None
        return ParsedCallback(
            reference=str(ref) if ref else None,
            external_reference=str(ext_ref) if ext_ref else None,
            status=normalize_status(payload.get("status")),
            amount=amount_val,
            raw_payload=redact_payload(payload),
        )

    def check_status(self, ref: str) -> Optional[StatusCheckResult]:
        if not ref:
            return None
        url = f"{self.base_url}/api/transactions/public/single/status/{ref}"
        try:
            if self._http_client is not None:
                response = self._http_client.get(url, headers=self._headers(), timeout=8.0)
            else:
                with httpx.Client(timeout=8.0) as client:
                    response = client.get(url, headers=self._headers())
            if response.status_code >= 400:
                logger.warning("FeexPay check_status HTTP %s for %s", response.status_code, ref)
                return None
            data = response.json() if response.content else {}
            raw_amount = data.get("amount")
            ext_ref = data.get("reference") or data.get("order_id") or data.get("transref")
            return StatusCheckResult(
                status=normalize_status(data.get("status")),
                external_reference=str(ext_ref) if ext_ref else None,
                amount=float(raw_amount) if raw_amount is not None else None,
                raw_payload=redact_payload(data),
            )
        except Exception as exc:
            logger.warning("FeexPay check_status error for %s: %s", ref, exc)
            return None
