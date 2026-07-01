from typing import Literal
from uuid import UUID

from fastapi import APIRouter, Depends, Query, Response, UploadFile, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.clock import utcnow
from app.core.config import get_settings
from app.core.database import get_session
from app.core.deps import get_current_business_id, get_current_user
from app.core.errors import AppError
from app.models.user import User
from app.repositories.product_repo import ProductRepository
from app.schemas.common import Page
from app.schemas.product import (
    BulkProductsIn,
    ImageUploadOut,
    ProductIn,
    ProductOut,
)
from app.services.product_service import ProductService
from app.services.storage_service import StorageService, build_s3_client
from app.services.sync_service import record_tombstone

router = APIRouter(prefix="/products", tags=["products"])


def _repo(
    business_id: UUID = Depends(get_current_business_id),
    session: AsyncSession = Depends(get_session),
) -> ProductRepository:
    return ProductRepository(session, business_id)


def _service(
    user: User = Depends(get_current_user),
    session: AsyncSession = Depends(get_session),
) -> ProductService:
    return ProductService(session, user.business_id, user.id)


def get_storage_service() -> StorageService:
    return StorageService(build_s3_client(), get_settings().s3_bucket)


@router.get("", response_model=Page[ProductOut])
async def list_products(
    repo: ProductRepository = Depends(_repo),
    search: str | None = Query(default=None, max_length=200),
    type: Literal["all", "products", "services"] = "all",
    page: int = Query(default=1, ge=1),
    limit: int = Query(default=20, ge=1, le=100),
) -> Page[ProductOut]:
    items, total = await repo.search(search=search, product_type=type, page=page, limit=limit)
    return Page(items=[ProductOut.model_validate(p) for p in items], page=page, total=total)


@router.get("/by-barcode/{code}", response_model=ProductOut)
async def get_by_barcode(code: str, repo: ProductRepository = Depends(_repo)) -> ProductOut:
    product = await repo.by_barcode(code)
    if product is None:
        raise AppError(code="not_found", message="Product not found", status_code=404)
    return ProductOut.model_validate(product)


@router.get("/{product_id}", response_model=ProductOut)
async def get_product(product_id: UUID, repo: ProductRepository = Depends(_repo)) -> ProductOut:
    product = await repo.get(product_id)
    if product is None:
        raise AppError(code="not_found", message="Product not found", status_code=404)
    return ProductOut.model_validate(product)


@router.post("", response_model=ProductOut, status_code=status.HTTP_201_CREATED)
async def create_product(
    data: ProductIn, service: ProductService = Depends(_service)
) -> ProductOut:
    product = await service.upsert(data)
    return ProductOut.model_validate(product)


@router.put("/{product_id}", response_model=ProductOut)
async def update_product(
    product_id: UUID, data: ProductIn, service: ProductService = Depends(_service)
) -> ProductOut:
    # Path id wins so the body can't retarget another product.
    data.id = product_id
    if await service.repo.get(product_id) is None:
        raise AppError(code="not_found", message="Product not found", status_code=404)
    product = await service.upsert(data)
    return ProductOut.model_validate(product)


@router.delete("/{product_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_product(
    product_id: UUID,
    repo: ProductRepository = Depends(_repo),
) -> Response:
    product = await repo.soft_delete(product_id)
    if product is None:
        raise AppError(code="not_found", message="Product not found", status_code=404)
    await record_tombstone(repo.session, repo.business_id, "products", product_id)
    await repo.session.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/bulk", response_model=list[ProductOut], status_code=status.HTTP_201_CREATED)
async def bulk_create(
    data: BulkProductsIn, service: ProductService = Depends(_service)
) -> list[ProductOut]:
    products = await service.bulk_upsert(data.products)
    return [ProductOut.model_validate(p) for p in products]


@router.post("/{product_id}/image", response_model=ImageUploadOut)
async def upload_image(
    product_id: UUID,
    file: UploadFile,
    repo: ProductRepository = Depends(_repo),
    storage: StorageService = Depends(get_storage_service),
) -> ImageUploadOut:
    product = await repo.get(product_id)
    if product is None:
        raise AppError(code="not_found", message="Product not found", status_code=404)
    data = await file.read()
    key, url = storage.upload_image(data, file.content_type or "application/octet-stream")
    product.image_url = key  # private bucket key; responses serve a fresh signed URL
    product.updated_at = utcnow()
    repo.session.add(product)
    await repo.session.commit()
    return ImageUploadOut(key=key, url=url)
