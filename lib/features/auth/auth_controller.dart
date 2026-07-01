import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/supabase/supabase_providers.dart';
import '../../data/models/user.dart';

/// Holds the current session user (or null). The router watches this to guard
/// routes; screens call [login]/[register]/[logout].
class AuthController extends AsyncNotifier<User?> {
  @override
  Future<User?> build() => ref.read(authRepositoryProvider).currentUser();

  Future<void> login(String usernameOrEmail, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).login(usernameOrEmail, password),
    );
    _syncAfterAuth();
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    String? fullName,
    String? phone,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).register(
            username: username,
            email: email,
            password: password,
            fullName: fullName,
            phone: phone,
          ),
    );
    _syncAfterAuth();
  }

  /// Fire-and-forget sync after a successful sign-in so a returning device pulls
  /// its cloud data. Failures are ignored — the app stays usable offline.
  void _syncAfterAuth() {
    if (!state.hasValue || state.value == null) return;
    unawaited(() async {
      try {
        await ref.read(supabaseSyncServiceProvider).syncNow();
      } catch (_) {
        // Offline or transient — manual "Sync now" / reconnect will retry.
      }
    }());
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(null);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, User?>(AuthController.new);
