import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

/// Whether UI animations (page transitions, etc.) play. Persisted in
/// SharedPreferences; device-level so it stays out of the synced settings.
class MotionController extends Notifier<bool> {
  static const _key = 'app_motion_enabled';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? true;

  void set(bool enabled) {
    state = enabled;
    ref.read(sharedPreferencesProvider).setBool(_key, enabled);
  }
}

final motionEnabledProvider =
    NotifierProvider<MotionController, bool>(MotionController.new);
