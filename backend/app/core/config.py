"""Application settings sourced exclusively from the environment.

Secrets (DB URL, JWT keys, S3 creds) are NEVER hardcoded — they come from env or a
gitignored `.env`. See `.env.example` for the contract.
"""

from functools import lru_cache
from typing import Literal

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
        case_sensitive=False,
    )

    env: Literal["dev", "test", "staging", "prod"] = "dev"
    api_base_path: str = "/v1"

    # Database
    database_url: str = Field(
        default="postgresql+asyncpg://dc:dc@localhost:5432/dc_motorshop",
        description="Async SQLAlchemy DSN (asyncpg driver).",
    )

    # Auth / JWT
    jwt_secret: str = Field(
        default="change-me-in-env",
        description="HS256 signing secret. Override in every non-dev environment.",
    )
    jwt_algorithm: str = "HS256"
    access_token_ttl_minutes: int = 15
    refresh_token_ttl_days: int = 30

    # Redis (rate limiting, refresh-token reuse detection)
    redis_url: str = "redis://localhost:6379/0"

    # S3-compatible object storage (product/logo images)
    s3_endpoint_url: str | None = None
    s3_region: str = "us-east-1"
    s3_bucket: str = "dc-motorshop"
    s3_access_key: str | None = None
    s3_secret_key: str | None = None

    # CORS — deny by default; comma-separated allowlist of origins.
    cors_allow_origins: list[str] = Field(default_factory=list)

    @property
    def is_prod(self) -> bool:
        return self.env in ("staging", "prod")


@lru_cache
def get_settings() -> Settings:
    return Settings()
