import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/supabase/supabase_auth_service.dart';
import '../../core/supabase/supabase_service.dart';
import '../../core/web/web_session.dart';
import '../models/user_web.dart';

/// Thrown when a sign-up or sign-in cannot be completed. The [message] is
/// safe to show directly in the UI.
class AuthWebException implements Exception {
  AuthWebException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Web-safe, Supabase-backed auth repository (cloud-only). Online only — the
/// offline Isar salted-hash fallback is not available on web.
class AuthRepositoryWeb {
  AuthRepositoryWeb(this._supabaseAuth);

  final SupabaseAuthService _supabaseAuth;

  Future<User> register({
    required String username,
    required String email,
    required String password,
    String? fullName,
    String? phone,
  }) async {
    final response = await _supabaseAuth.register(
      email: email.trim().toLowerCase(),
      password: password,
      metadata: {
        'username': username.trim(),
        if (fullName != null && fullName.trim().isNotEmpty)
          'full_name': fullName.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      },
    );
    if (response.user == null) {
      throw AuthWebException(
          'Registration failed. Check your email for a confirmation link.');
    }
    return _fromSupabase(response.user!);
  }

  Future<User> login(String usernameOrEmail, String password) async {
    final response = await _supabaseAuth.signIn(
      email: usernameOrEmail.trim().toLowerCase(),
      password: password,
    );
    if (response.user == null) {
      throw AuthWebException('Incorrect email or password.');
    }
    await WebSession.ensureBusinessId(SupabaseService.client);
    return _fromSupabase(response.user!);
  }

  Future<User?> currentUser() async {
    final sbUser = _supabaseAuth.currentUser;
    if (sbUser == null) return null;
    await WebSession.ensureBusinessId(SupabaseService.client);
    return _fromSupabase(sbUser);
  }

  Future<void> logout() async {
    await _supabaseAuth.signOut();
    WebSession.clear();
  }

  Future<void> markNewShopSetupComplete(int userId) async {
    try {
      if (SupabaseService.hasSession) {
        await _supabaseAuth.updateUser(data: {'new_shop_setup': true});
      }
    } catch (_) {
      // Best effort on web.
    }
  }

  /// Web is always cloud-linked, so this is a no-op (the user is already using
  /// Supabase auth). Kept so the cloud-sync screen compiles.
  Future<void> linkAccountToCloud({required String password}) async {}

  Future<void> changePasswordByEmail({
    required String email,
    required String newPassword,
  }) async {
    // On web use Supabase's own reset flow (emails a reset link).
    await SupabaseService.client.auth.resetPasswordForEmail(email.trim());
  }

  User _fromSupabase(sb.User sbUser) {
    WebSession.userId = sbUser.id;
    return User()
      ..uid = sbUser.id
      ..username = sbUser.userMetadata?['username'] as String? ?? ''
      ..email = sbUser.email ?? ''
      ..fullName = sbUser.userMetadata?['full_name'] as String?
      ..phone = sbUser.userMetadata?['phone'] as String?
      ..onboardingComplete = sbUser.userMetadata?['onboarding_complete'] as bool? ?? true
      ..newShopSetup = sbUser.userMetadata?['new_shop_setup'] as bool? ?? false;
  }
}
