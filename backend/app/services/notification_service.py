from email.message import EmailMessage
import logging
import smtplib
from urllib.parse import quote

import httpx

from app.core.config import settings

mail_logger = logging.getLogger("tocmanager.mail")
RESEND_API_URL = "https://api.resend.com/emails"


def _send_via_resend(to_email: str, subject: str, html_body: str, text_body: str) -> bool:
    api_key = (settings.RESEND_API_KEY or "").strip()
    if not api_key:
        return False
    response = httpx.post(
        RESEND_API_URL,
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        json={
            "from": settings.MAIL_FROM,
            "to": [to_email],
            "subject": subject,
            "html": html_body,
            "text": text_body,
        },
        timeout=10.0,
    )
    response.raise_for_status()
    return True


def _send_via_smtp(to_email: str, subject: str, text_body: str, html_body: str) -> bool:
    host = (settings.SMTP_HOST or "").strip()
    if not host:
        return False
    msg = EmailMessage()
    msg["Subject"] = subject
    msg["From"] = settings.MAIL_FROM
    msg["To"] = to_email
    msg.set_content(text_body)
    msg.add_alternative(html_body, subtype="html")

    with smtplib.SMTP(host, settings.SMTP_PORT, timeout=10) as server:
        server.starttls()
        if settings.SMTP_USER and settings.SMTP_PASSWORD:
            server.login(settings.SMTP_USER, settings.SMTP_PASSWORD)
        server.send_message(msg)
    return True


def send_transactional_email(
    *,
    to_email: str,
    subject: str,
    text_body: str,
    html_body: str,
    event_kind: str,
) -> str:
    """Deliver email via Resend primary, optional SMTP fallback, or structured console log in dev."""
    if _send_via_resend(to_email, subject, html_body, text_body):
        return "resend"
    if _send_via_smtp(to_email, subject, text_body, html_body):
        return "smtp"
    domain = to_email.split("@")[-1] if "@" in to_email else "unknown"
    mail_logger.info("transactional_email_fallback_log kind=%s domain=%s", event_kind, domain)
    return "console"


def send_email_verification(to_email: str, full_name: str, raw_token: str) -> str:
    base = settings.FRONTEND_BASE_URL.rstrip("/")
    verify_url = f"{base}/verify-email?token={quote(raw_token)}"
    greeting = full_name or "utilisateur"
    text_body = (
        f"Bonjour {greeting},\n\n"
        f"Confirmez votre adresse email TocManager en ouvrant ce lien (valable 24 heures) :\n{verify_url}\n"
    )
    html_body = (
        f"<p>Bonjour {greeting},</p>"
        f"<p>Confirmez votre adresse email TocManager via le lien ci-dessous (valable 24 heures) :</p>"
        f"<p><a href=\"{verify_url}\">Verifier mon adresse email</a></p>"
    )
    return send_transactional_email(
        to_email=to_email,
        subject="TocManager - Verification de votre adresse email",
        text_body=text_body,
        html_body=html_body,
        event_kind="email_verification",
    )


def send_password_reset(to_email: str, full_name: str, raw_token: str) -> str:
    base = settings.FRONTEND_BASE_URL.rstrip("/")
    reset_url = f"{base}/reset-password?token={quote(raw_token)}"
    greeting = full_name or "utilisateur"
    text_body = (
        f"Bonjour {greeting},\n\n"
        f"Reinitialisez votre mot de passe TocManager via ce lien (valable 30 minutes) :\n{reset_url}\n"
    )
    html_body = (
        f"<p>Bonjour {greeting},</p>"
        f"<p>Reinitialisez votre mot de passe TocManager via le lien ci-dessous (valable 30 minutes) :</p>"
        f"<p><a href=\"{reset_url}\">Reinitialiser mon mot de passe</a></p>"
    )
    return send_transactional_email(
        to_email=to_email,
        subject="TocManager - Reinitialisation de votre mot de passe",
        text_body=text_body,
        html_body=html_body,
        event_kind="password_reset",
    )
