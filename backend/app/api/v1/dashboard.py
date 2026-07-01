from datetime import date
from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_session
from app.core.deps import get_current_business_id
from app.schemas.expense import DashboardSummary
from app.services.dashboard_service import DashboardService

router = APIRouter(prefix="/dashboard", tags=["dashboard"])


@router.get("/summary", response_model=DashboardSummary)
async def summary(
    from_: date = Query(alias="from"),
    to: date = Query(),
    tz: str = Query(default="Asia/Manila", max_length=64),
    business_id: UUID = Depends(get_current_business_id),
    session: AsyncSession = Depends(get_session),
) -> DashboardSummary:
    service = DashboardService(session, business_id)
    return await service.summary(from_date=from_, to_date=to, tz=tz)
