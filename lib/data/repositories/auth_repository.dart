import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/supabase/supabase_auth_service.dart';
import '../../core/supabase/supabase_service.dart';
import '../models/business_settings.dart';
import '../models/user.dart';

/// Thrown when a sign-up or sign-in cannot be completed. The [message] is
/// safe to show directly in the UI.
class AuthException implements Exception {
  AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Online-first auth with an offline fallback.
///
/// When the device is online:
///   - register/login go through Supabase Auth.
///   - The Supabase session is stored securely by supabase_flutter.
///   - The account is mirrored into Isar so the app works offline.
///
/// When the network is down, register/login fall back to the local
/// salted-hash stub (unchanged from the original implementation).
class AuthRepository {
  AuthRepository(
    this._isar,
    this._prefs,
    this._supabaseAuth,
  );

  final Isar _isar;
  final SharedPreferences _prefs;
  final SupabaseAuthService _supabaseAuth;

  static const _sessionKey = 'session_user_id';

  Future<User> register({
    required String username,
    required String email,
    required String password,
    String? fullName,
    String? phone,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedUsername = username.trim();

    // SECURITY: Prevent overwriting existing local accounts if someone tries
    // to register with an email or username that already exists on this device.
    final existingLocal = await _isar.users
        .filter()
        .usernameEqualTo(normalizedUsername, caseSensitive: false)
        .or()
        .emailEqualTo(normalizedEmail, caseSensitive: false)
        .findFirst();

    if (existingLocal != null) {
      throw AuthException(
          'An account with that username or email already exists on this device. Please log in.');
    }

    try {
      final response = await _supabaseAuth.register(
        email: normalizedEmail,
        password: password,
        metadata: {
          'username': normalizedUsername,
          if (fullName != null && fullName.trim().isNotEmpty)
            'full_name': fullName.trim(),
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        },
      );

      if (response.user == null) {
        throw AuthException(
            'Registration failed. Check your email for a confirmation link.');
      }

      return _adoptSupabaseUser(
        sbUser: response.user!,
        password: password,
        username: normalizedUsername,
        fullName: fullName,
        phone: phone,
      );
    } on sb.AuthException catch (e) {
      throw AuthException(_friendlyAuthError(e.message));
    } catch (e) {
      // Network error → fall back to local registration.
      if (_isNetworkError(e)) {
        return _registerLocal(
          username: normalizedUsername,
          email: normalizedEmail,
          password: password,
          fullName: fullName,
          phone: phone,
        );
      }
      if (e is AuthException) rethrow;
      throw AuthException('Registration failed. Please try again.');
    }
  }

  Future<User> login(String usernameOrEmail, String password) async {
    final query = usernameOrEmail.trim();

    // Supabase Auth requires email; if the user typed a username, look it up
    // locally first.
    String email = query;
    if (!query.contains('@')) {
      final localUser = await _isar.users
          .filter()
          .usernameEqualTo(query, caseSensitive: false)
          .findFirst();
      if (localUser != null) {
        email = localUser.email;
      }
    }

    try {
      final response = await _supabaseAuth.signIn(
        email: email.toLowerCase(),
        password: password,
      );

      if (response.user == null) {
        throw AuthException('Incorrect email or password.');
      }

      return _adoptSupabaseUser(
        sbUser: response.user!,
        password: password,
        username: response.user!.userMetadata?['username'] as String? ?? email,
        fullName: response.user!.userMetadata?['full_name'] as String?,
        phone: response.user!.userMetadata?['phone'] as String?,
      );
    } on sb.AuthException {
      // Try offline fallback before throwing.
      try {
        return _loginLocal(query, password);
      } catch (_) {
        throw AuthException('Incorrect username or password.');
      }
    } catch (e) {
      if (_isNetworkError(e)) {
        return _loginLocal(query, password);
      }
      if (e is AuthException) rethrow;
      throw AuthException('Login failed. Please try again.');
    }
  }

  Future<User?> currentUser() async {
    // If Supabase has an active session, mirror it in Isar.
    final sbUser = _supabaseAuth.currentUser;
    if (sbUser != null) {
      final existing = await _isar.users
          .filter()
          .uidEqualTo(sbUser.id)
          .findFirst();
      if (existing != null) {
        await _setSession(existing.id);
        return existing;
      }
    }

    // Fall back to the local session id stored in SharedPreferences.
    final id = _prefs.getInt(_sessionKey);
    if (id == null) return null;
    return _isar.users.get(id);
  }

  Future<void> logout() async {
    await _supabaseAuth.signOut();
    await _prefs.remove(_sessionKey);
  }

  /// Links an existing local-only account to Supabase Auth.
  ///
  /// Call this when the user registered offline and now wants to enable
  /// cloud sync. Requires the user's current password to authenticate.
  Future<void> linkAccountToCloud({required String password}) async {
    // Load the currently logged-in local user.
    final id = _prefs.getInt(_sessionKey);
    if (id == null) throw AuthException('No active session found.');

    final user = await _isar.users.get(id);
    if (user == null) throw AuthException('Local account not found.');

    // Check if already linked (has a Supabase UID that isn't empty).
    if (user.uid.isNotEmpty) {
      // Already has a UID — try signing in to confirm it's still valid.
      try {
        await _supabaseAuth.signIn(
            email: user.email, password: password);
        return; // already linked and working
      } on sb.AuthException {
        // UID set but Supabase doesn't know about it — fall through to register.
      }
    }

    // Register the account in Supabase Auth.
    try {
      final response = await _supabaseAuth.register(
        email: user.email,
        password: password,
        metadata: {
          'username': user.username,
          if (user.fullName != null && user.fullName!.isNotEmpty)
            'full_name': user.fullName,
        },
      );

      if (response.user == null) {
        throw AuthException('Cloud registration failed. Please try again.');
      }

      // Update the local record with the Supabase UID.
      user.uid = response.user!.id;
      await _isar.writeTxn(() async => _isar.users.put(user));
    } on sb.AuthException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('already registered') || msg.contains('already exists')) {
        // Account exists in Supabase — just sign in to get the session.
        final signInRes = await _supabaseAuth.signIn(
          email: user.email,
          password: password,
        );
        if (signInRes.user != null) {
          user.uid = signInRes.user!.id;
          await _isar.writeTxn(() async => _isar.users.put(user));
          return;
        }
      }
      throw AuthException(_friendlyAuthError(e.message));
    }
  }

  Future<void> markNewShopSetupComplete(int userId) async {
    final user = await _isar.users.get(userId);
    if (user == null) return;
    user.newShopSetup = true;
    await _isar.writeTxn(() async => _isar.users.put(user));

    // Best-effort server sync.
    try {
      if (SupabaseService.hasSession) {
        await _supabaseAuth.updateUser(
          data: {'new_shop_setup': true},
        );
      }
    } catch (_) {
      // Ignored — will reconcile on next sync.
    }
  }

  // ── Supabase session adoption ─────────────────────────────────────────────

  Future<User> _adoptSupabaseUser({
    required sb.User sbUser,
    required String password,
    required String username,
    String? fullName,
    String? phone,
  }) async {
    final salt = _generateSalt();

    final existing = await _isar.users
        .filter()
        .uidEqualTo(sbUser.id)
        .or()
        .emailEqualTo(sbUser.email ?? '', caseSensitive: false)
        .or()
        .usernameEqualTo(username, caseSensitive: false)
        .findFirst();

    User userToSave;
    if (existing != null) {
      userToSave = existing
        ..uid = sbUser.id
        ..username = username
        ..email = sbUser.email ?? ''
        ..passwordSalt = salt
        ..passwordHash = _hash(password, salt);
        
      if (fullName?.trim().isNotEmpty == true) {
        userToSave.fullName = fullName!.trim();
      }
      if (phone?.trim().isNotEmpty == true) {
        userToSave.phone = phone!.trim();
      }
    } else {
      userToSave = User()
        ..uid = sbUser.id
        ..username = username
        ..email = sbUser.email ?? ''
        ..fullName = fullName?.trim().isNotEmpty == true ? fullName!.trim() : null
        ..phone = phone?.trim().isNotEmpty == true ? phone!.trim() : null
        ..passwordSalt = salt
        ..passwordHash = _hash(password, salt);
    }

    await _isar.writeTxn(() async {
      final settings =
          await _isar.businessSettings.get(BusinessSettings.singletonId) ??
              BusinessSettings();
      
      try {
        final profile = await SupabaseService.client
            .from('business_profiles')
            .select()
            .eq('owner_id', sbUser.id)
            .maybeSingle();

        if (profile != null) {
          settings.uid = profile['id'] as String;
          settings.businessName = profile['business_name'] as String? ?? '';
          settings.businessType = profile['business_type'] as String? ?? '';
          settings.address = profile['address'] as String? ?? '';
          settings.phone = profile['phone'] as String? ?? '';
          settings.email = profile['email'] as String? ?? '';
          if (profile['logo_url'] != null) {
            settings.logoPath = profile['logo_url'] as String;
          }
          
          userToSave.onboardingComplete = profile['onboarding_complete'] as bool? ?? true;
          userToSave.newShopSetup = profile['new_shop_setup'] as bool? ?? true;
        }
      } catch (_) {
        // Silently continue if network fails or no profile exists yet
      }
      
      await _isar.users.put(userToSave);
      await _isar.businessSettings.put(settings);
    });

    await _setSession(userToSave.id);
    return userToSave;
  }

  // ── Offline fallback ──────────────────────────────────────────────────────

  Future<User> _registerLocal({
    required String username,
    required String email,
    required String password,
    String? fullName,
    String? phone,
  }) async {
    final existing = await _isar.users
        .filter()
        .usernameEqualTo(username, caseSensitive: false)
        .or()
        .emailEqualTo(email, caseSensitive: false)
        .findFirst();
    if (existing != null) {
      throw AuthException('That username or email is already taken.');
    }

    final salt = _generateSalt();
    final user = User()
      ..username = username
      ..email = email
      ..passwordSalt = salt
      ..passwordHash = _hash(password, salt)
      ..fullName = (fullName?.trim().isEmpty ?? true) ? null : fullName!.trim()
      ..phone = (phone?.trim().isEmpty ?? true) ? null : phone!.trim();

    await _isar.writeTxn(() async => _isar.users.put(user));
    await _setSession(user.id);
    return user;
  }

  Future<User> _loginLocal(String query, String password) async {
    final user = await _isar.users
        .filter()
        .usernameEqualTo(query, caseSensitive: false)
        .or()
        .emailEqualTo(query.toLowerCase(), caseSensitive: false)
        .findFirst();

    if (user == null ||
        user.passwordHash.isEmpty ||
        _hash(password, user.passwordSalt) != user.passwordHash) {
      throw AuthException('Incorrect username or password.');
    }
    await _setSession(user.id);
    return user;
  }

  Future<void> _setSession(int userId) =>
      _prefs.setInt(_sessionKey, userId);

  String _generateSalt() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    return base64Url.encode(bytes);
  }

  String _hash(String password, String salt) {
    final digest = sha256.convert(utf8.encode('$salt:$password'));
    return digest.toString();
  }

  bool _isNetworkError(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains('socketexception') ||
        msg.contains('network') ||
        msg.contains('connection') ||
        msg.contains('timeout') ||
        msg.contains('failed host lookup');
  }

  String _friendlyAuthError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('already registered') ||
        lower.contains('already exists') ||
        lower.contains('duplicate')) {
      return 'An account with that email already exists.';
    }
    if (lower.contains('invalid') || lower.contains('weak password')) {
      return 'Password is too weak. Use at least 6 characters.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Please confirm your email before logging in.';
    }
    return 'Authentication failed. Please try again.';
  }

  /// Updates the stored password hash for the user matching [email].
  /// Used by the forgot-password reset flow.
  Future<void> changePasswordByEmail({
    required String email,
    required String newPassword,
  }) async {
    final user = await _isar.users
        .filter()
        .emailEqualTo(email.toLowerCase(), caseSensitive: false)
        .findFirst();

    if (user == null) {
      return; // Not found locally, just skip local update.
    }

    final salt = _generateSalt();
    final hash = _hash(newPassword, salt);

    await _isar.writeTxn(() async {
      user.passwordSalt = salt;
      user.passwordHash = hash;
      await _isar.users.put(user);
    });
  }
}

