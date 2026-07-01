import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../sync/sync_state_provider.dart';
import 'supabase_auth_service.dart';
import 'supabase_service.dart';
import 'supabase_storage_service.dart';
import 'supabase_sync_service.dart';

// ignore: unused_element
// SupabaseService.client is accessed directly where needed.

/// Provides the auth wrapper service.
final supabaseAuthServiceProvider = Provider<SupabaseAuthService>(
  (ref) => SupabaseAuthService(),
);

/// Provides the storage service for product image uploads.
final supabaseStorageServiceProvider = Provider<SupabaseStorageService>(
  (ref) => SupabaseStorageService(),
);

/// Provides the bidirectional sync service.
final supabaseSyncServiceProvider = Provider<SupabaseSyncService>(
  (ref) => SupabaseSyncService(
    isar: ref.watch(isarProvider),
    prefs: ref.watch(sharedPreferencesProvider),
    storage: ref.watch(supabaseStorageServiceProvider),
    syncState: ref.read(syncStateProvider.notifier),
  ),
);
