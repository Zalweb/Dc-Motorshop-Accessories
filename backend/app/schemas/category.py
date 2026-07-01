import uuid
from datetime import datetime

from pydantic import Field

from app.schemas.base import ORMModel, StrictModel


class CategoryIn(StrictModel):
    # Client may supply the UUID so create is an idempotent upsert (safe retries/sync).
    id: uuid.UUID | None = None
    name: str = Field(min_length=1, max_length=100)
    parent_id: uuid.UUID | None = None
    is_service: bool = False


class CategoryOut(ORMModel):
    id: uuid.UUID
    business_id: uuid.UUID
    parent_id: uuid.UUID | None
    name: str
    is_service: bool
    created_at: datetime
    updated_at: datetime
