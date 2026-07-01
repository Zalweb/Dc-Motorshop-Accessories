import uuid
from datetime import date, datetime
from decimal import Decimal

from pydantic import Field

from app.schemas.base import ORMModel, StrictModel


class ExpenseIn(StrictModel):
    # Client UUID → idempotent upsert.
    id: uuid.UUID | None = None
    label: str = Field(min_length=1, max_length=200)
    amount: Decimal = Field(gt=0, max_digits=12, decimal_places=2)
    spent_on: date | None = None
    category_id: uuid.UUID | None = None
    note: str | None = Field(default=None, max_length=1000)


class ExpenseOut(ORMModel):
    id: uuid.UUID
    business_id: uuid.UUID
    category_id: uuid.UUID | None
    label: str
    amount: Decimal
    spent_on: date
    note: str | None
    created_at: datetime
    updated_at: datetime


class DashboardSummary(StrictModel):
    from_date: date
    to_date: date
    tz: str
    revenue: Decimal
    cogs: Decimal
    gross_profit: Decimal
    expenses: Decimal
    net_profit: Decimal
    discount_total: Decimal
    sale_count: int
    avg_ticket: Decimal
    gross_margin: Decimal
