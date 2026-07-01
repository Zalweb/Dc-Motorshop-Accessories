"""Redis-backed login rate limiter.

Per-account fixed window: 5 failed attempts / 15 min. Triggers a generic lockout error
(no signal about whether the username exists). Successful login resets the counter.
"""

from fastapi import Depends, Request
from redis.asyncio import Redis

from app.core.errors import AppError
from app.core.redis import get_redis

MAX_ATTEMPTS = 5
WINDOW_SECONDS = 15 * 60

# Global per-IP cap across all endpoints (login keeps its stricter per-account limit on top).
GLOBAL_MAX_REQUESTS = 600
GLOBAL_WINDOW_SECONDS = 60


def _key(account: str) -> str:
    return f"login:fail:{account.strip().lower()}"


async def is_locked(redis: Redis, account: str) -> bool:
    count = await redis.get(_key(account))
    return count is not None and int(count) >= MAX_ATTEMPTS


async def record_failure(redis: Redis, account: str) -> None:
    key = _key(account)
    count = await redis.incr(key)
    if count == 1:
        await redis.expire(key, WINDOW_SECONDS)


async def reset(redis: Redis, account: str) -> None:
    await redis.delete(_key(account))


async def global_rate_limit(
    request: Request, redis: Redis = Depends(get_redis)
) -> None:
    """Per-IP fixed-window limiter applied to all v1 endpoints (a FastAPI dependency so it
    uses the same overridable Redis as everything else)."""
    ip = request.client.host if request.client else "anonymous"
    key = f"rl:ip:{ip}"
    count = await redis.incr(key)
    if count == 1:
        await redis.expire(key, GLOBAL_WINDOW_SECONDS)
    if count > GLOBAL_MAX_REQUESTS:
        raise AppError(
            code="too_many_requests",
            message="Too many requests. Slow down.",
            status_code=429,
        )
