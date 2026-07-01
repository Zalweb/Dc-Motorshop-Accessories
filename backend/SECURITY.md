# Backend Security & Operations

Status of the BACKEND_PLAN.md §10 security acceptance checklist, plus the restore runbook.
Code-level controls are implemented and tested; deployment/ops items are marked as such.

## §10 Acceptance checklist

| # | Control | Status | Where |
|---|---|---|---|
| 1 | All endpoints (except register/login/refresh/health) require a valid access token | ✅ | `core/deps.get_current_user` on every router |
| 2 | `business_id` always from JWT; no endpoint reads it from client input | ✅ | `core/deps`, `repositories/base`, Pydantic `extra='forbid'`; cross-tenant tests |
| 3 | Argon2id hashing; no plaintext/SHA-only | ✅ | `core/security`; `test_password_stored_as_argon2id` |
| 4 | Refresh rotation + reuse detection; logout revokes | ✅ | `services/auth_service`; reuse/family tests |
| 5 | Login rate-limited + lockout; generic errors (no enumeration) | ✅ | `core/rate_limit`; lockout + generic-error tests |
| 6 | Pydantic validation on every body; `extra='forbid'` | ✅ | `schemas/base.StrictModel` |
| 7 | File uploads: MIME + magic-byte + size; random keys; private bucket + signed URLs | ✅ code · ⚙️ bucket policy at deploy | `services/storage_service`; upload-reject tests |
| 8 | Security headers + HTTPS/HSTS + locked CORS | ✅ headers/CORS · ⚙️ TLS at PaaS | `core/middleware`, `main.py` |
| 9 | Server recomputes money; client totals never trusted | ✅ | `services/sale_service`; recompute tests |
| 10 | No secrets in repo; CI `pip-audit` + `bandit` green | ✅ | `.gitignore`, `.env.example`, CI |
| 11 | Error responses leak no stack traces / internals | ✅ | `core/errors`; generic 500 envelope |
| 12 | Audit log for auth + data export/import | ✅ | `AuditLog` writes in auth + backup services |
| 13 | DB backup + tested restore | ⚙️ ops | managed PaaS backups + runbook below |

Additional hardening implemented beyond the checklist:
- **Global per-IP rate limit** (600/min) across all `/v1` endpoints (`core/rate_limit.global_rate_limit`), on top of the stricter per-account login limit.
- **Secret-scrubbing log filter** (`core/logging`) redacts tokens/passwords/Authorization.
- **Migrations verified reversible** (upgrade → downgrade base → upgrade head) on PostgreSQL 16.

### Deferred (tracked)
- **EXIF stripping** on uploaded images — needs Pillow.
- **HTTPS/HSTS enforcement** is PaaS-terminated; `HTTPSRedirectMiddleware` is active when `ENV` is staging/prod.
- **Load test** (login, products list, checkout) and **pen-test pass** (authz/tenant isolation, rate limits, upload abuse, token replay) — run against a deployed environment.

## Restore runbook

Prerequisites: a base backup/snapshot from the managed Postgres provider, and the target
`DATABASE_URL`.

1. Provision (or empty) the target database.
2. Apply schema: `alembic upgrade head`.
3. Restore data:
   - **Provider snapshot:** restore the managed backup to the target instance, then run
     `alembic upgrade head` to reconcile to the latest revision.
   - **Per-tenant logical restore:** `POST /v1/backup/import` with a snapshot previously
     produced by `GET /v1/backup/export`. Idempotent — safe to re-run; never duplicates.
4. Verify: `GET /v1/health` → 200; spot-check `GET /v1/dashboard/summary` totals against a
   known-good export.

Drill cadence: exercise this runbook on a throwaway instance each release so the backup is
proven restorable, not just present.
