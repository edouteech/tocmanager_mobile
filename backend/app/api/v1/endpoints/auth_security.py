from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session

from app.api import deps
from app.core.database import get_db
from app.core.rate_limit import limiter
from app.models import User
from app.schemas.auth import (
    ForgotPasswordRequest,
    ResetPasswordRequest,
    Token,
    TwoFactorChallengeVerifyRequest,
    TwoFactorConfirmRequest,
    TwoFactorDisableRequest,
    TwoFactorSetupResponse,
    UserBrief,
    VerifyEmailRequest,
)
from app.services.account_security_service import (
    confirm_superadmin_2fa,
    disable_superadmin_2fa,
    request_email_verification,
    request_password_reset,
    reset_password_with_token,
    setup_superadmin_2fa,
    verify_email_with_token,
    verify_superadmin_2fa_challenge,
)
from app.services.auth_service import user_to_brief

router = APIRouter()

_FORGOT_PASSWORD_MESSAGE = (
    "Si un compte est associe a cette adresse email, un lien de reinitialisation vient d'etre envoye."
)


@router.post("/request-email-verification")
def post_request_email_verification(
    current_user: User = Depends(deps.get_current_user),
    db: Session = Depends(get_db),
):
    channel = request_email_verification(db, current_user)
    return {"status": "sent", "channel": channel}


@router.post("/verify-email", response_model=UserBrief)
def post_verify_email(
    payload: VerifyEmailRequest,
    db: Session = Depends(get_db),
):
    user = verify_email_with_token(db, payload.token)
    return user_to_brief(user)


@router.post("/forgot-password")
@limiter.limit("5/minute")
def post_forgot_password(
    request: Request,
    payload: ForgotPasswordRequest,
    db: Session = Depends(get_db),
):
    _ = request
    request_password_reset(db, payload.email)
    return {"status": "ok", "message": _FORGOT_PASSWORD_MESSAGE}


@router.post("/reset-password")
@limiter.limit("10/minute")
def post_reset_password(
    request: Request,
    payload: ResetPasswordRequest,
    db: Session = Depends(get_db),
):
    _ = request
    reset_password_with_token(db, payload.token, payload.new_password)
    return {"status": "ok", "message": "Mot de passe reinitialise avec succes."}


@router.post("/2fa/setup", response_model=TwoFactorSetupResponse)
def post_setup_2fa(
    current_user: User = Depends(deps.require_role(["superadmin"])),
    db: Session = Depends(get_db),
):
    secret, otpauth_uri = setup_superadmin_2fa(db, current_user)
    return TwoFactorSetupResponse(secret=secret, otpauth_uri=otpauth_uri)


@router.post("/2fa/confirm", response_model=UserBrief)
def post_confirm_2fa(
    payload: TwoFactorConfirmRequest,
    current_user: User = Depends(deps.require_role(["superadmin"])),
    db: Session = Depends(get_db),
):
    user = confirm_superadmin_2fa(db, current_user, payload.code)
    return user_to_brief(user)


@router.post("/2fa/disable", response_model=UserBrief)
def post_disable_2fa(
    payload: TwoFactorDisableRequest,
    current_user: User = Depends(deps.require_role(["superadmin"])),
    db: Session = Depends(get_db),
):
    user = disable_superadmin_2fa(db, current_user, payload.password, payload.code)
    return user_to_brief(user)


@router.post("/verify-2fa", response_model=Token)
@limiter.limit("10/minute")
def post_verify_2fa(
    request: Request,
    payload: TwoFactorChallengeVerifyRequest,
    db: Session = Depends(get_db),
):
    _ = request
    user, access_token, refresh_tok = verify_superadmin_2fa_challenge(
        db,
        payload.challenge_token,
        payload.code,
        device_id=payload.device_id,
    )
    return Token(
        access_token=access_token,
        refresh_token=refresh_tok,
        token_type="bearer",
        requires_2fa=False,
        user=user_to_brief(user),
    )
