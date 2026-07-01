from httpx import AsyncClient


async def test_health_returns_ok(client: AsyncClient) -> None:
    response = await client.get("/v1/health")
    assert response.json() == {"status": "ok"}


async def test_health_status_code_is_200(client: AsyncClient) -> None:
    response = await client.get("/v1/health")
    assert response.status_code == 200


async def test_security_headers_present(client: AsyncClient) -> None:
    response = await client.get("/v1/health")
    assert response.headers["X-Content-Type-Options"] == "nosniff"
    assert response.headers["X-Frame-Options"] == "DENY"
    assert response.headers["Referrer-Policy"] == "no-referrer"
    assert "Strict-Transport-Security" in response.headers


async def test_request_id_echoed(client: AsyncClient) -> None:
    response = await client.get("/v1/health")
    assert response.headers["X-Request-ID"]
