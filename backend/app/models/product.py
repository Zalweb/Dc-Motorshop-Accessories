import uuid
from datetime import datetime
from decimal import Decimal

import sqlalchemy as sa
from sqlmodel import Field, SQLModel

from app.core.clock import utcnow
from app.core.ids import uuid7
from app.models.base import (
    created_column,
    deleted_column,
    fk_column,
    id_column,
    money_column,
    updated_column,
)


class Product(SQLModel, table=True):
    __tablename__ = "products"

    id: uuid.UUID = Field(default_factory=uuid7, sa_column=id_column())
    business_id: uuid.UUID = Field(
        sa_column=fk_column("businesses.id", ondelete="CASCADE", nullable=False, index=True)
    )
    category_id: uuid.UUID | None = Field(
        default=None, sa_column=fk_column("categories.id", ondelete="SET NULL")
    )
    brand_id: uuid.UUID | None = Field(
        default=None, sa_column=fk_column("brands.id", ondelete="SET NULL")
    )
    name: str
    sku: str | None = None
    barcode: str | None = None
    part_number: str | None = None
    description: str | None = None
    unit: str = Field(default="piece")
    is_service: bool = Field(default=False)
    cost_price: Decimal = Field(default=Decimal("0"), sa_column=money_column())
    selling_price: Decimal = Field(default=Decimal("0"), sa_column=money_column())
    reorder_point: int = Field(default=0)
    # Cached on-hand; the inventory_movements ledger is authoritative (kept in sync by trigger).
    stock_on_hand: int = Field(default=0)
    image_url: str | None = None
    created_at: datetime = Field(default_factory=utcnow, sa_column=created_column())
    updated_at: datetime = Field(default_factory=utcnow, sa_column=updated_column())
    deleted_at: datetime | None = Field(default=None, sa_column=deleted_column())

    __table_args__ = (
        sa.CheckConstraint(
            "unit IN ('piece','liter','set','pair','box')", name="ck_products_unit"
        ),
        sa.CheckConstraint("cost_price >= 0", name="ck_products_cost_price"),
        sa.CheckConstraint("selling_price >= 0", name="ck_products_selling_price"),
    )
