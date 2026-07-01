from typing import Literal
from uuid import UUID

from sqlalchemy import func, or_, select

from app.models.product import Product
from app.repositories.base import BaseRepository

ProductType = Literal["all", "products", "services"]


class ProductRepository(BaseRepository[Product]):
    model = Product

    def _active(self):
        return self.scoped().where(Product.deleted_at.is_(None))

    async def get(self, id_: UUID) -> Product | None:
        product = await super().get(id_)
        if product is None or product.deleted_at is not None:
            return None
        return product

    async def by_barcode(self, barcode: str) -> Product | None:
        return await self.session.scalar(self._active().where(Product.barcode == barcode))

    async def search(
        self, *, search: str | None, product_type: ProductType, page: int, limit: int
    ) -> tuple[list[Product], int]:
        conditions = []
        if product_type == "products":
            conditions.append(Product.is_service.is_(False))
        elif product_type == "services":
            conditions.append(Product.is_service.is_(True))
        if search:
            term = f"%{search}%"
            conditions.append(
                or_(
                    Product.name.ilike(term),
                    Product.sku.ilike(term),
                    Product.barcode.ilike(term),
                    Product.part_number.ilike(term),
                )
            )

        base = self._active()
        for condition in conditions:
            base = base.where(condition)

        total = await self.session.scalar(
            select(func.count()).select_from(base.order_by(None).subquery())
        )
        rows = await self.session.scalars(
            base.order_by(Product.created_at.desc()).offset((page - 1) * limit).limit(limit)
        )
        return list(rows), int(total or 0)

    async def soft_delete(self, id_: UUID) -> Product | None:
        from app.core.clock import utcnow

        product = await self.get(id_)
        if product is None:
            return None
        product.deleted_at = utcnow()
        self.session.add(product)
        return product
