import uuid
from decimal import Decimal

import sqlalchemy as sa
from sqlmodel import Field, SQLModel

from app.core.ids import uuid7
from app.models.base import fk_column, id_column, money_column


class SaleItem(SQLModel, table=True):
    """Line item with price/cost SNAPSHOTS so a receipt never changes if a product is
    later re-priced or renamed (and COGS reflects the cost at time of sale)."""

    __tablename__ = "sale_items"

    id: uuid.UUID = Field(default_factory=uuid7, sa_column=id_column())
    sale_id: uuid.UUID = Field(
        sa_column=fk_column("sales.id", ondelete="CASCADE", nullable=False, index=True)
    )
    product_id: uuid.UUID | None = Field(
        default=None, sa_column=fk_column("products.id", ondelete="SET NULL")
    )
    name_snapshot: str
    quantity: int
    unit_price: Decimal = Field(sa_column=money_column(default=None))
    unit_cost: Decimal = Field(default=Decimal("0"), sa_column=money_column())
    discount: Decimal = Field(default=Decimal("0"), sa_column=money_column())
    line_total: Decimal = Field(sa_column=money_column(default=None))

    __table_args__ = (sa.CheckConstraint("quantity > 0", name="ck_sale_items_quantity"),)
