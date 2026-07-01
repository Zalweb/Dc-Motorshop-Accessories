import uuid
from datetime import datetime
from decimal import Decimal
from typing import Literal

from pydantic import Field

from app.schemas.base import ORMModel, StrictModel

PaymentMethod = Literal["cash", "gcash", "card", "bank", "other"]


class SaleItemIn(StrictModel):
    product_id: uuid.UUID | None = None
    # Required for custom (no product_id) lines; ignored when product_id is given
    # (server snapshots the product's current price — client price is not trusted).
    name: str | None = Field(default=None, max_length=200)
    unit_price: Decimal | None = Field(default=None, ge=0, max_digits=12, decimal_places=2)
    quantity: int = Field(gt=0, le=100000)
    discount: Decimal = Field(default=Decimal("0"), ge=0, max_digits=12, decimal_places=2)


class PaymentIn(StrictModel):
    method: PaymentMethod
    amount: Decimal = Field(gt=0, max_digits=12, decimal_places=2)


class SaleIn(StrictModel):
    # Client UUID → idempotent checkout (a retried POST never double-charges stock).
    id: uuid.UUID | None = None
    customer_id: uuid.UUID | None = None
    customer_name: str | None = Field(default=None, max_length=200)
    stage_id: uuid.UUID | None = None
    discount_total: Decimal = Field(default=Decimal("0"), ge=0, max_digits=12, decimal_places=2)
    tax_total: Decimal = Field(default=Decimal("0"), ge=0, max_digits=12, decimal_places=2)
    items: list[SaleItemIn] = Field(min_length=1, max_length=500)
    payments: list[PaymentIn] = Field(default_factory=list, max_length=20)


class SaleItemOut(ORMModel):
    id: uuid.UUID
    product_id: uuid.UUID | None
    name_snapshot: str
    quantity: int
    unit_price: Decimal
    unit_cost: Decimal
    discount: Decimal
    line_total: Decimal


class PaymentOut(ORMModel):
    id: uuid.UUID
    method: str
    amount: Decimal
    created_at: datetime


class SaleOut(ORMModel):
    id: uuid.UUID
    business_id: uuid.UUID
    sale_number: str
    customer_id: uuid.UUID | None
    customer_name: str | None
    stage_id: uuid.UUID | None
    sold_by: uuid.UUID | None
    subtotal: Decimal
    discount_total: Decimal
    tax_total: Decimal
    total: Decimal
    created_at: datetime


class SaleDetailOut(SaleOut):
    items: list[SaleItemOut]
    payments: list[PaymentOut]
