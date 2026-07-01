from datetime import datetime
from typing import Any
from uuid import UUID

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_session
from app.core.deps import get_current_business_id
from app.schemas.base import StrictModel
from app.services.sync_service import SyncService

router = APIRouter(prefix="/sync", tags=["sync"])


class SyncPushIn(StrictModel):
    rows: list[dict[str, Any]]


def _service(
    business_id: UUID = Depends(get_current_business_id),
    session: AsyncSession = Depends(get_session),
) -> SyncService:
    return SyncService(session, business_id)


@router.get("/{table}")
async def pull(
    table: str,
    since: datetime | None = Query(default=None),
    service: SyncService = Depends(_service),
) -> dict[str, Any]:
    return await service.pull(table, since)


@router.post("/{table}")
async def push(
    table: str, data: SyncPushIn, service: SyncService = Depends(_service)
) -> dict[str, int]:
    return await service.push(table, data.rows)
