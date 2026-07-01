from typing import Any

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_session
from app.core.deps import get_current_user
from app.models.user import User
from app.schemas.backup import BackupImportIn, BackupImportOut
from app.services.backup_service import BackupService

router = APIRouter(prefix="/backup", tags=["backup"])


def _service(
    user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> BackupService:
    return BackupService(session, user.business_id, user.id)


@router.get("/export")
async def export_backup(service: BackupService = Depends(_service)) -> dict[str, Any]:
    return await service.export()


@router.post("/import", response_model=BackupImportOut)
async def import_backup(
    data: BackupImportIn, service: BackupService = Depends(_service)
) -> BackupImportOut:
    counts = await service.import_(data.tables)
    return BackupImportOut(imported=counts)
