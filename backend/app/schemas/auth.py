from typing import Optional, List
from pydantic import BaseModel, ConfigDict

class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
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

class PinVerifyRequest(BaseModel):
    pin: str
    device_id: Optional[str] = None

class SetPinRequest(BaseModel):
    pin: str
    current_password: str

class UserBrief(BaseModel):
    id: str
    username: str
    email: Optional[str] = None
    full_name: Optional[str] = None
    role: str
    permissions: List[str] = []
    has_pin: bool = False

    model_config = ConfigDict(from_attributes=True)

Token.model_rebuild()
