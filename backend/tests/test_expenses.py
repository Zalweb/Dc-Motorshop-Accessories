from tests.helpers import auth_headers, register


async def _auth(client):
    return auth_headers(await register(client))


async def test_create_expense_returns_it(client):
    headers = await _auth(client)
    response = await client.post(
        "/v1/expenses", json={"label": "Rent", "amount": "5000.00"}, headers=headers
    )
    assert response.json()["label"] == "Rent"


async def test_expense_rejects_zero_amount(client):
    headers = await _auth(client)
    response = await client.post(
        "/v1/expenses", json={"label": "Rent", "amount": "0"}, headers=headers
    )
    assert response.status_code == 422


async def test_expense_is_idempotent_by_id(client):
    headers = await _auth(client)
    eid = "01920000-0000-7000-8000-0000000000e1"
    base = {"id": eid, "label": "Rent"}
    await client.post("/v1/expenses", json={**base, "amount": "100"}, headers=headers)
    await client.post("/v1/expenses", json={**base, "amount": "200"}, headers=headers)
    listing = await client.get("/v1/expenses", headers=headers)
    assert listing.json()["total"] == 1


async def test_expense_list_filters_by_date(client):
    headers = await _auth(client)
    await client.post(
        "/v1/expenses",
        json={"label": "Rent", "amount": "100", "spent_on": "2026-06-01"},
        headers=headers,
    )
    response = await client.get(
        "/v1/expenses", params={"from": "2026-06-01", "to": "2026-06-30"}, headers=headers
    )
    assert response.json()["total"] == 1


async def test_expense_date_filter_excludes_out_of_range(client):
    headers = await _auth(client)
    await client.post(
        "/v1/expenses",
        json={"label": "Rent", "amount": "100", "spent_on": "2026-06-01"},
        headers=headers,
    )
    response = await client.get(
        "/v1/expenses", params={"from": "2026-07-01", "to": "2026-07-31"}, headers=headers
    )
    assert response.json()["total"] == 0


async def test_expense_invalid_category_rejected(client):
    headers = await _auth(client)
    response = await client.post(
        "/v1/expenses",
        json={
            "label": "Rent",
            "amount": "100",
            "category_id": "01920000-0000-7000-8000-0000000000ee",
        },
        headers=headers,
    )
    assert response.status_code == 422


async def test_expenses_require_authentication(client):
    response = await client.get("/v1/expenses")
    assert response.status_code == 401
