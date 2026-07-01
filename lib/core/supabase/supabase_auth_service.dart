// ignore: unused_import — AuthResponse, Session, User, UserResponse, UserAttributes, AuthException are used below.
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// Wraps Supabase Auth for the DC Motorshop app.
///
/// Supabase handles JWT, refresh-token rotation, and secure storage
/// automatically. This class exposes a simple API that the
/// [AuthRepository] can call, with offline-detection so the existing
/// local-fallback logic stays intact.
class SupabaseAuthService {
  SupabaseClient get _auth => SupabaseService.client;

  // ── Registration ─────────────────────────────────────────────────────────

  /// Creates a new Supabase auth user and returns the session.
  ///
  /// Throws [AuthException] from supabase_flutter on validation errors
  /// (e.g. email already registered). Throws [SocketException] /
  /// [ClientException] when offline — the caller (AuthRepository) catches
  /// those and falls back to local registration.
  Future<AuthResponse> register({
    required String email,
    required String password,
    Map<String, dynamic>? metadata,
  }) async {
    return _auth.auth.signUp(
      email: email,
      password: password,
      data: metadata,
    );
  }

  // ── Sign in ───────────────────────────────────────────────────────────────

  /// Signs in with email + password.
  ///
  /// Returns the [AuthResponse] containing user + session on success.
  /// Throws on bad credentials or network error.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return _auth.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // ── Session ───────────────────────────────────────────────────────────────

  /// The currently active session, or null if signed out.
  Session? get currentSession => _auth.auth.currentSession;

  /// The currently signed-in user, or null if signed out.
  User? get currentUser => _auth.auth.currentUser;

  /// True if a valid session exists.
  bool get isSignedIn => currentSession != null;

  // ── Sign out ──────────────────────────────────────────────────────────────

  /// Signs out and invalidates the Supabase session.
  /// Best-effort when offline (local session is cleared regardless).
  Future<void> signOut() async {
    try {
      await _auth.auth.signOut();
    } on AuthException {
      // Ignore — local session cleared by the caller.
    }
  }

  // ── Profile updates ───────────────────────────────────────────────────────

  /// Updates the authenticated user's metadata fields.
  Future<UserResponse> updateUser({Map<String, dynamic>? data}) async {
    return _auth.auth.updateUser(UserAttributes(data: data));
  }

  // ── Business profile ──────────────────────────────────────────────────────

  /// Upserts the business_profiles row for the current user.
  ///
  /// Call this after registration (creates the row) or after onboarding
  /// (updates theme, settings, etc.).
  Future<void> upsertBusinessProfile(Map<String, dynamic> fields) async {
    final uid = _auth.auth.currentUser?.id;
    if (uid == null) return;

    await _auth
        .from('business_profiles')
        .upsert({...fields, 'owner_id': uid});
  }

  /// Fetches the business_profiles row for the current user.
  /// Returns null if no profile exists yet (pre-onboarding) or signed out.
  Future<Map<String, dynamic>?> fetchBusinessProfile() async {
    final uid = _auth.auth.currentUser?.id;
    if (uid == null) return null;

    final result = await _auth
        .from('business_profiles')
        .select()
        .eq('owner_id', uid)
        .maybeSingle();

    return result;
  }
}
