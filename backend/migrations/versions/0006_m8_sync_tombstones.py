"""M8 sync_tombstones

Revision ID: 0006_m8
Revises: 0005_m5
Create Date: 2026-06-26
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "0006_m8"
down_revision: str | None = "0005_m5"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "sync_tombstones",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "business_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("businesses.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("table_name", sa.Text(), nullable=False),
        sa.Column("row_id", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.UniqueConstraint("business_id", "table_name", "row_id", name="uq_tombstone_row"),
    )
    op.create_index("ix_sync_tombstones_business_id", "sync_tombstones", ["business_id"])
    op.create_index(
        "ix_tombstones_pull", "sync_tombstones", ["business_id", "table_name", "deleted_at"]
    )


def downgrade() -> None:
    op.drop_index("ix_tombstones_pull", table_name="sync_tombstones")
    op.drop_index("ix_sync_tombstones_business_id", table_name="sync_tombstones")
    op.drop_table("sync_tombstones")
