import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Lightweight web-only session state.
///
/// On mobile the session is persisted in Isar + secure storage; on web we keep
/// only what the cloud-only data layer needs in-memory. Set once after login
/// or session restore, before any repository is consumed.
class WebSession {
  WebSession._();

  static const String _kCachedBusinessIdKey = 'web_cached_business_id';

  static String? userId;
  static String? businessId;

  /// Resolves the current user's business id from Supabase `business_profiles`.
  /// Returns null if there is no active session or no profile yet.
  static Future<String?> ensureBusinessId(SupabaseClient db) async {
    final uid = db.auth.currentUser?.id;
    if (uid == null) return null;
    if (businessId != null && businessId!.isNotEmpty) return businessId;

    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_kCachedBusinessIdKey);
      if (cached != null && cached.isNotEmpty) {
        businessId = cached;
        return businessId;
      }
    } catch (_) {}

    final res = await db
        .from('business_profiles')
        .select('id')
        .eq('owner_id', uid)
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();
    final id = res?['id']?.toString();
    if (id != null && id.isNotEmpty) {
      businessId = id;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kCachedBusinessIdKey, id);
      } catch (_) {}
    }
    return businessId;
  }

  static Future<void> clear() async {
    userId = null;
    businessId = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kCachedBusinessIdKey);
    } catch (_) {}
  }
}

