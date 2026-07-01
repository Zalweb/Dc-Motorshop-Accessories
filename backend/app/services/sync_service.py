"""Phase-2 delta sync: pull changes/tombstones since a timestamp, push idempotent upserts.

Conflict policy (DATABASE.md §9, BACKEND_PLAN §5):
  - Catalog/config tables: last-write-wins by `updated_at`.
  - inventory_movements: append-only (insert-if-absent, never updated).
  - sales / sale_items / payments are NOT pushable here — they are server-authoritative and
    sync via the idempotent `POST /sales`, so money is always recomputed server-side. They
    are still PULLABLE so a device can download history.
  - products.stock_on_hand is never accepted from a client (push-excluded); the movement
    ledger + trigger remain the source of truth for stock.
Every row is scoped to the JWT business; rows whose id belongs to another tenant are skipped.
"""

from dataclasses import dataclass, field
from datetime import datetime
from typing import Any
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import SQLModel

from app.core.clock import utcnow
from app.core.errors import AppError
from app.models.brand import Brand
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
from app.services.serialization import dict_to_model, row_to_dict


@dataclass(frozen=True)
class TableSpec:
    model: type[SQLModel]
    scope: str  # "business" | "sale"
    updated_col: str | None  # column for since-filter + LWW; None = no timestamp (full sync)
    deleted_col: str | None  # soft-delete column (rows with it set are excluded from changes)
    append_only: bool
    pushable: bool
    push_exclude: frozenset[str] = field(default_factory=frozenset)


REGISTRY: dict[str, TableSpec] = {
    "categories": TableSpec(Category, "business", "updated_at", None, False, True),
    "brands": TableSpec(Brand, "business", None, None, False, True),
    "products": TableSpec(
        Product, "business", "updated_at", "deleted_at", False, True, frozenset({"stock_on_hand"})
    ),
    "customers": TableSpec(Customer, "business", "updated_at", "deleted_at", False, True),
    "workflow_stages": TableSpec(WorkflowStage, "business", None, None, False, True),
    "expense_categories": TableSpec(ExpenseCategory, "business", None, None, False, True),
    "expenses": TableSpec(Expense, "business", "updated_at", None, False, True),
    "users": TableSpec(User, "business", "updated_at", "deleted_at", False, True),
    "inventory_movements": TableSpec(
        InventoryMovement, "business", "created_at", None, True, True
    ),
    "sales": TableSpec(Sale, "business", "updated_at", None, True, False),
    "sale_items": TableSpec(SaleItem, "sale", None, None, True, False),
    "payments": TableSpec(Payment, "sale", "created_at", None, True, False),
}

# Reset values for push-excluded columns on insert (e.g. stock is rebuilt from movements).
_EXCLUDE_DEFAULTS = {"stock_on_hand": 0}


def _spec(table: str) -> TableSpec:
    spec = REGISTRY.get(table)
    if spec is None:
        raise AppError(code="unknown_table", message="Unknown sync table", status_code=404)
    return spec


class SyncService:
    def __init__(self, session: AsyncSession, business_id: UUID) -> None:
        self.session = session
        self.business_id = business_id

    async def pull(self, table: str, since: datetime | None) -> dict[str, Any]:
        spec = _spec(table)
        server_time = utcnow()

        if spec.scope == "business":
            base = select(spec.model).where(spec.model.business_id == self.business_id)
        else:
            sale_ids = (
                select(Sale.id).where(Sale.business_id == self.business_id).scalar_subquery()
            )
            base = select(spec.model).where(spec.model.sale_id.in_(sale_ids))

        if spec.deleted_col is not None:
            base = base.where(getattr(spec.model, spec.deleted_col).is_(None))
        if since is not None and spec.updated_col is not None:
            base = base.where(getattr(spec.model, spec.updated_col) > since)

        rows = await self.session.scalars(base)
        changes = [row_to_dict(r) for r in rows]

        tomb_query = select(SyncTombstone.row_id).where(
            SyncTombstone.business_id == self.business_id, SyncTombstone.table_name == table
        )
        if since is not None:
            tomb_query = tomb_query.where(SyncTombstone.deleted_at > since)
        tombstones = [str(rid) for rid in await self.session.scalars(tomb_query)]

        return {
            "table": table,
            "changes": changes,
            "tombstones": tombstones,
            "server_time": server_time.isoformat(),
        }

    async def push(self, table: str, rows: list[dict]) -> dict[str, int]:
        spec = _spec(table)
        if not spec.pushable:
            raise AppError(
                code="table_not_pushable",
                message=f"'{table}' is server-authoritative; sync it via its own endpoint",
                status_code=422,
            )

        applied = skipped = 0
        for row in rows:
            if await self._apply_push(spec, row):
                applied += 1
            else:
                skipped += 1
        await self.session.commit()
        return {"applied": applied, "skipped": skipped}

    async def _apply_push(self, spec: TableSpec, row: dict) -> bool:
        typed = dict_to_model(spec.model, row)

        if spec.scope == "business":
            typed.business_id = self.business_id
        else:
            sale = await self.session.get(Sale, typed.sale_id)
            if sale is None or sale.business_id != self.business_id:
                return False

        existing = await self.session.get(spec.model, typed.id)

        if existing is None:
            for col, default in _EXCLUDE_DEFAULTS.items():
                if col in spec.push_exclude:
                    setattr(typed, col, default)
            self.session.add(typed)
            await self.session.flush()
            return True

        if spec.scope == "business" and getattr(existing, "business_id", None) != self.business_id:
            return False  # belongs to another tenant
        if spec.append_only:
            return False  # never update append-only rows
        if spec.updated_col is not None and getattr(existing, spec.updated_col) >= getattr(
            typed, spec.updated_col
        ):
            return False  # last-write-wins: server copy is newer or equal

        for col in spec.model.__table__.columns.keys():
            if col in ("id", "business_id") or col in spec.push_exclude:
                continue
            setattr(existing, col, getattr(typed, col))
        self.session.add(existing)
        await self.session.flush()
        return True


async def record_tombstone(
    session: AsyncSession, business_id: UUID, table_name: str, row_id: UUID
) -> None:
    """Mark a row deleted so the deletion propagates on the next sync pull. Idempotent."""
    exists = await session.scalar(
        select(SyncTombstone.id).where(
            SyncTombstone.business_id == business_id,
            SyncTombstone.table_name == table_name,
            SyncTombstone.row_id == row_id,
        )
    )
    if exists is None:
        session.add(
            SyncTombstone(business_id=business_id, table_name=table_name, row_id=row_id)
        )
