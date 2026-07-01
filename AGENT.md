# AGENT.md — DC Motorcycle Inventory
> **STOP.** Read `CLAUDE.md` → this file → `SCREENS.md` → `Mobile reference image/` IN THAT ORDER before writing any code.
> This is the single source of truth for design, architecture, and feature scope.
> Never reference, name, or copy-comment from any other app or project. All decisions come from this file and the approved images only.

---

## Project Goal
Build **DC Motorcycle Inventory** — a Flutter mobile POS + inventory app for a Philippine motorcycle parts shop. The UI design is defined by the approved reference images in `Mobile reference image/`. Branding is **DC Motorcycle Inventory** only. Domain is adapted for motorcycle shops via MoSPAMS.

---

## Design System

### Colors
```dart
// Backgrounds
bgBase       = Color(0xFF0A0A0A)   // pure near-black (all screens)
bgSurface    = Color(0xFF1A1A1A)   // cards, input fields
bgSurface2   = Color(0xFF242424)   // elevated cards

// Accent (Blue theme — user confirmed)
accent       = Color(0xFF2563EB)   // primary blue (buttons, active nav, FAB)
accentLight  = Color(0xFF3B82F6)   // hover/lighter blue

// Text
textPrimary  = Color(0xFFFFFFFF)
textSecondary= Color(0xFF9CA3AF)
textMuted    = Color(0xFF6B7280)

// Status colors (from dashboard metric cards)
colorProfit  = Color(0xFF3B82F6)   // blue — gross/net profit values
colorCOGS    = Color(0xFF10B981)   // teal/green — cost of goods
colorExpense = Color(0xFFF59E0B)   // amber — expenses
colorDiscount= Color(0xFF8B5CF6)   // purple — discounts
colorMargin  = Color(0xFF3B82F6)   // blue — gross margin %
colorActive  = Color(0xFF22C55E)   // green — ACTIVE badge

// Danger
colorDanger  = Color(0xFFEF4444)
```

### Typography
```dart
// Use Inter or system default. Bold section headers, regular body.
headingLarge  = TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: textPrimary)
headingMedium = TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary)
labelCaps     = TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: textSecondary)
body          = TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: textPrimary)
bodySmall     = TextStyle(fontSize: 13, color: textSecondary)
```

### Spacing & Shape
```
cardRadius    = 14px
buttonRadius  = 14px (large full-width), 50px (pill chips)
inputRadius   = 12px
cardPadding   = EdgeInsets.all(16)
screenPadding = EdgeInsets.symmetric(horizontal: 16)
```

### Bottom Navigation
5 tabs — exact order:
1. **Dashboard** (grid icon)
2. **Sales** (receipt icon)
3. **New Sale** (cart icon — large blue FAB, elevated center)
4. **Products** (box/cube icon)
5. **More** (hamburger icon)

Active tab: accent blue icon + label. Inactive: gray. FAB center is always blue circle.

---

## Screen Inventory (from approved reference images in `Mobile reference image/`)

### AUTH FLOW
| Screen | File ref | Notes |
|---|---|---|
| Login | 1.jpg | Dark bg, DC Motorcycle Inventory logo/icon, username + password fields, Sign In button (blue), Forgot password?, Create one link |
| Register | 2.jpg | Username, Email, Password (min 8), Confirm password, Full name (optional), Phone (optional), Create account button |

### ONBOARDING FLOW (3 steps, progress bar)
> Restructured 2026-06-24 (was 4 steps). No business-type step; theme moved into step 1; workflow-stage editing removed from review.
| Step | File ref | Notes |
|---|---|---|
| Step 1 — Set up shop | 4.jpg | Optional logo (image_picker, can skip) + theme picker. Swatches: Green/Blue/Purple/Orange/Rose/Slate/Teal/Indigo/Amber/Cyan. Default: **Blue** |
| Step 2 — Review categories | 3.jpg, 3.1.jpg | Add/remove **categories only** (no workflow-stage editing). Default categories: Parts, Services. |
| Step 3 — Invite team | (implied) | Optional/skippable. No backend, so collects intent only. Last step → Complete. |
| Complete | 5.jpg | "You're all set! DC Motorshop & Accessories is ready for your first sale." + Go to dashboard. No mascot (omitted per spec). Persists settings + marks onboarding done. |

> Workflow stages still exist on BusinessSettings (default Pending → Processing → Completed) but are no longer edited during onboarding — they move to a later settings screen.

### POST-LOGIN
| Screen | File ref | Notes |
|---|---|---|
| Splash/Loading | 6.jpg | "DC Motorcycle Inventory — Welcome back! Preparing your dashboard..." with 3-dot loader |
| Setup Checklist | 7.jpg, 8.jpg | Progress bar (N of 8 done). Essentials: add logo, add address/phone, add first product, set up order workflow. Fine-tune: first expense, expense averaging window, low-stock alerts, closed days |

### MAIN APP (bottom nav)
| Screen | File ref | Notes |
|---|---|---|
| Dashboard | 9.jpg, 9.1.jpg | Revenue Today (large hero card, accent bg), At a Glance grid: Gross Profit, Net Profit, Cost of Goods, Expenses (tap to add), Avg Ticket, Discount, Gross Margin. Date filter "Today" dropdown. Reports button top-right |
| Sales History | 10.jpg | Search bar (by sale number or customer), filter button, empty state "No sales today" |
| New Sale | 11.jpg | Search products bar + barcode scanner icon button. Filter chips: ALL / PRODUCTS / SERVICES. Empty state "No items yet — Start with a product" in bottom tray |
| Products | 12.jpg | Search bar, ALL/PRODUCTS/SERVICES chips, product count, empty state, blue + FAB |
| Products FAB menu | 12.1.jpg | Expands to: Add Add-on, Categories, Bulk Add, Add Product |
| More / Profile | 13.jpg | Avatar initials, name, @username, My Profile button. ACCOUNT section (email, phone). BUSINESS section (shop name, slug, ACTIVE badge, address) |

### PRODUCT MANAGEMENT
| Screen | File ref | Notes |
|---|---|---|
| Categories | 12.1.1 | List of top-level categories with TOP badge, chevron, + FAB |
| Bulk Add Products | 12.1.2 | Blue SCAN BARCODES button, manual barcode entry, queue list "No products in queue" empty state |
| Add Product | 12.1.3, .3.1, .3.2 | Sections: PRODUCT IMAGE (tap to add photo), BARCODE OPTIONAL (text input + camera btn + scan btn), PRODUCT DETAILS (name*, category dropdown, description), PRICING (cost price ₱, selling price* ₱), INVENTORY (stock qty with quick-add chips: -1 +1 +5 +10 +50 +100). Bottom sticky ADD PRODUCT button. After save: can add variants + link add-ons |

---

## Motorcycle Shop Domain (MoSPAMS)

### Default Categories
```
Engine Parts     → sub: Pistons, Rings, Gaskets, Bearings, Camshaft, Crankshaft
Brakes           → sub: Brake Pads, Brake Shoes, Brake Fluid, Brake Discs
Electrical       → sub: Battery, Spark Plugs, Lights, CDI, Starter Motor
Body & Frame     → sub: Fenders, Fairings, Mirrors, Handles, Footpegs
Tires & Wheels   → sub: Front Tire, Rear Tire, Tubes, Rims
Lubricants/Oils  → sub: Engine Oil, Gear Oil, Brake Fluid, Grease
Accessories      → sub: Helmets, Covers, Locks, Phone Holders
Services         → sub: Labor, Oil Change, Tune-up, Repair
```

### Product Fields
> The system tracks **products/accessories**, not the motorcycles. No "compatible models" — removed 2026-06-24.
- `name` — product name (required)
- `barcode` — optional, scannable
- `partNumber` — OEM or aftermarket part number
- `brand` — manufacturer brand (NGK, Bendix, Motul, etc.)
- `category` — product category
- `unit` — piece, liter, set, pair, box
- `costPrice` / `sellingPrice` — pricing (₱)
- `stockQty` — on-hand quantity (services don't track stock)

### Workflow Stages (default for service jobs)
`Pending → Diagnosed → Parts Ordered → In Progress → Ready for Pickup → Completed`

---

## Backend API Shape (FastAPI)

```
POST   /auth/login
POST   /auth/register
GET    /dashboard/summary?date=today
GET    /products?category=&search=&page=
POST   /products
PUT    /products/{id}
DELETE /products/{id}
GET    /products/categories
POST   /products/categories
POST   /products/bulk-scan
GET    /sales?date=&search=&page=
POST   /sales
GET    /sales/{id}
POST   /expenses
GET    /expenses
PUT    /settings/business
GET    /settings/business
```

---

## Flutter Project Structure
```
lib/
  core/
    theme/           → app_theme.dart, colors.dart, text_styles.dart
    router/          → app_router.dart (GoRouter)
    models/          → shared data models (Isar schemas)
    services/        → api_service.dart, sync_service.dart
    constants/       → app_strings.dart, app_icons.dart
  features/
    auth/            → login_screen, register_screen, auth_provider
    onboarding/      → steps 1-4, setup_checklist_screen
    dashboard/       → dashboard_screen, dashboard_provider
    sales/           → sales_history_screen, new_sale_screen, sale_provider
    products/        → products_screen, add_product_screen, categories_screen, bulk_add_screen
    more/            → more_screen, profile_screen
  shared/
    widgets/         → app_bottom_nav, metric_card, search_bar, barcode_scanner_button
backend/
  main.py
  routers/
  models/
  schemas/
  services/
  migrations/
```

---

## Vibe Coding Rules
1. Re-read `CLAUDE.md`, `AGENT.md`, and `SCREENS.md` at the start of every session — do not rely on cached memory.
2. Never mention, comment, or reference any other app name, project name, or external product in code or docs.
3. Always match the dark UI from the approved reference images exactly — no light mode.
4. Every new screen needs an empty state (illustration/icon + message + CTA).
5. Bottom nav is always visible in main app screens (post-onboarding).
6. Barcode scanner must work fully offline (ML Kit via mobile_scanner).
7. All money values display as `₱0.00` format.
8. Quick-stock chips on Add Product: `-1`, `+1`, `+5`, `+10`, `+50`, `+100`.
9. FAB on Products screen expands to 4 sub-actions (speed dial pattern).
10. Setup checklist tracks progress with a linear progress bar + percentage.
11. API calls never block UI — always show local data first, sync in background.
12. One feature at a time. Build in order: Auth → Onboarding → Products → Sales → Dashboard.
