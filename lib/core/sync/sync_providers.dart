import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_providers.dart';
import '../providers.dart';
import 'sync_service.dart';

final syncServiceProvider = Provider<SyncService>(
  (ref) => SyncService(
    isar: ref.watch(isarProvider),
    syncApi: ref.watch(syncApiProvider),
    salesApi: ref.watch(salesApiProvider),
    backupApi: ref.watch(backupApiProvider),
    imageApi: ref.watch(productImageApiProvider),
    tokens: ref.watch(secureTokenStoreProvider),
    prefs: ref.watch(sharedPreferencesProvider),
  ),
);
