"""Tenant-scoped base repository.

Every read/write is constrained to the caller's `business_id`. The id comes from the JWT
(via deps), never from client input — this is the single chokepoint enforcing tenant
isolation (defense against IDOR/BOLA). Subclasses set `model`.
"""

from uuid import UUID

from sqlalchemy import Select, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlmodel import SQLModel


class BaseRepository[ModelT: SQLModel]:
    model: type[ModelT]

    def __init__(self, session: AsyncSession, business_id: UUID) -> None:
        self.session = session
        self.business_id = business_id

    def scoped(self) -> Select:
        return select(self.model).where(self.model.business_id == self.business_id)

    async def get(self, id_: UUID) -> ModelT | None:
        obj = await self.session.get(self.model, id_)
        if obj is None or obj.business_id != self.business_id:
            return None
        return obj

    async def list(self) -> list[ModelT]:
        result = await self.session.scalars(self.scoped())
        return list(result)

    async def delete(self, id_: UUID) -> bool:
        obj = await self.get(id_)
        if obj is None:
            return False
        await self.session.delete(obj)
        return True
