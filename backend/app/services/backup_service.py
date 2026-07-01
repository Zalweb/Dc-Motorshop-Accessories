"""Full-tenant backup export + idempotent import.

Export gathers every owned row for the caller's business into one JSON snapshot.
Import upserts that snapshot back by primary key, ALWAYS scoped to the caller's business:
  - rows whose id already belongs to a DIFFERENT tenant are skipped (never overwritten) —
    this is what makes import tenant-isolated;
  - re-running the same import changes nothing (idempotent), because PKs are client UUIDs.
Because PKs are stable UUIDs, restore-on-reinstall reproduces identical data.
"""

from typing import Any
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import SQLModel

from app.core.clock import utcnow
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
from app.models.user import User
from app.models.workflow_stage import WorkflowStage
from app.services.serialization import dict_to_model as _build
from app.services.serialization import row_to_dict as _dump

SNAPSHOT_VERSION = 1

# Owned tables (carry business_id), in FK-safe import order. Categories are handled
# separately (two-pass) because of their self-referential parent_id.
_OWNED_BEFORE_CATEGORIES = [User, WorkflowStage, Brand, Customer, ExpenseCategory]
_OWNED_AFTER_CATEGORIES = [Product, InventoryMovement, Sale, Expense]
# Children linked via sale_id rather than business_id.
_CHILDREN = [SaleItem, Payment]


class BackupService:
    def __init__(self, session: AsyncSession, business_id: UUID, user_id: UUID) -> None:
        self.session = session
        self.business_id = business_id
        self.user_id = user_id

    async def export(self) -> dict[str, Any]:
        tables: dict[str, list[dict]] = {}

        business = await self.session.get(Business, self.business_id)
        tables["businesses"] = [_dump(business)] if business is not None else []

        for model in (*_OWNED_BEFORE_CATEGORIES, Category, *_OWNED_AFTER_CATEGORIES):
            rows = await self.session.scalars(
                select(model).where(model.business_id == self.business_id)
            )
            tables[model.__tablename__] = [_dump(r) for r in rows]

        sale_ids = select(Sale.id).where(Sale.business_id == self.business_id).scalar_subquery()
        for model in _CHILDREN:
            rows = await self.session.scalars(select(model).where(model.sale_id.in_(sale_ids)))
            tables[model.__tablename__] = [_dump(r) for r in rows]

        self.session.add(
            AuditLog(business_id=self.business_id, user_id=self.user_id, event="backup_export")
        )
        await self.session.commit()
        return {
            "version": SNAPSHOT_VERSION,
            "business_id": str(self.business_id),
            "exported_at": utcnow().isoformat(),
            "tables": tables,
        }

    async def import_(self, tables: dict[str, list[dict]]) -> dict[str, int]:
        counts: dict[str, int] = {}

        for row in tables.get("businesses", []):
            await self._upsert_business(row)

        for model in _OWNED_BEFORE_CATEGORIES:
            counts[model.__tablename__] = await self._upsert_owned(
                model, tables.get(model.__tablename__, [])
            )
        counts["categories"] = await self._upsert_categories(tables.get("categories", []))
        for model in _OWNED_AFTER_CATEGORIES:
            counts[model.__tablename__] = await self._upsert_owned(
                model, tables.get(model.__tablename__, [])
            )
        for model in _CHILDREN:
            counts[model.__tablename__] = await self._upsert_child(
                model, tables.get(model.__tablename__, [])
            )

        self.session.add(
            AuditLog(business_id=self.business_id, user_id=self.user_id, event="backup_import")
        )
        await self.session.commit()
        return counts

    # --- helpers -------------------------------------------------------------

    async def _upsert_business(self, row: dict) -> None:
        business = await self.session.get(Business, self.business_id)
        if business is None:
            return  # only ever restore the caller's own business
        typed = _build(Business, row)
        for col in Business.__table__.columns.keys():
            if col in ("id", "created_at"):
                continue
            setattr(business, col, getattr(typed, col))
        self.session.add(business)

    async def _upsert_owned(self, model: type[SQLModel], rows: list[dict]) -> int:
        count = 0
        for row in rows:
            typed = _build(model, row)
            typed.business_id = self.business_id
            if await self._apply(model, typed):
                count += 1
        return count

    async def _upsert_categories(self, rows: list[dict]) -> int:
        # Pass 1: upsert every category with parent_id cleared (avoids self-FK ordering issues).
        for row in rows:
            flat = {**row, "parent_id": None}
            typed = _build(Category, flat)
            typed.business_id = self.business_id
            await self._apply(Category, typed)
        # Pass 2: wire up parent_id now that all rows exist.
        count = 0
        for row in rows:
            existing = await self.session.get(Category, UUID(row["id"]))
            if existing is None or existing.business_id != self.business_id:
                continue
            existing.parent_id = UUID(row["parent_id"]) if row.get("parent_id") else None
            self.session.add(existing)
            count += 1
        return count

    async def _upsert_child(self, model: type[SQLModel], rows: list[dict]) -> int:
        count = 0
        for row in rows:
            typed = _build(model, row)
            sale = await self.session.get(Sale, typed.sale_id)
            if sale is None or sale.business_id != self.business_id:
                continue  # parent sale isn't ours — skip
            if await self._apply(model, typed, scope_check=False):
                count += 1
        return count

    async def _apply(
        self, model: type[SQLModel], typed: SQLModel, *, scope_check: bool = True
    ) -> bool:
        """Insert `typed`, or update the existing row. Returns False (skips) if the id
        already belongs to another tenant."""
        existing = await self.session.get(model, typed.id)
        if existing is None:
            self.session.add(typed)
            await self.session.flush()
            return True
        if scope_check and getattr(existing, "business_id", None) != self.business_id:
            return False
        for col in model.__table__.columns.keys():
            if col in ("id", "business_id"):
                continue
            setattr(existing, col, getattr(typed, col))
        self.session.add(existing)
        await self.session.flush()
        return True
