"""Checkout: the money- and stock-critical path.

Guarantees:
  - The server RECOMPUTES every line_total, subtotal and total from server-side unit prices
    (a product line snapshots the product's current price/cost; client totals are never
    trusted or even accepted).
  - One negative `sale` inventory movement per stocked line, written in the SAME transaction
    as the sale + items + payments — so stock can never drift from recorded sales.
  - Idempotent by client sale UUID: a retried checkout returns the existing sale unchanged
    (no double-charge of stock).
"""

from decimal import Decimal
from uuid import UUID

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import AppError
from app.core.money import q2
from app.models.customer import Customer
from app.models.payment import Payment
from app.models.product import Product
from app.models.sale import Sale
from app.models.sale_item import SaleItem
from app.models.workflow_stage import WorkflowStage
from app.schemas.sale import SaleIn, SaleItemIn
from app.services.inventory_service import InventoryService


class SaleService:
    def __init__(self, session: AsyncSession, business_id: UUID, user_id: UUID) -> None:
        self.session = session
        self.business_id = business_id
        self.user_id = user_id
        self.inventory = InventoryService(session, business_id)

    async def checkout(self, data: SaleIn) -> Sale:
        if data.id is not None:
            existing = await self._get_scoped(data.id)
            if existing is not None:
                return existing  # idempotent: never re-run stock movements

        await self._validate_refs(data)
        products = await self._load_products(data.items)

        sale = Sale(
            business_id=self.business_id,
            sale_number=await self._next_sale_number(),
            customer_id=data.customer_id,
            customer_name=data.customer_name,
            stage_id=data.stage_id,
            sold_by=self.user_id,
            discount_total=q2(data.discount_total),
            tax_total=q2(data.tax_total),
        )
        if data.id is not None:
            sale.id = data.id
        self.session.add(sale)
        await self.session.flush()

        subtotal = Decimal("0")
        for item in data.items:
            line = self._build_line(sale.id, item, products.get(item.product_id))
            subtotal += line.unit_price * line.quantity
            self.session.add(line)
            await self.session.flush()
            product = products.get(item.product_id)
            if product is not None and not product.is_service:
                await self.inventory.record(
                    product_id=product.id,
                    change_qty=-item.quantity,
                    reason="sale",
                    created_by=self.user_id,
                    reference_type="sale",
                    reference_id=sale.id,
                )

        sale.subtotal = q2(subtotal)
        sale.total = q2(subtotal - sale.discount_total + sale.tax_total)
        self.session.add(sale)

        # Default to a single cash payment for the full total; skip if total is zero
        # (fully-discounted sale) since payments must be positive.
        payments = data.payments or ([_default_cash(sale.total)] if sale.total > 0 else [])
        for payment in payments:
            self.session.add(
                Payment(sale_id=sale.id, method=payment.method, amount=q2(payment.amount))
            )

        await self.session.commit()
        return await self._get_scoped(sale.id)

    def _build_line(self, sale_id: UUID, item: SaleItemIn, product: Product | None) -> SaleItem:
        if product is not None:
            unit_price = product.selling_price
            unit_cost = product.cost_price
            name = product.name
        else:
            if item.unit_price is None or not item.name:
                raise AppError(
                    code="invalid_line_item",
                    message="Custom line items require a name and unit_price",
                    status_code=422,
                )
            unit_price = item.unit_price
            unit_cost = Decimal("0")
            name = item.name
        line_total = q2(unit_price * item.quantity - item.discount)
        return SaleItem(
            sale_id=sale_id,
            product_id=item.product_id,
            name_snapshot=name,
            quantity=item.quantity,
            unit_price=q2(unit_price),
            unit_cost=q2(unit_cost),
            discount=q2(item.discount),
            line_total=line_total,
        )

    async def _load_products(self, items: list[SaleItemIn]) -> dict[UUID, Product]:
        ids = {item.product_id for item in items if item.product_id is not None}
        if not ids:
            return {}
        rows = await self.session.scalars(
            select(Product).where(
                Product.id.in_(ids),
                Product.business_id == self.business_id,
                Product.deleted_at.is_(None),
            )
        )
        products = {p.id: p for p in rows}
        missing = ids - products.keys()
        if missing:
            raise AppError(
                code="invalid_product", message="One or more products not found", status_code=422
            )
        return products

    async def _validate_refs(self, data: SaleIn) -> None:
        if data.customer_id is not None:
            owns = await self.session.scalar(
                select(Customer.id).where(
                    Customer.id == data.customer_id, Customer.business_id == self.business_id
                )
            )
            if owns is None:
                raise AppError(
                    code="invalid_customer", message="Customer not found", status_code=422
                )
        if data.stage_id is not None:
            owns = await self.session.scalar(
                select(WorkflowStage.id).where(
                    WorkflowStage.id == data.stage_id,
                    WorkflowStage.business_id == self.business_id,
                )
            )
            if owns is None:
                raise AppError(
                    code="invalid_stage", message="Workflow stage not found", status_code=422
                )

    async def _next_sale_number(self) -> str:
        count = await self.session.scalar(
            select(func.count()).select_from(Sale).where(Sale.business_id == self.business_id)
        )
        return f"S-{(count or 0) + 1:04d}"

    async def _get_scoped(self, sale_id: UUID) -> Sale | None:
        return await self.session.scalar(
            select(Sale).where(Sale.id == sale_id, Sale.business_id == self.business_id)
        )


def _default_cash(total: Decimal):
    from app.schemas.sale import PaymentIn

    return PaymentIn(method="cash", amount=total)
