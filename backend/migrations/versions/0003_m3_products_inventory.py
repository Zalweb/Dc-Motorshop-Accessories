"""M3 brands, products, inventory_movements (+ stock_on_hand trigger)

Revision ID: 0003_m3
Revises: 0002_m2
Create Date: 2026-06-26
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "0003_m3"
down_revision: str | None = "0002_m2"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

# Recompute the cached on-hand from the authoritative ledger after every movement insert.
_TRIGGER_FN = """
CREATE OR REPLACE FUNCTION sync_stock_on_hand() RETURNS trigger AS $$
BEGIN
    UPDATE products
       SET stock_on_hand = (
           SELECT COALESCE(SUM(change_qty), 0)
             FROM inventory_movements
            WHERE product_id = NEW.product_id
       )
     WHERE id = NEW.product_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
"""


def upgrade() -> None:
    op.create_table(
        "brands",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "business_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("businesses.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("name", sa.Text(), nullable=False),
        sa.UniqueConstraint("business_id", "name", name="uq_brands_name"),
    )
    op.create_index("ix_brands_business_id", "brands", ["business_id"])

    op.create_table(
        "products",
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
            sa.ForeignKey("categories.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column(
            "brand_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("brands.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("name", sa.Text(), nullable=False),
        sa.Column("sku", sa.Text(), nullable=True),
        sa.Column("barcode", sa.Text(), nullable=True),
        sa.Column("part_number", sa.Text(), nullable=True),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("unit", sa.Text(), nullable=False, server_default="piece"),
        sa.Column("is_service", sa.Boolean(), nullable=False, server_default=sa.false()),
        sa.Column("cost_price", sa.Numeric(12, 2), nullable=False, server_default="0"),
        sa.Column("selling_price", sa.Numeric(12, 2), nullable=False, server_default="0"),
        sa.Column("reorder_point", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("stock_on_hand", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("image_url", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True),
        sa.CheckConstraint("unit IN ('piece','liter','set','pair','box')", name="ck_products_unit"),
        sa.CheckConstraint("cost_price >= 0", name="ck_products_cost_price"),
        sa.CheckConstraint("selling_price >= 0", name="ck_products_selling_price"),
    )
    op.create_index("ix_products_business_id", "products", ["business_id"])
    # Barcode unique per shop, but only when present.
    op.create_index(
        "products_barcode_uq",
        "products",
        ["business_id", "barcode"],
        unique=True,
        postgresql_where=sa.text("barcode IS NOT NULL"),
    )
    # Fast listing of active (non-deleted) products.
    op.create_index(
        "products_business_active_idx",
        "products",
        ["business_id"],
        postgresql_where=sa.text("deleted_at IS NULL"),
    )

    op.create_table(
        "inventory_movements",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column(
            "business_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("businesses.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "product_id",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("products.id", ondelete="RESTRICT"),
            nullable=False,
        ),
        sa.Column("change_qty", sa.Integer(), nullable=False),
        sa.Column("reason", sa.Text(), nullable=False),
        sa.Column("reference_type", sa.Text(), nullable=True),
        sa.Column("reference_id", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("note", sa.Text(), nullable=True),
        sa.Column(
            "created_by",
            postgresql.UUID(as_uuid=True),
            sa.ForeignKey("users.id", ondelete="SET NULL"),
            nullable=True,
        ),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.CheckConstraint("change_qty <> 0", name="ck_inv_mov_change_qty"),
        sa.CheckConstraint(
            "reason IN ('initial','purchase','sale','adjustment','return')",
            name="ck_inv_mov_reason",
        ),
    )
    op.create_index("ix_inventory_movements_business_id", "inventory_movements", ["business_id"])
    op.create_index(
        "inv_mov_product_idx", "inventory_movements", ["product_id", "created_at"]
    )

    op.execute(_TRIGGER_FN)
    op.execute(
        "CREATE TRIGGER trg_sync_stock_on_hand AFTER INSERT ON inventory_movements "
        "FOR EACH ROW EXECUTE FUNCTION sync_stock_on_hand()"
    )


def downgrade() -> None:
    op.execute("DROP TRIGGER IF EXISTS trg_sync_stock_on_hand ON inventory_movements")
    op.execute("DROP FUNCTION IF EXISTS sync_stock_on_hand()")
    op.drop_index("inv_mov_product_idx", table_name="inventory_movements")
    op.drop_index("ix_inventory_movements_business_id", table_name="inventory_movements")
    op.drop_table("inventory_movements")
    op.drop_index("products_business_active_idx", table_name="products")
    op.drop_index("products_barcode_uq", table_name="products")
    op.drop_index("ix_products_business_id", table_name="products")
    op.drop_table("products")
    op.drop_index("ix_brands_business_id", table_name="brands")
    op.drop_table("brands")
