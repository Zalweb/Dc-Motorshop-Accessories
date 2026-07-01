"""M1 identity + auth: businesses, users, audit_log

Revision ID: 0001_m1
Revises:
Create Date: 2026-06-26

Note: businesses.onboarding_checklist (DATABASE.md schema addition) is created here with
the table, so the ORM model and DB agree from the first migration.
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "0001_m1"
down_revision: str | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.execute("CREATE EXTENSION IF NOT EXISTS citext")

    op.create_table(
        "businesses",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("name", sa.Text(), nullable=False),
        sa.Column("logo_url", sa.Text(), nullable=True),
        sa.Column("address", sa.Text(), nullable=True),
        sa.Column("phone", sa.Text(), nullable=True),
        sa.Column("currency", sa.CHAR(length=3), nullable=False, server_default="PHP"),
        sa.Column("theme_color", sa.Text(), nullable=False, server_default="Blue"),
        sa.Column(
            "onboarding_checklist",
            postgresql.JSONB(),
            nullable=False,
            server_default=sa.text("'[]'::jsonb"),
        ),
        sa.Column("expense_avg_months", sa.SmallInteger(), nullable=False, server_default="3"),
        sa.Column("low_stock_threshold_days", sa.SmallInteger(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.CheckConstraint("expense_avg_months > 0", name="ck_businesses_expense_avg_months"),
    )

    op.create_table(
        "users",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "business_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("businesses.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("username", postgresql.CITEXT(), nullable=False),
        sa.Column("email", postgresql.CITEXT(), nullable=False),
        sa.Column("password_hash", sa.Text(), nullable=False),
        sa.Column("full_name", sa.Text(), nullable=True),
        sa.Column("phone", sa.Text(), nullable=True),
        sa.Column("role", sa.Text(), nullable=False, server_default="owner"),
        sa.Column("onboarding_complete", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.CheckConstraint("role IN ('owner','manager','staff')", name="ck_users_role"),
        sa.UniqueConstraint("business_id", "username", name="uq_users_business_username"),
        sa.UniqueConstraint("business_id", "email", name="uq_users_business_email"),
    )
    op.create_index("ix_users_business_id", "users", ["business_id"])

    op.create_table(
        "audit_log",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "business_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("businesses.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column(
            "user_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("event", sa.Text(), nullable=False),
        sa.Column("ip", sa.Text(), nullable=True),
        sa.Column("detail", postgresql.JSONB(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )
    op.create_index("ix_audit_log_business_id", "audit_log", ["business_id"])


def downgrade() -> None:
    op.drop_index("ix_audit_log_business_id", table_name="audit_log")
    op.drop_table("audit_log")
    op.drop_index("ix_users_business_id", table_name="users")
    op.drop_table("users")
    op.drop_table("businesses")
    op.execute("DROP EXTENSION IF EXISTS citext")
