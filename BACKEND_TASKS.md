# Backend Task Plan — DC Motorshop & Accessories

> Actionable, ordered build checklist expanding [BACKEND_PLAN.md](BACKEND_PLAN.md) milestones M0–M9.
> Each task names the files to create and its **acceptance criteria (AC)**. Tick boxes as you go.
> Stack: FastAPI · SQLModel · Alembic · PostgreSQL · Redis · S3-compatible storage. API base `/v1`.

## Proposed project structure
```
backend/
  app/
    main.py                      # app factory, middleware, router mount
    core/
      config.py                  # pydantic-settings; reads env
      database.py                # async engine + session
      security.py                # Argon2id, JWT encode/decode
      deps.py                    # current_user / current_business (tenant scope)
      rate_limit.py              # Redis-backed limiter
      errors.py                  # error envelope + handlers
      logging.py                 # structured, secret-scrubbing
    models/                      # SQLModel tables (mirror DATABASE.md)
    schemas/                     # Pydantic request/response (extra='forbid')
    repositories/                # tenant-scoped data access (base enforces business_id)
    services/                    # auth, sale (recompute), dashboard, backup
    api/v1/
      router.py                  # aggregates routers
      health.py auth.py business.py categories.py products.py
      sales.py expenses.py dashboard.py backup.py sync.py
  migrations/                    # alembic
  tests/
  alembic.ini  pyproject.toml  Dockerfile  docker-compose.yml  .env.example
  .github/workflows/ci.yml
```

---

## M0 — Scaffold & CI
**Goal:** runnable empty API with tooling and security headers.
- [x] `pyproject.toml` — deps: fastapi, uvicorn, sqlmodel, alembic, asyncpg, pydantic-settings, argon2-cffi, pyjwt, redis, boto3, python-multipart; dev: pytest, httpx, pip-audit, bandit, ruff.
- [x] `app/core/config.py` — `Settings` from env (`DATABASE_URL`, `JWT_*`, `S3_*`, `REDIS_URL`, `ENV`). No secrets in code.
- [x] `app/core/database.py` — async engine + session dependency.
- [x] `app/core/errors.py` — exception handlers → `{ "error": { code, message } }`, no stack traces.
- [x] `app/main.py` — app factory; middleware: HTTPS redirect, security headers, CORS (deny-by-default), request-id.
- [x] `app/api/v1/health.py` — `GET /v1/health` → `{status:"ok"}`.
- [x] `Dockerfile` (non-root user) + `docker-compose.yml` (api, postgres, redis, minio).
- [x] `.env.example` + ensure `.env` gitignored.
- [x] `alembic.ini` + `migrations/env.py` wired to models metadata.
- [x] `.github/workflows/ci.yml` — ruff + bandit + pip-audit + pytest.
- **AC:** ✅ `docker compose up` serves `GET /v1/health` 200 over port 8000 (verified live); CI green (ruff + bandit + pip-audit + pytest); security headers present in response.

## M1 — Auth (secure)
**Goal:** owner can register/login; tokens issued; abuse-resistant.
- [x] `models/business.py`, `models/user.py` (mirror DATABASE.md; UUID v7 PKs, `role`, `onboarding_complete`).
- [x] First Alembic migration: businesses + users (+ audit_log table). (`0001_m1`; incl. `onboarding_checklist` so model/DB agree.)
- [x] `core/security.py` — Argon2id hash/verify; JWT encode/decode (access 15 min, refresh 30 d, `jti`).
- [x] `services/auth_service.py` — register (creates business + owner), login, refresh (rotate + reuse-detect via Redis), logout (revoke).
- [x] `schemas/auth.py` — Register/Login/Token/RefreshIn (`extra='forbid'`, length caps).
- [x] `api/v1/auth.py` — `POST /register`, `POST /login`, `POST /refresh`, `POST /logout`, `GET /me`, `PATCH /me`.
- [x] `core/rate_limit.py` + apply to login (5/15min/account, generic errors, no enumeration).
- [x] Audit-log writes on register/login/logout/refresh-reuse.
- [x] Tests: register→login→refresh→logout happy path; wrong password; reused refresh revokes family; rate-limit triggers. (20 tests)
- **AC:** ✅ register owner → access+refresh; invalid/missing tokens 401; refresh rotation + family-reuse detection test-verified; passwords Argon2id-only (verified in DB).

## M2 — Tenant scoping + Business + Categories + Checklist
**Goal:** every query is shop-scoped; onboarding data persists.
- [x] `core/deps.py` — `current_user`, `current_business` from JWT `bid`; **reject any `business_id` in input** (Pydantic `extra='forbid'`).
- [x] `repositories/base.py` — base repo auto-applies `WHERE business_id = :bid` (PEP 695 generic).
- [x] `models/category.py`; migration `0002_m2`: categories. (`onboarding_checklist` already in `0001_m1`.)
- [x] `api/v1/business.py` — `GET /business`, `PUT /business`, `GET/PUT /business/checklist`. (No `type` field — motorcycle-shop only.)
- [x] `api/v1/categories.py` — `GET/POST/DELETE /categories` (tenant-scoped; unique name per business via `NULLS NOT DISTINCT` index; idempotent upsert by client UUID).
- [x] Tests: user A cannot read/modify user B's business or categories (cross-tenant 404/empty); checklist round-trips. (12 tests)
- **AC:** ✅ no endpoint accepts `business_id` from client (422 if sent); cross-tenant list/delete don't leak; categories + checklist CRUD scoped to the shop.

## M3 — Products + images + bulk + barcode + inventory ledger
**Goal:** full catalog with stock as a ledger.
- [x] `models/brand.py`, `models/product.py`, `models/inventory_movement.py`; migration `0003_m3` (+ `sync_stock_on_hand` trigger, partial unique barcode index, active-products index). *(product_variants/addons + `variant_id` deferred — not in task scope / unused by frontend.)*
- [x] `repositories/product_repo.py` — list (search, type filter, pagination), get, soft-delete, by-barcode.
- [x] `services/inventory_service.py` — append movement; trigger recomputes `stock_on_hand` (reasons: initial/adjustment). `services/product_service.py` — idempotent upsert + ledger reconciliation.
- [x] `api/v1/products.py` — `GET /products?search=&type=&page=`, `GET /products/{id}`, `POST /products` (idempotent), `PUT /products/{id}`, `DELETE /products/{id}` (soft), `GET /products/by-barcode/{code}`, `POST /products/bulk`.
- [x] `services/storage_service.py` + `POST /products/{id}/image` — MIME + magic-byte + 5MB checks; random S3 key; returns signed URL. *(EXIF strip deferred — needs Pillow.)*
- [x] Tests: initial movement emitted; barcode lookup; bulk idempotent; image rejects non-image/spoofed/oversize; search + filter + pagination. (21 tests)
- **AC:** ✅ stock derivable from `inventory_movements` and matches `stock_on_hand` (test); re-POST same UUID doesn't duplicate; uploads enforce type/size + random keys.

## M4 — Sales checkout + history
**Goal:** record sales with trustworthy money + stock.
- [x] `models/customer.py`, `models/workflow_stage.py`, `models/sale.py`, `models/sale_item.py`, `models/payment.py`; migration `0004_m4`.
- [x] `services/sale_service.py` — checkout: **server recomputes** subtotal/total from server-side unit prices; writes sale + items + one negative `sale` movement per stocked line; single transaction; idempotent by sale UUID; auto sale_number `S-000N`.
- [x] `api/v1/sales.py` — `POST /sales`, `GET /sales?search=&from=&to=&page=`, `GET /sales/{id}`.
- [x] Tests: recompute ignores client `unit_price`; stock decremented via movements; duplicate UUID no-op (single sale, stock charged once); search by number/customer; date filter; cross-tenant product rejected. (14 tests)
- **AC:** ✅ client totals never accepted/persisted (server-recomputed); selling N units writes a −N movement; sales list filters by date + text.

## M5 — Expenses + Dashboard summary
**Goal:** finance metrics match the app, timezone-correct.
- [x] `models/expense.py`, `models/expense_category.py`; migration `0005_m5`.
- [x] `api/v1/expenses.py` — `POST /expenses` (idempotent), `GET /expenses?from=&to=&page=`.
- [x] `services/dashboard_service.py` — revenue, COGS (Σ unit_cost×qty), gross/net profit, expenses, avg ticket, discount, gross margin for a range in **Asia/Manila** (sales by tz-derived UTC bounds; expenses by `spent_on`).
- [x] `api/v1/dashboard.py` — `GET /dashboard/summary?from=&to=&tz=Asia/Manila`.
- [x] Tests: metric math on a fixed dataset (revenue/COGS/gross/net/avg/margin); Manila-boundary include/exclude. (18 tests; added `tzdata` runtime dep for Windows/slim images.)
- **AC:** ✅ summary numbers equal the expected computation for the same data; tz boundary correct (a 17:00 UTC sale counts on the next Manila day).

## M6 — Backup / restore  *(Phase 1 complete)*
**Goal:** a shop's data is safe in the cloud and restorable.
- [x] `services/backup_service.py` — export full tenant snapshot (all owned tables for `bid` + sale children); import = idempotent, FK-ordered upsert (categories two-pass) with type coercion; tenant-isolated (foreign ids skipped).
- [x] `api/v1/backup.py` — `GET /backup/export`, `POST /backup/import`. Audit-logged.
- [x] Tests: export → delete → import restores; import idempotent (re-run no dupes); cannot import into another tenant; origin tenant untouched. (9 tests)
- **AC:** ✅ round-trip yields identical rows; re-importing changes nothing; tenant-isolated. Migrations verified reversible (upgrade→downgrade→upgrade clean).

## M7 — Flutter client integration  *(done)*
- [x] **UUID migration** of Isar models — added a server-aligned `uid` (UUID v7) + sync metadata (`updatedAt`, `isDirty`) to every collection; Isar's int `Id` kept as a local surrogate (Isar requires an int PK). Regenerated via build_runner. `lib/core/utils/uuid.dart`.
- [x] `lib/core/api/api_client.dart` (Dio) — base URL, auth interceptor, 401→refresh-and-retry (bare Dio, no recursion), error mapping (`ApiException`).
- [x] Tokens in `flutter_secure_storage` via `SecureTokenStore` (`TokenStore` interface for testability).
- [x] Repositories write local → mark dirty (enqueue); `SyncService` reconciles. Offline-first preserved; auth is online-first with offline fallback.
- [x] Wire backup: "Sync now" + "Restore from cloud" (`/backup/export`) in More screen.
- [x] Image upload on product push → `POST /products/{id}/image`, stores returned URL (in sync, after the product exists server-side).
- [x] Tests: api_client refresh-retry (3), ApiException network/envelope mapping (3), uuid (3); offline write preserved via network-error fallback.
- **AC:** ✅ app works offline unchanged; online register/login hit the API; backup/restore + sync work from the device; tokens in secure storage. (`flutter analyze` 0 errors; 13 tests pass.)

## M8 — Delta sync + conflict rules  *(Phase 2 — backend done)*
**Goal:** multi-device, mergeable.
- [x] `api/v1/sync.py` — `GET /sync/{table}?since=` (changes + tombstones), `POST /sync/{table}` (batch idempotent upsert). Migration `0006_m8` (`sync_tombstones`).
- [x] Conflict rules: catalog/config = last-write-wins by `updated_at`; `inventory_movements` = append-only; **sales/sale_items/payments are pull-only** (pushed via idempotent `POST /sales` so money is always server-recomputed). Tombstones recorded on category/product delete; `products.stock_on_hand` push-excluded (ledger stays authoritative).
- [x] Inventory oversell handling: **allow-negative-and-flag** (recommended) — checkout permits it; negative `stock_on_hand` is the flag.
- [x] `lib/core/sync/sync_service.dart` — dirty flags + `updatedAt`; push (categories/expenses/products via `/sync`, sales via `POST /sales`), pull deltas + tombstones, reconcile by `uid`. Triggers: post-login + on reconnect (`connectivity_sync.dart`) + manual.
- [x] Tests (backend, 14): pull changes/tombstones since timestamp; LWW skips older, applies newer; append-only never updates; non-pushable rejected; cross-tenant push skipped; stock not client-settable.
- **AC:** ✅ (backend) deletes propagate via tombstones; LWW + append-only enforced; no duplicate rows. Client convergence pending the Flutter sync service.

## M9 — Hardening & launch gate
- [x] **Security acceptance checklist** documented end-to-end with status → `backend/SECURITY.md` (all code-level items ✅; deployment/ops items marked).
- [x] **Global per-IP rate limit** (600/min) across all `/v1` endpoints, in addition to login lockout (`core/rate_limit.global_rate_limit`; 2 tests).
- [x] **Restore runbook** documented (`backend/SECURITY.md`); migrations verified reversible on PG16.
- [ ] Load test key endpoints (login, products list, checkout) — **ops**, run against a deployed env.
- [ ] DB restore drill from automated backup — **ops**, per runbook.
- [ ] Pen-test pass: authz/tenant isolation, rate limits, upload abuse, token replay — **ops**.
- **AC:** code-level §10 items ✅ and documented; load/restore/pen-test are deployment-time activities.

---

## Decisions to confirm before coding
1. ✅ **Schema addition** — `businesses.onboarding_checklist jsonb` added to DATABASE.md + ERD. (No `business_type` column — app is motorcycle-shop only.)
2. **Inventory oversell rule** (needed in M8) — allow-negative-and-flag *(recommended)* vs reject-on-sync.
3. **Hosting pick** — concrete PaaS + Postgres + bucket provider (e.g. Render + Render Postgres + Cloudflare R2) so M0/M8 deploy steps are exact.

## Suggested sequencing
Phase 1 = **M0 → M6** (usable backup/restore). Phase 2 = **M7 → M9**.
M7 (client) can start in parallel with M5/M6 once auth (M1) is stable.
