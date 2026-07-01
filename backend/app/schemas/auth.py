import uuid
from datetime import datetime

from pydantic import EmailStr, Field

from app.schemas.base import ORMModel, StrictModel


class RegisterIn(StrictModel):
    business_name: str = Field(min_length=1, max_length=200)
    username: str = Field(min_length=3, max_length=50)
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    full_name: str | None = Field(default=None, max_length=200)
    phone: str | None = Field(default=None, max_length=30)


class LoginIn(StrictModel):
    username: str = Field(min_length=1, max_length=255)
    password: str = Field(min_length=1, max_length=128)


class RefreshIn(StrictModel):
    refresh_token: str = Field(min_length=1, max_length=4096)


class MeUpdateIn(StrictModel):
    full_name: str | None = Field(default=None, max_length=200)
    phone: str | None = Field(default=None, max_length=30)
    onboarding_complete: bool | None = None


class TokenOut(StrictModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"  # noqa: S105 — OAuth token type label, not a secret
    expires_in: int


class UserOut(ORMModel):
    id: uuid.UUID
    business_id: uuid.UUID
    username: str
    email: str
    full_name: str | None
    phone: str | None
    role: str
    onboarding_complete: bool
    created_at: datetime


class AuthResponse(StrictModel):
    user: UserOut
    tokens: TokenOut
