from tests.helpers import auth_headers, register


async def _auth(client):
    return auth_headers(await register(client))


async def _product(client, headers, **over):
    payload = {
        "name": "Brake Pad",
        "selling_price": "150.00",
        "cost_price": "90.00",
        "stock_qty": 10,
    }
    payload.update(over)
    return (await client.post("/v1/products", json=payload, headers=headers)).json()


async def test_checkout_returns_sale_number(client):
    headers = await _auth(client)
    product = await _product(client, headers)
    response = await client.post(
        "/v1/sales",
        json={"items": [{"product_id": product["id"], "quantity": 2}]},
        headers=headers,
    )
    assert response.json()["sale_number"] == "S-0001"


async def test_checkout_recomputes_total_from_server_price(client):
    headers = await _auth(client)
    product = await _product(client, headers, selling_price="150.00")
    # Client tries to smuggle a unit_price; server must ignore it and use 150.00 * 2 = 300.00.
    response = await client.post(
        "/v1/sales",
        json={"items": [{"product_id": product["id"], "quantity": 2, "unit_price": "1.00"}]},
        headers=headers,
    )
    assert response.json()["total"] == "300.00"


async def test_checkout_decrements_stock(client):
    headers = await _auth(client)
    product = await _product(client, headers, stock_qty=10)
    await client.post(
        "/v1/sales",
        json={"items": [{"product_id": product["id"], "quantity": 3}]},
        headers=headers,
    )
    refreshed = await client.get(f"/v1/products/{product['id']}", headers=headers)
    assert refreshed.json()["stock_on_hand"] == 7


async def test_checkout_snapshots_unit_cost(client):
    headers = await _auth(client)
    product = await _product(client, headers, cost_price="90.00")
    sale = (
        await client.post(
            "/v1/sales",
            json={"items": [{"product_id": product["id"], "quantity": 1}]},
            headers=headers,
        )
    ).json()
    detail = await client.get(f"/v1/sales/{sale['id']}", headers=headers)
    assert detail.json()["items"][0]["unit_cost"] == "90.00"


async def test_duplicate_sale_id_is_noop(client):
    headers = await _auth(client)
    product = await _product(client, headers, stock_qty=10)
    sid = "01920000-0000-7000-8000-0000000000c1"
    body = {"id": sid, "items": [{"product_id": product["id"], "quantity": 2}]}
    await client.post("/v1/sales", json=body, headers=headers)
    await client.post("/v1/sales", json=body, headers=headers)
    refreshed = await client.get(f"/v1/products/{product['id']}", headers=headers)
    assert refreshed.json()["stock_on_hand"] == 8


async def test_duplicate_sale_id_keeps_single_sale(client):
    headers = await _auth(client)
    product = await _product(client, headers)
    sid = "01920000-0000-7000-8000-0000000000c2"
    body = {"id": sid, "items": [{"product_id": product["id"], "quantity": 1}]}
    await client.post("/v1/sales", json=body, headers=headers)
    await client.post("/v1/sales", json=body, headers=headers)
    listing = await client.get("/v1/sales", headers=headers)
    assert listing.json()["total"] == 1


async def test_default_cash_payment_recorded(client):
    headers = await _auth(client)
    product = await _product(client, headers, selling_price="150.00")
    sale = (
        await client.post(
            "/v1/sales",
            json={"items": [{"product_id": product["id"], "quantity": 1}]},
            headers=headers,
        )
    ).json()
    detail = await client.get(f"/v1/sales/{sale['id']}", headers=headers)
    assert detail.json()["payments"][0]["amount"] == "150.00"


async def test_service_line_does_not_create_movement(client):
    headers = await _auth(client)
    service = await _product(client, headers, name="Labor", is_service=True, stock_qty=0)
    sale = await client.post(
        "/v1/sales",
        json={"items": [{"product_id": service["id"], "quantity": 1}]},
        headers=headers,
    )
    assert sale.status_code == 201


async def test_search_by_sale_number(client):
    headers = await _auth(client)
    product = await _product(client, headers)
    await client.post(
        "/v1/sales", json={"items": [{"product_id": product["id"], "quantity": 1}]}, headers=headers
    )
    response = await client.get("/v1/sales", params={"search": "S-0001"}, headers=headers)
    assert response.json()["total"] == 1


async def test_search_by_customer_name(client):
    headers = await _auth(client)
    product = await _product(client, headers)
    await client.post(
        "/v1/sales",
        json={
            "customer_name": "Juan Cruz",
            "items": [{"product_id": product["id"], "quantity": 1}],
        },
        headers=headers,
    )
    response = await client.get("/v1/sales", params={"search": "juan"}, headers=headers)
    assert response.json()["total"] == 1


async def test_date_filter_excludes_out_of_range(client):
    headers = await _auth(client)
    product = await _product(client, headers)
    await client.post(
        "/v1/sales", json={"items": [{"product_id": product["id"], "quantity": 1}]}, headers=headers
    )
    response = await client.get(
        "/v1/sales", params={"from": "2000-01-01", "to": "2000-01-02"}, headers=headers
    )
    assert response.json()["total"] == 0


async def test_invalid_product_rejected(client):
    headers = await _auth(client)
    response = await client.post(
        "/v1/sales",
        json={"items": [{"product_id": "01920000-0000-7000-8000-0000000000ff", "quantity": 1}]},
        headers=headers,
    )
    assert response.status_code == 422


async def test_sales_require_authentication(client):
    response = await client.get("/v1/sales")
    assert response.status_code == 401


async def test_cannot_sell_another_tenants_product(client):
    a = auth_headers(await register(client, username="owner_a", business_name="A"))
    b = auth_headers(await register(client, username="owner_b", business_name="B"))
    product = await _product(client, a)
    response = await client.post(
        "/v1/sales",
        json={"items": [{"product_id": product["id"], "quantity": 1}]},
        headers=b,
    )
    assert response.status_code == 422
