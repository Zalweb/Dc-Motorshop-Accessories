"""Alembic environment — async engine, autogenerate against SQLModel metadata.

The DB URL comes from application Settings (env), never from alembic.ini. All SQLModel
table modules are imported so `target_metadata` sees every table for autogeneration.
"""

import asyncio
from logging.config import fileConfig

# Import side-effect: registers all tables on SQLModel.metadata for autogenerate.
import app.models  # noqa: F401
from alembic import context
from app.core.config import get_settings
from sqlalchemy.engine import Connection
from sqlalchemy.ext.asyncio import async_engine_from_config
from sqlmodel import SQLModel

config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# Prefer a URL injected by the caller (e.g. tests against a throwaway container);
# otherwise fall back to application settings (env). Never hardcode a URL in alembic.ini.
_db_url = config.get_main_option("sqlalchemy.url") or get_settings().database_url
config.set_main_option("sqlalchemy.url", _db_url)

target_metadata = SQLModel.metadata


def run_migrations_offline() -> None:
    context.configure(
        url=_db_url,
        target_metadata=target_metadata,
        literal_binds=True,
        compare_type=True,
        compare_server_default=True,
        dialect_opts={"paramstyle": "named"},
    )
    with context.begin_transaction():
        context.run_migrations()


def _do_run_migrations(connection: Connection) -> None:
    context.configure(
        connection=connection,
        target_metadata=target_metadata,
        compare_type=True,
        compare_server_default=True,
    )
    with context.begin_transaction():
        context.run_migrations()


async def run_migrations_online() -> None:
    connectable = async_engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        future=True,
    )
    async with connectable.connect() as connection:
        await connection.run_sync(_do_run_migrations)
    await connectable.dispose()


if context.is_offline_mode():
    run_migrations_offline()
else:
    asyncio.run(run_migrations_online())
