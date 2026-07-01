from uuid import UUID

from app.core.clock import utcnow
from app.models.category import Category
from app.repositories.base import BaseRepository


class CategoryRepository(BaseRepository[Category]):
    model = Category

    async def upsert(
        self, *, id_: UUID | None, name: str, parent_id: UUID | None, is_service: bool
    ) -> Category:
        """Create, or update in place when the client-supplied id already exists.

        Idempotent by id so retries and Phase-2 sync don't duplicate rows.
        """
        existing = await self.get(id_) if id_ is not None else None
        if existing is not None:
            existing.name = name
            existing.parent_id = parent_id
            existing.is_service = is_service
            existing.updated_at = utcnow()
            self.session.add(existing)
            return existing

        category = Category(
            business_id=self.business_id,
            name=name,
            parent_id=parent_id,
            is_service=is_service,
        )
        if id_ is not None:
            category.id = id_
        self.session.add(category)
        return category
