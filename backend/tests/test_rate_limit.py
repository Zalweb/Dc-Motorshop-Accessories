import app.core.rate_limit as rate_limit

from tests.helpers import auth_headers, register


async def test_global_rate_limit_blocks_after_cap(client, monkeypatch):
    monkeypatch.setattr(rate_limit, "GLOBAL_MAX_REQUESTS", 3)
    headers = auth_headers(await register(client))
    statuses = [(await client.get("/v1/categories", headers=headers)).status_code for _ in range(4)]
    assert statuses[-1] == 429


async def test_health_is_not_rate_limited(client, monkeypatch):
    monkeypatch.setattr(rate_limit, "GLOBAL_MAX_REQUESTS", 1)
    first = await client.get("/v1/health")
    second = await client.get("/v1/health")
    assert (first.status_code, second.status_code) == (200, 200)
