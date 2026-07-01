from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.clock import utcnow
from app.core.database import get_session
from app.core.deps import get_current_business
from app.models.business import Business
from app.schemas.business import (
    BusinessOut,
    BusinessUpdateIn,
    ChecklistOut,
    ChecklistUpdateIn,
)

router = APIRouter(prefix="/business", tags=["business"])


@router.get("", response_model=BusinessOut)
async def get_business(business: Business = Depends(get_current_business)) -> BusinessOut:
    return BusinessOut.model_validate(business)


@router.put("", response_model=BusinessOut)
async def update_business(
    data: BusinessUpdateIn,
    business: Business = Depends(get_current_business),
    session: AsyncSession = Depends(get_session),
) -> BusinessOut:
    payload = data.model_dump(exclude_unset=True)
    for field, value in payload.items():
        setattr(business, field, value)
    if payload:
        business.updated_at = utcnow()
    session.add(business)
    await session.commit()
    await session.refresh(business)
    return BusinessOut.model_validate(business)


@router.get("/checklist", response_model=ChecklistOut)
async def get_checklist(business: Business = Depends(get_current_business)) -> ChecklistOut:
    return ChecklistOut(items=business.onboarding_checklist)


@router.put("/checklist", response_model=ChecklistOut)
async def update_checklist(
    data: ChecklistUpdateIn,
    business: Business = Depends(get_current_business),
    session: AsyncSession = Depends(get_session),
) -> ChecklistOut:
    # De-duplicate while preserving order; the checklist is a set of completed item ids.
    business.onboarding_checklist = list(dict.fromkeys(data.items))
    business.updated_at = utcnow()
    session.add(business)
    await session.commit()
    await session.refresh(business)
    return ChecklistOut(items=business.onboarding_checklist)
