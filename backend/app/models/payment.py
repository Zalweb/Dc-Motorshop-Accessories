import uuid
from datetime import datetime
from decimal import Decimal

import sqlalchemy as sa
from sqlmodel import Field, SQLModel

from app.core.clock import utcnow
from app.core.ids import uuid7
from app.models.base import created_column, fk_column, id_column, money_column


class Payment(SQLModel, table=True):
    __tablename__ = "payments"

    id: uuid.UUID = Field(default_factory=uuid7, sa_column=id_column())
    sale_id: uuid.UUID = Field(
        sa_column=fk_column("sales.id", ondelete="CASCADE", nullable=False, index=True)
    )
    method: str
    amount: Decimal = Field(sa_column=money_column(default=None))
    created_at: datetime = Field(default_factory=utcnow, sa_column=created_column())

    __table_args__ = (
        sa.CheckConstraint(
            "method IN ('cash','gcash','card','bank','other')", name="ck_payments_method"
        ),
        sa.CheckConstraint("amount > 0", name="ck_payments_amount"),
    )
