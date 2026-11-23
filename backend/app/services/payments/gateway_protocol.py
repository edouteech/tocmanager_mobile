from dataclasses import dataclass
from typing import Any, Dict, Optional, Protocol

SENSITIVE_KEYS = {"api_key", "authorization", "token", "secret", "password"}


def redact_payload(data: Any) -> Any:
    """Recursively mask sensitive credentials in stored or logged payment payloads."""
    if isinstance(data, dict):
        return {
            k: ("***" if str(k).lower() in SENSITIVE_KEYS else redact_payload(v))
            for k, v in data.items()
        }
    if isinstance(data, list):
        return [redact_payload(item) for item in data]
    return data


@dataclass
class InitiationResult:
    status: str
    flow_type: str
    external_reference: Optional[str]
    payment_url: Optional[str]
    raw_payload: Dict[str, Any]


@dataclass
class StatusCheckResult:
    status: str
    external_reference: Optional[str]
    amount: Optional[float]
    raw_payload: Dict[str, Any]


@dataclass
class ParsedCallback:
    reference: Optional[str]
    external_reference: Optional[str]
    status: str
    amount: Optional[float]
    raw_payload: Dict[str, Any]


class PaymentGatewayProtocol(Protocol):
    requires_callback_confirmation: bool

    def initiate(
        self,
        reference: str,
        amount: float,
        phone: str,
        network: str,
        fullname: str,
        email: str,
        description: str,
    ) -> InitiationResult: ...

    def parse_callback(self, payload: Dict[str, Any]) -> ParsedCallback: ...

    def check_status(self, ref: str) -> Optional[StatusCheckResult]: ...
