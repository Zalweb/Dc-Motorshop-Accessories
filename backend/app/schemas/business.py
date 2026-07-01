import uuid
from datetime import datetime

from pydantic import Field

from app.schemas.base import ORMModel, StrictModel


class BusinessOut(ORMModel):
    id: uuid.UUID
    name: str
    logo_url: str | None
    address: str | None
    phone: str | None
    currency: str
    theme_color: str
    onboarding_checklist: list[str]
    expense_avg_months: int
    low_stock_threshold_days: int | None
    created_at: datetime
    updated_at: datetime


class BusinessUpdateIn(StrictModel):
    name: str | None = Field(default=None, min_length=1, max_length=200)
    address: str | None = Field(default=None, max_length=500)
    phone: str | None = Field(default=None, max_length=30)
    currency: str | None = Field(default=None, min_length=3, max_length=3)
    theme_color: str | None = Field(default=None, max_length=30)
    expense_avg_months: int | None = Field(default=None, ge=1, le=24)
    low_stock_threshold_days: int | None = Field(default=None, ge=0, le=365)


class ChecklistOut(StrictModel):
    items: list[str]


class ChecklistUpdateIn(StrictModel):
    items: list[str] = Field(max_length=50)
