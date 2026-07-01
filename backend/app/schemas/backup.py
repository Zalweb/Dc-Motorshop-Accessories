from typing import Any

from pydantic import Field

from app.schemas.base import StrictModel


class BackupImportIn(StrictModel):
    version: int = 1
    # business_id in the payload is informational only — import always targets the JWT's
    # business; this field is never used to choose a tenant.
    business_id: str | None = None
    exported_at: str | None = None
    tables: dict[str, list[dict[str, Any]]] = Field(default_factory=dict)


class BackupImportOut(StrictModel):
    imported: dict[str, int]
