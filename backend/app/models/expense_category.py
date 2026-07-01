import uuid

import sqlalchemy as sa
from sqlmodel import Field, SQLModel

from app.core.ids import uuid7
from app.models.base import fk_column, id_column


class ExpenseCategory(SQLModel, table=True):
    __tablename__ = "expense_categories"

    id: uuid.UUID = Field(default_factory=uuid7, sa_column=id_column())
    business_id: uuid.UUID = Field(
        sa_column=fk_column("businesses.id", ondelete="CASCADE", nullable=False, index=True)
    )
    name: str

    __table_args__ = (
        sa.UniqueConstraint("business_id", "name", name="uq_expense_categories_name"),
    )
