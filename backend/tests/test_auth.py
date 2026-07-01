from app.models.user import User
from sqlalchemy import select


async def _register(client, **overrides):
    payload = {
        "business_name": "DC Motorshop",
        "username": "owner1",
        "email": "owner1@example.com",
        "password": "s3cret-pass",
        "full_name": "Owner One",
    }
    payload.update(overrides)
    return await client.post("/v1/auth/register", json=payload)


async def test_register_returns_access_token(client):
    response = await _register(client)
    assert response.json()["tokens"]["access_token"]


async def test_register_returns_created_status(client):
    response = await _register(client)
    assert response.status_code == 201


async def test_register_rejects_unknown_fields(client):
    response = await _register(client, is_admin=True)
    assert response.status_code == 422


async def test_register_duplicate_username_conflicts(client):
    await _register(client)
    response = await _register(client, email="other@example.com")
    assert response.status_code == 409


async def test_password_stored_as_argon2id(client, session_factory):
    await _register(client)
    async with session_factory() as session:
        user = await session.scalar(select(User).where(User.username == "owner1"))
    assert user.password_hash.startswith("$argon2id$")


async def test_login_returns_tokens(client):
    await _register(client)
    response = await client.post(
        "/v1/auth/login", json={"username": "owner1", "password": "s3cret-pass"}
    )
    assert response.json()["tokens"]["refresh_token"]


async def test_login_wrong_password_rejected(client):
    await _register(client)
    response = await client.post(
        "/v1/auth/login", json={"username": "owner1", "password": "wrong-pass"}
    )
    assert response.status_code == 401


async def test_login_unknown_user_gives_generic_error(client):
    response = await client.post(
        "/v1/auth/login", json={"username": "ghost", "password": "whatever123"}
    )
    assert response.json()["error"]["message"] == "Invalid username or password"


async def test_login_locks_out_after_five_failures(client):
    await _register(client)
    for _ in range(5):
        await client.post("/v1/auth/login", json={"username": "owner1", "password": "bad"})
    response = await client.post("/v1/auth/login", json={"username": "owner1", "password": "bad"})
    assert response.status_code == 429


async def test_refresh_rotates_refresh_token(client):
    tokens = (await _register(client)).json()["tokens"]
    response = await client.post(
        "/v1/auth/refresh", json={"refresh_token": tokens["refresh_token"]}
    )
    assert response.json()["refresh_token"] != tokens["refresh_token"]


async def test_reused_refresh_token_is_rejected(client):
    tokens = (await _register(client)).json()["tokens"]
    await client.post("/v1/auth/refresh", json={"refresh_token": tokens["refresh_token"]})
    response = await client.post(
        "/v1/auth/refresh", json={"refresh_token": tokens["refresh_token"]}
    )
    assert response.status_code == 401


async def test_reuse_revokes_whole_family(client):
    first = (await _register(client)).json()["tokens"]
    second = (
        await client.post("/v1/auth/refresh", json={"refresh_token": first["refresh_token"]})
    ).json()
    # Replay the old token → family revoked; the legitimately rotated token must also die.
    await client.post("/v1/auth/refresh", json={"refresh_token": first["refresh_token"]})
    response = await client.post(
        "/v1/auth/refresh", json={"refresh_token": second["refresh_token"]}
    )
    assert response.status_code == 401


async def test_logout_then_refresh_rejected(client):
    tokens = (await _register(client)).json()["tokens"]
    await client.post("/v1/auth/logout", json={"refresh_token": tokens["refresh_token"]})
    response = await client.post(
        "/v1/auth/refresh", json={"refresh_token": tokens["refresh_token"]}
    )
    assert response.status_code == 401


async def test_me_requires_authentication(client):
    response = await client.get("/v1/auth/me")
    assert response.status_code == 401


async def test_me_returns_current_user(client):
    tokens = (await _register(client)).json()["tokens"]
    response = await client.get(
        "/v1/auth/me", headers={"Authorization": f"Bearer {tokens['access_token']}"}
    )
    assert response.json()["username"] == "owner1"


async def test_patch_me_sets_onboarding_complete(client):
    tokens = (await _register(client)).json()["tokens"]
    response = await client.patch(
        "/v1/auth/me",
        json={"onboarding_complete": True},
        headers={"Authorization": f"Bearer {tokens['access_token']}"},
    )
    assert response.json()["onboarding_complete"] is True
