# Backend Integration Plan (Secured) — DC Motorshop & Accessories

> **Goal.** Add a secure FastAPI + PostgreSQL backend that backs up and syncs the offline-first Flutter app's data to the cloud, covering **every feature in the current frontend**. Security is a first-class requirement, not an afterthought.
>
> **Canonical schema:** [DATABASE.md](DATABASE.md). **Frontend screens:** [SCREENS.md](SCREENS.md).

## Locked decisions
| Topic | Decision |
|---|---|
| Accounts | **Single owner** per shop now; JWT carries a `role` claim and the schema supports staff, so multi-staff is additive later (no rework). |
| Backend job | **Cloud sync + backup** for one shop — restorable on reinstall / new phone. |
| Rollout | **Phase 1:** secure auth + REST API + full backup/restore. **Phase 2:** bidirectional delta sync + conflict rules. |
| Hosting | **Managed PaaS** (Render/Railway/Fly) + **managed Postgres** + **S3-compatible bucket** for images. |

---

## 1. Stack

| Concern | Choice | Note |
|---|---|---|
| API | **FastAPI** (Python 3.12) | async, Pydantic v2 validation |
| ORM / models | **SQLModel** (or SQLAlchemy 2.0) + **Alembic** | typed models, versioned migrations |
| DB | **PostgreSQL 16+** | per DATABASE.md (UUID v7, NUMERIC money) |
| Auth | **JWT** (access + rotating refresh), **Argon2id** hashing | `python-jose`/`pyjwt` + `argon2-cffi` |
| Files | **S3-compatible** object storage + signed URLs | product/logo images |
| Cache / limits | **Redis** | rate limiting, refresh-token reuse detection |
| Validation | **Pydantic v2** schemas | strict, length-bounded |
| Tests | **pytest** + httpx | + `pip-audit`, `bandit` in CI |

API base path: **`/v1`**. All responses JSON. Consistent error envelope `{ "error": { "code", "message", "details?" } }` — **never leak stack traces**.

---

## 2. Security foundations (the core of "secured")

These apply to **every** endpoint and phase.

### Transport & headers
- **HTTPS/TLS only** (PaaS-terminated). Redirect HTTP→HTTPS. **HSTS** enabled.
- Security headers via middleware: `Strict-Transport-Security`, `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: no-referrer`, `Content-Security-Policy` (locked for any web surface).
- **CORS**: deny by default; allowlist only known origins (mobile app sends no Origin; lock down when a web dashboard is added).

### Authentication
- Passwords hashed with **Argon2id** (salt embedded). The local stub's salt+SHA-256 is **upgraded** server-side at first login/registration.
- **Access token**: JWT, short TTL (**15 min**), signed (RS256 or HS256 with rotated secret). Claims: `sub` (user id), `bid` (business id), `role`, `exp`, `jti`.
- **Refresh token**: opaque or JWT, **30 days, rotating**. On each refresh, issue a new one and invalidate the old; **detect reuse** (replayed old refresh → revoke the whole family = stolen-token defense). Store hashes in Redis/DB, never plaintext.
- Client stores tokens in **`flutter_secure_storage`** (Keystore/Keychain) — **not** SharedPreferences.
- **Logout** revokes the refresh token.
- **Password reset** (email link) is **deferred** (needs email infra) — documented as a later add.

### Authorization & tenant isolation
- Every owned table has `business_id`. **`business_id` is taken from the JWT (`bid`), never from the request body or query** — this prevents cross-shop data access (IDOR/BOLA).
- A shared dependency injects the authenticated user + business and scopes **every** query: enforce with a base repository that always adds `WHERE business_id = :bid`, and/or Postgres **Row-Level Security** as defense-in-depth.
- `role` claim gates privileged actions (owner-only today; staff perms later).

### Input handling
- All bodies validated by **Pydantic** schemas with explicit types, length caps, and ranges (e.g. `quantity > 0`, `amount > 0`, name ≤ 200 chars).
- **No raw SQL** — ORM/parameterized only (blocks SQL injection).
- Reject unknown fields (`model_config = ConfigDict(extra='forbid')`).

### Rate limiting & abuse
- Global rate limit per IP + per user (Redis).
- **Login**: stricter (e.g. 5 attempts / 15 min / account) + exponential backoff; generic error ("invalid username or password") to avoid user enumeration.
- Registration throttled; optional CAPTCHA if abused.

### File upload security
- Accept only image MIME types; verify **magic bytes**, not just extension; enforce **max size** (e.g. 5 MB).
- Store under **random keys** (UUID) in the bucket; **never** use the client filename (path-traversal defense). Strip EXIF.
- Serve via **time-limited signed URLs** or CDN; bucket is private.

### Operations
- Secrets only via **env / secret manager** (DB URL, JWT keys, S3 creds) — never committed. (`.gitignore` already excludes `.env`.)
- **Audit log** table for sensitive events (login, logout, password change, data export/import).
- Structured logging **without** secrets/passwords/tokens; scrub PII where feasible.
- CI: **`pip-audit`** (dependency CVEs) + **`bandit`** (static analysis) gate merges. Pin dependencies.
- DB backups: managed automated backups + tested restore.

---

## 3. Feature alignment — every frontend screen → API → tables

| Frontend screen / feature | Endpoints (`/v1`) | Tables |
|---|---|---|
| **Register** (1,2.jpg) | `POST /auth/register` | users, businesses |
| **Login** | `POST /auth/login` → access+refresh | users |
| Token refresh / logout | `POST /auth/refresh`, `POST /auth/logout` | (refresh store) |
| **Splash** (session check) | `GET /auth/me` | users |
| **Onboarding – set up shop** (logo + theme) | `PUT /business`, `POST /business/logo` | businesses |
| **Onboarding – review categories** | `GET/POST/DELETE /categories` | categories |
| **Onboarding – complete** (persist + mark done) | `PUT /business`, `PATCH /auth/me` (onboarding_complete) | businesses, users, categories |
| **Setup checklist** (8 items, progress) | `GET/PUT /business/checklist` | businesses (`onboarding_checklist` jsonb) |
| **Products list** (search, ALL/PRODUCTS/SERVICES, paginate) | `GET /products?search=&type=&page=` | products, brands, categories |
| **Add product** (image, barcode, details, pricing, stock) | `POST /products`, `POST /products/{id}/image` | products, brands, inventory_movements |
| Edit / delete product | `PUT /products/{id}`, `DELETE /products/{id}` (soft) | products |
| Barcode lookup (autofill) | `GET /products/by-barcode/{code}` | products |
| **Bulk add** (scan queue → save) | `POST /products/bulk` | products, inventory_movements |
| **Categories** screen (CRUD) | `GET/POST/DELETE /categories` | categories |
| **New Sale** (search, scan-to-add, cart, checkout) | `POST /sales` (server recomputes totals, writes movements) | sales, sale_items, inventory_movements |
| **Sales History** (search by #/customer, paginate) | `GET /sales?search=&from=&to=&page=`, `GET /sales/{id}` | sales, sale_items |
| **Dashboard** (revenue, COGS, gross/net, avg, discount, margin) | `GET /dashboard/summary?from=&to=&tz=Asia/Manila` | sales, sale_items, expenses |
| **Add expense** (dashboard) | `POST /expenses`, `GET /expenses` | expenses, expense_categories |
| **More / Profile** (account + business info) | `GET /auth/me`, `GET /business` | users, businesses |
| **Logout** | `POST /auth/logout` | (refresh store) |
| Invite team (optional, currently no-op) | **deferred** to multi-staff phase | users |

**Conventions:** cursor or page/limit pagination; list endpoints return `{ items, page, total }`; all mutating endpoints are **idempotent by client-supplied UUID id** (upsert), which is what makes retries and Phase-2 sync safe.

---

## 4. Phase 1 — Secure auth + REST + backup/restore

**Deliverables**
1. Auth module: register/login/refresh/logout/me, Argon2id, JWT, rate limiting, audit log.
2. Tenant-scoped CRUD for: business, categories, products (+image, +bulk, +barcode lookup), sales (checkout with server-side total recompute + stock movements), expenses, dashboard summary, checklist.
3. **Backup/restore** (the core P1 value for "sync + backup"):
   - `GET /backup/export` → full tenant snapshot (all tables for this `business_id`) as one signed payload.
   - `POST /backup/import` → idempotent upsert of a snapshot (used on reinstall / new device). Because PKs are client UUIDs, re-import is safe and non-duplicating.
4. **Money integrity:** server **recomputes** `subtotal/total` from line items and unit prices; client-sent totals are validated, not trusted. All money `NUMERIC(12,2)`; round half-up when ingesting the app's `double`.
5. **Stock:** every checkout and stock edit writes an `inventory_movements` row in the **same transaction**; `stock_on_hand` updated by trigger.

**Phase 1 = "your data is safe in the cloud and restorable."** Single device, last-writer is the device that pushed.

---

## 5. Phase 2 — Bidirectional delta sync + conflict rules

**Deliverables**
1. **Pull:** `GET /sync/{table}?since=<timestamp>` → rows changed since last sync (+ tombstones for deletes).
2. **Push:** `POST /sync/{table}` → batch idempotent **upserts** keyed by UUID id.
3. **Conflict policy per table:**
   - Catalog/config (products, categories, business): **last-write-wins** by `updated_at`.
   - **sales, payments, inventory_movements: append-only** — never updated, so they merge with zero conflict.
   - **Inventory reconciliation:** offline oversell is allowed but **flagged** (negative on-hand surfaces a reconciliation task) — the append-only ledger keeps it auditable. *(Confirm this business rule before building.)*
4. **Client sync service** (Flutter): per-record dirty flag + `updated_at`; push on reconnect, pull deltas, resolve, mark clean. Background + on-app-resume triggers.

---

## 6. Flutter client integration changes

The app already isolates data access behind **repositories + Riverpod providers** — so integration is mostly swapping implementations, not rewriting screens.

1. **UUID migration:** switch Isar models from `Isar.autoIncrement` int ids to **UUID v7** strings *before* enabling sync, so local and server ids match. (One-time local migration.)
2. **`ApiClient`** (Dio) with: base URL, auth interceptor (attach access token), **401 → refresh-and-retry** interceptor, error mapping.
3. **Secure token storage:** `flutter_secure_storage` for refresh token; move session off SharedPreferences.
4. **Repositories** gain a remote path: write locally (offline-first) → enqueue for sync → reconcile. UI/providers unchanged.
5. **Connectivity-aware sync service** (Phase 2).
6. Image upload: on product save with a new local image, upload to `POST /products/{id}/image`, store returned URL.

---

## 7. Schema alignment with the frontend

- ✅ `businesses.onboarding_checklist jsonb` — added to DATABASE.md; persists the setup-checklist completion (`BusinessSettings.completedChecklistItems`). Create via Alembic migration in M2.
- No `business_type` column — the app is **motorcycle-shop only**, so it's a constant, not data.
- Everything else in the frontend already maps to DATABASE.md.

---

## 8. Deployment

- **PaaS** service (Docker image) + **managed Postgres** + **S3-compatible bucket** + **managed Redis**.
- Migrations run on deploy (`alembic upgrade head`).
- Env: `DATABASE_URL`, `JWT_PRIVATE_KEY`/`JWT_PUBLIC_KEY`, `S3_*`, `REDIS_URL`. Secrets in the platform's secret store.
- Health check `GET /health`; readiness gates traffic.
- Automated DB backups + a tested restore runbook.

---

## 9. Build order (milestones)

```
M0  Project scaffold (FastAPI, SQLModel, Alembic, Docker, CI: pip-audit + bandit)
M1  Auth: register/login/refresh/logout/me + Argon2id + JWT + rate limit + audit log
M2  Tenant scoping (JWT bid, base repo / RLS) + business + categories + checklist
M3  Products (+ image upload, bulk, barcode lookup) + inventory movements
M4  Sales checkout (server-recompute totals, stock movements) + sales history
M5  Expenses + dashboard summary (Asia/Manila)
M6  Backup export/import (idempotent)            ← Phase 1 done
M7  Flutter: UUID migration + ApiClient + secure storage + remote repos + backup wiring
M8  Sync pull/push + conflict rules + client sync service  ← Phase 2
M9  Hardening pass: pen-test checklist, load test, restore drill
```

---

## 10. Security acceptance checklist (gate before launch)
- [ ] All endpoints (except register/login/refresh/health) require a valid access token.
- [ ] `business_id` always from JWT; verified no endpoint reads it from client input.
- [ ] Argon2id hashing; no plaintext/SHA-only passwords server-side.
- [ ] Refresh-token rotation + reuse detection working; logout revokes.
- [ ] Login rate-limited + lockout; generic auth errors (no user enumeration).
- [ ] Pydantic validation on every body; `extra='forbid'`.
- [ ] File uploads: MIME + magic-byte + size checks; random keys; private bucket + signed URLs.
- [ ] Security headers + HTTPS/HSTS + locked CORS.
- [ ] Server recomputes money; client totals never trusted.
- [ ] No secrets in repo; CI `pip-audit` + `bandit` green.
- [ ] Error responses leak no stack traces / internals.
- [ ] Audit log for auth + data export/import.
- [ ] DB backup + tested restore.

---

## Open item to confirm before Phase 2
**Inventory oversell rule:** when two offline sales drop the last unit, do we (a) allow negative stock + flag for reconciliation *(recommended — matches the append-only ledger)*, or (b) reject the later sale on sync? This is a business decision — flagging it here so it's settled before sync is built.
