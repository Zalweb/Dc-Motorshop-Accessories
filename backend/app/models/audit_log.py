import uuid
from datetime import datetime

import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB
from sqlmodel import Field, SQLModel

from app.core.clock import utcnow
from app.core.ids import uuid7
from app.models.base import created_column, fk_column, id_column


class AuditLog(SQLModel, table=True):
    """Append-only record of sensitive events (auth, data export/import).

    business_id / user_id are nullable so a failed login against an unknown account is
    still auditable. Never store passwords or tokens here.
    """

    __tablename__ = "audit_log"

    id: uuid.UUID = Field(default_factory=uuid7, sa_column=id_column())
    business_id: uuid.UUID | None = Field(
        default=None, sa_column=fk_column("businesses.id", ondelete="SET NULL", index=True)
    )
    user_id: uuid.UUID | None = Field(
        default=None, sa_column=fk_column("users.id", ondelete="SET NULL")
    )
    event: str
    ip: str | None = None
    detail: dict | None = Field(default=None, sa_column=sa.Column(JSONB, nullable=True))
    created_at: datetime = Field(default_factory=utcnow, sa_column=created_column())
