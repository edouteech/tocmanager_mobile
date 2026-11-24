from typing import List, Optional
from pydantic import BaseModel, ConfigDict


class Token(BaseModel):
    access_token: str = ""
    refresh_token: str = ""
    token_type: str = "bearer"
    requires_2fa: bool = False
    challenge_token: Optional[str] = None
    user: "UserBrief"


class TokenPayload(BaseModel):
    sub: Optional[str] = None
    type: Optional[str] = None


class LoginRequest(BaseModel):
    username_or_email: str
    password: str
    device_id: Optional[str] = None


class RefreshRequest(BaseModel):
    refresh_token: str


class LogoutRequest(BaseModel):
    refresh_token: Optional[str] = None
    all_devices: bool = False


class PinVerifyRequest(BaseModel):
    pin: str
    device_id: Optional[str] = None


class SetPinRequest(BaseModel):
    pin: str
    current_password: str


class ForgotPasswordRequest(BaseModel):
    email: str


class ResetPasswordRequest(BaseModel):
    token: str
    new_password: str


class VerifyEmailRequest(BaseModel):
    token: str


class TwoFactorSetupResponse(BaseModel):
    secret: str
    otpauth_uri: str


class TwoFactorConfirmRequest(BaseModel):
    code: str


class TwoFactorDisableRequest(BaseModel):
    password: str
    code: str


class TwoFactorChallengeVerifyRequest(BaseModel):
    challenge_token: str
    code: str
    device_id: Optional[str] = None


class UserBrief(BaseModel):
    id: str
    username: str
    email: Optional[str] = None
    full_name: Optional[str] = None
    role: str
    permissions: List[str] = []
    has_pin: bool = False
    is_active: bool = True
    email_verified: bool = False
    totp_enabled: bool = False
    assigned_magasin_ids: List[str] = []

    model_config = ConfigDict(from_attributes=True)


Token.model_rebuild()
