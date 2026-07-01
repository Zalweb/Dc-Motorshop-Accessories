"""M2 categories

Revision ID: 0002_m2
Revises: 0001_m1
Create Date: 2026-06-26

(businesses.onboarding_checklist already exists from 0001_m1.)
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "0002_m2"
down_revision: str | None = "0001_m1"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "categories",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "business_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("businesses.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "parent_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("categories.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("name", sa.Text(), nullable=False),
        sa.Column("is_service", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_categories_business_id", "categories", ["business_id"])
    # NULLS NOT DISTINCT enforces unique top-level names (parent_id IS NULL) too.
    op.create_index(
        "uq_categories_name",
        "categories",
        ["business_id", "parent_id", "name"],
        unique=True,
        postgresql_nulls_not_distinct=True,
    )


def downgrade() -> None:
    op.drop_index("uq_categories_name", table_name="categories")
    op.drop_index("ix_categories_business_id", table_name="categories")
    op.drop_table("categories")
