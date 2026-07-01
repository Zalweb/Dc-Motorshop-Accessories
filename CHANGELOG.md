# Changelog

Format: `[YYYY-MM-DD] phase/feature: description`

## [2026-06-27] feature: More page — Advance options, Motion toggle, developer footer
- more: new "ADVANCE" section — an expandable "Advance account options" card (ExpansionTile) revealing two destructive actions: **Reset Local Data** (clears products/sales/expenses, keeps account + settings) and **Delete account** (erases every local collection then signs out). Both confirm first.
- more/Appearance: added a **Motion** row (normal Switch, on/off) beneath the Theme picker. `motion_controller.dart` (`motionEnabledProvider`, persisted in prefs as `app_motion_enabled`). When off, `main.dart` swaps in a no-op `PageTransitionsTheme` for instant navigation on every route and sets `MediaQuery.disableAnimations`, so motion is reduced app-wide.
- more: formal developer footer at the bottom — "DC Motorcycle Inventory · Designed & developed by Frienzal S. Labisig", selectable contact email frienzalsumalpong@gmail.com, and a copyright line.
- `maintenance_repository.dart` (`maintenanceRepositoryProvider`): `resetLocalData()` clears Product/Category/Sale/Expense collections; `deleteAllLocal()` runs `isar.clear()` in a txn.

## [2026-06-27] feature: Setup checklist derives completion from real app state
- Setup checklist completion is now computed from actual data instead of a manually-toggled stored flag: logo set, address + phone set, ≥1 product, workflow stages configured, ≥1 expense, ≥1 closed day (reads `calendar_closed_dates` / weekend auto-close prefs). Tapping an item now navigates to the screen that completes it (General settings, Add product, Expenses, Business calendar) and re-reads on return; items auto-check when their data exists.
- Dropped the two non-functional fine-tune items ("expense averaging window", "low-stock alerts") — neither feature exists to detect. Checklist is now 6 items.
- Removed the now-unused manual `SettingsRepository.toggleChecklistItem`; `completedChecklistItems` stays on the model (still synced/backed up), just no longer drives the UI.

## [2026-06-27] remove: Dashboard profit-trend comparison chart
- Deleted the "Profit Trend vs <period>" card from the dashboard and all its supporting code: `_ComparisonChart/_ComparisonRow/_DeltaBadge/_DualBar`, the `_pctChange` helper, and the `_upColor/_downColor` constants in `dashboard_screen.dart`.
- `DashboardSummary` lost `prevGrossProfit/prevNetProfit/prevCogs/comparisonLabel`; `dashboard_controller.dart` dropped the previous-period bounds and the `profitFor(start,end)` helper. The Week/Month period options and the revenue line chart remain.
- Removed the now-obsolete "today period exposes yesterday gross profit" test.

## [2026-06-27] feature: Appearance / theme mode (System / Light / Dark)
- more: new "APPEARANCE" section with a Theme card — a segmented System / Light / Dark picker (each with an icon), highlighting the active choice. Tapping applies instantly app-wide.
- `theme_mode_controller.dart` — `themeModeProvider` (Notifier<ThemeMode>) persisted in SharedPreferences under `app_theme_mode`; `main.dart` now reads it for `MaterialApp.themeMode` (was hardcoded `ThemeMode.system`). Kept in prefs (device-level) rather than the synced BusinessSettings, so it doesn't sync across devices.

## [2026-06-27] feature: Sales history Excel export (save to device or share)
- Sales History app bar gains an export icon that writes the **currently filtered** sales to an `.xlsx` (sheet "Sales"). Columns: Qty, Name, Brand, Part Number, Price, Status, Date — one row per line item.
- Tapping export opens a choice sheet: **Save to device** (downloads via the Android save dialog → Downloads, using `file_picker`'s `saveFile` with bytes — no storage permission) or **Share** (system share sheet via `share_plus`).
- `sales_export.dart`: builds the workbook with the `excel` package; brand & part number are looked up from the product catalog (by uid → id → name) since a sale line only snapshots name/qty/price. Empty selection / cancel show snackbars.
- deps: added `excel: ^4.0.6`. Verified on-device (choice sheet + share sheet + save dialog all open; file parsed: correct headers + item rows).

## [2026-06-27] feature: Credit sales require a named customer + customer dropdown
- new sale: the Customer field is now a `RawAutocomplete` dropdown of existing customers (from `buildCustomerSummaries`), each suggestion showing their current "owes ₱X". Picking one links the sale to that ledger so a new balance adds to their running total (customers are grouped by name, so no duplicate entries).
- new sale: a customer name is now **required** when the sale resolves to partial or unpaid — checkout blocks with an inline error + snackbar and focuses the field. Fully-paid (walk-in) sales stay optional.
- new sale: when the typed/selected name matches a customer who already owes, an inline red hint shows their current balance and that this sale adds to it.
- (Customers page already lists one row per unique person with the summed balance and drills into all their transactions — unchanged.)

## [2026-06-27] feature: Dashboard profit-trend comparison chart
- dashboard: new "Profit Trend vs <period>" card under At a Glance — Gross Profit, Net Profit, and Cost of Goods each show a % up/down badge (green = better, red = worse; COGS inverted since rising cost is bad) plus a dual bar (current over previous) and the previous value. "New" badge when there's no prior baseline.
- Each period compares against the equivalent preceding one: Today → yesterday, Week → last week, Month → last month, Yesterday → the day before, Custom → the previous equal-length range.
- `DashboardPeriod` gains `week` (Mon-start calendar week) and `month` (calendar month); the period selector is now horizontally scrollable. `DashboardSummary` gains `prevGrossProfit/prevNetProfit/prevCogs/comparisonLabel`, computed via a shared `profitFor(start,end)` helper that respects the include-unpaid setting.

## [2026-06-27] fix: Sales History rendering blank while sales exist
- Root cause: the inline "Complete payment" `FilledButton` on unpaid/partial sale cards. A `Row` measures non-flex children with unbounded width, and a Material button turns that into a forced-infinite-width assert ("BoxConstraints forces an infinite width"). The exception aborted the whole ListView viewport layout, so every tile (even paid ones) painted nothing — the data was always present. Replaced the inline button with a custom tappable `Container` pill (shrink-wraps, can't force infinite width) in both `_SaleTile` and customers' `_SaleRow`. Diagnosed on-device via adb screenshots + render-log capture.
- Hardened `saleBalance` against non-finite legacy data (was showing "Balance due ₱∞" for a couple of old sales): falls back to the full total / 0 when `amountReceived` or the difference isn't finite.
- Also read the sales stream via `.value` (like dashboard/reports) instead of `AsyncValue.when`, so a transient stream tick can't blank the list; and dev seed now creates 4 sample sales (paid/partial/unpaid, some customer-linked) for testing.

## [2026-06-27] feature: Sales history — clickable, status-coded, payable
- Sale cards are now tappable (ripple + chevron) into a new `sale_detail_screen.dart` (line items, subtotal/discount/total, amount received, balance due, customer, method, notes).
- Each card shows a color-coded status: a left status bar + a PAID (green) / PARTIAL (amber) / UNPAID (red) chip. Cards with a balance show an inline "Complete payment" button.
- Header gains a date filter (`tune` icon, badge when active): All time / Today / Yesterday / Last 7 days / This month / Custom range (date-range picker), surfaced as a dismissible chip.
- New `sale_payment.dart` holds the shared `saleBalance`, `SaleStatusChip`, status colors, and `showCompletePaymentSheet` (record full or partial payment; caps received at total, recomputes paid/partial). Since a customer's balance is the sum of their sale balances, settling a sale here auto-reduces the linked customer's outstanding balance.
- Refactor: `customers_screen.dart` now reuses these shared pieces (removed its duplicate `saleBalance`/`_StatusChip`/mark-paid dialog; "Mark paid" → "Complete payment" sheet).

## [2026-06-27] feature: Customers (receivables) screen
- `customers/customers_screen.dart` — More → Finance "Customers" ("View customer list & balances"). Aggregates every sale that carried a customer name into a per-customer ledger: initials avatar, order count, total spent, and outstanding balance. Search bar on top; customers who owe are sorted first; a red "Total receivables" banner sums all balances.
- `CustomerDetailScreen` — per-customer header (orders / spent / balance) + each sale with a PAID/PARTIAL/UNPAID chip; unpaid & partial sales show "Balance due" with a "Mark paid" action that settles the sale (sets amountReceived = total, status = paid, marks dirty for sync).
- Balance = `total − amountReceived` for partial/unpaid sales (0 when paid). No new model — reads `Sale.customerName/status/total/amountReceived`; settle reuses `SaleRepository.save`.

## [2026-06-27] feature: General settings screen redesign
- `general_settings_screen.dart` rebuilt to match 20/20.1/20.2.jpg: Branding card (logo drop target + 10-swatch color theme grid + live preview), Business details card (name*, address, phone, email, timezone, currency), Receipts card (QR link). Centered "General · <business name>" app bar, no save button.
- Edits auto-persist: theme/logo/dropdowns save on change, text fields debounce 500ms. The reactive `businessSettingsStreamProvider` propagates logo → dashboard header + More profile/business cards, accent theme → whole app, business details → More "Business" section, live.
- BusinessSettings gains `address`, `phone`, `email`, `timezone`, `currency`, `receiptQrLink`. More screen's Business card now lists every filled detail as icon rows (address, phone, email, timezone, currency, QR link), or a prompt when empty.

## [2026-06-27] feature: Inventory settings screen
- `inventory_settings_screen.dart` — Inventory settings (21.jpg): one "Selling & stock" section with three persisted toggles. Defaults match the current setup: only "Include unpaid sales in reports" is on. (Recipe & ingredient tracking section dropped — no recipe/BOM model in a parts shop.)
- BusinessSettings gains `allowSellWhenOutOfStock`, `trackPartialChange`, `includeUnpaidInReports`.
- Wired logic: New Sale grid + barcode scan + checkout now respect "Allow selling when out of stock" (when on, out-of-stock items stay addable and can exceed stock; when off, checkout throws `OutOfStockException` → snackbar). Dashboard/reports/financial calendar exclude unpaid sales from revenue/profit/COGS when "Include unpaid" is off. Cart sheet records "change still owed" when partial-change tracking is on.
- more: Inventory row now navigates to the screen (was a "coming soon" snackbar).

## [2026-06-27] feature: Business Calendar screen
- `business_calendar_screen.dart` — tag closed days (22.jpg/22.1.jpg): OPERATING/CLOSED/RATE stat cards, monthly calendar with today/closed/open states, "Mark as closed" bottom sheet (Holiday/Day off/Maintenance/Other reasons + optional note), and an Upcoming closed dates list with empty state.
- Shares the `calendar_closed_dates` SharedPreferences key with the Financial Calendar so both stay in sync; stores reason/note in `calendar_closed_meta`.
- more: Business Calendar row now navigates to the screen (was a "coming soon" snackbar).

## [2026-06-26] feature: Product list/detail polish + stock health
- shared: `stock_health.dart` — CRITICAL (≤5, red) / LOW STOCK (≤20, amber) / IN STOCK (>20, green), used by both list and detail.
- products list: each tile now shows a left thumbnail (box icon fallback), the "in stock" count colored by stock health, and a right chevron to signal it's tappable.
- product detail: Pricing card is now one row of 3 bold columns (SELLING / COST / MARGIN, caps, no "price" word, margin as %); Inventory card shows "N PCS" on the left and the caps health label on the right at the same font size (headingMedium).

## [2026-06-26] feature: Product detail screen + edit
- products: tapping a product opens `ProductDetailScreen` — image (default box icon when none), name + small description, a Pricing card (selling/cost/margin with % and color), an Inventory card (qty pcs + health badge: green in stock / amber low stock ≤5 / red no stock; services show "not tracked"), and a Details card (barcode, brand, part number, created date).
- add product: header edit button opens the form in edit mode (prefilled, "SAVE CHANGES") updating the product in place (id/uid/createdAt preserved); detail view follows the live list so edits reflect immediately.

## [2026-06-26] feature: Products filter by user categories
- products: replaced the hardcoded "All / Products / Services" filter chips with "All" + the categories the user added (from `categoryListStreamProvider`); filtering now matches `product.category`. Selected index is clamped so deleting a category can't crash.

## [2026-06-26] feature: Bulk Add continuous scanner
- bulk scan: on each scan, a green top banner shows the product name, the device vibrates (`HapticFeedback.vibrate`, added `VIBRATE` permission), and a 4-second cooldown gates the next scan. Fixed first-scan-of-existing double-counting (now starts at qty 1).
- bulk scan: new `BulkScanScreen` keeps the camera open across scans with a live "Point camera at barcode. / Scanned: N" overlay; existing barcodes tally as restocks, repeat draft barcodes bump quantity, unknown ones prompt Add/Skip and open the Add Product form inline (camera resumes after, count updates). DONE/back returns the accumulated queue.
- bulk add: "SCAN BARCODES" launches the continuous scanner seeded with the current queue; each queued tile now has a quantity stepper (+/-) and a remove button. Nothing is written until the confirm button.
- shared: extracted `BulkQueueItem` (draft vs. restock, editable quantity) for the page and scanner.

## [2026-06-26] feature: Bulk Add staging queue + confirm button
- bulk add: scans/manual entries now stage into a pending queue instead of committing immediately; bottom "ADD {n} PRODUCT(S)" button commits the whole queue in one pass. Existing barcodes stage as restocks (repeat scans bump qty); queued items can be removed before confirming.
- bulk add: top "Add" button opens the Add Product form (prefilled with any typed barcode) and appends the result to the queue.
- add product: new staged mode (`AddProductArgs.stage`) returns the built `Product` to the caller instead of saving; button reads "ADD TO LIST" when staging.

## [2026-06-26] Flutter M7/M8 — API client + secure auth + sync (client)
- deps: dio, flutter_secure_storage, connectivity_plus.
- models: added server-aligned `uid` (UUID v7) + sync metadata (`updatedAt`, `isDirty`) to User/Business/Category/Product/Sale/Expense; Isar int `Id` kept as local surrogate. `lib/core/utils/uuid.dart` (UUID v7). Regenerated Isar schemas.
- api: `ApiClient` (Dio) with auth interceptor + 401→refresh-and-retry; `SecureTokenStore` (Keystore/Keychain via `TokenStore` interface); typed APIs (auth, backup, sync, sales, product image) + `ApiException` envelope mapping.
- auth: online-first register/login/logout/me with JWTs in secure storage; offline fallback to the local salted-hash stub when the network is down.
- sync (`lib/core/sync/`): `SyncService` pushes dirty rows (catalog/config via `/sync/{table}` LWW, sales via idempotent `POST /sales`), pulls deltas + tombstones, reconciles by `uid` (local dirty rows protected); image upload after product push; restore via `/backup/export`. Triggers: post-login, on reconnect (connectivity), and manual ("Sync now" / "Restore from cloud" in More).
- repositories mark records dirty on write (offline-first behavior unchanged); cart lines carry product `uid` for checkout push.
- tests: +9 Flutter (api_client refresh-retry 3, ApiException mapping 3, uuid 3) → 13 total; `flutter analyze` 0 errors.

## [2026-06-26] Backend M8/M9 — Delta sync API + hardening (backend portions)
- sync: `GET /v1/sync/{table}?since=` (changes + tombstones), `POST /v1/sync/{table}` (idempotent upsert). Conflict rules: catalog/config last-write-wins by `updated_at`; `inventory_movements` append-only; sales/sale_items/payments pull-only (pushed via `POST /sales` to preserve money recompute). `products.stock_on_hand` push-excluded.
- tombstones: `SyncTombstone` table + migration `0006_m8`; recorded on category/product delete so deletions propagate. Oversell rule: allow-negative-and-flag.
- refactor: shared `services/serialization.py` (row<->model coercion) used by backup + sync.
- hardening (M9): global per-IP rate limit (600/min) on all `/v1` routes; `backend/SECURITY.md` (§10 checklist status + restore runbook); all 6 migrations verified reversible on PG16.
- tests: +16 (sync 14, rate-limit 2) → 108 total backend tests green (ruff + bandit + pip-audit + pytest).
- HELD (require editing Flutter `lib/`, fenced off by the backend-only rule): M7 client integration, M8 `sync_service.dart`. All endpoints they need are live + tested.

## [2026-06-26] Backend M6 — Backup / restore (Phase 1 complete)
- backup service: `GET /backup/export` → full tenant snapshot (businesses, users, catalog, sales + children, expenses); `POST /backup/import` → idempotent FK-ordered upsert (categories two-pass, JSON→type coercion since SQLModel table models skip validation).
- tenant isolation: import only ever targets the JWT business; rows whose id belongs to another tenant are skipped (never overwritten). Audit-logged on export/import.
- tests: 9 — export contents, restore-after-delete, idempotent re-import, cross-tenant import skipped + origin intact, auth required.
- verified: all 5 migrations reversible (upgrade → downgrade base → upgrade head clean on a real PG16). Phase 1 (M0–M6) done; 92 backend tests green (ruff + bandit + pip-audit + pytest).

## [2026-06-26] Backend M5 — Expenses + Dashboard summary
- models/migration: `ExpenseCategory`, `Expense` + `0005_m5` (amount>0, spent_on date, business+date index).
- expenses api: `POST /expenses` (idempotent by UUID), `GET /expenses` (from/to date filter, pagination).
- dashboard: `GET /dashboard/summary?from=&to=&tz=Asia/Manila` — revenue, COGS, gross/net profit, expenses, discount, sale_count, avg_ticket, gross_margin. Sales windowed by tz-derived UTC bounds; expenses by `spent_on`. Computed, never stored.
- fix: validation error envelope now JSON-encodes error context (Decimal constraints no longer 500). Added `tzdata` runtime dep (Windows/slim images lack a system tz db).
- tests: 18 — metric math on a fixed dataset + Manila day-boundary include/exclude. All gates green.

## [2026-06-26] Backend M4 — Sales checkout + history
- models/migration: `Customer`, `WorkflowStage`, `Sale`, `SaleItem`, `Payment` + `0004_m4` (snapshot price/cost on sale_items; unique sale_number per shop; payment method/amount checks).
- checkout: server recomputes every line_total/subtotal/total from server-side product prices (client `unit_price`/totals never trusted); one negative `sale` movement per stocked line in the same transaction; idempotent by client sale UUID; auto `S-000N` numbering; default cash payment.
- history: `GET /sales` (search by number/customer, from/to date filter, pagination), `GET /sales/{id}` (items + payments).
- money: Decimal throughout, `q2` half-up to 2dp (`core/money.py`).
- tests: 14 — total recompute, stock decrement, idempotent no-op, COGS snapshot, search/date filters, cross-tenant rejection. All gates green.

## [2026-06-26] Backend M3 — Products + images + bulk + barcode + inventory ledger
- models/migration: `Brand`, `Product`, `InventoryMovement` + `0003_m3`; `sync_stock_on_hand` AFTER-INSERT trigger recomputes cached on-hand from the ledger; partial unique barcode index; active-products partial index. (Variants/addons deferred.)
- inventory: stock is an append-only ledger; create emits `initial` movement, stock edits emit `adjustment` delta — on-hand always reconstructable; idempotent product upsert by client UUID.
- products api: list (search across name/sku/barcode/part_number, ALL/PRODUCTS/SERVICES filter, pagination), get, by-barcode, create, update, soft-delete, bulk.
- storage: S3 image upload with MIME + magic-byte + 5MB validation, random UUID keys, signed URLs (private bucket). EXIF stripping deferred.
- tests: 21 — ledger/cache consistency, idempotency, barcode lookup, search/filter/pagination, bulk, image rejects (non-image/spoofed/oversize). All gates green.

## [2026-06-26] Backend M2 — Tenant scoping + Business + Categories + Checklist
- deps: `current_business_id` / `current_business` sourced only from JWT `bid`; client `business_id` in any body → 422 (extra='forbid').
- repo: `BaseRepository[ModelT]` auto-scopes every query to `WHERE business_id = :bid` (the tenant-isolation chokepoint).
- models/migration: `Category` (self-parent, soft uniqueness) + `0002_m2`; unique name per business via `NULLS NOT DISTINCT` index (enforces top-level names too).
- api: `/v1/business` (GET/PUT + checklist GET/PUT), `/v1/categories` (GET/POST/DELETE); category POST is idempotent upsert by client UUID; duplicate name → 409.
- tests: 12 — cross-tenant isolation (can't see/delete another shop's data), business_id-rejection, checklist round-trip + dedupe, idempotent upsert. All gates green.

## [2026-06-26] Backend M1 — Auth (secure)
- models: `Business`, `User`, `AuditLog` (SQLModel, UUID v7 PKs, citext username/email, role check, soft-delete). Migration `0001_m1` (citext ext + 3 tables, hand-written to match DATABASE.md).
- security: Argon2id hash/verify (+ timing-equalizing dummy hash), JWT access (15m) + refresh (30d) with jti/fid claims.
- auth flow: register (creates business + owner), login, refresh (rotate + Redis reuse-detection → family revoke), logout (revoke family). Audit-log on every auth event.
- rate limit: login 5 failures / 15 min / account → 429; generic "Invalid username or password" (no user enumeration).
- api: `/v1/auth` register/login/refresh/logout/me(GET,PATCH); tenant `business_id` only ever from JWT.
- tests: 20 (testcontainers Postgres + fakeredis) — happy path, wrong password, reuse revokes family, lockout, argon2id-in-db, /me auth. ruff + bandit + pip-audit + pytest green.

## [2026-06-26] Backend M0 — Scaffold & CI
- scaffold: created `backend/` — FastAPI app factory (`app/main.py`), versioned router under `/v1`, `GET /v1/health` → `{status:"ok"}`. Python 3.12 via uv.
- core: `config.py` (pydantic-settings from env, no secrets in code), `database.py` (lazy async engine + session dep), `errors.py` (error envelope `{error:{code,message}}`, no stack-trace leaks), `logging.py` (secret/token-scrubbing filter), `middleware.py` (security headers + request-id).
- security: HSTS/nosniff/frame-deny/referrer/CSP headers, HTTPS redirect in prod, CORS deny-by-default.
- infra: Dockerfile (python:3.12-slim, non-root user, healthcheck), docker-compose (api + postgres16 + redis + minio), `.env.example` (.env gitignored), Alembic wired to SQLModel metadata (async env.py).
- ci: `.github/workflows/ci.yml` — ruff + bandit + pip-audit + pytest (note: lives under backend/ per task plan; needs root-level copy to trigger on GitHub).
- verify: ruff + bandit + pip-audit + pytest (4 tests) all green; `docker compose up` serves `/v1/health` 200 with security headers, api container healthy.

## [2026-06-24] Phase 0 — Project Scaffold & Foundation
- scaffold: created Flutter project (`dc_motorcycle_inventory`, org `com.dcmotorcycle`, Android + iOS).
- deps: flutter_riverpod ^3.3, go_router ^17.3, mobile_scanner ^7.2, image_picker ^1.2, shared_preferences ^2.5, intl ^0.20, path_provider, `isar_community` ^3.3 (+ flutter_libs, generator, build_runner).
- db: switched original `isar` → `isar_community` — original `isar_generator` 3.1.0 caps `analyzer <6.0.0`, incompatible with Dart 3.12. `isar_community` is the maintained drop-in (same API, import `package:isar_community/isar.dart`). Recorded in CLAUDE.md.
- theme: design system from AGENT.md — app_colors, app_text_styles, app_dimens, app_theme (dark only, bg #0A0A0A, accent #2563EB).
- core: route_paths, app_strings constants, isar_service (opens single Isar instance), providers (isarServiceProvider).
- models: User (Isar @collection) + generated user.g.dart — validates codegen pipeline.
- widgets: PrimaryButton, EmptyState, SearchField, FilterChips, SectionHeader, PlaceholderScreen.
- router: skeleton GoRouter (splash/login/register/dashboard → placeholders), main.dart boots Isar then app.
- verify: `flutter analyze` clean (0 issues); `flutter test` green.

## [2026-06-24] Backend planning + schema alignment
- docs: added DATABASE.md (normalized PostgreSQL schema + Mermaid ERD), BACKEND_PLAN.md (secured FastAPI integration plan), BACKEND_TASKS.md (M0–M9 task checklist). Linked from CLAUDE.md.
- schema: added `businesses.onboarding_checklist jsonb` (persists setup-checklist progress) to DATABASE.md table + ERD + sync mapping. No `business_type` column — app is motorcycle-shop only (per user).

## [2026-06-24] Scope — drop motorcycle-model tracking (per user)
- decision: system tracks **products/accessories** only, not the motorcycles. Removed "compatible models" entirely.
- db: DATABASE.md — dropped `motorcycle_models` table + `product_compatible_models` junction; updated ER diagram, migration order, and Local↔Server mapping.
- code: removed `Product.compatibleModels` (Isar model regenerated); cleaned dev_seed sample.
- docs: AGENT.md Product Fields rewritten (name/barcode/partNumber/brand/category/unit/pricing/stock); SCREENS.md AddProduct details updated.

## [2026-06-24] Phases 3–6 — Products, POS, Dashboard, Polish
- models: Category, Product (motorcycle fields: partNumber, compatibleModels, brand, unit, isService), Sale + embedded SaleItem (cost snapshot), Expense. All added to Isar schema + generated.
- data: ProductRepository (watch/save/delete/findByBarcode/decrementStock), CategoryRepository (watch/add/delete/seed), SaleRepository (watch/between/nextSaleNumber), ExpenseRepository. Stream providers for each.
- nav: AppBottomNav (5 tabs, elevated center New Sale FAB) + MainShell via StatefulShellRoute.indexedStack. Router rewritten: auth/onboarding/product-subscreens top-level; dashboard/sales/new-sale/products/more in the shell.
- products (Phase 3): ProductsScreen (search + ALL/PRODUCTS/SERVICES filter + empty state + FAB menu), AddProductScreen (image, barcode+scan, details, pricing ₱, stock with quick-qty chips -1/+1/+5/+10/+50/+100), CategoriesScreen (CRUD), BulkAddScreen (scan/manual queue → save). BarcodeScannerScreen (mobile_scanner, offline). Camera permission added to AndroidManifest. Onboarding now seeds Category rows.
- POS (Phase 4): CartController (add/inc/dec/checkout → writes Sale, decrements stock), NewSaleScreen (search + scan-to-add + qty steppers + cart tray + checkout), SalesHistoryScreen (search + empty state).
- dashboard (Phase 5): dashboardSummaryProvider (revenue, COGS, gross/net profit, expenses, avg ticket, discount, gross margin for today), DashboardScreen (revenue hero + At-a-Glance grid + wide metric cards + tap-to-add expense), MetricCard. MoreScreen (profile, account/business cards, ACTIVE badge, setup-checklist link, logout) + ProfileScreen merged into More.
- polish (Phase 6): formatPeso util (₱ everywhere), dev "Load sample data" button (seedSampleData — sample motorcycle catalog), empty states on all lists, mounted checks across async gaps. Tests: money formatting, cart line math, onboarding render. Removed dead placeholder_screen.dart.
- verify: `flutter analyze` clean (0 issues); `flutter test` green (4 tests); **Android debug build succeeded (exit 0)**.

## [2026-06-24] Phase 2 — Onboarding restructure (per user)
- flow: 4 steps → **3 steps**. Removed business-type step; merged theme into step 1; removed workflow-stage editing from review.
  - Step 1 "Set up your shop": optional logo (image_picker) + theme picker.
  - Step 2 "Review categories": add/remove categories only.
  - Step 3 "Invite team": optional, last → Complete.
- fix: OnboardingScaffold layout bug (header/footer collided at top) — footer now pinned via `bottomNavigationBar`, body is a single ListView.
- model: BusinessSettings.logoPath added (regenerated). OnboardingDraft now {categories, themeColor, logoPath}.
- files: deleted step1_business_type_screen.dart + step4_theme_screen.dart; added step1_setup_shop_screen.dart; removed RoutePaths.onboardingStep4.
- docs: AGENT.md + SCREENS.md updated to the 3-step flow.
- verify: `flutter analyze` clean.

## [2026-06-24] Phase 2 — Onboarding & Setup Checklist
- model: BusinessSettings (Isar singleton row) — businessName, businessType, categories, workflowStages, themeColor, completedChecklistItems. Added to Isar schema + regenerated.
- data: SettingsRepository (getOrCreate/save/watch/toggleChecklistItem); providers settingsRepositoryProvider + businessSettingsStreamProvider.
- state: OnboardingController (Notifier<OnboardingDraft>) holds the draft across steps; finish() persists settings, marks user onboarding complete, invalidates auth so the guard routes to dashboard.
- theme: theme_options.dart — 10 accent swatches (Blue default).
- screens: Step1 business type (Motorcycle Shop preselected), Step2 review setup (3.jpg — editable categories + workflow stages), Step3 invite staff (skippable), Step4 theme picker (4.jpg — swatch grid + live preview), Complete (5.jpg — no mascot per spec), SetupChecklist (7/8.jpg — 8 items, persisted progress bar). Shared OnboardingScaffold (progress bar + Back/primary footer).
- router: all onboarding routes + setup-checklist wired; guard gates `/onboarding/*` while onboarding incomplete; setup-checklist is a normal authenticated route.
- verify: `flutter analyze` clean; `flutter test` green.

## [2026-06-24] Phase 1 — Splash & Auth (local stub)
- deps: crypto (salted SHA-256 password hashing).
- auth: AuthRepository — register/login/logout/currentUser/markOnboardingComplete. Accounts in Isar, session id in SharedPreferences, passwords salted + hashed (never plaintext). AuthException with UI-safe messages.
- state: AuthController (AsyncNotifier<User?>) + providers (sharedPreferencesProvider, isarProvider, authRepositoryProvider).
- screens: SplashScreen (6.jpg), LoginScreen (1.jpg), RegisterScreen (2.jpg) with shared AuthField + BrandMark widgets; form validation, Show/Hide password, error snackbars.
- router: routerProvider with auth guard — unauthenticated → login; logged-in but onboarding incomplete → onboarding; logged-in → dashboard. Refreshes on auth change. main.dart now inits SharedPreferences.
- verify: `flutter analyze` clean; `flutter test` green; Android debug build succeeded (exit 0).

## [2026-06-24] Tooling — run/preview
- fix: re-encoded root `.gitignore` from UTF-16 → UTF-8 (no BOM). Flutter's web tooling crashed reading it as UTF-8; added standard Flutter ignores.
- decision: **web preview not possible** — Isar/`isar_community` uses `dart:ffi` (native only) and won't compile to JS. App is Android-first; preview runs on the Android emulator.
- tool: added `tool/run_emulator.ps1` + `.bat` — boots the Android emulator (auto-detects id, e.g. Pixel_9_Pro_XL), waits for it, runs the app with hot reload.
