from typing import List, Literal, Optional
from pydantic import BaseModel, field_validator

AssignableTenantRole = Literal["store_admin", "manager", "cashier"]


def _validate_pin_format(value: Optional[str]) -> Optional[str]:
    if value is None or value == "":
        return None
    cleaned = value.strip()
    if len(cleaned) not in (4, 6) or not cleaned.isdigit():
        raise ValueError("Le code PIN doit comporter 4 ou 6 chiffres")
    return cleaned


class UserCreate(BaseModel):
    username: str
    password: str
    email: Optional[str] = None
    full_name: Optional[str] = None
    role: AssignableTenantRole = "cashier"
    pin: Optional[str] = None
    assigned_magasin_ids: Optional[List[str]] = None

    @field_validator("password")
    @classmethod
    def check_password(cls, value: str) -> str:
        if len(value) < 6:
            raise ValueError("Le mot de passe doit contenir au moins 6 caractères")
        return value

    @field_validator("pin", mode="before")
    @classmethod
    def check_pin(cls, value: Optional[str]) -> Optional[str]:
        return _validate_pin_format(value)


class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    email: Optional[str] = None
    password: Optional[str] = None
    role: Optional[AssignableTenantRole] = None
    pin: Optional[str] = None
    is_active: Optional[bool] = None
    assigned_magasin_ids: Optional[List[str]] = None

    @field_validator("password")
    @classmethod
    def check_password(cls, value: Optional[str]) -> Optional[str]:
        if value is not None and value != "" and len(value) < 6:
            raise ValueError("Le mot de passe doit contenir au moins 6 caractères")
        return value or None

    @field_validator("pin", mode="before")
    @classmethod
    def check_pin(cls, value: Optional[str]) -> Optional[str]:
        return _validate_pin_format(value)
