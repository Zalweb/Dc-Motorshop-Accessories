"""Stock as an append-only ledger.

Movements are the source of truth; `products.stock_on_hand` is a cache the DB trigger
recomputes after each insert. This service only appends — it never mutates on-hand directly.
"""

from uuid import UUID

from sqlalchemy.ext.asyncio import AsyncSession

from app.models.inventory_movement import InventoryMovement


class InventoryService:
    def __init__(self, session: AsyncSession, business_id: UUID) -> None:
        self.session = session
        self.business_id = business_id

    async def record(
        self,
        *,
        product_id: UUID,
        change_qty: int,
        reason: str,
        created_by: UUID | None,
        reference_type: str | None = None,
        reference_id: UUID | None = None,
        note: str | None = None,
    ) -> InventoryMovement | None:
        """Append one movement. A zero delta is a no-op (the ledger forbids change_qty=0)."""
        if change_qty == 0:
            return None
        movement = InventoryMovement(
            business_id=self.business_id,
            product_id=product_id,
            change_qty=change_qty,
            reason=reason,
            reference_type=reference_type,
            reference_id=reference_id,
            note=note,
            created_by=created_by,
        )
        self.session.add(movement)
        await self.session.flush()  # fire the trigger so stock_on_hand reflects this movement
        return movement
