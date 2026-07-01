import uuid
from datetime import datetime

import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import CITEXT
from sqlmodel import Field, SQLModel

from app.core.clock import utcnow
from app.core.ids import uuid7
from app.models.base import created_column, deleted_column, fk_column, id_column, updated_column


class User(SQLModel, table=True):
    __tablename__ = "users"

    id: uuid.UUID = Field(default_factory=uuid7, sa_column=id_column())
    business_id: uuid.UUID = Field(
        sa_column=fk_column("businesses.id", ondelete="CASCADE", nullable=False, index=True)
    )
    username: str = Field(sa_column=sa.Column(CITEXT, nullable=False))
    email: str = Field(sa_column=sa.Column(CITEXT, nullable=False))
    password_hash: str  # Argon2id (salt embedded)
    full_name: str | None = None
    phone: str | None = None
    role: str = Field(default="owner")
    onboarding_complete: bool = Field(default=False)
    created_at: datetime = Field(default_factory=utcnow, sa_column=created_column())
    updated_at: datetime = Field(default_factory=utcnow, sa_column=updated_column())
    deleted_at: datetime | None = Field(default=None, sa_column=deleted_column())

    __table_args__ = (
        sa.CheckConstraint("role IN ('owner','manager','staff')", name="ck_users_role"),
        sa.UniqueConstraint("business_id", "username", name="uq_users_business_username"),
        sa.UniqueConstraint("business_id", "email", name="uq_users_business_email"),
    )
