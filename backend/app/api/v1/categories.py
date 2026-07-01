from uuid import UUID

from fastapi import APIRouter, Depends, Response, status
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_session
from app.core.deps import get_current_business_id
from app.core.errors import AppError
from app.repositories.category_repo import CategoryRepository
from app.schemas.category import CategoryIn, CategoryOut
from app.services.sync_service import record_tombstone

router = APIRouter(prefix="/categories", tags=["categories"])


def _repo(
    business_id: UUID = Depends(get_current_business_id),
    session: AsyncSession = Depends(get_session),
) -> CategoryRepository:
    return CategoryRepository(session, business_id)


@router.get("", response_model=list[CategoryOut])
async def list_categories(repo: CategoryRepository = Depends(_repo)) -> list[CategoryOut]:
    rows = await repo.list()
    return [CategoryOut.model_validate(row) for row in rows]


@router.post("", response_model=CategoryOut, status_code=status.HTTP_201_CREATED)
async def create_category(
    data: CategoryIn, repo: CategoryRepository = Depends(_repo)
) -> CategoryOut:
    if data.parent_id is not None and await repo.get(data.parent_id) is None:
        raise AppError(code="invalid_parent", message="Parent category not found", status_code=422)
    try:
        category = await repo.upsert(
            id_=data.id, name=data.name, parent_id=data.parent_id, is_service=data.is_service
        )
        await repo.session.commit()
    except IntegrityError as exc:
        await repo.session.rollback()
        raise AppError(
            code="duplicate_category",
            message="A category with this name already exists",
            status_code=409,
        ) from exc
    await repo.session.refresh(category)
    return CategoryOut.model_validate(category)


@router.delete("/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_category(
    category_id: UUID, repo: CategoryRepository = Depends(_repo)
) -> Response:
    deleted = await repo.delete(category_id)
    if not deleted:
        raise AppError(code="not_found", message="Category not found", status_code=404)
    await record_tombstone(repo.session, repo.business_id, "categories", category_id)
    await repo.session.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
