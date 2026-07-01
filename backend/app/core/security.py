"""Password hashing (Argon2id) and JWT encode/decode.

Tokens carry: sub (user id), bid (business id), role, typ (access|refresh), jti, exp, iat.
Refresh tokens additionally carry fid (token family) for rotation + reuse detection.
Secrets/tokens are never logged.
"""

from uuid import UUID

import jwt
from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerifyMismatchError
from fastapi import status

from app.core.clock import utcnow
from app.core.config import get_settings
from app.core.errors import AppError
from app.core.ids import uuid7

_hasher = PasswordHasher()

# Pre-computed hash used to equalize timing when a login targets an unknown user
# (defeats username enumeration via response-time differences).
DUMMY_HASH = _hasher.hash("dc-motorshop-timing-equalizer")


class TokenError(AppError):
    def __init__(self, code: str = "invalid_token", message: str = "Invalid token") -> None:
        super().__init__(code=code, message=message, status_code=status.HTTP_401_UNAUTHORIZED)


def hash_password(password: str) -> str:
    return _hasher.hash(password)


def verify_password(password_hash: str, password: str) -> bool:
    try:
        return _hasher.verify(password_hash, password)
    except (VerifyMismatchError, InvalidHashError):
        return False


def needs_rehash(password_hash: str) -> bool:
    return _hasher.check_needs_rehash(password_hash)


def _encode(claims: dict) -> str:
    settings = get_settings()
    return jwt.encode(claims, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def create_access_token(*, user_id: UUID, business_id: UUID, role: str) -> str:
    now = utcnow()
    claims = {
        "sub": str(user_id),
        "bid": str(business_id),
        "role": role,
        "typ": "access",
        "jti": uuid7().hex,
        "iat": now,
        "exp": now + _access_ttl(),
    }
    return _encode(claims)


def create_refresh_token(
    *, user_id: UUID, business_id: UUID, role: str, family_id: str, jti: str
) -> str:
    now = utcnow()
    claims = {
        "sub": str(user_id),
        "bid": str(business_id),
        "role": role,
        "typ": "refresh",
        "fid": family_id,
        "jti": jti,
        "iat": now,
        "exp": now + _refresh_ttl(),
    }
    return _encode(claims)


def decode_token(token: str, *, expected_type: str) -> dict:
    settings = get_settings()
    try:
        claims = jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
    except jwt.ExpiredSignatureError as exc:
        raise TokenError(code="token_expired", message="Token has expired") from exc
    except jwt.InvalidTokenError as exc:
        raise TokenError() from exc
    if claims.get("typ") != expected_type:
        raise TokenError()
    return claims


def access_ttl_seconds() -> int:
    return int(_access_ttl().total_seconds())


def _access_ttl():
    from datetime import timedelta

    return timedelta(minutes=get_settings().access_token_ttl_minutes)


def _refresh_ttl():
    from datetime import timedelta

    return timedelta(days=get_settings().refresh_token_ttl_days)
