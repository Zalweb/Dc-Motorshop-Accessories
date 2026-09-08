import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers.dart';
import 'app_update_info.dart';

/// Notifier that manages app update status and dismissal state.
class AppUpdateNotifier extends AsyncNotifier<AppUpdateInfo?> {
  static const String dismissedVersionKey = 'mospams_dismissed_update_version';

  @override
  Future<AppUpdateInfo?> build() async {
    // Web is continuously updated via cloud hosting; bypass update check
    if (kIsWeb) return null;
    // Check for updates on startup using cache cooldown
    return _fetchUpdate(force: false);
  }

  Future<AppUpdateInfo?> _fetchUpdate({required bool force}) async {
    if (kIsWeb) return null;
    final service = ref.read(appUpdateServiceProvider);
    final updateInfo = await service.checkForUpdate(force: force);
    if (updateInfo == null) return null;

    final dismissed = await isDismissed(updateInfo.latestVersion);
    return updateInfo.copyWith(isDismissed: dismissed);
  }

  /// Checks for available updates.
  /// Set [force] to true to bypass cache and dismissal check (e.g. manual user refresh).
  Future<AppUpdateInfo?> checkForUpdate({bool force = false}) async {
    if (kIsWeb) return null;
    state = const AsyncValue.loading();
    try {
      final updateInfo = await _fetchUpdate(force: force);
      state = AsyncValue.data(updateInfo);
      return updateInfo;
    } catch (e, st) {
      debugPrint('[AppUpdateNotifier] Error checking for updates: $e');
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Whether the user dismissed this update version in a previous prompt.
  Future<bool> isDismissed(String version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getString(dismissedVersionKey);
      return dismissed == version;
    } catch (_) {
      return false;
    }
  }

  /// Records that the user dismissed this update version and reactively updates state.
  Future<void> dismiss(String version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(dismissedVersionKey, version);
    } catch (_) {}

    final current = state.value;
    if (current != null && current.latestVersion == version) {
      state = AsyncValue.data(current.copyWith(isDismissed: true));
    }
  }

  /// Clears any dismissed update version record and reactively updates state.
  Future<void> clearDismissed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(dismissedVersionKey);
    } catch (_) {}

    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(isDismissed: false));
    }
  }
}
