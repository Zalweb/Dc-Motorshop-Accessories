import uuid
from datetime import date, datetime
from decimal import Decimal

import sqlalchemy as sa
from sqlmodel import Field, SQLModel

from app.core.clock import utcnow
from app.core.ids import uuid7
from app.models.base import created_column, fk_column, id_column, money_column, updated_column


class Expense(SQLModel, table=True):
    __tablename__ = "expenses"

    id: uuid.UUID = Field(default_factory=uuid7, sa_column=id_column())
    business_id: uuid.UUID = Field(
        sa_column=fk_column("businesses.id", ondelete="CASCADE", nullable=False, index=True)
    )
    category_id: uuid.UUID | None = Field(
        default=None, sa_column=fk_column("expense_categories.id", ondelete="SET NULL")
    )
    label: str
    amount: Decimal = Field(sa_column=money_column(default=None))
    spent_on: date = Field(
        sa_column=sa.Column(sa.Date, nullable=False, server_default=sa.func.current_date())
    )
    note: str | None = None
    created_by: uuid.UUID | None = Field(
        default=None, sa_column=fk_column("users.id", ondelete="SET NULL")
    )
    created_at: datetime = Field(default_factory=utcnow, sa_column=created_column())
    updated_at: datetime = Field(default_factory=utcnow, sa_column=updated_column())

    __table_args__ = (sa.CheckConstraint("amount > 0", name="ck_expenses_amount"),)
