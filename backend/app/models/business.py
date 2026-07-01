import uuid
from datetime import datetime

import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB
from sqlmodel import Field, SQLModel

from app.core.clock import utcnow
from app.core.ids import uuid7
from app.models.base import created_column, id_column, updated_column


class Business(SQLModel, table=True):
    __tablename__ = "businesses"

    id: uuid.UUID = Field(default_factory=uuid7, sa_column=id_column())
    name: str
    logo_url: str | None = None
    address: str | None = None
    phone: str | None = None
    currency: str = Field(default="PHP", max_length=3)
    theme_color: str = Field(default="Blue")
    # Completed setup-checklist item ids, e.g. ["add_logo","add_product"].
    onboarding_checklist: list[str] = Field(
        default_factory=list,
        sa_column=sa.Column(JSONB, nullable=False, server_default=sa.text("'[]'::jsonb")),
    )
    expense_avg_months: int = Field(default=3)
    low_stock_threshold_days: int | None = None
    created_at: datetime = Field(default_factory=utcnow, sa_column=created_column())
    updated_at: datetime = Field(default_factory=utcnow, sa_column=updated_column())

    __table_args__ = (
        sa.CheckConstraint("expense_avg_months > 0", name="ck_businesses_expense_avg_months"),
    )
