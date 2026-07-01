from datetime import UTC, date, datetime, time, timedelta
from uuid import UUID

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_session
from app.core.deps import get_current_business_id, get_current_user
from app.core.errors import AppError
from app.models.payment import Payment
from app.models.sale import Sale
from app.models.sale_item import SaleItem
from app.models.user import User
from app.schemas.common import Page
from app.schemas.sale import (
    PaymentOut,
    SaleDetailOut,
    SaleIn,
    SaleItemOut,
    SaleOut,
)
from app.services.sale_service import SaleService

router = APIRouter(prefix="/sales", tags=["sales"])


def _service(
    user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> SaleService:
    return SaleService(session, user.business_id, user.id)


@router.post("", response_model=SaleOut, status_code=status.HTTP_201_CREATED)
async def create_sale(data: SaleIn, service: SaleService = Depends(_service)) -> SaleOut:
    sale = await service.checkout(data)
    return SaleOut.model_validate(sale)


@router.get("", response_model=Page[SaleOut])
async def list_sales(
    business_id: UUID = Depends(get_current_business_id),
    session: AsyncSession = Depends(get_session),
    search: str | None = Query(default=None, max_length=200),
    from_: date | None = Query(default=None, alias="from"),
    to: date | None = Query(default=None),
    page: int = Query(default=1, ge=1),
    limit: int = Query(default=20, ge=1, le=100),
) -> Page[SaleOut]:
    base = select(Sale).where(Sale.business_id == business_id)
    if search:
        term = f"%{search}%"
        base = base.where(or_(Sale.sale_number.ilike(term), Sale.customer_name.ilike(term)))
    if from_ is not None:
        base = base.where(Sale.created_at >= datetime.combine(from_, time.min, UTC))
    if to is not None:
        # Inclusive upper bound: anything before the start of the next day.
        end = datetime.combine(to + timedelta(days=1), time.min, UTC)
        base = base.where(Sale.created_at < end)

    total = await session.scalar(select(func.count()).select_from(base.order_by(None).subquery()))
    rows = await session.scalars(
        base.order_by(Sale.created_at.desc()).offset((page - 1) * limit).limit(limit)
    )
    return Page(items=[SaleOut.model_validate(s) for s in rows], page=page, total=int(total or 0))


@router.get("/{sale_id}", response_model=SaleDetailOut)
async def get_sale(
    sale_id: UUID,
    business_id: UUID = Depends(get_current_business_id),
    session: AsyncSession = Depends(get_session),
) -> SaleDetailOut:
    sale = await session.scalar(
        select(Sale).where(Sale.id == sale_id, Sale.business_id == business_id)
    )
    if sale is None:
        raise AppError(code="not_found", message="Sale not found", status_code=404)
    items = await session.scalars(select(SaleItem).where(SaleItem.sale_id == sale_id))
    payments = await session.scalars(select(Payment).where(Payment.sale_id == sale_id))
    return SaleDetailOut(
        **SaleOut.model_validate(sale).model_dump(),
        items=[SaleItemOut.model_validate(i) for i in items],
        payments=[PaymentOut.model_validate(p) for p in payments],
    )
