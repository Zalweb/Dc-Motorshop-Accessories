from tests.helpers import auth_headers, register


async def _auth(client, **over):
    return auth_headers(await register(client, **over))


async def _category(client, headers, name="Brakes"):
    return (await client.post("/v1/categories", json={"name": name}, headers=headers)).json()


async def _product(client, headers, **over):
    payload = {"name": "Brake Pad", "selling_price": "150.00", "stock_qty": 5}
    payload.update(over)
    return (await client.post("/v1/products", json=payload, headers=headers)).json()


async def test_pull_returns_created_rows(client):
    headers = await _auth(client)
    await _category(client, headers)
    response = await client.get("/v1/sync/categories", headers=headers)
    assert len(response.json()["changes"]) == 1


async def test_pull_since_server_time_returns_no_changes(client):
    headers = await _auth(client)
    await _category(client, headers)
    server_time = (await client.get("/v1/sync/categories", headers=headers)).json()["server_time"]
    response = await client.get(
        "/v1/sync/categories", params={"since": server_time}, headers=headers
    )
    assert response.json()["changes"] == []


async def test_pull_unknown_table_is_404(client):
    headers = await _auth(client)
    response = await client.get("/v1/sync/nope", headers=headers)
    assert response.status_code == 404


async def test_push_creates_row(client):
    headers = await _auth(client)
    row = {
        "id": "01920000-0000-7000-8000-0000000000d1",
        "name": "Oil",
        "is_service": False,
    }
    response = await client.post("/v1/sync/categories", json={"rows": [row]}, headers=headers)
    assert response.json()["applied"] == 1


async def test_push_lww_skips_equal_or_older_timestamp(client):
    headers = await _auth(client)
    await _category(client, headers, name="Brakes")
    row = (await client.get("/v1/sync/categories", headers=headers)).json()["changes"][0]
    row["name"] = "Changed"  # same updated_at → server copy wins
    await client.post("/v1/sync/categories", json={"rows": [row]}, headers=headers)
    listing = await client.get("/v1/categories", headers=headers)
    assert listing.json()[0]["name"] == "Brakes"


async def test_push_lww_applies_newer_timestamp(client):
    headers = await _auth(client)
    await _category(client, headers, name="Brakes")
    row = (await client.get("/v1/sync/categories", headers=headers)).json()["changes"][0]
    row["name"] = "Renamed"
    row["updated_at"] = "2099-01-01T00:00:00+00:00"
    await client.post("/v1/sync/categories", json={"rows": [row]}, headers=headers)
    listing = await client.get("/v1/categories", headers=headers)
    assert listing.json()[0]["name"] == "Renamed"


async def test_push_to_non_pushable_table_rejected(client):
    headers = await _auth(client)
    response = await client.post("/v1/sync/sales", json={"rows": []}, headers=headers)
    assert response.status_code == 422


async def test_deleted_category_appears_as_tombstone(client):
    headers = await _auth(client)
    category = await _category(client, headers)
    await client.delete(f"/v1/categories/{category['id']}", headers=headers)
    response = await client.get("/v1/sync/categories", headers=headers)
    assert category["id"] in response.json()["tombstones"]


async def test_soft_deleted_product_excluded_from_changes(client):
    headers = await _auth(client)
    product = await _product(client, headers)
    await client.delete(f"/v1/products/{product['id']}", headers=headers)
    response = await client.get("/v1/sync/products", headers=headers)
    assert response.json()["changes"] == []


async def test_soft_deleted_product_appears_as_tombstone(client):
    headers = await _auth(client)
    product = await _product(client, headers)
    await client.delete(f"/v1/products/{product['id']}", headers=headers)
    response = await client.get("/v1/sync/products", headers=headers)
    assert product["id"] in response.json()["tombstones"]


async def test_push_movement_is_append_only(client):
    headers = await _auth(client)
    await _product(client, headers, stock_qty=5)
    movement = (await client.get("/v1/sync/inventory_movements", headers=headers)).json()[
        "changes"
    ][0]
    movement["change_qty"] = 999  # try to mutate an existing append-only row
    response = await client.post(
        "/v1/sync/inventory_movements", json={"rows": [movement]}, headers=headers
    )
    assert response.json()["skipped"] == 1


async def test_push_product_ignores_client_stock(client):
    headers = await _auth(client)
    row = {
        "id": "01920000-0000-7000-8000-0000000000d9",
        "name": "Synced Part",
        "stock_on_hand": 999,
        "updated_at": "2099-01-01T00:00:00+00:00",
    }
    await client.post("/v1/sync/products", json={"rows": [row]}, headers=headers)
    fetched = await client.get(f"/v1/products/{row['id']}", headers=headers)
    assert fetched.json()["stock_on_hand"] == 0


async def test_push_cannot_overwrite_other_tenant(client):
    a = await _auth(client, username="owner_a", business_name="A")
    b = await _auth(client, username="owner_b", business_name="B")
    await _category(client, a, name="OnlyA")
    row = (await client.get("/v1/sync/categories", headers=a)).json()["changes"][0]
    row["name"] = "Hijacked"
    row["updated_at"] = "2099-01-01T00:00:00+00:00"
    response = await client.post("/v1/sync/categories", json={"rows": [row]}, headers=b)
    assert response.json()["skipped"] == 1


async def test_sync_requires_authentication(client):
    response = await client.get("/v1/sync/categories")
    assert response.status_code == 401
