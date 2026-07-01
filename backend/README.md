# DC Motorshop & Accessories — Backend

Secured FastAPI + PostgreSQL backend for cloud sync + backup of the offline-first Flutter
app. Canonical schema: [../DATABASE.md](../DATABASE.md). Plan: [../BACKEND_PLAN.md](../BACKEND_PLAN.md).
Task checklist: [../BACKEND_TASKS.md](../BACKEND_TASKS.md).

API base path: `/v1`.

## Stack
FastAPI (Python 3.12) · SQLModel + Alembic · PostgreSQL 16 · Redis · S3-compatible storage.

## Local development

Requires [uv](https://docs.astral.sh/uv/) and Docker.

```bash
cd backend
cp .env.example .env            # fill secrets; .env is gitignored

# Run the full stack (api + postgres + redis + minio)
docker compose up --build       # GET http://localhost:8000/v1/health

# Or run the API directly against local services
uv sync --all-groups
uv run uvicorn app.main:app --reload
```

## Quality gates

```bash
uv run ruff check .             # lint
uv run bandit -c pyproject.toml -r app   # security static analysis
uv run pip-audit                # dependency CVEs
uv run pytest -q                # tests
```

## Migrations (Alembic)

```bash
uv run alembic revision --autogenerate -m "message"   # never edit an applied migration
uv run alembic upgrade head
```

## Layout

```
app/
  main.py            app factory + middleware (security headers, CORS, request-id)
  core/              config, database, security, deps, errors, logging, middleware
  models/            SQLModel tables (mirror DATABASE.md)
  schemas/           Pydantic v2 request/response (extra='forbid')
  repositories/      tenant-scoped data access (base enforces business_id)
  services/          auth, sale (recompute), dashboard, backup
  api/v1/            routers mounted under /v1
migrations/          alembic
tests/               pytest + httpx
```
