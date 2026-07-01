# DC Motorcycle Inventory — Project Instructions

## MANDATORY: Read Before Any Action
Every agent or AI session MUST read these files in order before writing a single line of code or making any decision:
1. `CLAUDE.md` — stack, architecture, commands, don'ts (this file)
2. `AGENT.md` — design tokens, screen specs, domain rules, vibe coding rules
3. `SCREENS.md` — full route map and per-screen component spec
4. `Mobile reference image/` — visual reference for every screen (images 1–13)

If you have not read all four, stop and read them now. Do not rely on memory from a previous session — always re-read to catch updates.

---

## What This Is
A Flutter + Python FastAPI mobile app for **DC Motorcycle Inventory** — a Philippine motorcycle shop POS and inventory tracking system. All UI design decisions come from the approved reference images in `Mobile reference image/`. Branding: **DC Motorcycle Inventory**. Currency: Philippine Peso (₱).

## Stack
| Layer | Technology |
|---|---|
| Mobile | Flutter 3.44 / Dart 3.12 (Android-first, iOS later) |
| State | Riverpod (`flutter_riverpod` ^3.3) |
| Local DB | `isar_community` ^3.3 — import `package:isar_community/isar.dart` |
| Routing | `go_router` ^17 |
| Barcode | `mobile_scanner` ^7 |
| Backend | Python FastAPI (out of scope for current frontend build) |
| Backend DB | PostgreSQL |
| Auth | Local stub now (Isar); JWT via FastAPI later |

> **DB note:** Use `isar_community`, NOT the original `isar`. The original `isar_generator` 3.1.0 caps `analyzer <6.0.0`, which is incompatible with Dart 3.12. `isar_community` is the maintained drop-in fork — same `@collection` / `Isar` API, import `package:isar_community/isar.dart`, codegen via `dart run build_runner build`.

## Architecture
- **Local-first**: all features work offline via Isar. Sync to backend when connected.
- `lib/features/` — feature folders (auth, dashboard, sales, products, more)
- `lib/core/` — theme, router (GoRouter), models, services
- `backend/` — FastAPI app, routers, models, migrations (Alembic)
- No direct DB calls from UI widgets — always go through a Riverpod provider → repository pattern.
- **Canonical server schema:** see [DATABASE.md](DATABASE.md) — normalized PostgreSQL design (3NF) the offline Isar models sync up to.
- **Backend integration:** see [BACKEND_PLAN.md](BACKEND_PLAN.md) — secured FastAPI plan (auth, per-feature endpoints, phased sync, security checklist).

## Domain (MoSPAMS)
MoSPAMS = **Mo**torcycle **S**hop **P**arts **A**nd **M**anagement **S**ystem — the domain framework this app implements:
- Parts catalog with barcode + OEM/part number + compatible motorcycle models
- Categories: Engine Parts, Brakes, Electrical, Body/Frame, Tires, Lubricants/Oils, Accessories, Services
- POS: new sale, barcode scan to add items, receipt generation
- Dashboard: revenue, gross profit, net profit, COGS, expenses, avg ticket, gross margin
- Setup checklist onboarding flow (4 steps)

## Commands
```bash
# Flutter
flutter run                    # run on device/emulator
flutter test                   # run tests
flutter build apk --release    # build APK
dart analyze                   # type check

# Backend
cd backend
uvicorn main:app --reload      # dev server
alembic upgrade head           # run migrations
pytest                         # run tests
```

## Key Decisions
- Blue accent `#2563EB` — confirmed in reference image 4.jpg
- Isar over sqflite — no SQL boilerplate, reactive streams, better DX
- Riverpod over Provider/Bloc — compile-safe, testable, code-gen friendly
- FastAPI backend for future multi-device sync; app is fully functional without it

## Don'ts
- Don't use `BuildContext` across async gaps without checking `mounted`
- Don't call Isar directly in widgets — always via repository
- Don't hardcode strings — use `AppStrings` constants
- Don't modify generated files (`*.g.dart`, `*.freezed.dart`)
