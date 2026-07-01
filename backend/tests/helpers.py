"""Shared helpers for API tests."""


async def register(client, *, username="owner1", email=None, business_name="DC Motorshop"):
    email = email or f"{username}@example.com"
    response = await client.post(
        "/v1/auth/register",
        json={
            "business_name": business_name,
            "username": username,
            "email": email,
            "password": "s3cret-pass",
        },
    )
    return response.json()


def auth_headers(auth_json: dict) -> dict[str, str]:
    return {"Authorization": f"Bearer {auth_json['tokens']['access_token']}"}
