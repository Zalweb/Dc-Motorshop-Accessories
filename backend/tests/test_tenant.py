from tests.helpers import auth_headers, register


async def _two_tenants(client):
    a = auth_headers(await register(client, username="owner_a", business_name="Shop A"))
    b = auth_headers(await register(client, username="owner_b", business_name="Shop B"))
    return a, b


async def test_get_business_returns_own_shop(client):
    headers = auth_headers(await register(client, business_name="My Shop"))
    response = await client.get("/v1/business", headers=headers)
    assert response.json()["name"] == "My Shop"


async def test_update_business_persists_name(client):
    headers = auth_headers(await register(client))
    await client.put("/v1/business", json={"name": "Renamed Shop"}, headers=headers)
    response = await client.get("/v1/business", headers=headers)
    assert response.json()["name"] == "Renamed Shop"


async def test_business_update_rejects_business_id_field(client):
    headers = auth_headers(await register(client))
    response = await client.put(
        "/v1/business", json={"id": "00000000-0000-0000-0000-000000000000"}, headers=headers
    )
    assert response.status_code == 422


async def test_checklist_round_trips(client):
    headers = auth_headers(await register(client))
    await client.put(
        "/v1/business/checklist", json={"items": ["add_logo", "add_product"]}, headers=headers
    )
    response = await client.get("/v1/business/checklist", headers=headers)
    assert response.json()["items"] == ["add_logo", "add_product"]


async def test_checklist_deduplicates(client):
    headers = auth_headers(await register(client))
    response = await client.put(
        "/v1/business/checklist", json={"items": ["a", "a", "b"]}, headers=headers
    )
    assert response.json()["items"] == ["a", "b"]


async def test_create_category_returns_it(client):
    headers = auth_headers(await register(client))
    response = await client.post("/v1/categories", json={"name": "Brakes"}, headers=headers)
    assert response.json()["name"] == "Brakes"


async def test_category_rejects_business_id_field(client):
    headers = auth_headers(await register(client))
    response = await client.post(
        "/v1/categories",
        json={"name": "Brakes", "business_id": "00000000-0000-0000-0000-000000000000"},
        headers=headers,
    )
    assert response.status_code == 422


async def test_duplicate_category_name_conflicts(client):
    headers = auth_headers(await register(client))
    await client.post("/v1/categories", json={"name": "Brakes"}, headers=headers)
    response = await client.post("/v1/categories", json={"name": "Brakes"}, headers=headers)
    assert response.status_code == 409


async def test_category_upsert_is_idempotent(client):
    headers = auth_headers(await register(client))
    cid = "01920000-0000-7000-8000-000000000001"
    await client.post("/v1/categories", json={"id": cid, "name": "Brakes"}, headers=headers)
    await client.post("/v1/categories", json={"id": cid, "name": "Brake Pads"}, headers=headers)
    response = await client.get("/v1/categories", headers=headers)
    assert len(response.json()) == 1


async def test_tenant_cannot_see_other_shop_categories(client):
    a_headers, b_headers = await _two_tenants(client)
    await client.post("/v1/categories", json={"name": "Brakes"}, headers=a_headers)
    response = await client.get("/v1/categories", headers=b_headers)
    assert response.json() == []


async def test_tenant_cannot_delete_other_shop_category(client):
    a_headers, b_headers = await _two_tenants(client)
    created = await client.post("/v1/categories", json={"name": "Brakes"}, headers=a_headers)
    response = await client.delete(f"/v1/categories/{created.json()['id']}", headers=b_headers)
    assert response.status_code == 404


async def test_categories_require_authentication(client):
    response = await client.get("/v1/categories")
    assert response.status_code == 401
