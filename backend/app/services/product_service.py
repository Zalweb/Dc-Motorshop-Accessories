"""Product writes: idempotent upsert by client UUID, with stock kept in the ledger.

Creating a product with stock N emits one `initial` movement of +N. Updating the desired
on-hand emits an `adjustment` movement for the delta — so re-sending the same payload is a
no-op (idempotent) and stock is always reconstructable from inventory_movements.
"""

from contextlib import asynccontextmanager
from uuid import UUID

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.clock import utcnow
from app.core.errors import AppError
from app.models.brand import Brand
from app.models.category import Category
from app.models.product import Product
from app.repositories.product_repo import ProductRepository
from app.schemas.product import ProductIn
from app.services.inventory_service import InventoryService

_EDITABLE_FIELDS = (
    "name",
    "sku",
    "barcode",
    "part_number",
    "description",
    "unit",
    "is_service",
    "category_id",
    "brand_id",
    "cost_price",
    "selling_price",
    "reorder_point",
)


class ProductService:
    def __init__(self, session: AsyncSession, business_id: UUID, user_id: UUID) -> None:
        self.session = session
        self.business_id = business_id
        self.user_id = user_id
        self.repo = ProductRepository(session, business_id)
        self.inventory = InventoryService(session, business_id)

    async def upsert(self, data: ProductIn) -> Product:
        async with self._barcode_conflict_guard():
            product = await self._upsert_one(data)
            await self.session.commit()
        await self.session.refresh(product)
        return product

    async def bulk_upsert(self, items: list[ProductIn]) -> list[Product]:
        async with self._barcode_conflict_guard():
            products = [await self._upsert_one(item) for item in items]
            await self.session.commit()
        for product in products:
            await self.session.refresh(product)
        return products

    @asynccontextmanager
    async def _barcode_conflict_guard(self):
        # The partial unique index on barcode raises on flush *or* commit — guard both.
        try:
            yield
        except IntegrityError as exc:
            await self.session.rollback()
            raise AppError(
                code="duplicate_barcode",
                message="A product with this barcode already exists",
                status_code=409,
            ) from exc

    async def _upsert_one(self, data: ProductIn) -> Product:
        await self._validate_refs(data)
        existing = await self.repo.get(data.id) if data.id is not None else None

        if existing is not None:
            for field in _EDITABLE_FIELDS:
                setattr(existing, field, getattr(data, field))
            existing.updated_at = utcnow()
            self.session.add(existing)
            await self.session.flush()
            delta = data.stock_qty - existing.stock_on_hand
            await self.inventory.record(
                product_id=existing.id,
                change_qty=delta,
                reason="adjustment",
                created_by=self.user_id,
            )
            return existing

        product = Product(
            business_id=self.business_id, **data.model_dump(include=set(_EDITABLE_FIELDS))
        )
        if data.id is not None:
            product.id = data.id
        self.session.add(product)
        await self.session.flush()
        await self.inventory.record(
            product_id=product.id,
            change_qty=data.stock_qty,
            reason="initial",
            created_by=self.user_id,
        )
        return product

    async def _validate_refs(self, data: ProductIn) -> None:
        if data.category_id is not None:
            owns = await self.session.scalar(
                select(Category.id).where(
                    Category.id == data.category_id, Category.business_id == self.business_id
                )
            )
            if owns is None:
                raise AppError(
                    code="invalid_category", message="Category not found", status_code=422
                )
        if data.brand_id is not None:
            owns = await self.session.scalar(
                select(Brand.id).where(
                    Brand.id == data.brand_id, Brand.business_id == self.business_id
                )
            )
            if owns is None:
                raise AppError(code="invalid_brand", message="Brand not found", status_code=422)
