import uuid
from datetime import datetime

import sqlalchemy as sa
from sqlmodel import Field, SQLModel

from app.core.clock import utcnow
from app.core.ids import uuid7
from app.models.base import created_column, fk_column, id_column


class SyncTombstone(SQLModel, table=True):
    """Records a deletion so Phase-2 delta sync can propagate it to other devices.

    Written whenever a row is deleted (soft or hard). Pull returns tombstones for a table
    since the client's last sync so the client can remove the corresponding local rows.
    """

    __tablename__ = "sync_tombstones"

    id: uuid.UUID = Field(default_factory=uuid7, sa_column=id_column())
    business_id: uuid.UUID = Field(
        sa_column=fk_column("businesses.id", ondelete="CASCADE", nullable=False, index=True)
    )
    table_name: str
    row_id: uuid.UUID
    deleted_at: datetime = Field(default_factory=utcnow, sa_column=created_column())

    __table_args__ = (
        sa.UniqueConstraint("business_id", "table_name", "row_id", name="uq_tombstone_row"),
        sa.Index("ix_tombstones_pull", "business_id", "table_name", "deleted_at"),
    )
