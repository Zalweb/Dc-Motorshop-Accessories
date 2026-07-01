import uuid
from datetime import datetime
from decimal import Decimal

import sqlalchemy as sa
from sqlmodel import Field, SQLModel

from app.core.clock import utcnow
from app.core.ids import uuid7
from app.models.base import created_column, fk_column, id_column, money_column, updated_column


class Sale(SQLModel, table=True):
    __tablename__ = "sales"

    id: uuid.UUID = Field(default_factory=uuid7, sa_column=id_column())
    business_id: uuid.UUID = Field(
        sa_column=fk_column("businesses.id", ondelete="CASCADE", nullable=False, index=True)
    )
    sale_number: str
    customer_id: uuid.UUID | None = Field(
        default=None, sa_column=fk_column("customers.id", ondelete="SET NULL")
    )
    customer_name: str | None = None  # snapshot for walk-ins (denormalized)
    stage_id: uuid.UUID | None = Field(
        default=None, sa_column=fk_column("workflow_stages.id", ondelete="RESTRICT")
    )
    sold_by: uuid.UUID | None = Field(
        default=None, sa_column=fk_column("users.id", ondelete="SET NULL")
    )
    subtotal: Decimal = Field(default=Decimal("0"), sa_column=money_column())
    discount_total: Decimal = Field(default=Decimal("0"), sa_column=money_column())
    tax_total: Decimal = Field(default=Decimal("0"), sa_column=money_column())
    total: Decimal = Field(default=Decimal("0"), sa_column=money_column())
    created_at: datetime = Field(default_factory=utcnow, sa_column=created_column())
    updated_at: datetime = Field(default_factory=utcnow, sa_column=updated_column())

    __table_args__ = (
        sa.UniqueConstraint("business_id", "sale_number", name="uq_sales_sale_number"),
    )
