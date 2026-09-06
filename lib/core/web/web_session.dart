import 'package:supabase_flutter/supabase_flutter.dart';

/// Lightweight web-only session state.
///
/// On mobile the session is persisted in Isar + secure storage; on web we keep
/// only what the cloud-only data layer needs in-memory. Set once after login
/// or session restore, before any repository is consumed.
class WebSession {
  WebSession._();

  static String? userId;
  static String? businessId;

  /// Resolves the current user's business id from Supabase `business_profiles`.
  /// Returns null if there is no active session or no profile yet.
  static Future<String?> ensureBusinessId(SupabaseClient db) async {
    final uid = db.auth.currentUser?.id;
    if (uid == null) return null;
    if (businessId != null) return businessId;

    final res = await db
        .from('business_profiles')
        .select('id')
        .eq('owner_id', uid)
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();
    final id = res?['id']?.toString();
    if (id != null && id.isNotEmpty) businessId = id;
    return businessId;
  }

  static void clear() {
    userId = null;
    businessId = null;
  }
}
