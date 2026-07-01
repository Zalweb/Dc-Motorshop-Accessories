from datetime import UTC, datetime
from decimal import Decimal
from uuid import UUID
from zoneinfo import ZoneInfo

from app.models.sale import Sale

from tests.helpers import auth_headers, register

MANILA = ZoneInfo("Asia/Manila")


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


def _today() -> str:
    return str(datetime.now(MANILA).date())


async def _sell_two(client, headers):
    product = await _product(client, headers)
    await client.post(
        "/v1/sales",
        json={"items": [{"product_id": product["id"], "quantity": 2}]},
        headers=headers,
    )


async def test_revenue_sums_sale_totals(client):
    headers = await _auth(client)
    await _sell_two(client, headers)
    response = await client.get(
        "/v1/dashboard/summary", params={"from": _today(), "to": _today()}, headers=headers
    )
    assert response.json()["revenue"] == "300.00"


async def test_cogs_uses_unit_cost(client):
    headers = await _auth(client)
    await _sell_two(client, headers)
    response = await client.get(
        "/v1/dashboard/summary", params={"from": _today(), "to": _today()}, headers=headers
    )
    assert response.json()["cogs"] == "180.00"


async def test_gross_profit_is_revenue_minus_cogs(client):
    headers = await _auth(client)
    await _sell_two(client, headers)
    response = await client.get(
        "/v1/dashboard/summary", params={"from": _today(), "to": _today()}, headers=headers
    )
    assert response.json()["gross_profit"] == "120.00"


async def test_net_profit_subtracts_expenses(client):
    headers = await _auth(client)
    await _sell_two(client, headers)
    await client.post(
        "/v1/expenses",
        json={"label": "Rent", "amount": "50.00", "spent_on": _today()},
        headers=headers,
    )
    response = await client.get(
        "/v1/dashboard/summary", params={"from": _today(), "to": _today()}, headers=headers
    )
    assert response.json()["net_profit"] == "70.00"


async def test_avg_ticket_divides_by_sale_count(client):
    headers = await _auth(client)
    await _sell_two(client, headers)
    response = await client.get(
        "/v1/dashboard/summary", params={"from": _today(), "to": _today()}, headers=headers
    )
    assert response.json()["avg_ticket"] == "300.00"


async def test_gross_margin_ratio(client):
    headers = await _auth(client)
    await _sell_two(client, headers)
    response = await client.get(
        "/v1/dashboard/summary", params={"from": _today(), "to": _today()}, headers=headers
    )
    assert response.json()["gross_margin"] == "0.4000"


async def test_empty_window_returns_zeroes(client):
    headers = await _auth(client)
    response = await client.get(
        "/v1/dashboard/summary",
        params={"from": "2000-01-01", "to": "2000-01-01"},
        headers=headers,
    )
    body = response.json()
    assert body["revenue"] == "0.00" and body["avg_ticket"] == "0.00"


async def test_invalid_timezone_rejected(client):
    headers = await _auth(client)
    response = await client.get(
        "/v1/dashboard/summary",
        params={"from": _today(), "to": _today(), "tz": "Mars/Phobos"},
        headers=headers,
    )
    assert response.status_code == 422


async def _insert_sale_at(session_factory, business_id, when, number):
    async with session_factory() as session:
        session.add(
            Sale(
                business_id=UUID(business_id),
                sale_number=number,
                subtotal=Decimal("100.00"),
                total=Decimal("100.00"),
                created_at=when,
            )
        )
        await session.commit()


async def test_manila_boundary_includes_local_date(client, session_factory):
    headers = await _auth(client)
    business_id = (await client.get("/v1/business", headers=headers)).json()["id"]
    # 2026-03-15 17:00 UTC == 2026-03-16 01:00 Manila
    await _insert_sale_at(
        session_factory, business_id, datetime(2026, 3, 15, 17, 0, tzinfo=UTC), "S-9001"
    )
    response = await client.get(
        "/v1/dashboard/summary", params={"from": "2026-03-16", "to": "2026-03-16"}, headers=headers
    )
    assert response.json()["revenue"] == "100.00"


async def test_manila_boundary_excludes_utc_date(client, session_factory):
    headers = await _auth(client)
    business_id = (await client.get("/v1/business", headers=headers)).json()["id"]
    await _insert_sale_at(
        session_factory, business_id, datetime(2026, 3, 15, 17, 0, tzinfo=UTC), "S-9002"
    )
    # The sale is on the 16th in Manila, so querying the 15th must exclude it.
    response = await client.get(
        "/v1/dashboard/summary", params={"from": "2026-03-15", "to": "2026-03-15"}, headers=headers
    )
    assert response.json()["revenue"] == "0.00"
