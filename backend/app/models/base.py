"""Reusable column factories so every table matches DATABASE.md conventions.

Each factory returns a fresh `Column` (SQLAlchemy forbids sharing a Column across tables).
UUID v7 PKs, timezone-aware timestamps, NUMERIC(12,2) money — never float.
"""

import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import UUID as PgUUID


def id_column() -> sa.Column:
    return sa.Column(PgUUID(as_uuid=True), primary_key=True)


def fk_column(
    target: str, *, ondelete: str, nullable: bool = True, index: bool = False
) -> sa.Column:
    return sa.Column(
        PgUUID(as_uuid=True),
        sa.ForeignKey(target, ondelete=ondelete),
        nullable=nullable,
        index=index,
    )


def created_column() -> sa.Column:
    return sa.Column(sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now())


def updated_column() -> sa.Column:
    return sa.Column(sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now())


def deleted_column() -> sa.Column:
    return sa.Column(sa.DateTime(timezone=True), nullable=True)


def money_column(*, nullable: bool = False, default: str | None = "0") -> sa.Column:
    server_default = sa.text(default) if default is not None else None
    return sa.Column(sa.Numeric(12, 2), nullable=nullable, server_default=server_default)
