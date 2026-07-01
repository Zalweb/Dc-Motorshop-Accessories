"""Import every table module so SQLModel.metadata is complete for Alembic autogenerate."""

from app.models.audit_log import AuditLog
from app.models.brand import Brand
from app.models.business import Business
from app.models.category import Category
from app.models.customer import Customer
from app.models.expense import Expense
from app.models.expense_category import ExpenseCategory
from app.models.inventory_movement import InventoryMovement
from app.models.payment import Payment
from app.models.product import Product
from app.models.sale import Sale
from app.models.sale_item import SaleItem
from app.models.sync_tombstone import SyncTombstone
from app.models.user import User
from app.models.workflow_stage import WorkflowStage

__all__ = [
    "AuditLog",
    "Brand",
    "Business",
    "Category",
    "Customer",
    "Expense",
    "ExpenseCategory",
    "InventoryMovement",
    "Payment",
    "Product",
    "Sale",
    "SaleItem",
    "SyncTombstone",
    "User",
    "WorkflowStage",
]
