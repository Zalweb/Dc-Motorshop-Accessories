from tests.helpers import auth_headers, register


async def _auth(client, **over):
    return auth_headers(await register(client, **over))


async def _seed(client, headers):
    """Create a category, a product, an expense, and a sale for the tenant."""
    category = (
        await client.post("/v1/categories", json={"name": "Brakes"}, headers=headers)
    ).json()
    product = (
        await client.post(
            "/v1/products",
            json={
                "name": "Brake Pad",
                "selling_price": "150.00",
                "cost_price": "90.00",
                "stock_qty": 10,
                "category_id": category["id"],
            },
            headers=headers,
        )
    ).json()
    await client.post(
        "/v1/expenses", json={"label": "Rent", "amount": "100.00"}, headers=headers
    )
    await client.post(
        "/v1/sales",
        json={"items": [{"product_id": product["id"], "quantity": 2}]},
        headers=headers,
    )
    return category, product


async def test_export_includes_products(client):
    headers = await _auth(client)
    await _seed(client, headers)
    snapshot = (await client.get("/v1/backup/export", headers=headers)).json()
    assert len(snapshot["tables"]["products"]) == 1


async def test_export_includes_sale_items(client):
    headers = await _auth(client)
    await _seed(client, headers)
    snapshot = (await client.get("/v1/backup/export", headers=headers)).json()
    assert len(snapshot["tables"]["sale_items"]) == 1


async def test_import_restores_deleted_category(client):
    headers = await _auth(client)
    category, _ = await _seed(client, headers)
    snapshot = (await client.get("/v1/backup/export", headers=headers)).json()
    await client.delete(f"/v1/categories/{category['id']}", headers=headers)
    await client.post("/v1/backup/import", json=snapshot, headers=headers)
    listing = await client.get("/v1/categories", headers=headers)
    assert any(c["id"] == category["id"] for c in listing.json())


async def test_import_is_idempotent(client):
    headers = await _auth(client)
    await _seed(client, headers)
    snapshot = (await client.get("/v1/backup/export", headers=headers)).json()
    await client.post("/v1/backup/import", json=snapshot, headers=headers)
    await client.post("/v1/backup/import", json=snapshot, headers=headers)
    listing = await client.get("/v1/products", headers=headers)
    assert listing.json()["total"] == 1


async def test_reimport_preserves_sale_count(client):
    headers = await _auth(client)
    await _seed(client, headers)
    snapshot = (await client.get("/v1/backup/export", headers=headers)).json()
    await client.post("/v1/backup/import", json=snapshot, headers=headers)
    listing = await client.get("/v1/sales", headers=headers)
    assert listing.json()["total"] == 1


async def test_export_excludes_other_tenant(client):
    a = await _auth(client, username="owner_a", business_name="A")
    b = await _auth(client, username="owner_b", business_name="B")
    await client.post("/v1/categories", json={"name": "OnlyA"}, headers=a)
    snapshot = (await client.get("/v1/backup/export", headers=b)).json()
    assert snapshot["tables"]["categories"] == []


async def test_cannot_import_into_another_tenant(client):
    a = await _auth(client, username="owner_a", business_name="A")
    b = await _auth(client, username="owner_b", business_name="B")
    await _seed(client, a)
    snapshot = (await client.get("/v1/backup/export", headers=a)).json()
    # B imports A's snapshot: A's rows belong to A and must be skipped (not copied to B).
    await client.post("/v1/backup/import", json=snapshot, headers=b)
    b_products = await client.get("/v1/products", headers=b)
    assert b_products.json()["total"] == 0


async def test_import_into_other_tenant_leaves_origin_intact(client):
    a = await _auth(client, username="owner_a", business_name="A")
    b = await _auth(client, username="owner_b", business_name="B")
    await _seed(client, a)
    snapshot = (await client.get("/v1/backup/export", headers=a)).json()
    await client.post("/v1/backup/import", json=snapshot, headers=b)
    a_products = await client.get("/v1/products", headers=a)
    assert a_products.json()["total"] == 1


async def test_export_requires_authentication(client):
    response = await client.get("/v1/backup/export")
    assert response.status_code == 401
