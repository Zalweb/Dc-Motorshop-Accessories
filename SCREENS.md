# Screen Map — DC Motorcycle Inventory
> **Read `CLAUDE.md` and `AGENT.md` before this file.**
> Derived from approved design images in `Mobile reference image/`.
> Each screen maps 1:1 to a Flutter route. Build in order shown.
> Do not reference any other app name in code, comments, or strings.

---

## Route Map

```
/splash                          → SplashScreen
/login                           → LoginScreen
/register                        → RegisterScreen
/onboarding/step-1               → OnboardingSetupShopScreen   (logo + theme)
/onboarding/step-2               → OnboardingReviewSetupScreen (categories only)
/onboarding/step-3               → OnboardingInviteStaffScreen (optional, last)
/onboarding/complete             → OnboardingCompleteScreen
/setup-checklist                 → SetupChecklistScreen
/dashboard                       → DashboardScreen  (shell route)
/sales                           → SalesHistoryScreen  (shell route)
/new-sale                        → NewSaleScreen  (shell route)
/products                        → ProductsScreen  (shell route)
/products/categories             → CategoriesScreen
/products/bulk-add               → BulkAddScreen
/products/add                    → AddProductScreen
/products/:id/edit               → EditProductScreen
/more                            → MoreScreen  (shell route)
/more/profile                    → ProfileScreen
```

---

## Screen Details

### 1. SplashScreen (`/splash`)
**Image ref:** 6.jpg
- Full black background
- App name "DC Motorcycle Inventory" centered bold
- Subtitle: "Welcome back! Preparing your dashboard..."
- 3-dot animated loader below
- Auto-navigate: check auth token → if valid go `/dashboard`, else `/login`

---

### 2. LoginScreen (`/login`)
**Image ref:** 1.jpg
- Logo icon (bar chart style, blue bg) centered upper third
- App name + tagline "Inventory made simple"
- `Username` label + rounded dark text field
- `Password` label + rounded dark text field + "Show" toggle
- "Forgot password?" link (right-aligned, accent color)
- Full-width blue "Sign in" button (pill shape)
- "Don't have an account? **Create one**" (accent link)
- App version at bottom

---

### 3. RegisterScreen (`/register`)
**Image ref:** 2.jpg
- Back chevron top-left
- Fields (top to bottom):
  - Username*
  - Email*
  - Password* (min 8 chars, show toggle)
  - Confirm Password*
  - --- ABOUT YOU · OPTIONAL section header ---
  - Full Name (optional)
  - Phone Number (optional, e.g. 09171234567)
- Terms & Privacy link
- Full-width blue "Create account" button
- "Already have an account? **Sign in**"

---

### 4. OnboardingSetupShopScreen (`/onboarding/step-1`)
**Image ref:** 4.jpg (theme picker)
- 3-segment progress bar, "Step 1 of 3 · Shop"
- Title: "Set up your shop" / subtitle mentions logo is optional
- LOGO · OPTIONAL: tap-to-add circle (image_picker, gallery); shows preview when set; skippable
- ACCENT COLOR: 3×3+1 grid of swatches — Green, **Blue** (default), Purple, Orange, Rose, Slate, Teal, Indigo, Amber, Cyan; selected = white border + checkmark
- Footer: **Continue** → step 2

---

### 5. OnboardingReviewSetupScreen (`/onboarding/step-2`)
**Image ref:** 3.jpg, 3.1.jpg
- 3-segment progress bar (2/3), "Step 2 of 3 · Categories"
- Title: "Review your categories"
- Summary card: motorcycle icon + "Motorcycle Shop" + "N categories"
- CATEGORIES: editable list (each removable) + "Add a category" input + Add button
- **No workflow-stage editing** (removed 2026-06-24 — stages keep defaults, edited later in settings)
- Footer: Back | **Looks good** → step 3

---

### 5b. OnboardingInviteStaffScreen (`/onboarding/step-3`)
**Image ref:** (implied)
- 3-segment progress bar (3/3), "Step 3 of 3 · Team"
- Optional. Info card + "Skip for now"
- Footer: Back | **Finish** → complete

---

### 6. OnboardingCompleteScreen (`/onboarding/complete`)
**Image ref:** 5.jpg
- Mascot illustration centered (celebratory)
- "You're all set!"
- "**DC Motorcycle Inventory** is ready for your first sale."
- Full-width blue "Go to dashboard" button
- "You can update settings anytime" caption

---

### 7. SetupChecklistScreen (`/setup-checklist`)
**Image ref:** 7.jpg, 8.jpg
- "Setup checklist" chip badge top center
- Title: "Finish setting up **DC Motorcycle Inventory**"
- "A few small steps so everything's ready for your first sale."
- Linear progress bar + "N of 8 done" + percentage
- **ESSENTIALS** section:
  - [x] Add your business logo
  - [x] Add address and phone number
  - [ ] Add your first product → "Add a product →"
  - [x] Set up your order workflow
- **FINE-TUNE** section:
  - [ ] Record your first expense → "Add an expense →"
  - [ ] Check your expense averaging window → "Review settings →"
  - [ ] Set up low-stock alerts → "Review alerts →"
  - [ ] Tell us your closed days → "Open calendar →"
- Bottom: "I'll come back to this" (left) | **Finish for now** (blue, right)

---

### 8. DashboardScreen (`/dashboard`)
**Image ref:** 9.jpg, 9.1.jpg

**Header:**
- Shop logo (circle avatar) + "DC Motorcycle Inventory"
- "Today ˅" date filter dropdown
- "Reports" button (top-right pill)

**Hero card (accent blue bg):**
- "REVENUE TODAY" label
- `₱0.00` large bold
- Sparkline chart placeholder
- "0 sales · ₱0.00 avg"

**AT A GLANCE grid (2 columns):**
| Card | Color | Icon |
|---|---|---|
| GROSS PROFIT | blue value | wallet |
| NET PROFIT | blue value | bar chart |
| COST OF GOODS | teal value | box |
| EXPENSES | amber, "Tap to add" | wallet-arrow |

**Full-width cards:**
- AVG TICKET → `₱0.00` (amber)
- DISCOUNT → `₱0.00` (purple)
- GROSS MARGIN → `0.0%` (blue)

---

### 9. SalesHistoryScreen (`/sales`)
**Image ref:** 10.jpg
- Title: "Sales History"
- Search bar: "Search by sale number or customer..."
- Filter icon button (with active count badge)
- Empty state: receipt icon + "No sales today" + "New sales today will show up here."
- Each sale item (when populated): sale number, customer, items count, total, timestamp

---

### 10. NewSaleScreen (`/new-sale`)
**Image ref:** 11.jpg
- Title: "New Sale"
- Search bar: "Search products..." + barcode scanner icon button (right)
- Filter chips: **ALL** (active/blue) · PRODUCTS · SERVICES
- Empty state: box icon + "No products" + "No products available."
- Bottom tray: cart icon + "No items yet — **Start with a product**"
- When items added: tray shows item count + total + Checkout button

---

### 11. ProductsScreen (`/products`)
**Image ref:** 12.jpg, 12.1.jpg
- Title: "Products"
- Search bar: "Search products..."
- Filter chips: **ALL** · PRODUCTS · SERVICES
- "N products" count label
- Product list (name, category, stock, price per item)
- Empty state: box icon + "No products found" + "Add products to get started."
- Blue FAB (+ icon) → expands to speed dial:
  - Add Add-on (box+ icon)
  - Categories (tree icon)
  - Bulk Add (stack icon)
  - Add Product (+ icon)

---

### 12. CategoriesScreen (`/products/categories`)
**Image ref:** 12.1.1
- Back chevron + "Categories" title
- List of categories: icon + name + "TOP" badge + chevron
- Default MC categories: Parts, Services (expandable to sub-categories)
- Blue + FAB to add new category

---

### 13. BulkAddScreen (`/products/bulk-add`)
**Image ref:** 12.1.2
- Back chevron + "Bulk Add Products" title
- Blue full-width "📷 SCAN BARCODES" button
- Manual input: "Enter barcode or add without" text field + add button
- Queue list area
- Empty state: scanner frame icon + "No products in queue" + instruction text

---

### 14. AddProductScreen (`/products/add`)
**Image ref:** 12.1.3, 12.1.3.1, 12.1.3.2

**Section: PRODUCT IMAGE**
- Dashed-border square tap area: image icon + "Tap to add photo"

**Section: BARCODE (OPTIONAL)**
- Text input "Enter barcode"
- Camera button (white rounded square)
- Barcode scanner button (blue rounded square)
- Helper: "Scan with camera or enter manually, then tap lookup to auto-fill"

**Section: PRODUCT DETAILS**
- Name* text field
- Category dropdown (Select category)
- Description multiline text field
- Part Number text field
- Brand text field
- Unit dropdown (piece/liter/set/pair)
- (No "compatible models" — the system tracks products, not motorcycles. Removed 2026-06-24.)

**Section: PRICING**
- Cost Price (₱0.00)
- Selling Price* (₱0.00)

**Section: INVENTORY**
- Stock Quantity number input
- Quick-add chips: `-1` `+1` `+5` `+10` `+50` `+100`

**Info card:** "AFTER SAVING, YOU CAN... Add variants · Link add-ons"

**Sticky bottom:** Blue "ADD PRODUCT" full-width button

---

### 15. MoreScreen (`/more`)
**Image ref:** 13.jpg
- Title: "More"
- Avatar (initials circle, blue bg)
- Full name + @username
- "My Profile" outline button
- **ACCOUNT** section: Email, Phone (grouped card)
- **BUSINESS** section: shop logo + name + slug + ACTIVE badge, Address (grouped card)
- (Scroll: more settings, logout)

---

## Build Order
```
Phase 1 — Foundation                                   [DONE]
  [x] Project scaffold (Flutter + Riverpod + GoRouter + isar_community)
  [x] Design system (theme, colors, text styles)
  [x] SplashScreen
  [x] LoginScreen + RegisterScreen (local stub auth + route guard)

Phase 2 — Onboarding                                   [DONE]
  [x] Onboarding 4-step flow (business type, review setup, invite staff, theme)
  [x] OnboardingComplete screen
  [x] SetupChecklistScreen (persisted progress)

Phase 3 — Core Features                                [DONE]
  [x] Bottom nav shell (5 tabs, center New Sale FAB)
  [x] ProductsScreen + AddProductScreen
  [x] CategoriesScreen + BulkAddScreen
  [x] Barcode scanner (mobile_scanner, offline) + camera permission

Phase 4 — POS                                          [DONE]
  [x] NewSaleScreen (search + scan-to-add + cart + checkout)
  [x] SalesHistoryScreen

Phase 5 — Dashboard & More                             [DONE]
  [x] DashboardScreen (revenue hero + metrics + add expense)
  [x] MoreScreen / Profile (account, business, logout)
  [x] BusinessCalendarScreen (tag closed days: holiday/day off/maintenance/other)
  [x] CustomersScreen (receivables ledger: balances per customer, search, mark paid)

Phase 6 — Polish & QA                                  [DONE]
  [x] ₱ formatting util, dev seed button, empty states
  [x] Unit tests (money, cart, onboarding render)

Phase 7 — Backend Sync                                 [FUTURE / out of scope]
  [ ] FastAPI backend setup
  [ ] Offline → online sync service
```
