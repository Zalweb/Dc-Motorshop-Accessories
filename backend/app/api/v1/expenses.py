from datetime import date

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.clock import utcnow
from app.core.database import get_session
from app.core.deps import get_current_user
from app.core.errors import AppError
from app.models.expense import Expense
from app.models.expense_category import ExpenseCategory
from app.models.user import User
from app.schemas.common import Page
from app.schemas.expense import ExpenseIn, ExpenseOut

router = APIRouter(prefix="/expenses", tags=["expenses"])


@router.post("", response_model=ExpenseOut, status_code=status.HTTP_201_CREATED)
async def create_expense(
    data: ExpenseIn,
    user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> ExpenseOut:
    if data.category_id is not None:
        owns = await session.scalar(
            select(ExpenseCategory.id).where(
                ExpenseCategory.id == data.category_id,
                ExpenseCategory.business_id == user.business_id,
            )
        )
        if owns is None:
            raise AppError(
                code="invalid_category", message="Expense category not found", status_code=422
            )

    existing = None
    if data.id is not None:
        existing = await session.scalar(
            select(Expense).where(
                Expense.id == data.id, Expense.business_id == user.business_id
            )
        )

    if existing is not None:
        existing.label = data.label
        existing.amount = data.amount
        existing.category_id = data.category_id
        existing.note = data.note
        if data.spent_on is not None:
            existing.spent_on = data.spent_on
        existing.updated_at = utcnow()
        expense = existing
    else:
        expense = Expense(
            business_id=user.business_id,
            label=data.label,
            amount=data.amount,
            category_id=data.category_id,
            note=data.note,
            created_by=user.id,
            **({"spent_on": data.spent_on} if data.spent_on is not None else {}),
        )
        if data.id is not None:
            expense.id = data.id

    session.add(expense)
    await session.commit()
    await session.refresh(expense)
    return ExpenseOut.model_validate(expense)


@router.get("", response_model=Page[ExpenseOut])
async def list_expenses(
    user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
    from_: date | None = Query(default=None, alias="from"),
    to: date | None = Query(default=None),
    page: int = Query(default=1, ge=1),
    limit: int = Query(default=20, ge=1, le=100),
) -> Page[ExpenseOut]:
    base = select(Expense).where(Expense.business_id == user.business_id)
    if from_ is not None:
        base = base.where(Expense.spent_on >= from_)
    if to is not None:
        base = base.where(Expense.spent_on <= to)

    total = await session.scalar(select(func.count()).select_from(base.order_by(None).subquery()))
    rows = await session.scalars(
        base.order_by(Expense.spent_on.desc()).offset((page - 1) * limit).limit(limit)
    )
    return Page(
        items=[ExpenseOut.model_validate(e) for e in rows], page=page, total=int(total or 0)
    )
