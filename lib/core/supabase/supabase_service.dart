import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

/// Initializes the Supabase client and provides a convenient accessor.
///
/// Call [SupabaseService.initialize] once in main() before runApp().
/// After that, use [SupabaseService.client] anywhere in the app.
class SupabaseService {
  SupabaseService._();

  /// Initializes Supabase. Must be called before [client] is accessed.
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: kSupabaseUrl,
      anonKey: kSupabaseAnonKey,
      // Supabase Flutter stores the session in flutter_secure_storage
      // automatically — no manual token management needed.
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  /// The global Supabase client. Available after [initialize] is called.
  static SupabaseClient get client => Supabase.instance.client;

  /// Whether a user session currently exists (i.e. the user is logged in).
  static bool get hasSession => client.auth.currentSession != null;

  /// The current user's ID, or null if not logged in.
  static String? get currentUserId => client.auth.currentUser?.id;

  /// Stream of auth state changes (sign-in, sign-out, token refresh, etc.).
  static Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;
}
