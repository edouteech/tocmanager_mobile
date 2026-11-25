from contextvars import ContextVar
from datetime import datetime, timezone
import json
import logging
import time
import uuid

from fastapi import Request
from fastapi.responses import JSONResponse
from jose import JWTError, jwt
from starlette.middleware.base import BaseHTTPMiddleware

from app.core.config import settings

_request_id_ctx: ContextVar[str] = ContextVar("request_id", default="-")
_user_id_ctx: ContextVar[str] = ContextVar("user_id", default="-")
_boutique_id_ctx: ContextVar[str] = ContextVar("boutique_id", default="-")

http_logger = logging.getLogger("tocmanager.http")


class JsonLogFormatter(logging.Formatter):
    """Emit structured single-line JSON logs without secrets or PII."""

    def format(self, record: logging.LogRecord) -> str:
        payload = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "request_id": getattr(record, "request_id", _request_id_ctx.get()),
            "user_id": getattr(record, "user_id", _user_id_ctx.get()),
            "boutique_id": getattr(record, "boutique_id", _boutique_id_ctx.get()),
        }
        for key in ("method", "path", "status_code", "duration_ms"):
            val = getattr(record, key, None)
            if val is not None:
                payload[key] = val
        if record.exc_info:
            payload["exception"] = self.formatException(record.exc_info)
        return json.dumps(payload, ensure_ascii=False)


def configure_json_logging(level: int = logging.INFO) -> None:
    handler = logging.StreamHandler()
    handler.setFormatter(JsonLogFormatter())
    logger = logging.getLogger("tocmanager")
    logger.handlers = [handler]
    logger.setLevel(level)
    logger.propagate = False


def init_sentry() -> bool:
    dsn = (settings.SENTRY_DSN or "").strip()
    if not dsn:
        return False
    import sentry_sdk

    sentry_sdk.init(
        dsn=dsn,
        environment=settings.ENVIRONMENT,
        traces_sample_rate=settings.SENTRY_TRACES_SAMPLE_RATE,
        send_default_pii=False,
    )
    return True


def _extract_bearer_sub(auth_header: str) -> str:
    if not auth_header.startswith("Bearer "):
        return "-"
    token = auth_header[7:].strip()
    if not token:
        return "-"
    try:
        claims = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        sub = claims.get("sub")
        return str(sub) if sub else "-"
    except JWTError:
        return "-"


class RequestObservabilityMiddleware(BaseHTTPMiddleware):
    """Attach X-Request-Id and emit structured JSON access log for each HTTP call."""

    async def dispatch(self, request: Request, call_next):
        req_id = request.headers.get("X-Request-Id") or uuid.uuid4().hex
        btq_id = request.headers.get("X-Boutique-Id") or "-"
        usr_id = _extract_bearer_sub(request.headers.get("Authorization", ""))

        t_req = _request_id_ctx.set(req_id)
        t_usr = _user_id_ctx.set(usr_id)
        t_btq = _boutique_id_ctx.set(btq_id)
        start = time.perf_counter()

        try:
            response = await call_next(request)
        except Exception as exc:
            duration_ms = round((time.perf_counter() - start) * 1000.0, 2)
            http_logger.exception(
                "request_failed",
                extra={
                    "request_id": req_id,
                    "user_id": usr_id,
                    "boutique_id": btq_id,
                    "method": request.method,
                    "path": request.url.path,
                    "status_code": 500,
                    "duration_ms": duration_ms,
                },
            )
            if (settings.SENTRY_DSN or "").strip():
                try:
                    import sentry_sdk

                    sentry_sdk.capture_exception(exc)
                except Exception:
                    pass
            # Return JSON inside the CORS middleware boundary so allowed origins receive CORS headers on 500s.
            return JSONResponse(
                status_code=500,
                content={"detail": "Erreur interne du serveur.", "request_id": req_id},
                headers={"X-Request-Id": req_id},
            )
        finally:
            _request_id_ctx.reset(t_req)
            _user_id_ctx.reset(t_usr)
            _boutique_id_ctx.reset(t_btq)

        duration_ms = round((time.perf_counter() - start) * 1000.0, 2)
        response.headers["X-Request-Id"] = req_id
        http_logger.info(
            "http_request",
            extra={
                "request_id": req_id,
                "user_id": usr_id,
                "boutique_id": btq_id,
                "method": request.method,
                "path": request.url.path,
                "status_code": response.status_code,
                "duration_ms": duration_ms,
            },
        )
        return response
