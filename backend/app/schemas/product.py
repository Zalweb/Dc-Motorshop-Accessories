import uuid
from datetime import datetime
from decimal import Decimal
from typing import Literal

from pydantic import Field

from app.schemas.base import ORMModel, StrictModel

Unit = Literal["piece", "liter", "set", "pair", "box"]


class ProductIn(StrictModel):
    # Client may supply the UUID so create is an idempotent upsert (safe retries/sync).
    id: uuid.UUID | None = None
    name: str = Field(min_length=1, max_length=200)
    sku: str | None = Field(default=None, max_length=100)
    barcode: str | None = Field(default=None, max_length=100)
    part_number: str | None = Field(default=None, max_length=100)
    description: str | None = Field(default=None, max_length=2000)
    unit: Unit = "piece"
    is_service: bool = False
    category_id: uuid.UUID | None = None
    brand_id: uuid.UUID | None = None
    cost_price: Decimal = Field(default=Decimal("0"), ge=0, max_digits=12, decimal_places=2)
    selling_price: Decimal = Field(default=Decimal("0"), ge=0, max_digits=12, decimal_places=2)
    reorder_point: int = Field(default=0, ge=0)
    # Desired on-hand quantity; the service reconciles it to the ledger via a movement.
    stock_qty: int = Field(default=0, ge=0)


class BulkProductsIn(StrictModel):
    products: list[ProductIn] = Field(min_length=1, max_length=200)


class ProductOut(ORMModel):
    id: uuid.UUID
    business_id: uuid.UUID
    category_id: uuid.UUID | None
    brand_id: uuid.UUID | None
    name: str
    sku: str | None
    barcode: str | None
    part_number: str | None
    description: str | None
    unit: str
    is_service: bool
    cost_price: Decimal
    selling_price: Decimal
    reorder_point: int
    stock_on_hand: int
    image_url: str | None
    created_at: datetime
    updated_at: datetime


class ImageUploadOut(StrictModel):
    key: str
    url: str
