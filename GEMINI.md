# Workspace Behavioral Instructions: 100% Mobile & Web Synchronization

> **CRITICAL RULE FOR ALL AI AGENTS & SESSIONS:**
> **Mobile and Web MUST be kept in 100% synchronization at all times.**
> Every code edit, feature addition, model change, and UI component must function seamlessly on both Mobile (Android/iOS) and Web.

---

## Non-Negotiable Rules

1. **Dual-Platform Parity**:
   - Every feature must be available and operational on both Mobile and Web.
   - If a screen, dialog, payment flow, scanner integration, or reporting feature is added or updated, it must work identically on both platforms.

2. **Model & State Synchronization**:
   - Any property, method, or validation added to `lib/data/models/*_native.dart` MUST be added to `lib/data/models/*_web.dart` and vice versa.
   - Riverpod state providers in `lib/core/providers_native.dart` and `lib/core/providers_web.dart` must stay in 100% parity.

3. **Web-Safe Coding Standards**:
   - NEVER import `dart:io` or instantiate `File(...)` in shared UI widgets or logic without platform-safe conditional imports/stubs. Use `AppImage` (`lib/shared/widgets/app_image.dart`) for all image rendering.
   - NEVER import `dart:html` or browser-only libraries into native code.
   - Use conditional compilation barrels (`export '..._stub.dart' if (dart.library.html) '..._web.dart';`) for platform-divergent functions (e.g. printing, file sharing).

4. **Responsive UI Architecture**:
   - Adaptive viewports: Mobile uses bottom navigation and modal bottom sheets; Web/Desktop ($\ge$ 800px) uses sidebar navigation and split-screen POS with a persistent right-hand cart.
   - Both layouts bind to identical Riverpod controllers and backend data streams.

5. **Validation Requirement**:
   - Test every change to ensure zero compiler errors on both native and web targets before marking any task as complete.

6. **Data Safety & Release Preservation**:
   - NEVER modify the Android `applicationId` (`com.dcmotorcycle.dc_motorcycle_inventory`), keystore signing keys, or wipe local Isar databases during updates.
   - Sideloaded updates MUST be performed via in-place APK upgrades to preserve all client inventory, sales, and settings.
   - Always follow `RELEASE_AND_UPDATE_GUIDE.md` when bumping versions or deploying new releases.

