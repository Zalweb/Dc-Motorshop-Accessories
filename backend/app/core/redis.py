"""Async Redis client provider.

Used for login rate limiting and refresh-token reuse detection. Exposed as a FastAPI
dependency so tests can override it with an in-memory fake.
"""

from redis.asyncio import Redis, from_url

from app.core.config import get_settings

_client: Redis | None = None


def get_redis_client() -> Redis:
    global _client
    if _client is None:
        _client = from_url(get_settings().redis_url, decode_responses=True)
    return _client


async def get_redis() -> Redis:
    return get_redis_client()


async def close_redis() -> None:
    global _client
    if _client is not None:
        await _client.aclose()
        _client = None
