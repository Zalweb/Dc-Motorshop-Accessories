import uuid
from datetime import datetime

import sqlalchemy as sa
from sqlmodel import Field, SQLModel

from app.core.clock import utcnow
from app.core.ids import uuid7
from app.models.base import created_column, fk_column, id_column


class InventoryMovement(SQLModel, table=True):
    """Append-only stock ledger. On-hand = SUM(change_qty); never mutate a row.

    (variant_id from DATABASE.md is deferred until product_variants exists.)
    """

    __tablename__ = "inventory_movements"

    id: uuid.UUID = Field(default_factory=uuid7, sa_column=id_column())
    business_id: uuid.UUID = Field(
        sa_column=fk_column("businesses.id", ondelete="CASCADE", nullable=False, index=True)
    )
    product_id: uuid.UUID = Field(
        sa_column=fk_column("products.id", ondelete="RESTRICT", nullable=False, index=True)
    )
    change_qty: int  # +in / -out, never 0
    reason: str
    reference_type: str | None = None
    reference_id: uuid.UUID | None = None
    note: str | None = None
    created_by: uuid.UUID | None = Field(
        default=None, sa_column=fk_column("users.id", ondelete="SET NULL")
    )
    created_at: datetime = Field(default_factory=utcnow, sa_column=created_column())

    __table_args__ = (
        sa.CheckConstraint("change_qty <> 0", name="ck_inv_mov_change_qty"),
        sa.CheckConstraint(
            "reason IN ('initial','purchase','sale','adjustment','return')",
            name="ck_inv_mov_reason",
        ),
    )
