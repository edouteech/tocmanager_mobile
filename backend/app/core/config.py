import json
import os
from typing import Any, List, Optional, Union
from pydantic import field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

DEFAULT_DEV_SECRET_KEY = "dev-only-insecure-secret-key-not-for-prod"
MIN_PROD_SECRET_LENGTH = 32


class Settings(BaseSettings):
    PROJECT_NAME: str = "TocManager API"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development")
    ENABLE_DEMO_SEED: bool = True

    SECRET_KEY: str = os.getenv("SECRET_KEY", DEFAULT_DEV_SECRET_KEY)
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 48  # 48 hours
    REFRESH_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 30  # 30 days (sliding rotation)

    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./tocmanager.db")

    BACKEND_CORS_ORIGINS: Union[List[str], str] = [
        "http://localhost:5173",
        "http://localhost:3000",
        "http://127.0.0.1:5173",
        "http://localhost:8000",
    ]

    BOOTSTRAP_SUPERADMIN_USERNAME: str = "admin"
    BOOTSTRAP_SUPERADMIN_EMAIL: Optional[str] = None
    BOOTSTRAP_SUPERADMIN_PASSWORD: Optional[str] = None

    @field_validator("BACKEND_CORS_ORIGINS", mode="before")
    @classmethod
    def parse_cors_origins(cls, value: Any) -> List[str]:
        if isinstance(value, str):
            raw = value.strip()
            if not raw:
                return []
            if raw.startswith("["):
                parsed = json.loads(raw)
                return [str(item).strip() for item in parsed if str(item).strip()]
            return [item.strip() for item in raw.split(",") if item.strip()]
        if isinstance(value, (list, tuple)):
            return [str(item).strip() for item in value if str(item).strip()]
        return []

    @model_validator(mode="after")
    def validate_production_security(self) -> "Settings":
        if isinstance(self.BACKEND_CORS_ORIGINS, str):
            self.BACKEND_CORS_ORIGINS = self.parse_cors_origins(self.BACKEND_CORS_ORIGINS)

        if self.ENVIRONMENT.strip().lower() == "production":
            key = (self.SECRET_KEY or "").strip()
            if (
                not key
                or len(key) < MIN_PROD_SECRET_LENGTH
                or key == DEFAULT_DEV_SECRET_KEY
                or "change-in-production" in key.lower()
                or "replace-with" in key.lower()
            ):
                raise ValueError(
                    "SECRET_KEY must be set to a unique secret of at least 32 characters in production."
                )
            if "*" in self.BACKEND_CORS_ORIGINS:
                raise ValueError(
                    "BACKEND_CORS_ORIGINS cannot contain '*' when allow_credentials=True in production."
                )
        return self

    model_config = SettingsConfigDict(
        env_file=".env",
        case_sensitive=True,
    )


settings = Settings()
