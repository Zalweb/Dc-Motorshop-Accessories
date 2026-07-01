import uuid
from datetime import datetime

import sqlalchemy as sa
from sqlmodel import Field, SQLModel

from app.core.clock import utcnow
from app.core.ids import uuid7
from app.models.base import created_column, fk_column, id_column, updated_column


class Category(SQLModel, table=True):
    __tablename__ = "categories"

    id: uuid.UUID = Field(default_factory=uuid7, sa_column=id_column())
    business_id: uuid.UUID = Field(
        sa_column=fk_column("businesses.id", ondelete="CASCADE", nullable=False, index=True)
    )
    parent_id: uuid.UUID | None = Field(
        default=None, sa_column=fk_column("categories.id", ondelete="SET NULL")
    )
    name: str
    is_service: bool = Field(default=False)
    created_at: datetime = Field(default_factory=utcnow, sa_column=created_column())
    updated_at: datetime = Field(default_factory=utcnow, sa_column=updated_column())

    # NULLS NOT DISTINCT so two top-level (parent_id IS NULL) categories can't share a name
    # — Postgres otherwise treats NULLs as distinct and the uniqueness wouldn't fire.
    __table_args__ = (
        sa.Index(
            "uq_categories_name",
            "business_id",
            "parent_id",
            "name",
            unique=True,
            postgresql_nulls_not_distinct=True,
        ),
    )
