"""Authentication service: register, login, refresh (rotate + reuse-detect), logout.

Refresh-token security model (Redis-backed, stores only opaque jti state — never tokens):
  - Each login starts a token *family* (`fid`). The active refresh jti is keyed
    `refresh:{jti}` = "active" with a 30-day TTL.
  - On refresh the presented jti must be "active"; it is then marked "rotated" and a new
    active jti is issued in the same family.
  - Presenting a "rotated" (already-used) jti = replay of a stolen token → the whole
    family is revoked (`refresh:family:{fid}:revoked`). This is the stolen-token defense.
  - Logout revokes the family.
"""

from dataclasses import dataclass
from uuid import UUID

from redis.asyncio import Redis
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core import rate_limit
from app.core.config import get_settings
from app.core.errors import AppError
from app.core.ids import uuid7
from app.core.security import (
    DUMMY_HASH,
    TokenError,
    access_ttl_seconds,
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)
from app.models.audit_log import AuditLog
from app.models.business import Business
from app.models.user import User


@dataclass
class TokenPair:
    access_token: str
    refresh_token: str
    expires_in: int


_INVALID_CREDENTIALS = AppError(
    code="invalid_credentials",
    message="Invalid username or password",
    status_code=401,
)


class AuthService:
    def __init__(self, session: AsyncSession, redis: Redis) -> None:
        self.session = session
        self.redis = redis

    async def register(self, *, business_name, username, email, password, full_name, phone, ip):
        existing = await self.session.scalar(
            select(func.count()).select_from(User).where(User.username == username)
        )
        if existing:
            # Generic conflict — do not reveal which field collided.
            raise AppError(code="already_exists", message="Account already exists", status_code=409)

        business = Business(name=business_name)
        self.session.add(business)
        await self.session.flush()

        user = User(
            business_id=business.id,
            username=username,
            email=email,
            password_hash=hash_password(password),
            full_name=full_name,
            phone=phone,
            role="owner",
        )
        self.session.add(user)
        await self.session.flush()

        await self._audit("register", business_id=business.id, user_id=user.id, ip=ip)
        tokens = await self._issue_new_family(user)
        await self.session.commit()
        await self.session.refresh(user)
        return user, tokens

    async def login(self, *, username: str, password: str, ip: str | None):
        if await rate_limit.is_locked(self.redis, username):
            raise AppError(
                code="too_many_attempts",
                message="Too many login attempts. Try again later.",
                status_code=429,
            )

        user = await self.session.scalar(
            select(User).where(User.username == username, User.deleted_at.is_(None))
        )

        # Always run a verify (real or dummy) so response timing can't enumerate users.
        password_ok = verify_password(user.password_hash if user else DUMMY_HASH, password)

        if user is None or not password_ok:
            await rate_limit.record_failure(self.redis, username)
            await self._audit(
                "login_failed",
                business_id=user.business_id if user else None,
                user_id=user.id if user else None,
                ip=ip,
            )
            await self.session.commit()
            raise _INVALID_CREDENTIALS

        await rate_limit.reset(self.redis, username)
        await self._audit("login", business_id=user.business_id, user_id=user.id, ip=ip)
        tokens = await self._issue_new_family(user)
        await self.session.commit()
        return user, tokens

    async def refresh(self, *, refresh_token: str, ip: str | None) -> TokenPair:
        claims = decode_token(refresh_token, expected_type="refresh")
        jti = claims["jti"]
        fid = claims["fid"]
        user_id = UUID(claims["sub"])

        if await self.redis.get(self._family_key(fid)) == "revoked":
            raise TokenError(code="token_revoked", message="Token has been revoked")

        state = await self.redis.get(self._jti_key(jti))
        if state is None:
            raise TokenError(code="token_revoked", message="Token has been revoked")
        if state == "rotated":
            # Replay of an already-used refresh token → revoke the whole family.
            await self.redis.set(self._family_key(fid), "revoked", ex=self._refresh_ttl())
            await self._audit(
                "refresh_reuse", business_id=UUID(claims["bid"]), user_id=user_id, ip=ip
            )
            await self.session.commit()
            raise TokenError(code="token_reuse_detected", message="Token has been revoked")

        user = await self.session.get(User, user_id)
        if user is None or user.deleted_at is not None:
            raise TokenError(code="unauthorized", message="Authentication required")

        await self.redis.set(self._jti_key(jti), "rotated", ex=self._refresh_ttl())
        tokens = await self._issue_in_family(user, family_id=fid)
        return tokens

    async def logout(self, *, refresh_token: str, ip: str | None) -> None:
        try:
            claims = decode_token(refresh_token, expected_type="refresh")
        except TokenError:
            return  # Idempotent: an already-invalid token is already "logged out".
        fid = claims["fid"]
        await self.redis.set(self._family_key(fid), "revoked", ex=self._refresh_ttl())
        await self._audit(
            "logout", business_id=UUID(claims["bid"]), user_id=UUID(claims["sub"]), ip=ip
        )
        await self.session.commit()

    # --- helpers -------------------------------------------------------------

    async def _issue_new_family(self, user: User) -> TokenPair:
        return await self._issue_in_family(user, family_id=uuid7().hex)

    async def _issue_in_family(self, user: User, *, family_id: str) -> TokenPair:
        jti = uuid7().hex
        await self.redis.set(self._jti_key(jti), "active", ex=self._refresh_ttl())
        access = create_access_token(
            user_id=user.id, business_id=user.business_id, role=user.role
        )
        refresh = create_refresh_token(
            user_id=user.id,
            business_id=user.business_id,
            role=user.role,
            family_id=family_id,
            jti=jti,
        )
        return TokenPair(
            access_token=access, refresh_token=refresh, expires_in=access_ttl_seconds()
        )

    async def _audit(self, event, *, business_id, user_id, ip, detail=None) -> None:
        self.session.add(
            AuditLog(business_id=business_id, user_id=user_id, event=event, ip=ip, detail=detail)
        )

    @staticmethod
    def _jti_key(jti: str) -> str:
        return f"refresh:{jti}"

    @staticmethod
    def _family_key(fid: str) -> str:
        return f"refresh:family:{fid}:revoked"

    @staticmethod
    def _refresh_ttl() -> int:
        return get_settings().refresh_token_ttl_days * 86400
