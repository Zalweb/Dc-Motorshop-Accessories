# Release & In-App Update Guide

> **MANDATORY READING FOR ALL AGENTS & DEVELOPERS:**
> This document details how to safely bump versions, build, test, deploy, and publish releases for **DC Motorcycle Inventory (MoSPAMS)** across both **Android** and **Web**, and explains the inner workings of the **In-App Auto-Update & Notification System**.

---

## 1. Zero Data Loss Guarantee (CRITICAL SAFETY RULES)

The client's business runs on this app. Data safety is the single highest priority.

### Why Sideloaded APK Upgrades Are 100% Safe:
1. **Android Package Identity**:
   - The application ID is `com.dcmotorcycle.dc_motorcycle_inventory` in `android/app/build.gradle.kts`.
   - When a user downloads and opens an updated APK with a higher `versionCode`, the Android OS triggers `ACTION_INSTALL_PACKAGE` (an **in-place update**).
   - Android **never deletes** the app data directory (`/data/data/com.dcmotorcycle.dc_motorcycle_inventory/`).
2. **Local Database Preservation**:
   - The Isar database files (`default.isar`), local SQLite tables, offline transaction queues, and SharedPreferences files remain intact in the internal app storage.
3. **Supabase Cloud Sync**:
   - Supabase auth tokens, offline sync queues, and device identifiers are retained across in-place upgrades.

### Golden Rules for Future Agents:
> [!CAUTION]
> 1. **NEVER change `applicationId`** (`com.dcmotorcycle.dc_motorcycle_inventory`) in `android/app/build.gradle.kts` or `AndroidManifest.xml`. Changing it causes Android to install a separate app and lose access to existing local databases!
> 2. **NEVER change the Android signing keystore** or debug/release keys in production. Key mismatch causes Android to reject the update with `INSTALL_FAILED_UPDATE_INCOMPATIBLE`.
> 3. **NEVER call `isar.clear()` or delete `.isar` files** during startup or migrations unless explicitly initiated by the user through the confirmed "Reset Data" option in More Settings.
> 4. **Always test data persistence** when changing Isar schema models. Run `dart run build_runner build` and ensure schema migrations do not drop existing collections.

---

## 2. In-App Update System Architecture

The update system is modular and platform-safe. It lives in `lib/core/update/`.

```
lib/core/
  constants/
    app_version.dart          → Central source of truth for version strings & repo metadata
  update/
    app_update_info.dart      → Data model for release metadata, notes, and APK download links
    app_update_service.dart   → Network service (GitHub Releases API + Supabase fallback)
    app_update_controller.dart→ Riverpod AsyncNotifier managing update state & dismissals
    version_comparator.dart   → Strict SemVer 2.0 comparison (major, minor, patch, build, prerelease)
    update_action.dart        → Conditional compilation barrel for platform update action
    update_action_stub.dart   → Native (Android/iOS) action: launches external APK download
    update_action_web.dart    → Web action: prompts and reloads window to bust cache
    widgets/
      update_banner.dart      → Animated top banner for available updates
      update_dialog.dart      → Detailed modal dialog with release notes & safety reassurance
```

### Detection Logic:
1. **Startup Check**:
   - On app launch, `appUpdateControllerProvider` runs `checkForUpdate()`.
   - Requests `GET https://api.github.com/repos/Zalweb/Dc-Motorshop-Accessories/releases/latest`.
   - Includes custom `User-Agent: MoSPAMS-App/<version>` header.
2. **30-Minute Cooldown Cache**:
   - Background checks are cached for 30 minutes (`backgroundCheckCooldown = Duration(minutes: 30)`) to avoid hitting GitHub unauthenticated rate limits (60 requests/hour per IP).
   - Manual checks (from **More → SYSTEM & UPDATES**) bypass the cache with `force: true`.
3. **Fallback to Supabase**:
   - If GitHub API fails or is rate-limited, the service queries the `app_config` table in Supabase.
4. **SemVer Comparison**:
   - Parsed by `AppSemanticVersion` (`lib/core/update/version_comparator.dart`).
   - If `latest.isNewerThan(current)` is `true`, `info.hasUpdate` is set to `true`.
   - If release notes contain `[MANDATORY]` or `REQUIRED`, `info.isMandatory` is flagged `true`.
5. **Presentation**:
   - **Non-mandatory update**: `UpdateNotificationBanner` smoothly slides down at the top of the screen. User can tap **Update Now** or dismiss with **✕**. Dismissals are stored in SharedPreferences per version (`app_update_dismissed_<version>`).
   - **Mandatory update**: `UpdateDialog` opens as a non-dismissible blocking modal.
   - **Manual check**: Available anytime under **More Settings** → **SYSTEM & UPDATES**.

---

## 3. Step-by-Step Release & Deployment Workflow

Whenever you are tasked with creating a new release or update, follow these steps in order:

### Step 1: Bump the App Version
Update the version in **two** places:
1. `pubspec.yaml` (line ~19):
   ```yaml
   version: 1.3.0+4   # Format: <major>.<minor>.<patch>+<buildNumber>
   ```
2. `lib/core/constants/app_version.dart`:
   ```dart
   static const String current = '1.3.0';
   static const int buildNumber = 4;
   ```

### Step 2: Run Automated Tests & Static Analysis
Always verify zero compiler errors and passing tests before building:
```powershell
# 1. Targeted dart analyze
dart analyze lib/core/update/ lib/core/constants/app_version.dart lib/core/providers_native.dart lib/core/providers_web.dart lib/features/more/more_screen.dart lib/features/shell/main_shell.dart

# 2. Run update test suite
flutter test test/version_comparator_test.dart test/app_update_service_test.dart test/app_update_controller_test.dart test/update_dialog_test.dart

# 3. Run regression tests
flutter test test/api_client_test.dart test/money_test.dart test/uuid_test.dart test/stock_health_test.dart
```

### Step 3: Build Web Release
```powershell
flutter build web --release --no-wasm-dry-run
```
*Output: `build\web`*

### Step 4: Build Android Release APK
```powershell
flutter build apk --release
```
*Output: `build\app\outputs\flutter-apk\app-release.apk`*

### Step 5: Deploy Web to Vercel & Map Domain
Deploy the newly compiled web assets to Vercel and alias the production domain:
```powershell
# Deploy production build
npx vercel deploy build\web --prod --yes --scope team_K5clGTGnllR07t5KnfzORXJB

# Re-alias the custom domain to the new deployment URL
npx vercel alias set <deployment-url> dcmotorshop.mospams.shop --scope team_K5clGTGnllR07t5KnfzORXJB
```

### Step 6: Commit and Push Code to GitHub
```powershell
git add .
git commit -m "feat: release v1.x.x with <brief description of changes>"
git push origin main
```

### Step 7: Create GitHub Release & Upload APK Asset
Use the GitHub CLI (`gh`) to publish the release and attach the APK:
```powershell
# Copy APK to friendly release name matching previous releases (MoSPAMS.<major>.<minor>.apk)
Copy-Item "build\app\outputs\flutter-apk\app-release.apk" "MoSPAMS.1.3.apk" -Force

# Create the release on GitHub
gh release create v1.3.0 MoSPAMS.1.3.apk --title "MoSPAMS v1.3.0" --notes "### MoSPAMS v1.3.0 Release Notes`n- Summary of changes...`n`n#### Download:`n- **[MoSPAMS 1.3.apk](https://github.com/Zalweb/Dc-Motorshop-Accessories/releases/download/v1.3.0/MoSPAMS.1.3.apk)**"

# Clean up temporary root copy
Remove-Item "MoSPAMS.1.3.apk" -Force
```

---

## 4. Dual-Platform Synchronization Rules (GEMINI.md Parity)

1. **State Parity**:
   - `lib/core/providers_native.dart` and `lib/core/providers_web.dart` must always define identical providers.
   - `appUpdateServiceProvider` and `appUpdateControllerProvider` must remain identical on both.
2. **Conditional Compilation**:
   - When calling platform-specific actions (e.g., launching an external browser vs. reloading the window), use the `update_action.dart` barrel:
     ```dart
     export 'update_action_stub.dart'
         if (dart.library.html) 'update_action_web.dart';
     ```
   - Never import `dart:html` or `dart:io` in shared UI widgets.
3. **Verification**:
   - Test both native and web targets before committing. Both must build with zero warnings or errors.

---

## 5. Troubleshooting & FAQs

| Issue | Cause | Solution |
|---|---|---|
| In-app banner doesn't appear after publishing release | 30-minute cooldown cache is active | Go to **More → SYSTEM & UPDATES** and tap **Check for Updates** to force a live check. |
| GitHub API returns 403 / Rate limit | Unauthenticated client exceeded 60 req/hr | App will automatically fall back to Supabase config and use cached data. |
| Android shows "Install unknown apps" prompt | User's browser doesn't have sideloading permission | Normal Android OS security behavior. User toggles "Allow from this source" once. |
| App crashes on launch after update | Broken Isar schema migration | Run `dart run build_runner build` before building APK, and never rename non-nullable fields without default values. |

## 6. Changelog

### v1.2.1+4
- Fixed silent image upload failures.
- Added limit(500) to unbounded Supabase sync queries.
- Optimized Supabase queries to fetch explicit columns.
- Implemented split-screen POS layout for wide screens.
- Added flutter_image_compress for pre-upload compression.
