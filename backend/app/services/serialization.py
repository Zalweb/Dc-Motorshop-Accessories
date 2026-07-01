"""Row <-> JSON helpers shared by backup and sync.

SQLModel `table=True` models skip Pydantic validation, so a snapshot's ISO strings would
reach the driver untyped. `dict_to_model` coerces each value back to its column's Python
type; `row_to_dict` produces JSON-safe output.
"""

from datetime import date, datetime
from decimal import Decimal
from typing import Any
from uuid import UUID

import sqlalchemy as sa
from fastapi.encoders import jsonable_encoder
from sqlalchemy.dialects.postgresql import UUID as PgUUID
from sqlmodel import SQLModel


def row_to_dict(obj: SQLModel) -> dict[str, Any]:
    columns = obj.__table__.columns.keys()
    return jsonable_encoder({col: getattr(obj, col) for col in columns})


def coerce(column_type, value):
    if value is None:
        return None
    if isinstance(column_type, PgUUID):
        return UUID(value) if isinstance(value, str) else value
    if isinstance(column_type, sa.DateTime):
        return datetime.fromisoformat(value) if isinstance(value, str) else value
    if isinstance(column_type, sa.Date):
        return date.fromisoformat(value) if isinstance(value, str) else value
    if isinstance(column_type, sa.Numeric):
        return Decimal(str(value))
    return value


def dict_to_model(model: type[SQLModel], row: dict) -> SQLModel:
    columns = model.__table__.columns
    coerced = {col: coerce(columns[col].type, row[col]) for col in columns.keys() if col in row}
    return model(**coerced)
