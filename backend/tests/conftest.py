"""Test harness: a throwaway Postgres (testcontainers) with migrations applied, plus an
in-memory fake Redis and a fake S3 client. The app's DB/Redis/storage dependencies are
overridden to point at them.

The container + migrations are session-scoped (slow, shared). The async engine is
function-scoped so it binds to each test's own event loop (asyncpg pools are loop-bound).
"""

# Import models so SQLModel.metadata knows every table (for TRUNCATE between tests).
import app.models  # noqa: F401
import fakeredis.aioredis
import pytest
from alembic import command
from alembic.config import Config
from app.api.v1.products import get_storage_service
from app.core.config import Settings
from app.core.database import get_session
from app.core.redis import get_redis
from app.main import create_app
from app.services.storage_service import StorageService
from httpx import ASGITransport, AsyncClient
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from sqlmodel import SQLModel
from testcontainers.postgres import PostgresContainer


class FakeS3Client:
    """Minimal in-memory stand-in for a boto3 S3 client (records puts, signs URLs)."""

    def __init__(self) -> None:
        self.objects: dict[str, bytes] = {}

    def put_object(self, *, Bucket, Key, Body, ContentType):  # noqa: N803 (boto3 kwarg names)
        self.objects[Key] = Body

    def generate_presigned_url(self, _operation, *, Params, ExpiresIn):  # noqa: N803
        return f"https://signed.example/{Params['Key']}?expires={ExpiresIn}"


@pytest.fixture(scope="session")
def database_url() -> str:
    with PostgresContainer("postgres:16") as pg:
        async_url = pg.get_connection_url().replace("+psycopg2", "+asyncpg")
        cfg = Config("alembic.ini")
        cfg.set_main_option("sqlalchemy.url", async_url)
        command.upgrade(cfg, "head")
        yield async_url


@pytest.fixture
async def engine(database_url: str):
    eng = create_async_engine(database_url)
    yield eng
    await eng.dispose()


@pytest.fixture
def session_factory(engine) -> async_sessionmaker[AsyncSession]:
    return async_sessionmaker(bind=engine, class_=AsyncSession, expire_on_commit=False)


@pytest.fixture(autouse=True)
async def _clean_db(engine):
    yield
    tables = ", ".join(t.name for t in reversed(SQLModel.metadata.sorted_tables))
    if tables:
        async with engine.begin() as conn:
            await conn.execute(text(f"TRUNCATE {tables} RESTART IDENTITY CASCADE"))


@pytest.fixture
def settings(database_url: str) -> Settings:
    return Settings(env="test", database_url=database_url, jwt_secret="test-secret")


@pytest.fixture
async def client(settings: Settings, session_factory):
    app = create_app(settings)
    fake_redis = fakeredis.aioredis.FakeRedis(decode_responses=True)
    fake_s3 = FakeS3Client()

    async def _session_override():
        async with session_factory() as session:
            yield session

    async def _redis_override():
        return fake_redis

    def _storage_override():
        return StorageService(fake_s3, "test-bucket")

    app.dependency_overrides[get_session] = _session_override
    app.dependency_overrides[get_redis] = _redis_override
    app.dependency_overrides[get_storage_service] = _storage_override

    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as ac:
        ac.redis = fake_redis  # exposed so tests can simulate expiry/clears
        yield ac
    await fake_redis.aclose()
