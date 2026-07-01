import uuid
from datetime import datetime

import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import CITEXT
from sqlmodel import Field, SQLModel

from app.core.clock import utcnow
from app.core.ids import uuid7
from app.models.base import created_column, deleted_column, fk_column, id_column, updated_column


class Customer(SQLModel, table=True):
    __tablename__ = "customers"

    id: uuid.UUID = Field(default_factory=uuid7, sa_column=id_column())
    business_id: uuid.UUID = Field(
        sa_column=fk_column("businesses.id", ondelete="CASCADE", nullable=False, index=True)
    )
    name: str
    phone: str | None = None
    email: str | None = Field(default=None, sa_column=sa.Column(CITEXT, nullable=True))
    created_at: datetime = Field(default_factory=utcnow, sa_column=created_column())
    updated_at: datetime = Field(default_factory=utcnow, sa_column=updated_column())
    deleted_at: datetime | None = Field(default=None, sa_column=deleted_column())
