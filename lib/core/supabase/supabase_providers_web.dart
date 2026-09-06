import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../web/supabase_storage_service_web.dart';
import 'supabase_auth_service.dart';

/// Provides the auth wrapper service (shared with native — it is web-safe).
final supabaseAuthServiceProvider = Provider<SupabaseAuthService>(
  (ref) => SupabaseAuthService(),
);

/// Provides a web-safe storage service (no dart:io). Product/logo uploads use
/// bytes on web.
final supabaseStorageServiceProvider = Provider<SupabaseStorageServiceWeb>(
  (ref) => SupabaseStorageServiceWeb(),
);

/// Cloud-only sync: data already lives in Supabase, so sync is a no-op. These
/// are provided so screens that reference the sync service keep working.
final supabaseSyncServiceProvider = Provider<WebSyncService>(
  (ref) => WebSyncService(),
);

class WebSyncService {
  Future<bool> syncNow() async => true;
  Future<bool> restoreFromCloud() async => true;
  Future<bool> cleanupSalesAndDuplicates() async => true;
  Future<void> pushBusinessSettings(_) async {}
}
