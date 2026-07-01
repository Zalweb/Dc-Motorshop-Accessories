from app.models.inventory_movement import InventoryMovement
from sqlalchemy import func, select

from tests.helpers import auth_headers, register

PNG = b"\x89PNG\r\n\x1a\n" + b"payloadbytes"


async def _auth(client):
    return auth_headers(await register(client))


async def _create(client, headers, **over):
    payload = {"name": "Brake Pad", "selling_price": "150.00", "stock_qty": 5}
    payload.update(over)
    return await client.post("/v1/products", json=payload, headers=headers)


async def test_create_product_returns_it(client):
    headers = await _auth(client)
    response = await _create(client, headers)
    assert response.json()["name"] == "Brake Pad"


async def test_create_product_caches_initial_stock(client):
    headers = await _auth(client)
    response = await _create(client, headers, stock_qty=7)
    assert response.json()["stock_on_hand"] == 7


async def test_create_emits_initial_movement(client, session_factory):
    headers = await _auth(client)
    product_id = (await _create(client, headers, stock_qty=7)).json()["id"]
    async with session_factory() as session:
        reason = await session.scalar(
            select(InventoryMovement.reason).where(InventoryMovement.product_id == product_id)
        )
    assert reason == "initial"


async def test_stock_on_hand_matches_ledger(client, session_factory):
    headers = await _auth(client)
    pid = (await _create(client, headers, stock_qty=5)).json()["id"]
    await client.put(
        f"/v1/products/{pid}",
        json={"name": "Brake Pad", "selling_price": "150.00", "stock_qty": 8},
        headers=headers,
    )
    async with session_factory() as session:
        ledger_sum = await session.scalar(
            select(func.coalesce(func.sum(InventoryMovement.change_qty), 0)).where(
                InventoryMovement.product_id == pid
            )
        )
    assert ledger_sum == 8


async def test_update_adjusts_stock(client):
    headers = await _auth(client)
    pid = (await _create(client, headers, stock_qty=5)).json()["id"]
    response = await client.put(
        f"/v1/products/{pid}",
        json={"name": "Brake Pad", "selling_price": "150.00", "stock_qty": 8},
        headers=headers,
    )
    assert response.json()["stock_on_hand"] == 8


async def test_create_is_idempotent_by_id(client):
    headers = await _auth(client)
    pid = "01920000-0000-7000-8000-0000000000aa"
    await _create(client, headers, id=pid)
    await _create(client, headers, id=pid)
    listing = await client.get("/v1/products", headers=headers)
    assert listing.json()["total"] == 1


async def test_barcode_lookup_returns_product(client):
    headers = await _auth(client)
    await _create(client, headers, barcode="4800001")
    response = await client.get("/v1/products/by-barcode/4800001", headers=headers)
    assert response.json()["barcode"] == "4800001"


async def test_barcode_lookup_missing_is_404(client):
    headers = await _auth(client)
    response = await client.get("/v1/products/by-barcode/nope", headers=headers)
    assert response.status_code == 404


async def test_duplicate_barcode_conflicts(client):
    headers = await _auth(client)
    await _create(client, headers, barcode="4800001")
    response = await _create(client, headers, barcode="4800001")
    assert response.status_code == 409


async def test_soft_deleted_product_is_hidden(client):
    headers = await _auth(client)
    pid = (await _create(client, headers)).json()["id"]
    await client.delete(f"/v1/products/{pid}", headers=headers)
    response = await client.get(f"/v1/products/{pid}", headers=headers)
    assert response.status_code == 404


async def test_search_filters_by_name(client):
    headers = await _auth(client)
    await _create(client, headers, name="Brake Pad")
    await _create(client, headers, name="Oil Filter")
    response = await client.get("/v1/products", params={"search": "brake"}, headers=headers)
    assert response.json()["total"] == 1


async def test_type_filter_returns_only_services(client):
    headers = await _auth(client)
    await _create(client, headers, name="Brake Pad", is_service=False)
    await _create(client, headers, name="Tune Up", is_service=True, stock_qty=0)
    response = await client.get("/v1/products", params={"type": "services"}, headers=headers)
    assert response.json()["items"][0]["name"] == "Tune Up"


async def test_pagination_limits_page_size(client):
    headers = await _auth(client)
    for i in range(3):
        await _create(client, headers, name=f"Part {i}")
    response = await client.get("/v1/products", params={"limit": 2, "page": 1}, headers=headers)
    body = response.json()
    assert len(body["items"]) == 2 and body["total"] == 3


async def test_bulk_creates_all(client):
    headers = await _auth(client)
    response = await client.post(
        "/v1/products/bulk",
        json={"products": [{"name": "A", "stock_qty": 1}, {"name": "B", "stock_qty": 2}]},
        headers=headers,
    )
    assert len(response.json()) == 2


async def test_bulk_is_idempotent(client):
    headers = await _auth(client)
    items = [
        {"id": "01920000-0000-7000-8000-0000000000b1", "name": "A"},
        {"id": "01920000-0000-7000-8000-0000000000b2", "name": "B"},
    ]
    await client.post("/v1/products/bulk", json={"products": items}, headers=headers)
    await client.post("/v1/products/bulk", json={"products": items}, headers=headers)
    listing = await client.get("/v1/products", headers=headers)
    assert listing.json()["total"] == 2


async def test_image_upload_rejects_non_image(client):
    headers = await _auth(client)
    pid = (await _create(client, headers)).json()["id"]
    response = await client.post(
        f"/v1/products/{pid}/image",
        files={"file": ("note.txt", b"hello", "text/plain")},
        headers=headers,
    )
    assert response.status_code == 415


async def test_image_upload_rejects_spoofed_type(client):
    headers = await _auth(client)
    pid = (await _create(client, headers)).json()["id"]
    response = await client.post(
        f"/v1/products/{pid}/image",
        files={"file": ("x.png", b"not-a-png", "image/png")},
        headers=headers,
    )
    assert response.status_code == 415


async def test_image_upload_rejects_oversize(client):
    headers = await _auth(client)
    pid = (await _create(client, headers)).json()["id"]
    oversize = b"\x89PNG\r\n\x1a\n" + b"0" * (5 * 1024 * 1024 + 1)
    response = await client.post(
        f"/v1/products/{pid}/image",
        files={"file": ("big.png", oversize, "image/png")},
        headers=headers,
    )
    assert response.status_code == 413


async def test_image_upload_stores_random_key(client):
    headers = await _auth(client)
    pid = (await _create(client, headers)).json()["id"]
    response = await client.post(
        f"/v1/products/{pid}/image",
        files={"file": ("x.png", PNG, "image/png")},
        headers=headers,
    )
    assert response.json()["key"].startswith("products/")


async def test_products_require_authentication(client):
    response = await client.get("/v1/products")
    assert response.status_code == 401
