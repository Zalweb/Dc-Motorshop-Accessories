"""M4 sales: customers, workflow_stages, sales, sale_items, payments

Revision ID: 0004_m4
Revises: 0003_m3
Create Date: 2026-06-26
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "0004_m4"
down_revision: str | None = "0003_m3"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.create_table(
        "customers",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "business_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("businesses.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("name", sa.Text(), nullable=False),
        sa.Column("phone", sa.Text(), nullable=True),
        sa.Column("email", postgresql.CITEXT(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index("ix_customers_business_id", "customers", ["business_id"])

    op.create_table(
        "workflow_stages",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "business_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("businesses.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("name", sa.Text(), nullable=False),
        sa.Column("position", sa.SmallInteger(), nullable=False),
        sa.Column("is_terminal", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.UniqueConstraint("business_id", "position", name="uq_workflow_stages_position"),
        sa.UniqueConstraint("business_id", "name", name="uq_workflow_stages_name"),
    )
    op.create_index("ix_workflow_stages_business_id", "workflow_stages", ["business_id"])

    op.create_table(
        "sales",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "business_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("businesses.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("sale_number", sa.Text(), nullable=False),
        sa.Column(
            "customer_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("customers.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("customer_name", sa.Text(), nullable=True),
        sa.Column(
            "stage_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("workflow_stages.id", ondelete="RESTRICT"),
            nullable=True,
        ),
        sa.Column(
            "sold_by",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("subtotal", sa.Numeric(12, 2), nullable=False, server_default="0"),
        sa.Column("discount_total", sa.Numeric(12, 2), nullable=False, server_default="0"),
        sa.Column("tax_total", sa.Numeric(12, 2), nullable=False, server_default="0"),
        sa.Column("total", sa.Numeric(12, 2), nullable=False, server_default="0"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.UniqueConstraint("business_id", "sale_number", name="uq_sales_sale_number"),
    )
    op.create_index("ix_sales_business_id", "sales", ["business_id"])
    op.create_index(
        "sales_business_created_idx", "sales", ["business_id", sa.text("created_at DESC")]
    )

    op.create_table(
        "sale_items",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "sale_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("sales.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "product_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("products.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("name_snapshot", sa.Text(), nullable=False),
        sa.Column("quantity", sa.Integer(), nullable=False),
        sa.Column("unit_price", sa.Numeric(12, 2), nullable=False),
        sa.Column("unit_cost", sa.Numeric(12, 2), nullable=False, server_default="0"),
        sa.Column("discount", sa.Numeric(12, 2), nullable=False, server_default="0"),
        sa.Column("line_total", sa.Numeric(12, 2), nullable=False),
        sa.CheckConstraint("quantity > 0", name="ck_sale_items_quantity"),
    )
    op.create_index("ix_sale_items_sale_id", "sale_items", ["sale_id"])

    op.create_table(
        "payments",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "sale_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("sales.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("method", sa.Text(), nullable=False),
        sa.Column("amount", sa.Numeric(12, 2), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.CheckConstraint("method IN ('cash','gcash','card','bank','other')", name="ck_payments_method"),
        sa.CheckConstraint("amount > 0", name="ck_payments_amount"),
    )
    op.create_index("ix_payments_sale_id", "payments", ["sale_id"])


def downgrade() -> None:
    op.drop_index("ix_payments_sale_id", table_name="payments")
    op.drop_table("payments")
    op.drop_index("ix_sale_items_sale_id", table_name="sale_items")
    op.drop_table("sale_items")
    op.drop_index("sales_business_created_idx", table_name="sales")
    op.drop_index("ix_sales_business_id", table_name="sales")
    op.drop_table("sales")
    op.drop_index("ix_workflow_stages_business_id", table_name="workflow_stages")
    op.drop_table("workflow_stages")
    op.drop_index("ix_customers_business_id", table_name="customers")
    op.drop_table("customers")
