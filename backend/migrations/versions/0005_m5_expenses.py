"""M5 expenses: expense_categories, expenses

Revision ID: 0005_m5
Revises: 0004_m4
Create Date: 2026-06-26
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "0005_m5"
down_revision: str | None = "0004_m4"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "expense_categories",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "business_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("businesses.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("name", sa.Text(), nullable=False),
        sa.UniqueConstraint("business_id", "name", name="uq_expense_categories_name"),
    )
    op.create_index("ix_expense_categories_business_id", "expense_categories", ["business_id"])

    op.create_table(
        "expenses",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "business_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("businesses.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "category_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("expense_categories.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("label", sa.Text(), nullable=False),
        sa.Column("amount", sa.Numeric(12, 2), nullable=False),
        sa.Column("spent_on", sa.Date(), nullable=False, server_default=sa.func.current_date()),
        sa.Column("note", sa.Text(), nullable=True),
        sa.Column(
            "created_by",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.CheckConstraint("amount > 0", name="ck_expenses_amount"),
    )
    op.create_index("ix_expenses_business_id", "expenses", ["business_id"])
    op.create_index("expenses_business_date_idx", "expenses", ["business_id", "spent_on"])


def downgrade() -> None:
    op.drop_index("expenses_business_date_idx", table_name="expenses")
    op.drop_index("ix_expenses_business_id", table_name="expenses")
    op.drop_table("expenses")
    op.drop_index("ix_expense_categories_business_id", table_name="expense_categories")
    op.drop_table("expense_categories")
