"""Dashboard metrics — computed, never stored (DATABASE.md §8).

The reporting window is a pair of calendar DATES interpreted in a timezone (default
Asia/Manila): a sale at 02:00 Manila on the 27th counts toward the 27th even though it is
the 26th in UTC. Sales are filtered by their UTC `created_at` against the tz-derived bounds;
expenses by their `spent_on` date (already tz-free).
"""

from datetime import UTC, date, datetime, time, timedelta
from decimal import Decimal
from uuid import UUID
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.errors import AppError
from app.core.money import q2
from app.models.expense import Expense
from app.models.sale import Sale
from app.models.sale_item import SaleItem
from app.schemas.expense import DashboardSummary


class DashboardService:
    def __init__(self, session: AsyncSession, business_id: UUID) -> None:
        self.session = session
        self.business_id = business_id

    async def summary(self, *, from_date: date, to_date: date, tz: str) -> DashboardSummary:
        try:
            zone = ZoneInfo(tz)
        except (ZoneInfoNotFoundError, ValueError) as exc:
            raise AppError(
                code="invalid_timezone", message="Unknown timezone", status_code=422
            ) from exc
        if from_date > to_date:
            raise AppError(code="invalid_range", message="'from' must be <= 'to'", status_code=422)

        start = datetime.combine(from_date, time.min, zone).astimezone(UTC)
        end = datetime.combine(to_date + timedelta(days=1), time.min, zone).astimezone(UTC)
        in_window = (
            Sale.business_id == self.business_id,
            Sale.created_at >= start,
            Sale.created_at < end,
        )

        revenue, discount, sale_count = (
            await self.session.execute(
                select(
                    func.coalesce(func.sum(Sale.total), 0),
                    func.coalesce(func.sum(Sale.discount_total), 0),
                    func.count(Sale.id),
                ).where(*in_window)
            )
        ).one()

        cogs = await self.session.scalar(
            select(func.coalesce(func.sum(SaleItem.unit_cost * SaleItem.quantity), 0))
            .select_from(SaleItem)
            .join(Sale, SaleItem.sale_id == Sale.id)
            .where(*in_window)
        )

        expenses = await self.session.scalar(
            select(func.coalesce(func.sum(Expense.amount), 0)).where(
                Expense.business_id == self.business_id,
                Expense.spent_on >= from_date,
                Expense.spent_on <= to_date,
            )
        )

        revenue = Decimal(revenue)
        cogs = Decimal(cogs)
        expenses = Decimal(expenses)
        gross_profit = revenue - cogs
        net_profit = gross_profit - expenses
        avg_ticket = revenue / sale_count if sale_count else Decimal("0")
        gross_margin = (gross_profit / revenue) if revenue > 0 else Decimal("0")

        return DashboardSummary(
            from_date=from_date,
            to_date=to_date,
            tz=tz,
            revenue=q2(revenue),
            cogs=q2(cogs),
            gross_profit=q2(gross_profit),
            expenses=q2(expenses),
            net_profit=q2(net_profit),
            discount_total=q2(Decimal(discount)),
            sale_count=sale_count,
            avg_ticket=q2(avg_ticket),
            gross_margin=gross_margin.quantize(Decimal("0.0001")),
        )
